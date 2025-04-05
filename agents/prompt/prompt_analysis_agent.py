from typing import Dict
from ..base.base_agent import BaseAgent
from ..utils.json_utils import extract_json_from_text, create_error_response

class PromptAnalysisAgent(BaseAgent):
    """Agent responsible for analyzing text-to-image prompts and extracting structured information."""
    
    def __init__(self, name: str = "prompt_analyzer", model_client=None, **kwargs):
        self._analysis_system_message = """You are a specialized agent for analyzing text-to-image prompts.
        Your task is to break down prompts into structured components and identify key elements
        that make a prompt effective or areas where it could be improved.
        
        You analyze:
        1. Keywords and phrases
        2. Categories (Character, Place, Action, Emotion/Style)
        3. Grammatical structure
        4. Overall atmosphere
        5. Missing or insufficient elements
        
        Provide your analysis in a clear, structured format."""
        
        super().__init__(
            name=name,
            system_message=self._analysis_system_message,
            model_client=model_client,
            **kwargs
        )
    
    async def analyze_prompt(self, prompt: str) -> Dict:
        """
        Analyzes the given prompt and returns structured information.
        
        Args:
            prompt: The text-to-image prompt to analyze
            
        Returns:
            Dict containing the analysis results
        """
        analysis_prompt = f"""Analyze the following text-to-image prompt and break it down into its components:

Prompt: "{prompt}"

Please provide a detailed analysis including:
1. Extracted keywords and phrases
2. Categorized elements:
   - Characters
   - Places
   - Actions/Processes
   - Emotions/Style
3. Overall atmosphere/tone
4. Missing or insufficient elements
5. Suggestions for improvement

Format the response as a JSON object."""

        # Create a completion using OpenAI directly
        response = self.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": self._analysis_system_message},
                {"role": "user", "content": analysis_prompt}
            ]
        )
        
        try:
            # Extract the JSON from the response
            analysis_text = response.choices[0].message.content
            analysis_json = extract_json_from_text(analysis_text)
            if analysis_json:
                return analysis_json
            return create_error_response(
                "Could not parse JSON from response",
                analysis_text
            )
        except Exception as e:
            return create_error_response(
                f"Error parsing analysis: {str(e)}",
                response.choices[0].message.content
            ) 