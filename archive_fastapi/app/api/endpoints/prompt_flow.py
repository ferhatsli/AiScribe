from fastapi import APIRouter, HTTPException
# Pydantic BaseModel importunu kaldırabiliriz, şemadan gelecek
# from pydantic import BaseModel
# Şemaları import et
from app.schemas.prompt import PromptInput, ModuleScores
from app.core.prompt_analyzer import analyze_prompt
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

# Bu modelleri şemadan aldığımız için kaldırıyoruz
# class PromptRequest(BaseModel):
#     prompt: str
#
# class AnalysisScores(BaseModel):
#     character: float
#     setting: float
#     atmosphere: float
#     action: float

# Yanıt modeli için yeni bir şema (isteğe bağlı ama daha düzenli)
# İstersen bunu da app/schemas/prompt.py içine taşıyabiliriz.
from pydantic import BaseModel # Bunu AnalysisResponse için tekrar ekleyelim
class AnalysisResponse(BaseModel):
    modules: ModuleScores

@router.post("/analyze", response_model=AnalysisResponse)
# Request modelini PromptInput olarak değiştir
async def analyze_prompt_endpoint(request: PromptInput):
    """
    Accepts a prompt and returns an analysis of its components.
    """
    if not request.prompt:
        raise HTTPException(status_code=400, detail="Prompt cannot be empty.")

    try:
        logger.info(f"Analyzing prompt: {request.prompt[:50]}...")
        analysis_result = await analyze_prompt(request.prompt)
        logger.info(f"Analysis result: {analysis_result}")
        # Pydantic modelini ModuleScores kullanarak oluştur
        response_data = AnalysisResponse(modules=ModuleScores(**analysis_result))
        return response_data
    except Exception as e:
        logger.error(f"Error during prompt analysis endpoint: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error during analysis.") 