import json
from typing import Dict, Any, Optional

def extract_json_from_text(text: str) -> Optional[Dict[str, Any]]:
    """Extract JSON object from text response."""
    try:
        json_start = text.find('{')
        json_end = text.rfind('}') + 1
        if json_start >= 0 and json_end > json_start:
            return json.loads(text[json_start:json_end])
        return None
    except Exception:
        return None

def create_error_response(error_msg: str, raw_response: str) -> Dict[str, str]:
    """Create standardized error response."""
    return {
        "error": error_msg,
        "raw_response": raw_response
    } 