from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from ..services.custom_auth_service import CustomAuthService
from typing import Optional
import uuid

# OAuth2 bearer token scheme - artık /auth/login yerine tam yolu belirtiyoruz
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    Kimlik doğrulama token'ından mevcut kullanıcıyı elde eder
    """
    user = await CustomAuthService.get_user_by_token(token)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # User ID'yi UUID'ye dönüştür
    try:
        user["id"] = uuid.UUID(user["id"])
    except (ValueError, KeyError):
        pass
        
    return user

async def get_optional_user(token: Optional[str] = Depends(oauth2_scheme)):
    """
    Token varsa kullanıcıyı döndürür, yoksa None döndürür
    """
    if not token:
        return None
    
    try:
        return await CustomAuthService.get_user_by_token(token)
    except:
        return None 