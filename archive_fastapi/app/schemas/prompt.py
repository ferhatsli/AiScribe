from pydantic import BaseModel

class PromptInput(BaseModel):
    """Schema for prompt input."""
    prompt: str

class ModuleScores(BaseModel):
    """Schema for analysis module scores."""
    character: float = 0.0
    setting: float = 0.0
    atmosphere: float = 0.0
    action: float = 0.0 