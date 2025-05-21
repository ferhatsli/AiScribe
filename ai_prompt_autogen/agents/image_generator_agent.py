from autogen import AssistantAgent
from openai import OpenAI
import os
import base64
import requests
from ..config.settings import OPENAI_API_KEY

# Configure OpenAI client with API key
client = OpenAI(api_key=OPENAI_API_KEY)

IMAGE_GENERATOR_PROMPT = """
You are an image generation agent powered by DALL-E-3.

Your task is to generate high-quality images based on the finalized text prompts provided by users.

You will receive:
- A finalized text prompt that is already enhanced with descriptive details
- Optional style parameter that should influence the generated image

You should:
1. Use DALL-E-3 to convert the text prompt into a vivid, detailed image
2. Apply the requested style if specified
3. Return the generated image URL and any relevant metadata

Note: You will not modify the prompt text unless absolutely necessary for technical reasons.
If the prompt needs modification, preserve all the key visual elements and meaning.
"""

class ImageGeneratorAgent(AssistantAgent):
    """Custom agent that extends AssistantAgent to handle DALL-E-3 image generation"""
    
    def __init__(self, name="image_generator", llm_config=None, system_message=IMAGE_GENERATOR_PROMPT,
                 description="Generates images using DALL-E-3 based on finalized text prompts."):
        super().__init__(name=name, llm_config=llm_config, system_message=system_message, description=description)

    def generate_image(self, prompt, style=None, size="1024x1024"):
        """
        Generate an image using DALL-E-3 with the given prompt
        
        Args:
            prompt (str): The finalized text prompt
            style (str, optional): Optional style parameter
            size (str, optional): Image size (1024x1024, 1792x1024, or 1024x1792)
            
        Returns:
            dict: Dictionary containing image URL and metadata
        """
        try:
            # Augment the prompt with style if provided
            effective_prompt = prompt
            if style:
                effective_prompt = f"{prompt} Style: {style}"
            
            # Call DALL-E-3 API with updated client
            response = client.images.generate(
                model="dall-e-3",
                prompt=effective_prompt,
                size=size,
                quality="standard",
                n=1
            )
            
            # Extract the image URL from the response
            image_url = response.data[0].url
            
            # Optional: Download and save the image locally if needed
            # image_data = self._download_image(image_url)
            # local_path = self._save_image(image_data)
            
            return {
                "status": "success",
                "image_url": image_url,
                "prompt_used": effective_prompt
            }
            
        except Exception as e:
            print(f"DALL-E-3 image generation error: {str(e)}")
            return {
                "status": "error",
                "error_message": str(e)
            }
    
    def _download_image(self, url):
        """Download image from URL"""
        response = requests.get(url)
        if response.status_code == 200:
            return response.content
        else:
            raise Exception(f"Failed to download image: {response.status_code}")
    
    def _save_image(self, image_data, directory="generated_images"):
        """Save image to local directory"""
        import time
        import hashlib
        import os
        
        # Create directory if it doesn't exist
        if not os.path.exists(directory):
            os.makedirs(directory)
        
        # Generate a unique filename
        timestamp = int(time.time())
        hash_str = hashlib.md5(image_data).hexdigest()[:10]
        filename = f"{timestamp}_{hash_str}.png"
        filepath = os.path.join(directory, filename)
        
        # Save the image
        with open(filepath, "wb") as f:
            f.write(image_data)
        
        return filepath

# Initialize the agent
image_generator = ImageGeneratorAgent() 