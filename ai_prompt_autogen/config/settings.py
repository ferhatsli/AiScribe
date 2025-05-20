import os
from dotenv import load_dotenv

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

LLM_CONFIG = {
    "model": "gpt-4o-mini",
    "api_key": OPENAI_API_KEY
} 