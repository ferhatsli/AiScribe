from fastapi import APIRouter, HTTPException, Depends, Request
from typing import List, Dict, Optional, Any
import json
import re
from copy import deepcopy

# Use relative imports within the package
from ...agents.user_proxy import user_proxy
from ...agents.prompt_analyzer_agent import prompt_analyzer
from ...agents.module_suggester_agent import module_suggester
from ...agents.question_agent import question_agent
from ...agents.prompt_finalizer_agent import prompt_finalizer
from ...agents.language_detector_agent import language_detector
from ...agents.auto_prompt_expander_agent import auto_prompt_expander

# Use relative imports for schemas
from ...schemas.prompt import PromptRequest, PromptResponse, QuestionItem, AnswerItem

# Import dependencies for auth
from ..dependencies import get_current_user, get_optional_user

router = APIRouter()

def _safe_json_loads(text: str) -> Optional[Dict[str, Any]]:
    """Attempts to parse JSON, returning None on failure."""
    try:
        text = re.sub(r"^```json\n?", "", text.strip(), flags=re.MULTILINE)
        text = re.sub(r"\n?```$", "", text.strip(), flags=re.MULTILINE)
        return json.loads(text)
    except json.JSONDecodeError:
        try:
            fixed_text = re.sub(r",\s*([}\]])", r"\1", text)
            fixed_text = re.sub(r"//.*", "", fixed_text)
            return json.loads(fixed_text)
        except json.JSONDecodeError:
             return None

def _call_agent(recipient: Any, message: str, silent: bool = True) -> Optional[str]:
    """Helper function to call an agent and return the last message content."""
    try:
        # Make sure user_proxy is correctly initialized and accessible here
        # If UserProxyAgent needs specific setup that happens in run.py, that logic needs to be centralized or replicated.
        # For now, assume user_proxy is usable as imported.
        result = user_proxy.initiate_chat(
            recipient=recipient,
            message=message,
            summary_method=None,
            silent=silent,
            max_turns=2
        )
        if result.chat_history and len(result.chat_history) > 1:
            # Assuming the agent's final response is the last message in the history
            return result.chat_history[-1]["content"]
        else:
            print(f"Warning: No valid response in chat history for recipient {recipient.name}")
            return None
    except Exception as e:
        print(f"Error during agent call to {recipient.name}: {e}")
        # Consider re-raising or raising HTTPException for API context
        # raise HTTPException(status_code=500, detail=f"Agent call failed: {e}")
        return None

@router.post("/generate", response_model=PromptResponse, tags=["Prompt Generation"])
async def generate_prompt_flow(request: PromptRequest, user=Depends(get_optional_user), req: Request = None) -> PromptResponse:
    """
    Processes a user prompt through a multi-agent workflow:
    1. (Optional) Expands the prompt.
    2. Detects language (if not provided).
    3. Analyzes prompt for scores and elements.
    4. Suggests active modules.
    5. If no answers provided: Generates clarifying questions.
    6. If answers provided: Generates a final, enhanced prompt.
    
    Authentication is optional - if user is authenticated, their preferences can be used.
    """
    # Authenticated user'ı kontrol et
    if user:
        print(f"User authenticated: {user.get('email', 'unknown')}")
        # İsteğe bağlı: kullanıcı tercihlerini ekleyebilirsiniz
        
    current_prompt = request.prompt
    expansions_list: Optional[List[str]] = None
    final_prompt: Optional[str] = None
    questions_list: Optional[List[QuestionItem]] = None
    categorized_elements: Optional[Dict[str, List[str]]] = None
    qa_list_resp: Optional[List[AnswerItem]] = request.answers

    # --- 1. Auto Expansion (Optional) ---
    if request.auto_expand:
        print("API: Expanding prompt...")
        expander_response = _call_agent(auto_prompt_expander, current_prompt)
        if expander_response:
            parsed_expansions = _safe_json_loads(expander_response)
            if parsed_expansions and "expansions" in parsed_expansions:
                expansions_list = parsed_expansions["expansions"]
                print(f"API: Expansions generated: {len(expansions_list)}")
            else:
                print(f"API Warning: Failed to parse expansions JSON or key missing: {expander_response}")
        else:
            print("API Warning: No response from AutoExpander.")

    # --- 2. Language Detection --- 
    effective_language_code = "en" # Default
    if request.language_code:
        if len(request.language_code) == 2 and request.language_code.isalpha():
            effective_language_code = request.language_code.lower()
            print(f"API: Using provided language code: {effective_language_code}")
        else:
            print(f"API Warning: Invalid provided language code '{request.language_code}'. Detecting...")
            request.language_code = None

    if not request.language_code:
        print("API: Detecting language...")
        detector_response = _call_agent(language_detector, current_prompt)
        if detector_response:
            detected_code = detector_response.strip().lower()
            if len(detected_code) == 2 and detected_code.isalpha():
                effective_language_code = detected_code
                print(f"API: Detected language: {effective_language_code}")
            else:
                 print(f"API Warning: Invalid language code '{detected_code}' detected. Defaulting to 'en'.")
        else:
            print("API Warning: Language detection failed. Defaulting to 'en'.")

    # --- 3. Prompt Analysis --- 
    print("API: Analyzing prompt...")
    analyzer_message = f"User language: {effective_language_code}. Please analyze this prompt: '{current_prompt}'"
    analyzer_response = _call_agent(prompt_analyzer, analyzer_message)
    module_scores = {}
    if analyzer_response:
        parsed_analysis = _safe_json_loads(analyzer_response)
        if parsed_analysis:
            module_scores = parsed_analysis.get("scores", {})
            categorized_elements = parsed_analysis.get("categorized_elements", {})
            print(f"API: Analysis complete. Scores: {module_scores}, Elements: {categorized_elements}")
        else:
             print(f"API Error: Failed to parse analyzer response JSON: {analyzer_response}")
             # Return HTTP Exception on critical failure
             raise HTTPException(status_code=500, detail="Failed to parse analysis from PromptAnalyzer.")
    else:
        print("API Error: No response from PromptAnalyzer.")
        raise HTTPException(status_code=500, detail="No response from PromptAnalyzer.")

    # --- 4. Module Suggestion --- 
    print("API: Suggesting modules...")
    suggester_message = f"User language: {effective_language_code}. Here are the module scores: {json.dumps(module_scores)}"
    suggester_response = _call_agent(module_suggester, suggester_message)
    active_modules = {}
    if suggester_response:
        parsed_suggestion = _safe_json_loads(suggester_response)
        if parsed_suggestion and "active_modules" in parsed_suggestion:
            active_modules = parsed_suggestion["active_modules"]
            print(f"API: Suggested active modules: {active_modules}")
        else:
             print(f"API Error: Failed to parse suggester response JSON: {suggester_response}")
             # Proceeding with empty active_modules if parsing fails
    else:
        print("API Warning: No response from ModuleSuggester. Proceeding without suggestions.")

    # --- 5/6. Question Generation OR Finalization --- 
    if request.answers:
        # --- 6a. Finalize Prompt --- 
        print("API: Finalizing prompt using provided answers...")

        # Stil bilgisini categorized_elements'e ekle
        if request.style:
            if categorized_elements is None:
                categorized_elements = {}
            categorized_elements.setdefault("Style", []).append(request.style)

        finalizer_input = {
            "original_prompt": current_prompt,
            "categorized_elements": categorized_elements,
            "qa_list": [ans.dict() for ans in request.answers]
        }
        finalizer_message = f"User language: {effective_language_code}. Final prompt generation input:\n{json.dumps(finalizer_input, indent=2)}"
        finalizer_response = _call_agent(prompt_finalizer, finalizer_message, silent=False)

        if finalizer_response:
            final_prompt = finalizer_response.strip()
            print(f"API: Final prompt generated.")
            return PromptResponse(
                status="prompt_finalized",
                final_prompt=final_prompt,
                categorized_elements=categorized_elements,
                language_code=effective_language_code,
                qa_list=qa_list_resp,
                expansions=expansions_list
            )
        else:
             print("API Error: No response from PromptFinalizer.")
             raise HTTPException(status_code=500, detail="Failed to finalize prompt after receiving answers.")
    else:
        # --- 5a. Generate Questions --- 
        print("API: Generating questions...")
        question_input = {
            "language_code": effective_language_code,
            "active_modules": deepcopy(active_modules),
            "categorized_elements": deepcopy(categorized_elements)
        }
        question_message = f"Question generation input:\n{json.dumps(question_input, indent=2)}"
        question_response = _call_agent(question_agent, question_message)
        
        questions_list = [] # Initialize as empty list
        if question_response:
            parsed_questions = _safe_json_loads(question_response)
            if parsed_questions and "questions" in parsed_questions:
                try:
                    # Validate structure before creating QuestionItem objects
                    valid_questions = []
                    for q in parsed_questions["questions"]:
                        if isinstance(q, dict) and "module" in q and "question" in q and "examples" in q and isinstance(q["examples"], list):
                            valid_questions.append(QuestionItem(**q))
                        else:
                            print(f"API Warning: Skipping invalid question structure: {q}")
                    questions_list = valid_questions
                    print(f"API: Questions generated: {len(questions_list)}")
                except Exception as e:
                     print(f"API Error: Failed to parse question items structure: {parsed_questions.get('questions', 'N/A')} - Error: {e}")
                     # questions_list remains empty
            else:
                print(f"API Warning: Failed to parse question response JSON or key missing: {question_response}")
                # questions_list remains empty
        else:
            print("API Warning: No response from QuestionAgent.")
            # questions_list remains empty
            
        # If no questions were generated (either error or logic decided none needed)
        if not questions_list:
             print("API: No questions generated, proceeding to finalize without Q&A.")
             # Directly call finalizer without answers
             finalizer_input = {
                 "original_prompt": current_prompt,
                 "categorized_elements": categorized_elements,
                 "qa_list": [] # Empty list as no questions were asked/answered
             }
             finalizer_message = f"User language: {effective_language_code}. Final prompt generation input (no Q&A):\n{json.dumps(finalizer_input, indent=2)}"
             finalizer_response = _call_agent(prompt_finalizer, finalizer_message, silent=False)

             if finalizer_response:
                 final_prompt = finalizer_response.strip()
                 print(f"API: Final prompt generated directly (no questions).")
                 return PromptResponse(
                     status="prompt_finalized",
                     final_prompt=final_prompt,
                     categorized_elements=categorized_elements,
                     language_code=effective_language_code,
                     qa_list=[],
                     expansions=expansions_list
                 )
             else:
                 print("API Error: No response from PromptFinalizer during direct finalization.")
                 raise HTTPException(status_code=500, detail="Failed to finalize prompt (direct path).")
        else:
            # Return generated questions for the user
            return PromptResponse(
                status="questions_generated",
                questions=questions_list,
                categorized_elements=categorized_elements,
                language_code=effective_language_code,
                expansions=expansions_list
            ) 