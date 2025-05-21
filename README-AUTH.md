# AiScribe - Supabase Kimlik Doğrulama Kurulumu

Bu belge, AiScribe uygulaması için Supabase kimlik doğrulama kurulumunu açıklar.

## Supabase Kurulumu

1. [Supabase](https://app.supabase.io/)'de ücretsiz bir hesap oluşturun
2. Yeni bir proje oluşturun
3. Sol menüden "Authentication" seçeneğine tıklayın
4. "Settings" > "Auth Providers" kısmından Email/Password sağlayıcısını etkinleştirin
5. "Project Settings" > "API" kısmından şu bilgileri bulabilirsiniz:
   - API URL
   - anon/public API key

## Veritabanı Kurulumu

1. Sol menüden "Table Editor" seçeneğine tıklayın
2. "Create a new table" butonuna tıklayın ve "profiles" adlı bir tablo oluşturun
3. Aşağıdaki sütunları ekleyin:
   - id (uuid, primary key)
   - email (text, not null)
   - name (text, nullable)
   - created_at (timestamp with time zone, not null)

## .env Dosyası Oluşturma

Proje kök dizininde bir `.env` dosyası oluşturun ve şu değişkenleri ekleyin:

```
# Supabase Credentials
SUPABASE_URL=your-supabase-url
SUPABASE_KEY=your-supabase-key

# App Settings
APP_SECRET_KEY=your-app-secret-key-for-jwt
```

## API Kullanımı

### Kullanıcı Kaydı
```
POST /api/v1/auth/register
{
  "email": "user@example.com",
  "password": "securepassword",
  "name": "John Doe"
}
```

### Kullanıcı Girişi
```
POST /api/v1/auth/login
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

### Kullanıcı Çıkışı
```
POST /api/v1/auth/logout
Authorization: Bearer <access_token>
```

### Kullanıcı Profili
```
GET /api/v1/auth/profile
Authorization: Bearer <access_token>
``` 