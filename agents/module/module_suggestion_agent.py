from typing import Dict
import json
from ..base.base_agent import BaseAgent
from ..utils.json_utils import extract_json_from_text, create_error_response
from .module_config import MODULES

class ModuleSuggestionAgent(BaseAgent):
    """Agent responsible for determining which modules should be active and generating appropriate suggestions."""
    
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
        
        super().__init__(
            name=name,
            system_message=self._suggestion_system_message,
            model_client=model_client,
            **kwargs
        )
        
        # Store module configurations
        self.modules = MODULES
        
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
            suggestion_text = response.choices[0].message.content
            suggestions = extract_json_from_text(suggestion_text)
            if suggestions:
                return suggestions
            return create_error_response(
                "Could not parse JSON from response",
                suggestion_text
            )
        except Exception as e:
            return create_error_response(
                f"Error parsing suggestions: {str(e)}",
                response.choices[0].message.content
            )
    
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
                module: self.modules[module]["questions"]
                for module, status in active_modules.items()
                if status["active"]
            }
        } 