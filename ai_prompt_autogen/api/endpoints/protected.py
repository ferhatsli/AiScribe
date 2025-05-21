from fastapi import APIRouter, Depends, HTTPException, status, Request
from typing import Dict, Any, List
from ..dependencies import get_current_user
import uuid

router = APIRouter()

@router.get("/user-data", tags=["Protected"])
async def get_user_data(current_user: Dict[str, Any] = Depends(get_current_user)):
    """
    Kullanıcı bilgilerini ve tercihlerini döndürür.
    Bu endpoint'e erişim için kimlik doğrulama gereklidir.
    """
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required"
        )
        
    # Kullanıcı ID'sini denetlemek için doğru formata dönüştür
    try:
        user_id = current_user.get("id", "")
        if isinstance(user_id, str):
            user_id = uuid.UUID(user_id)
    except:
        user_id = None
        
    return {
        "id": str(user_id) if user_id else None,
        "email": current_user.get("email", ""),
        "name": current_user.get("name", ""),
        "is_authenticated": True,
        "preferences": {
            "language": "tr",  # Kullanıcı tercihlerini veritabanından alabilirsiniz
            "theme": "light"
        }
    }

@router.get("/my-prompts", tags=["Protected"])
async def get_user_prompts(current_user: Dict[str, Any] = Depends(get_current_user)):
    """
    Kullanıcının oluşturduğu promptları döndürür.
    Bu endpoint'e erişim için kimlik doğrulama gereklidir.
    """
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required"
        )
        
    # Örnek veri - gerçek uygulamada veritabanından gelecek
    return {
        "prompts": [
            {
                "id": "prompt-1",
                "text": "A beautiful sunset on the beach",
                "created_at": "2025-05-20T21:32:11Z"
            },
            {
                "id": "prompt-2", 
                "text": "A sci-fi city with flying cars",
                "created_at": "2025-05-19T14:22:45Z"
            }
        ],
        "total": 2
    }

@router.post("/save-prompt", tags=["Protected"])
async def save_user_prompt(
    prompt_data: Dict[str, str],
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """
    Kullanıcının oluşturduğu promptu kaydeder.
    Bu endpoint'e erişim için kimlik doğrulama gereklidir.
    """
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required"
        )
        
    # Gerçek uygulamada veritabanına kaydedilecek
    prompt_text = prompt_data.get("prompt", "")
    if not prompt_text:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Prompt text is required"
        )
        
    # Örnek başarılı yanıt
    return {
        "status": "success",
        "message": "Prompt saved successfully",
        "id": str(uuid.uuid4()),  # Gerçek uygulamada veritabanından gelen ID
        "prompt": prompt_text
    }