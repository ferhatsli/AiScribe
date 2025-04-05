from typing import Dict, Any, Optional
import json
from openai import OpenAI
from .question_templates import QUESTION_TEMPLATES

class QuestionGenerator:
    """Generates dynamic, context-sensitive questions based on user responses."""
    
    def __init__(self, client: OpenAI):
        self.client = client
        self.templates = QUESTION_TEMPLATES
    
    async def generate_next_question(
        self,
        context: Dict[str, Any],
        response_analysis: Optional[Dict[str, float]] = None,
        initial_prompt: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Generate the next appropriate question based on the current context and previous responses.
        
        Args:
            context: Current session context
            response_analysis: Analysis of the previous response (if any)
            initial_prompt: The initial prompt that started the session
            
        Returns:
            Dict containing the next question, options, and examples
        """
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
3. Helps gather missing but important details

Format the response as a JSON object with:
- question: The question text
- options: List of 3-4 possible answers
- examples: List of example responses
- module: The primary module this question relates to
- category: The specific category within the module"""

        response = self.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You generate contextual questions for image prompts."},
                {"role": "user", "content": prompt}
            ]
        )
        
        try:
            question_text = response.choices[0].message.content
            json_start = question_text.find('{')
            json_end = question_text.rfind('}') + 1
            if json_start >= 0 and json_end > json_start:
                return json.loads(question_text[json_start:json_end])
        except Exception:
            # Fallback to template-based question
            return self._get_fallback_question(context)
    
    def _get_fallback_question(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Generate a fallback question based on templates and context."""
        # Find the first incomplete module
        for module, status in context["progress"].items():
            if status["completed"] < status["total"]:
                template = self.templates.get(module, {})
                if template:
                    first_category = next(iter(template))
                    question_data = template[first_category]
                    return {
                        "question": question_data["question"],
                        "options": question_data["options"],
                        "examples": [question_data["examples"]],
                        "module": module,
                        "category": first_category
                    }
        
        # If all modules are complete or no templates available, return a general question
        return {
            "question": "What other details would you like to add to the image?",
            "options": ["Add more detail", "Enhance mood", "Adjust composition", "Complete as is"],
            "examples": ["Add more intricate details to the background"],
            "module": "general",
            "category": "refinement"
        } 