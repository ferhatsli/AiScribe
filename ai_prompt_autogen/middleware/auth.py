from fastapi import Request, HTTPException, status
from ..services.custom_auth_service import CustomAuthService
from fastapi.responses import JSONResponse
import traceback

async def auth_middleware(request: Request, call_next):
    """
    Middleware to check for user authentication and add user to request state
    """
    # Swagger UI ve docs için bu yolları kontrol etmeyiz
    if request.url.path.startswith("/docs") or request.url.path.startswith("/openapi.json"):
        response = await call_next(request)
        return response
    
    # Kimlik doğrulama gerektirmeyen güvenli yollar (public endpoints)
    PUBLIC_PATHS = [
        "/api/v1/auth/login", 
        "/api/v1/auth/register",
        "/health",
        "/",
        "/static"
    ]
    
    # Hız için prefix kontrolü
    is_public = any(request.url.path.startswith(path) for path in PUBLIC_PATHS)
    if is_public:
        response = await call_next(request)
        return response
    
    # Authorization header'ı kontrol et
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        # Yetkilendirme başarısız, ancak hala işlemi devam ettiriyoruz
        # Rota bağımlılıkları gerekirse bu kontrolü daha sonra yapacak
        request.state.user = None
        response = await call_next(request)
        return response
    
    # Token'ı çıkar ve doğrula
    token = auth_header.replace("Bearer ", "")
    try:
        user_data = await CustomAuthService.get_user_by_token(token)
        if user_data:
            # Kullanıcıyı istek state'ine ekle
            request.state.user = user_data
        else:
            request.state.user = None
    except Exception as e:
        # Hata durumunu logla
        print(f"Auth middleware error: {str(e)}")
        print(traceback.format_exc())
        request.state.user = None
    
    # İşlemi devam ettir
    response = await call_next(request)
    return response 