# AiScribe Projesi

## Genel Bakış
AiScribe, yapay zeka destekli bir metin işleme ve analiz platformudur. Bu proje, kullanıcıların metin girişlerini işleyerek akıllı analizler ve öneriler sunan bir sistemdir. Proje, modern bir mobil uygulama ve güçlü bir backend altyapısından oluşmaktadır.

## Teknik Mimari

### Backend (ai_prompt_autogen)
Backend sistemi Python tabanlı olup, aşağıdaki ana bileşenlerden oluşmaktadır:

#### Ana Bileşenler
- **API Katmanı**: FastAPI framework'ü kullanılarak geliştirilmiş RESTful API
- **Veri Modelleri**: Pydantic ile tanımlanmış veri şemaları
- **AI Ajanları**: Özel geliştirilmiş yapay zeka ajanları
- **Konfigürasyon Yönetimi**: Merkezi yapılandırma sistemi

#### Teknolojiler
- Python 3.x
- FastAPI
- Pydantic
- AutoGen (AI Framework)
- SQLAlchemy (Veritabanı ORM)

### Mobil Uygulama (Aiscribe-mobile)
iOS platformu için geliştirilmiş native mobil uygulama:

#### Özellikler
- SwiftUI tabanlı modern kullanıcı arayüzü
- MVVM (Model-View-ViewModel) mimari deseni
- Asenkron veri işleme
- Yerel veri depolama
- Gerçek zamanlı veri senkronizasyonu

#### Teknolojiler
- Swift
- SwiftUI
- Combine Framework
- Core Data

## Kurulum ve Geliştirme

### Backend Kurulumu
```bash
# Sanal ortam oluşturma
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# veya
.venv\Scripts\activate  # Windows

# Bağımlılıkları yükleme
pip install -r requirements.txt

# Uygulamayı başlatma
python run.py
```

### Mobil Uygulama Kurulumu
1. Xcode'u açın
2. Aiscribe-mobile.xcodeproj dosyasını açın
3. Gerekli bağımlılıkları yükleyin
4. Projeyi derleyin ve çalıştırın

## API Dokümantasyonu

### Temel Endpointler
- `POST /api/prompt`: Yeni bir prompt işleme isteği
- `GET /api/history`: Kullanıcı geçmişi
- `POST /api/analyze`: Metin analizi
- `GET /api/status`: Sistem durumu

## Veri Modelleri

### Prompt Modeli
```python
class Prompt(BaseModel):
    id: UUID
    content: str
    created_at: datetime
    status: str
    result: Optional[Dict]
```

### Kullanıcı Modeli
```python
class User(BaseModel):
    id: UUID
    username: str
    email: str
    created_at: datetime
```

## Güvenlik
- JWT tabanlı kimlik doğrulama
- HTTPS zorunluluğu
- Rate limiting
- Input validasyonu
- Güvenli veri depolama

## Performans
- Asenkron işlem desteği
- Önbellek mekanizması
- Veritabanı optimizasyonu
- Yük dengeleme

## Katkıda Bulunma
1. Bu repository'yi fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## Lisans
Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakınız.

## İletişim
Proje Yöneticisi - [İletişim Bilgileri]

## Teşekkürler
- Tüm katkıda bulunanlara
- Açık kaynak topluluğuna
- Proje destekçilerine
