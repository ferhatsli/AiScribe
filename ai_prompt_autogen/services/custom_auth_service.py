from ..config.supabase import supabase
from ..schemas.user import UserCreate, UserLogin, UserResponse, TokenResponse
from fastapi import HTTPException, status
from typing import Dict, Any, Optional
import uuid
import hashlib
import secrets
import time
from datetime import datetime, timedelta
import traceback
import json

# Salt ekleyerek güvenli şifre hash'leme
def hash_password(password: str, salt: Optional[str] = None) -> tuple:
    if salt is None:
        salt = secrets.token_hex(16)
    hash_obj = hashlib.sha256((password + salt).encode())
    return hash_obj.hexdigest(), salt

# Token oluşturma
def create_token(user_id: str) -> str:
    token = secrets.token_hex(32)
    expires = int(time.time()) + 3600 * 24  # 24 saat
    
    # Token veritabanına kaydedilir
    token_data = {
        "token": token,
        "user_id": user_id,
        "expires": expires
    }
    
    # Mevcut tokenları sil (isteğe bağlı)
    supabase.table("tokens").delete().eq("user_id", user_id).execute()
    
    # Yeni token ekle
    supabase.table("tokens").insert(token_data).execute()
    
    return token

class CustomAuthService:
    @staticmethod
    async def register_user(user_data: UserCreate) -> TokenResponse:
        """Yeni kullanıcı kaydı oluşturur ve token döndürür."""
        try:
            print(f"Attempting to register user with email: {user_data.email}")
            
            # Email adresi kontrolü
            existing_user = supabase.table("users").select("*").eq("email", user_data.email).execute()
            
            if existing_user and len(existing_user.data) > 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="User with this email already exists"
                )
            
            print("Step 1: No existing user found, proceeding with registration")
            
            # Kullanıcı ID'si oluştur
            user_id = str(uuid.uuid4())
            
            # Şifreyi hash'le
            hashed_password, salt = hash_password(user_data.password)
            
            # Kullanıcıyı veritabanına ekle
            user_data_db = {
                "id": user_id,
                "email": user_data.email,
                "password_hash": hashed_password,
                "salt": salt,
                "created_at": datetime.utcnow().isoformat()
            }
            
            print(f"Step 2: Creating user with ID: {user_id}")
            
            # Adım 1: Önce kullanıcı kaydını oluştur (users)
            try:
                users_result = supabase.table("users").insert(user_data_db).execute()
                print(f"Users insert result: {users_result}")
                
                if not users_result or not users_result.data or len(users_result.data) == 0:
                    raise ValueError("Failed to insert user data")
            except Exception as user_err:
                print(f"Error inserting user: {str(user_err)}")
                raise
                
            print("Step 3: User created successfully, creating profile")
            
            # Adım 2: Sonra profil kaydını oluştur (profiles)
            profile_data = {
                "id": user_id,  # Aynı ID kullanılıyor
                "email": user_data.email,
                "name": user_data.name or "",
                "created_at": datetime.utcnow().isoformat()
            }
            
            try:
                profiles_result = supabase.table("profiles").insert(profile_data).execute()
                print(f"Profiles insert result: {profiles_result}")
            except Exception as profile_err:
                # Profil oluşturulamazsa kullanıcıyı silmeyi deneyebiliriz (cleanup)
                print(f"Error inserting profile: {str(profile_err)}")
                try:
                    supabase.table("users").delete().eq("id", user_id).execute()
                    print(f"Rolled back user creation for ID: {user_id}")
                except:
                    pass
                raise profile_err
                
            print("Step 4: Profile created successfully, generating token")
            
            # Adım 3: Token oluştur (tokens)
            try:
                token = create_token(user_id)
                print(f"Token created: {token[:10]}...")
            except Exception as token_err:
                print(f"Error creating token: {str(token_err)}")
                raise
            
            print("Step 5: Registration completed successfully")
            
            # Yanıt oluştur
            user_response = UserResponse(
                id=uuid.UUID(user_id),
                email=user_data.email,
                name=user_data.name,
                created_at=datetime.utcnow()
            )
            
            return TokenResponse(
                access_token=token,
                user=user_response
            )
            
        except HTTPException as he:
            # HTTPException'ı yeniden yükselt
            raise he
        except Exception as e:
            # Hata durumunu işle
            error_details = str(e)
            stack_trace = traceback.format_exc()
            print(f"Detailed registration error: {error_details}")
            print(f"Stack trace: {stack_trace}")
            
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to register user: {error_details}"
            )
    
    @staticmethod
    async def login_user(login_data: UserLogin) -> TokenResponse:
        """Kullanıcı girişi yapar ve token döndürür."""
        try:
            print(f"Attempting to login user with email: {login_data.email}")
            
            # Kullanıcıyı e-posta ile bul
            user_result = supabase.table("users").select("*").eq("email", login_data.email).execute()
            
            if not user_result or len(user_result.data) == 0:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid email or password"
                )
            
            user_data = user_result.data[0]
            
            # Şifre doğrulama
            hashed_input, _ = hash_password(login_data.password, user_data.get("salt"))
            if hashed_input != user_data.get("password_hash"):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid email or password"
                )
            
            # Kullanıcı ID'sini al
            user_id = user_data.get("id")
            
            # Profil bilgilerini al
            profile = supabase.table("profiles").select("*").eq("id", user_id).execute()
            
            if len(profile.data) == 0:
                # Profil yoksa oluştur
                profile_data = {
                    "id": user_id,
                    "email": login_data.email,
                    "name": "",
                    "created_at": datetime.utcnow().isoformat()
                }
                supabase.table("profiles").insert(profile_data).execute()
                profile_data = profile_data
            else:
                profile_data = profile.data[0]
            
            # Token oluştur
            token = create_token(user_id)
            
            # Yanıt oluştur
            user_response = UserResponse(
                id=uuid.UUID(user_id),
                email=login_data.email,
                name=profile_data.get("name"),
                created_at=datetime.fromisoformat(profile_data.get("created_at")) if isinstance(profile_data.get("created_at"), str) else datetime.utcnow()
            )
            
            return TokenResponse(
                access_token=token,
                user=user_response
            )
            
        except HTTPException as he:
            # HTTPException'ı yeniden yükselt
            raise he
        except Exception as e:
            # Hata durumunu işle
            error_details = str(e)
            stack_trace = traceback.format_exc()
            print(f"Login error details: {error_details}")
            print(f"Login stack trace: {stack_trace}")
            
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to login: {error_details}"
            )
    
    @staticmethod
    async def logout(token: str) -> Dict[str, Any]:
        """Kullanıcı oturumunu kapatır."""
        try:
            if token:
                # Token'ı veritabanından sil
                supabase.table("tokens").delete().eq("token", token).execute()
            
            return {"message": "Successfully logged out"}
        except Exception as e:
            error_details = str(e)
            stack_trace = traceback.format_exc()
            print(f"Logout error details: {error_details}")
            print(f"Logout stack trace: {stack_trace}")
            
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to logout: {error_details}"
            )
    
    @staticmethod
    async def get_user_by_token(token: str) -> Optional[dict]:
        """Token ile kullanıcı bilgilerini getirir."""
        try:
            # Token'ı veritabanında ara
            token_result = supabase.table("tokens").select("*").eq("token", token).execute()
            
            if not token_result or len(token_result.data) == 0:
                return None
                
            token_data = token_result.data[0]
            
            # Token süresi dolmuş mu kontrol et
            if token_data.get("expires", 0) < int(time.time()):
                # Süresi dolmuş token'ı sil
                supabase.table("tokens").delete().eq("token", token).execute()
                return None
            
            # Kullanıcı bilgilerini getir
            user_id = token_data.get("user_id")
            user_result = supabase.table("users").select("*").eq("id", user_id).execute()
            
            if not user_result or len(user_result.data) == 0:
                return None
                
            return user_result.data[0]
            
        except Exception as e:
            print(f"Error getting user by token: {str(e)}")
            return None 