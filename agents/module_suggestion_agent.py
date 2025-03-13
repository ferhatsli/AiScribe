from typing import Dict, List, Optional
import json
from autogen_agentchat.agents import AssistantAgent
from autogen_ext.models.openai import OpenAIChatCompletionClient
from openai import OpenAI

class ModuleSuggestionAgent(AssistantAgent):
    """Agent responsible for determining which modules should be active and generating appropriate suggestions."""
    
    # Define standard modules and their question templates
    MODULES = {
        "character": {
            "name": "Character Module",
            "questions": [
                "What is the character's appearance?",
                "What is the character's emotional state?",
                "What is the character's pose or position?",
                "What is the character wearing?",
                "What accessories or items does the character have?"
            ]
        },
        "setting": {
            "name": "Setting Module",
            "questions": [
                "What season or time period is it?",
                "What are the weather conditions?",
                "What specific details about the environment should be emphasized?",
                "What is the lighting like?",
                "What is the overall color palette?"
            ]
        },
        "atmosphere": {
            "name": "Atmosphere Module",
            "questions": [
                "What mood should the scene convey?",
                "What emotional response should it evoke?",
                "What artistic style should be used?",
                "Should there be any special effects or atmospheric elements?",
                "What is the desired level of realism vs. stylization?"
            ]
        },
        "action": {
            "name": "Action Module",
            "questions": [
                "What specific action is taking place?",
                "What is the intensity of the action?",
                "What is the direction or flow of movement?",
                "Are there any secondary actions or movements?",
                "How should the action be captured (e.g., motion blur, freeze frame)?"
            ]
        }
    }
    
    def __init__(self, name: str = "module_suggester", model_client=None, **kwargs):
        self._suggestion_system_message = """You are a specialized agent for selecting relevant modules 
        and generating suggestions for text-to-image prompts. Your task is to analyze the prompt analysis
        results and determine which modules should be active and what questions should be asked to improve
        the prompt.
        
        You work with standard modules:
        1. Character Module - For character-related details
        2. Setting Module - For environment and scene details
        3. Atmosphere Module - For mood and style details
        4. Action Module - For movement and action details
        
        For each module, determine if it should be active based on the prompt analysis,
        and generate relevant questions and suggestions for improvement."""
        
        if model_client is None:
            model_client = OpenAIChatCompletionClient(
                model="gpt-4o-mini"
            )
            
        super().__init__(
            name=name,
            system_message=self._suggestion_system_message,
            model_client=model_client,
            **kwargs
        )
        
        # Create OpenAI client for direct API calls
        self.client = OpenAI()
        
    def determine_active_modules(self, analysis_result: Dict) -> Dict:
        """
        Determines which modules should be active based on the analysis results.
        
        Args:
            analysis_result: The analysis results from the PromptAnalysisAgent
            
        Returns:
            Dict containing active modules and their status
        """
        active_modules = {}
        
        # Check for character elements
        if "categorized_elements" in analysis_result and "Characters" in analysis_result["categorized_elements"]:
            active_modules["character"] = {
                "active": True,
                "existing_elements": analysis_result["categorized_elements"]["Characters"]
            }
        else:
            active_modules["character"] = {"active": False}
            
        # Check for setting elements
        if "categorized_elements" in analysis_result and "Places" in analysis_result["categorized_elements"]:
            active_modules["setting"] = {
                "active": True,
                "existing_elements": analysis_result["categorized_elements"]["Places"]
            }
        else:
            active_modules["setting"] = {"active": False}
            
        # Check for atmosphere elements
        if "categorized_elements" in analysis_result and "Emotions/Style" in analysis_result["categorized_elements"]:
            active_modules["atmosphere"] = {
                "active": True,
                "existing_elements": analysis_result["categorized_elements"]["Emotions/Style"]
            }
        else:
            active_modules["atmosphere"] = {"active": False}
            
        # Check for action elements
        if "categorized_elements" in analysis_result and "Actions/Processes" in analysis_result["categorized_elements"]:
            active_modules["action"] = {
                "active": True,
                "existing_elements": analysis_result["categorized_elements"]["Actions/Processes"]
            }
        else:
            active_modules["action"] = {"active": False}
            
        return active_modules
    
    async def generate_suggestions(self, analysis_result: Dict) -> Dict:
        """
        Generates module-specific suggestions and questions based on the analysis results.
        
        Args:
            analysis_result: The analysis results from the PromptAnalysisAgent
            
        Returns:
            Dict containing suggestions and questions for each active module
        """
        suggestion_prompt = f"""Based on the following prompt analysis, generate specific suggestions and questions:

Analysis: {json.dumps(analysis_result, indent=2)}

Please provide:
1. List of active modules
2. For each active module:
   - Relevant questions based on missing elements
   - Specific suggestions for improvement
3. Additional modules that should be considered

Format the response as a JSON object."""

        # Get suggestions from the model
        response = self.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": self._suggestion_system_message},
                {"role": "user", "content": suggestion_prompt}
            ]
        )
        
        try:
            # Extract the JSON from the response
            suggestion_text = response.choices[0].message.content
            json_start = suggestion_text.find('{')
            json_end = suggestion_text.rfind('}') + 1
            if json_start >= 0 and json_end > json_start:
                suggestions = json.loads(suggestion_text[json_start:json_end])
            else:
                suggestions = {
                    "error": "Could not parse JSON from response",
                    "raw_response": suggestion_text
                }
            return suggestions
        except Exception as e:
            return {
                "error": f"Error parsing suggestions: {str(e)}",
                "raw_response": response.choices[0].message.content
            }
    
    async def process_prompt_analysis(self, analysis_result: Dict) -> Dict:
        """
        Main method to process the analysis results and generate a complete module suggestion response.
        
        Args:
            analysis_result: The analysis results from the PromptAnalysisAgent
            
        Returns:
            Dict containing active modules, suggestions, and questions
        """
        # Determine which modules should be active
        active_modules = self.determine_active_modules(analysis_result)
        
        # Generate suggestions based on the analysis
        suggestions = await self.generate_suggestions(analysis_result)
        
        # Combine results
        return {
            "active_modules": active_modules,
            "suggestions": suggestions,
            "standard_questions": {
                module: self.MODULES[module]["questions"]
                for module, status in active_modules.items()
                if status["active"]
            }
        } 