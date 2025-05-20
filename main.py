from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates # Optional, but good for serving HTML

# Correct imports assuming main.py is in the root directory
import sys
import os

# Ensure necessary directories exist
static_dir = os.path.join(os.path.dirname(__file__), "static")
if not os.path.exists(static_dir):
    os.makedirs(static_dir)
    print(f"Created static directory at: {static_dir}")

# Ensure __init__.py files exist (important for module discovery)
required_dirs = [
    "ai_prompt_autogen",
    "ai_prompt_autogen/api", 
    "ai_prompt_autogen/api/endpoints", 
    "ai_prompt_autogen/schemas", 
    "ai_prompt_autogen/agents", 
    "ai_prompt_autogen/config"
]
for req_dir in required_dirs:
    init_path = os.path.join(os.path.dirname(__file__), req_dir, "__init__.py")
    if not os.path.exists(init_path):
        try:
            # Create parent dirs if they don't exist
            os.makedirs(os.path.dirname(init_path), exist_ok=True)
            with open(init_path, 'w') as f:
                pass # Create empty file
            print(f"Created __init__.py in {req_dir}")
        except OSError as e:
            print(f"Warning: Could not create __init__.py in {req_dir}: {e}")

try:
    from ai_prompt_autogen.api.endpoints import prompt_flow
except ImportError as e:
    print(f"Error importing prompt_flow router: {e}")
    print("Ensure main.py is run from the workspace root (AiScribe-Final) and all necessary __init__.py files exist.")
    # Attempting relative import if standard fails (useful in some structures)
    try:
        # Adjust based on your exact structure if needed
        from .ai_prompt_autogen.api.endpoints import prompt_flow
        print("Successfully imported using relative path.")
    except ImportError:
         sys.exit(1)

app = FastAPI(
    title="AiScribe Prompt Generation API",
    description="API for processing user prompts through a multi-agent workflow to generate enhanced text-to-image prompts.",
    version="1.0.0"
)

# Mount static files directory
app.mount("/static", StaticFiles(directory=static_dir), name="static")

# Optional: Use Jinja2Templates if you plan more complex HTML rendering
# templates = Jinja2Templates(directory=static_dir)

# Include the API router
app.include_router(prompt_flow.router, prefix="/api/v1")

@app.get("/", response_class=HTMLResponse, tags=["User Interface"])
async def read_ui(request: Request):
    # Serve the index.html file
    index_path = os.path.join(static_dir, "index.html")
    if not os.path.exists(index_path):
         return HTMLResponse("<html><body><h1>Error: index.html not found in static folder.</h1></body></html>", status_code=404)
    
    with open(index_path, "r", encoding="utf-8") as f:
        html_content = f.read()
    return HTMLResponse(content=html_content)

@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    print("Starting FastAPI server for AiScribe...")
    print("Access the API docs at http://127.0.0.1:8000/docs")
    print("Access the UI at http://127.0.0.1:8000/")
    print("Run with: uvicorn main:app --reload --port 8000")
    # Example command: uvicorn main:app --reload --host 0.0.0.0 --port 8000
    # uvicorn.run(app, host="0.0.0.0", port=8000) # Use this line for direct run without reload 