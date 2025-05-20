from fastapi import FastAPI
from app.api.endpoints import prompt_flow
import logging

# Logging yapılandırması (isteğe bağlı, ama iyi pratik)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="AI Prompt Assistant", version="0.1.0")

# Prompt Flow router'ını ekle
app.include_router(prompt_flow.router, prefix="/api/v1", tags=["Prompt Flow"])

@app.get("/")
def root():
    logger.info("Root endpoint called")
    return {"message": "AI Prompt Assistant is running!"}

# Uygulamayı çalıştırmak için (geliştirme sırasında):
# uvicorn app.main:app --reload
