from autogen_agentchat.agents import AssistantAgent
from autogen_ext.models.openai import OpenAIChatCompletionClient
from openai import OpenAI

class BaseAgent(AssistantAgent):
    """Base agent class with common functionality."""
    
    def __init__(self, name: str, system_message: str, model_client=None, **kwargs):
        if model_client is None:
            model_client = OpenAIChatCompletionClient(
                model="gpt-4o-mini"
            )
            
        super().__init__(
            name=name,
            system_message=system_message,
            model_client=model_client,
            **kwargs
        )
        
        # Create OpenAI client for direct API calls
        self.client = OpenAI() 