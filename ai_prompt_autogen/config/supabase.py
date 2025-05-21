import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

# Supabase bilgilerini .env dosyasından alın
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")  # Bu muhtemelen anon key

# Yetkili erişim için service role anahtarı
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", SUPABASE_KEY)  # Varsayılan olarak normal anahtarı kullan

# Supabase istemcisini oluşturun
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

print(f"Supabase URL: {SUPABASE_URL}")
print(f"Using service key: {'Yes' if SUPABASE_SERVICE_KEY != SUPABASE_KEY else 'No - using anon key'}") 