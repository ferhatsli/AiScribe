from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any

class AnswerItem(BaseModel):
    question: str
    answer: str

class PromptRequest(BaseModel):
    prompt: str = Field(..., description="The user's initial prompt.")
    auto_expand: bool = Field(False, description="Whether to generate expanded prompt options.")
    language_code: Optional[str] = Field(None, description="Optional ISO 639-1 language code (e.g., 'en', 'tr'). If None, language will be detected.")
    # Note: selected_expansion_index is included as requested, but its handling in a single API call is complex.
    # The current implementation focuses on returning expansions if auto_expand=True.
    # A client would typically call again with the selected prompt text.
    selected_expansion_index: Optional[int] = Field(None, description="Index of the chosen expansion (if applicable, client-managed).")
    answers: Optional[List[AnswerItem]] = Field(None, description="List of user answers to previously generated questions.")
    style: Optional[str] = None

class QuestionItem(BaseModel):
    module: str
    question: str
    examples: List[str]

class PromptResponse(BaseModel):
    status: str = Field(..., description="Indicates the result ('expansions_generated', 'questions_generated', 'prompt_finalized', 'error').")
    final_prompt: Optional[str] = Field(None, description="The final generated text-to-image prompt.")
    expansions: Optional[List[str]] = Field(None, description="List of expanded prompt versions, if requested.")
    questions: Optional[List[QuestionItem]] = Field(None, description="List of questions generated for the user to answer.")
    qa_list: Optional[List[AnswerItem]] = Field(None, description="The list of question-answer pairs used for finalization (from request).")
    categorized_elements: Optional[Dict[str, List[str]]] = Field(None, description="Elements extracted from the prompt by the analyzer.")
    language_code: Optional[str] = Field(None, description="The detected or provided language code.")
    error_message: Optional[str] = Field(None, description="Error details if the status is 'error'.") 