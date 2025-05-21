from fastapi import APIRouter, Depends, HTTPException, status
from ...schemas.user import UserCreate, UserLogin, TokenResponse, UserResponse
from ...services.custom_auth_service import CustomAuthService
from ..dependencies import get_current_user
from typing import Dict, Any
import uuid
from datetime import datetime

router = APIRouter()

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate):
    """Yeni kullanıcı oluştur ve token döndür"""
    return await CustomAuthService.register_user(user_data)

@router.post("/login", response_model=TokenResponse)
async def login(login_data: UserLogin):
    """Kullanıcı girişi yap ve token döndür"""
    return await CustomAuthService.login_user(login_data)

@router.post("/logout", response_model=Dict[str, Any])
async def logout(current_user = Depends(get_current_user)):
    """Kullanıcı oturumunu kapat"""
    token = current_user.get("token") if isinstance(current_user, dict) else None
    return await CustomAuthService.logout(token)

@router.get("/profile", response_model=UserResponse)
async def get_profile(current_user = Depends(get_current_user)):
    """Mevcut kullanıcının profilini döndür"""
    try:
        if not current_user or not current_user.get("id"):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found"
            )
        
        user_id = current_user.get("id")
        email = current_user.get("email", "")
        
        # Profil bilgilerini çek
        profile = await get_profile_data(user_id)
        
        return UserResponse(
            id=user_id if isinstance(user_id, uuid.UUID) else uuid.UUID(user_id),
            email=email,
            name=profile.get("name", ""),
            created_at=datetime.fromisoformat(profile.get("created_at")) if isinstance(profile.get("created_at"), str) else datetime.utcnow()
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch profile: {str(e)}"
        )

async def get_profile_data(user_id):
    """Profil verilerini getir, yoksa oluştur"""
    from ...config.supabase import supabase
    
    profile = supabase.table("profiles").select("*").eq("id", str(user_id)).execute()
    
    if not profile or len(profile.data) == 0:
        return {"name": "", "created_at": datetime.utcnow().isoformat()}
    
    return profile.data[0] 