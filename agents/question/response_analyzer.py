from typing import Dict
from openai import OpenAI

class ResponseAnalyzer:
    """Analyzes user responses to determine relevance to different modules."""
    
    def __init__(self, client: OpenAI):
        self.client = client
    
    def analyze_response(self, response: str) -> Dict[str, float]:
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
                analysis = eval(analysis_text[json_start:json_end])
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