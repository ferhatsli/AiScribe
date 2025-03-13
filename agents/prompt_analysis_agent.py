from typing import Dict, List, Optional
import json
from autogen_agentchat.agents import AssistantAgent
from autogen_ext.models.openai import OpenAIChatCompletionClient
from openai import OpenAI

class PromptAnalysisAgent(AssistantAgent):
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
        
        if model_client is None:
            model_client = OpenAIChatCompletionClient(
                model="gpt-4o-mini"
            )
            
        super().__init__(
            name=name,
            system_message=self._analysis_system_message,
            model_client=model_client,
            **kwargs
        )
        
        # Create OpenAI client for direct API calls
        self.client = OpenAI()
        
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
            # Find the JSON part (assuming it's properly formatted)
            json_start = analysis_text.find('{')
            json_end = analysis_text.rfind('}') + 1
            if json_start >= 0 and json_end > json_start:
                analysis_json = json.loads(analysis_text[json_start:json_end])
            else:
                # Fallback if JSON parsing fails
                analysis_json = {
                    "error": "Could not parse JSON from response",
                    "raw_response": analysis_text
                }
            return analysis_json
        except Exception as e:
            return {
                "error": f"Error parsing analysis: {str(e)}",
                "raw_response": response.choices[0].message.content
            }

# Example usage:
"""
from autogen_ext.models.openai import OpenAIChatCompletionClient

# Initialize the model client
model_client = OpenAIChatCompletionClient(
    model="gpt-4",
    api_key="your-api-key"
)

# Create the agent
analyzer = PromptAnalysisAgent(model_client=model_client)

# Analyze a prompt
prompt = "Little Red Riding Hood walking through a misty forest at dawn"
analysis = await analyzer.analyze_prompt(prompt)
print(json.dumps(analysis, indent=2))
""" 