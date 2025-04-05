from typing import Dict, Optional
from ..base.base_agent import BaseAgent
from .session_manager import QuestionSession
from .response_analyzer import ResponseAnalyzer
from .question_generator import QuestionGenerator
import json

class DynamicQuestionAgent(BaseAgent):
    """Agent responsible for generating dynamic, context-sensitive questions and managing user responses."""
    
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
        
        super().__init__(
            name=name,
            system_message=self._question_system_message,
            model_client=model_client,
            **kwargs
        )
        
        # Initialize components
        self.session = QuestionSession()
        self.analyzer = ResponseAnalyzer(self.client)
        self.generator = QuestionGenerator(self.client)
    
    async def process_module_suggestions(self, module_suggestions: Dict) -> Dict:
        """
        Process module suggestions and initialize a question session.
        
        Args:
            module_suggestions: Output from ModuleSuggestionAgent
            
        Returns:
            Dict containing initial question and session info
        """
        # Initialize new session
        self.session.initialize_session(module_suggestions)
        
        # Generate initial question
        initial_question = await self.generator.generate_next_question(
            context=self.session.get_session_state()
        )
        
        return {
            "initial_question": initial_question,
            "session_state": self.session.get_session_state()
        }
    
    def record_response(self, question: Dict, response: str):
        """
        Record a user's response to a question.
        
        Args:
            question: The question that was asked
            response: The user's response
        """
        self.session.record_response(question, response)
    
    async def generate_next_question(self, previous_response: Optional[Dict] = None) -> Optional[Dict]:
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
        if previous_response and "response" in previous_response:
            response_analysis = self.analyzer.analyze_response(previous_response["response"])
        
        # Generate next question
        return await self.generator.generate_next_question(
            context=self.session.get_session_state(),
            response_analysis=response_analysis,
            initial_prompt=initial_prompt
        )
    
    async def generate_final_prompt(self) -> str:
        """
        Generate the final enhanced prompt based on all responses.
        
        Returns:
            The final enhanced prompt string
        """
        # Create a prompt to generate the final text
        history = self.session.get_response_history()
        prompt = f"""Based on these question-answer pairs, generate an enhanced image prompt:

Questions and Answers:
{json.dumps(history, indent=2)}

Create a detailed, cohesive prompt that:
1. Incorporates all the provided information
2. Maintains a natural, flowing description
3. Emphasizes the most important elements
4. Includes technical aspects (style, composition, lighting)

Return only the final prompt text."""

        response = self.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You create enhanced image prompts from user responses."},
                {"role": "user", "content": prompt}
            ]
        )
        
        return response.choices[0].message.content.strip() 