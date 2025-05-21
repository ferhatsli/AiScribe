from fastapi import APIRouter, HTTPException
from typing import Optional
from pydantic import BaseModel, Field

from ...agents.image_generator_agent import image_generator

router = APIRouter()

class ImageGenerationRequest(BaseModel):
    prompt: str = Field(..., description="The finalized text prompt to generate an image from")
    style: Optional[str] = Field(None, description="Optional style parameter to apply to the image")
    size: str = Field("1024x1024", description="Image size (1024x1024, 1792x1024, or 1024x1792)")

class ImageGenerationResponse(BaseModel):
    status: str = Field(..., description="Status of the image generation request (success/error)")
    image_url: Optional[str] = Field(None, description="URL of the generated image (if successful)")
    prompt_used: Optional[str] = Field(None, description="The actual prompt used for generation (may include style)")
    error_message: Optional[str] = Field(None, description="Error details if the status is 'error'")

@router.post("/generate", response_model=ImageGenerationResponse, tags=["Image Generation"])
async def generate_image(request: ImageGenerationRequest) -> ImageGenerationResponse:
    """
    Generate an image using DALL-E-3 based on the provided prompt
    
    This endpoint:
    1. Takes a finalized text prompt (typically from the prompt generation flow)
    2. Uses the DALL-E-3 model to create an image
    3. Returns the URL of the generated image
    """
    try:
        # Validate size parameter
        valid_sizes = ["1024x1024", "1792x1024", "1024x1792"]
        if request.size not in valid_sizes:
            return ImageGenerationResponse(
                status="error",
                error_message=f"Invalid size parameter. Must be one of: {', '.join(valid_sizes)}"
            )
        
        # Call image generator agent
        result = image_generator.generate_image(
            prompt=request.prompt,
            style=request.style,
            size=request.size
        )
        
        # Convert result to response model
        if result["status"] == "success":
            return ImageGenerationResponse(
                status="success",
                image_url=result["image_url"],
                prompt_used=result["prompt_used"]
            )
        else:
            return ImageGenerationResponse(
                status="error",
                error_message=result.get("error_message", "Unknown error during image generation")
            )
            
    except Exception as e:
        return ImageGenerationResponse(
            status="error",
            error_message=f"Image generation failed: {str(e)}"
        ) 