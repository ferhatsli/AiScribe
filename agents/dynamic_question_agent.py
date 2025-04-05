from typing import Dict, List, Optional
import json
from autogen_agentchat.agents import AssistantAgent
from autogen_ext.models.openai import OpenAIChatCompletionClient
from openai import OpenAI

class DynamicQuestionAgent(AssistantAgent):
    """Agent responsible for generating dynamic, context-sensitive questions and managing user responses."""
    
    # Define question templates with examples and options
    QUESTION_TEMPLATES = {
        "character": {
            "appearance": {
                "question": "What should the character's appearance be like?",
                "options": ["young", "elderly", "tall", "petite"],
                "examples": "For example: 'A tall, slender figure with flowing silver hair'",
                "follow_up": {
                    "facial_expression": {
                        "question": "What facial expression should the character have?",
                        "options": ["cheerful", "determined", "mysterious", "worried"],
                        "examples": "For example: 'A gentle smile with knowing eyes'"
                    },
                    "clothing": {
                        "question": "What should the character be wearing?",
                        "options": ["casual", "formal", "fantasy", "period-specific"],
                        "examples": "For example: 'A flowing red cloak with golden trim'"
                    }
                }
            }
        },
        "setting": {
            "environment": {
                "question": "What kind of environment should be depicted?",
                "options": ["natural", "urban", "fantasy", "historical"],
                "examples": "For example: 'A misty forest at dawn'",
                "follow_up": {
                    "weather": {
                        "question": "What should the weather conditions be?",
                        "options": ["clear", "rainy", "stormy", "misty"],
                        "examples": "For example: 'Light fog with rays of sunlight breaking through'"
                    },
                    "time": {
                        "question": "What time of day/season should it be?",
                        "options": ["dawn", "noon", "dusk", "night"],
                        "examples": "For example: 'Early morning in autumn'"
                    }
                }
            }
        },
        "atmosphere": {
            "mood": {
                "question": "What mood should the scene convey?",
                "options": ["peaceful", "mysterious", "dramatic", "whimsical"],
                "examples": "For example: 'A serene and mystical atmosphere'",
                "follow_up": {
                    "lighting": {
                        "question": "How should the lighting enhance the mood?",
                        "options": ["soft", "dramatic", "ethereal", "dark"],
                        "examples": "For example: 'Soft, golden light filtering through trees'"
                    }
                }
            }
        },
        "action": {
            "movement": {
                "question": "What kind of movement or action should be shown?",
                "options": ["walking", "running", "floating", "dancing"],
                "examples": "For example: 'Gracefully dancing in the wind'",
                "follow_up": {
                    "intensity": {
                        "question": "What should be the intensity of the action?",
                        "options": ["gentle", "dynamic", "frozen", "flowing"],
                        "examples": "For example: 'A gentle, flowing movement'"
                    }
                }
            }
        }
    }
    
    def __init__(self, name: str = "question_generator", model_client=None, **kwargs):
        self._question_system_message = """You are a specialized agent for generating dynamic, 
        context-sensitive questions about text-to-image prompts. Your task is to create an 
        interactive question flow that helps users provide detailed information for their prompts.
        
        You should:
        1. Generate appropriate questions based on active modules
        2. Provide example answers and suggestions
        3. Adapt questions based on previous responses
        4. Track progress and maintain context
        
        Always format responses clearly and provide helpful examples."""
        
        if model_client is None:
            model_client = OpenAIChatCompletionClient(
                model="gpt-4o-mini"
            )
            
        super().__init__(
            name=name,
            system_message=self._question_system_message,
            model_client=model_client,
            **kwargs
        )
        
        # Create OpenAI client for direct API calls
        self.client = OpenAI()
        
        # Initialize session storage
        self.current_session = {
            "active_modules": {},
            "responses": {},
            "progress": {},
            "question_history": []
        }
    
    def initialize_session(self, module_suggestions: Dict):
        """
        Initialize a new question session based on active modules.
        
        Args:
            module_suggestions: The output from ModuleSuggestionAgent
        """
        self.current_session = {
            "active_modules": module_suggestions["active_modules"],
            "responses": {},
            "progress": {
                module: {"completed": 0, "total": len(self.QUESTION_TEMPLATES.get(module, {}))}
                for module in module_suggestions["active_modules"]
                if module_suggestions["active_modules"][module]["active"]
            },
            "question_history": []
        }
    
    def analyze_response_content(self, response: str) -> Dict:
        """
        Analyze the content of a response to determine which modules it relates to.
        
        Args:
            response: The user's response text
            
        Returns:
            Dict containing detected modules and their relevance scores
        """
        # Create a prompt to analyze the response
        analysis_prompt = f"""Analyze this response and determine which modules it relates to:
        Response: "{response}"
        
        Consider these aspects and rate their relevance from 0.0 to 1.0:
        1. Character details (appearance, expressions, clothing)
        2. Setting details (environment, weather, time)
        3. Atmosphere details (mood, lighting, feeling)
        4. Action details (movement, interaction, poses)
        
        Return a JSON object with module relevance scores."""
        
        try:
            analysis_response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": "You analyze text to identify relevant modules."},
                    {"role": "user", "content": analysis_prompt}
                ]
            )
            
            analysis_text = analysis_response.choices[0].message.content
            json_start = analysis_text.find('{')
            json_end = analysis_text.rfind('}') + 1
            if json_start >= 0 and json_end > json_start:
                analysis = json.loads(analysis_text[json_start:json_end])
                # Convert to simple relevance scores if nested structure
                if isinstance(analysis.get("character_details"), dict):
                    return {
                        "character": sum(1 for v in analysis["character_details"].values() if v) / 3 if analysis["character_details"] else 0.0,
                        "setting": sum(1 for v in analysis["setting_details"].values() if v) / 3 if analysis["setting_details"] else 0.0,
                        "atmosphere": sum(1 for v in analysis["atmosphere_details"].values() if v) / 3 if analysis["atmosphere_details"] else 0.0,
                        "action": sum(1 for v in analysis["action_details"].values() if v) / 3 if analysis["action_details"] else 0.0
                    }
                return analysis
        except Exception:
            # Fallback to basic keyword analysis
            return {
                "character": 1.0 if ("character" in response.lower() or "figure" in response.lower()) else 0.0,
                "setting": 1.0 if ("forest" in response.lower() or "environment" in response.lower()) else 0.0,
                "atmosphere": 1.0 if ("mood" in response.lower() or "mysterious" in response.lower()) else 0.0,
                "action": 1.0 if ("standing" in response.lower() or "moving" in response.lower()) else 0.0
            }
    
    async def generate_next_question(self, previous_response: Optional[Dict] = None) -> Dict:
        """
        Generate the next appropriate question based on the current context and previous responses.
        
        Args:
            previous_response: The user's response to the previous question (if any)
            
        Returns:
            Dict containing the next question, options, and examples
        """
        # Get the initial prompt if provided
        initial_prompt = previous_response.get("initial_prompt") if previous_response else None
        
        # Analyze the previous response if provided
        response_analysis = None
        intended_module = None
        actual_module = None
        
        if previous_response:
            # Get the intended module from the question
            intended_module = previous_response["question"].get("module", "general")
            # Analyze what the response actually contained
            response_analysis = self.analyze_response_content(previous_response["response"])
            # Determine the most relevant module from the response
            if isinstance(response_analysis, dict):
                # Find the module with highest relevance score, ensuring we handle nested dictionaries
                relevance_scores = {}
                for module, value in response_analysis.items():
                    if isinstance(value, dict):
                        # If it's a nested structure, calculate average of values
                        relevance_scores[module] = sum(float(v) for v in value.values()) / len(value)
                    else:
                        # If it's a direct score
                        relevance_scores[module] = float(value)
                actual_module = max(relevance_scores.items(), key=lambda x: x[1])[0] if relevance_scores else None
        
        context = {
            "session": self.current_session,
            "previous_response": previous_response,
            "response_analysis": response_analysis,
            "intended_module": intended_module,
            "actual_module": actual_module,
            "initial_prompt": initial_prompt  # Include initial prompt in context
        }
        
        prompt = f"""Based on the current context and keeping in mind the initial prompt: "{initial_prompt}", generate the next appropriate question.

Context: {json.dumps(context, indent=2)}

Special considerations:
1. Ensure the question maintains relevance to the initial prompt theme
2. If the previous response contained information for a different module than intended,
   consider whether to:
   a) Ask a follow-up question about the provided information
   b) Gently redirect back to the intended module
   c) Adapt the question flow to the user's natural direction

3. Ensure the question builds upon all previously provided information,
   even if it was given in response to questions about different modules.

Generate a question that:
1. Follows naturally from previous responses
2. Is relevant to active modules and initial prompt theme
3. Includes helpful examples and options
4. Adapts to the user's level of detail

Format the response as a JSON object with:
- id: A unique identifier for the question
- module: The module this question belongs to
- question: The actual question text
- options: List of possible answers (keep these focused on the initial prompt theme)
- examples: List of example responses
- adaptation_reason: Explanation of why this question was chosen"""

        response = self.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": self._question_system_message},
                {"role": "user", "content": prompt}
            ]
        )
        
        try:
            question_text = response.choices[0].message.content
            json_start = question_text.find('{')
            json_end = question_text.rfind('}') + 1
            if json_start >= 0 and json_end > json_start:
                question = json.loads(question_text[json_start:json_end])
                # Ensure required fields are present
                if "id" not in question:
                    question["id"] = f"q_{len(self.current_session['question_history'])}"
                if "module" not in question:
                    question["module"] = "general"
                if "adaptation_reason" not in question:
                    question["adaptation_reason"] = "Following standard question flow"
                return question
            else:
                return {
                    "id": f"q_{len(self.current_session['question_history'])}",
                    "module": "general",
                    "error": "Could not parse JSON from response",
                    "question": "What would you like to specify about the image?",
                    "options": ["character", "setting", "atmosphere", "action"],
                    "examples": ["A mysterious character", "A forest at dawn", "A dramatic scene"],
                    "adaptation_reason": "Fallback due to parsing error"
                }
        except Exception as e:
            return {
                "id": f"q_{len(self.current_session['question_history'])}",
                "module": "general",
                "error": f"Error generating question: {str(e)}",
                "question": "What would you like to specify about the image?",
                "options": ["character", "setting", "atmosphere", "action"],
                "examples": ["A mysterious character", "A forest at dawn", "A dramatic scene"],
                "adaptation_reason": "Fallback due to error"
            }
    
    def record_response(self, question: Dict, response: str) -> None:
        """
        Record a user's response to a question and update progress.
        
        Args:
            question: The question that was asked
            response: The user's response
        """
        # Add response to history
        self.current_session["responses"][question["id"]] = response
        self.current_session["question_history"].append({
            "question": question,
            "response": response,
            "timestamp": "now"  # You might want to use actual timestamps
        })
        
        # Update progress
        if "module" in question:
            module = question["module"]
            if module in self.current_session["progress"]:
                self.current_session["progress"][module]["completed"] += 1
    
    def get_session_progress(self) -> Dict:
        """
        Get the current progress of the question session.
        
        Returns:
            Dict containing progress information for each module
        """
        return {
            "progress": self.current_session["progress"],
            "completed_questions": len(self.current_session["responses"]),
            "remaining_modules": [
                module for module, progress in self.current_session["progress"].items()
                if progress["completed"] < progress["total"]
            ]
        }
    
    async def process_module_suggestions(self, module_suggestions: Dict) -> Dict:
        """
        Process module suggestions and prepare the initial question set.
        
        Args:
            module_suggestions: The output from ModuleSuggestionAgent
            
        Returns:
            Dict containing the initial questions and session information
        """
        # Initialize new session
        self.initialize_session(module_suggestions)
        
        # Generate initial question
        initial_question = await self.generate_next_question()
        
        return {
            "session_id": "session_" + str(hash(str(module_suggestions)))[:8],
            "initial_question": initial_question,
            "active_modules": self.current_session["active_modules"],
            "progress": self.get_session_progress()
        }

    async def generate_final_prompt(self) -> str:
        """
        Generates a final, cohesive prompt from all collected responses in a natural, flowing style.
        
        Returns:
            str: A well-structured prompt combining all elements
        """
        # Collect all responses and categorize them
        prompt_elements = {
            "character": [],
            "setting": [],
            "action": [],
            "atmosphere": [],
            "style": ["cinematic composition", "professional photography", "highly detailed", "masterful composition"]  # Default style elements
        }
        
        # Process responses and categorize them
        for qa in self.current_session["question_history"]:
            module = qa["question"].get("module", "general")
            response = qa["response"]
            
            # Clean and process the response
            response = response.strip()
            if response:
                if module in prompt_elements:
                    prompt_elements[module].append(response)
                elif module == "general":
                    # Analyze the response to determine the best category
                    analysis = self.analyze_response_content(response)
                    if isinstance(analysis, dict):
                        # Find the most relevant category
                        max_relevance = 0
                        best_category = None
                        for category, score in analysis.items():
                            if isinstance(score, (int, float)) and score > max_relevance:
                                max_relevance = score
                                best_category = category
                        if best_category and best_category in prompt_elements:
                            prompt_elements[best_category].append(response)
        
        # Create the prompt generation request
        generation_prompt = f"""Create a cohesive, natural-flowing prompt that combines these elements:

Character details: {"; ".join(prompt_elements["character"]) if prompt_elements["character"] else "N/A"}
Setting details: {"; ".join(prompt_elements["setting"]) if prompt_elements["setting"] else "N/A"}
Action details: {"; ".join(prompt_elements["action"]) if prompt_elements["action"] else "N/A"}
Atmosphere details: {"; ".join(prompt_elements["atmosphere"]) if prompt_elements["atmosphere"] else "N/A"}
Style elements: {"; ".join(prompt_elements["style"])}

Format it as a single, flowing description that reads naturally, similar to this example:
"Little Red Riding Hood, in a detailed and realistic illustration, in the depths of the forest, under the dramatic sunlight filtering through the trees, walking with care and determination with her red cape; The dense, vibrant green vegetation surrounding her, elegant floral details and mystical atmosphere are professionally depicted with a cinematic composition and atmospheric lighting."

Requirements:
1. Start with the main subject/character and their key attributes
2. Flow naturally into the setting and atmosphere
3. Incorporate actions and movements
4. End with technical/style specifications
5. Use semicolons to separate major scene elements
6. Maintain a natural, descriptive flow throughout
7. Include all provided details while avoiding repetition
8. Ensure the prompt reads as one cohesive description"""

        # Generate the final prompt
        response = self.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a specialist in creating cohesive, natural-flowing image generation prompts that combine multiple elements into a single, compelling description."},
                {"role": "user", "content": generation_prompt}
            ]
        )
        
        return response.choices[0].message.content.strip() 