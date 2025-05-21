from ..config.supabase import supabase
from ..schemas.user import UserCreate, UserLogin, UserResponse, TokenResponse
from fastapi import HTTPException, status
from typing import Dict, Any
import uuid
from datetime import datetime
import traceback

class AuthService:
    @staticmethod
    async def register_user(user_data: UserCreate) -> TokenResponse:
        """Yeni kullanıcı kaydı oluşturur ve token döndürür."""
        try:
            # Kullanıcı verisini sağlamlaştır
            email = user_data.email
            password = user_data.password
            
            print(f"Attempting to register user with email: {email}")
            
            # Supabase Auth ile kullanıcı kaydı
            auth_response = supabase.auth.sign_up({
                "email": email,
                "password": password,
                "options": {
                    "data": {
                        "name": user_data.name or ""
                    }
                }
            })
            
            print(f"Supabase auth response: {auth_response}")
            
            # Kullanıcı ID'sini kontrol et
            if not auth_response.user or not auth_response.user.id:
                raise ValueError("User creation failed - no user ID returned")
                
            user_id = auth_response.user.id
            
            # Kullanıcı profil bilgilerini veritabanında saklama
            profile_data = {
                "id": user_id,
                "email": email,
                "name": user_data.name or "",
                "created_at": datetime.utcnow().isoformat()
            }
            
            # Supabase profiles tablosuna profil bilgilerini ekleyin
            profile_result = supabase.table("profiles").insert(profile_data).execute()
            print(f"Profile creation result: {profile_result}")
            
            # Kullanıcı yanıtını oluşturun
            user_response = UserResponse(
                id=uuid.UUID(user_id),
                email=email,
                name=user_data.name,
                created_at=datetime.utcnow()
            )
            
            # Token yanıtını döndürün - session null olabilir, kontrol et
            access_token = ""
            if auth_response.session:
                access_token = auth_response.session.access_token
            
            return TokenResponse(
                access_token=access_token,
                user=user_response
            )
            
        except Exception as e:
            # Hata durumunu işleyin ve stack trace'i yakalayın
            error_details = str(e)
            stack_trace = traceback.format_exc()
            print(f"Detailed error: {error_details}")
            print(f"Stack trace: {stack_trace}")
            
            if "User already registered" in error_details:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="User with this email already exists"
                )
                
            if "invalid email" in error_details.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Please provide a valid email address"
                )
                
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to register user: {error_details}"
            )
    
    @staticmethod
    async def login_user(login_data: UserLogin) -> TokenResponse:
        """Kullanıcı girişi yapar ve token döndürür."""
        try:
            # Kullanıcı verisini sağlamlaştır
            email = login_data.email
            password = login_data.password
            
            print(f"Attempting to login user with email: {email}")
            
            # Supabase Auth ile kullanıcı girişi
            auth_response = supabase.auth.sign_in_with_password({
                "email": email,
                "password": password
            })
            
            print(f"Login auth response received, checking user data")
            
            # Kullanıcı ID'sini kontrol et
            if not auth_response.user or not auth_response.user.id:
                raise ValueError("Login failed - no user ID returned")
                
            user_id = auth_response.user.id
            
            # Kullanıcı profilini veritabanından çekin
            profile = supabase.table("profiles").select("*").eq("id", user_id).execute()
            print(f"Profile query result: {profile}")
            
            if len(profile.data) == 0:
                # Profil bulunamadıysa, yeni bir profil oluştur
                print(f"No profile found for user {user_id}, creating one")
                profile_data = {
                    "id": user_id,
                    "email": email,
                    "name": "",
                    "created_at": datetime.utcnow().isoformat()
                }
                supabase.table("profiles").insert(profile_data).execute()
                profile_data = profile_data
            else:
                profile_data = profile.data[0]
            
            # Kullanıcı yanıtını oluşturun
            user_response = UserResponse(
                id=uuid.UUID(user_id),
                email=email,
                name=profile_data.get("name"),
                created_at=datetime.fromisoformat(profile_data.get("created_at")) if isinstance(profile_data.get("created_at"), str) else datetime.utcnow()
            )
            
            # Token yanıtını döndürün
            return TokenResponse(
                access_token=auth_response.session.access_token,
                user=user_response
            )
            
        except Exception as e:
            # Hata durumunu işleyin
            error_details = str(e)
            stack_trace = traceback.format_exc()
            print(f"Login error details: {error_details}")
            print(f"Login stack trace: {stack_trace}")
            
            if "Invalid login credentials" in error_details:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid email or password"
                )
                
            if "invalid email" in error_details.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Please provide a valid email address"
                )
                
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to login: {error_details}"
            )
    
    @staticmethod
    async def logout(token: str) -> Dict[str, Any]:
        """Kullanıcı oturumunu kapatır."""
        try:
            supabase.auth.sign_out()
            return {"message": "Successfully logged out"}
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to logout: {str(e)}"
            ) 