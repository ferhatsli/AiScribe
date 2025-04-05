from typing import Dict, List, Any

class QuestionSession:
    """Manages the state and progress of a question session."""
    
    def __init__(self):
        self.reset()
    
    def reset(self):
        """Reset the session state."""
        self.current_session = {
            "active_modules": {},
            "responses": {},
            "progress": {},
            "question_history": []
        }
    
    def initialize_session(self, module_suggestions: Dict[str, Any]):
        """
        Initialize a new question session based on active modules.
        
        Args:
            module_suggestions: The output from ModuleSuggestionAgent
        """
        self.current_session = {
            "active_modules": module_suggestions["active_modules"],
            "responses": {},
            "progress": {
                module: {"completed": 0, "total": len(module_suggestions.get("standard_questions", {}).get(module, []))}
                for module in module_suggestions["active_modules"]
                if module_suggestions["active_modules"][module]["active"]
            },
            "question_history": []
        }
    
    def record_response(self, question: Dict[str, Any], response: str):
        """
        Record a user's response to a question.
        
        Args:
            question: The question that was asked
            response: The user's response
        """
        # Add to response history
        self.current_session["responses"][question["question"]] = response
        
        # Add to question history
        self.current_session["question_history"].append({
            "question": question,
            "response": response
        })
        
        # Update progress if module is specified
        if "module" in question:
            module = question["module"]
            if module in self.current_session["progress"]:
                self.current_session["progress"][module]["completed"] += 1
    
    def get_session_state(self) -> Dict[str, Any]:
        """Get the current session state."""
        return self.current_session
    
    def get_response_history(self) -> List[Dict[str, Any]]:
        """Get the history of questions and responses."""
        return self.current_session["question_history"]
    
    def get_module_progress(self, module: str) -> Dict[str, int]:
        """Get the progress for a specific module."""
        return self.current_session["progress"].get(module, {"completed": 0, "total": 0}) 