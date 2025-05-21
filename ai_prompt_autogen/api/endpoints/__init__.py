from fastapi import APIRouter
from .prompt_flow import router as prompt_flow_router
from .image_generation import router as image_generation_router
from .auth import router as auth_router
from .protected import router as protected_router

# Main API router
api_router = APIRouter()

# Register all endpoints
api_router.include_router(prompt_flow_router, prefix="/prompt", tags=["Prompt Generation"])
api_router.include_router(image_generation_router, prefix="/image", tags=["Image Generation"])
api_router.include_router(auth_router, prefix="/auth", tags=["Authentication"])
api_router.include_router(protected_router, prefix="/protected", tags=["Protected"])
