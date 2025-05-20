# AiScribe Mobil Uygulama Sayfa Yapısı

## 1. Giriş Sayfaları
### Splash Screen
- Uygulama açılış ekranı
- Logo ve marka gösterimi
- Yükleme animasyonu

### Giriş (Login) Sayfası
- E-posta/şifre girişi
- Sosyal medya ile giriş seçenekleri
- "Beni hatırla" seçeneği
- Kayıt sayfasına yönlendirme

### Kayıt (Register) Sayfası
- Kullanıcı bilgileri formu
- E-posta doğrulama
- Şifre oluşturma kuralları
- Kullanım şartları onayı

### Şifremi Unuttum Sayfası
- E-posta girişi
- Doğrulama kodu gönderimi
- Yeni şifre oluşturma

## 2. Ana Sayfalar
### Ana Ekran (Dashboard)
- Son işlemler listesi
- Hızlı erişim butonları
- Kullanım istatistikleri
- Bildirim merkezi

### Prompt Oluşturma Sayfası
- Metin giriş alanı
- Prompt şablonları
- Özelleştirme seçenekleri
- Hızlı komutlar

### Geçmiş Sayfası
- Önceki promptlar listesi
- Sonuçlar görüntüleme
- Filtreleme özellikleri
- Arama fonksiyonu

## 3. Detay Sayfaları
### Prompt Detay Sayfası
- Tam metin görüntüleme
- Sonuç analizi
- Düzenleme araçları
- Paylaşım seçenekleri

### Profil Sayfası
- Kullanıcı bilgileri
- Hesap ayarları
- Kullanım istatistikleri
- Abonelik durumu

## 4. Yardımcı Sayfalar
### Ayarlar Sayfası
- Bildirim ayarları
- Tema seçenekleri
- Dil seçenekleri
- Gizlilik ayarları

### Yardım ve Destek Sayfası
- Sık sorulan sorular
- İletişim formu
- Kullanım kılavuzu
- Canlı destek

## 5. Özel Sayfalar
### Prompt Şablonları Sayfası
- Hazır şablonlar listesi
- Özel şablon oluşturma
- Şablon kategorileri
- Favori şablonlar

### Analiz Sonuçları Sayfası
- Detaylı analiz görüntüleme
- Grafikler ve istatistikler
- Dışa aktarma seçenekleri
- Karşılaştırma araçları

## Sayfa Geliştirme Öncelikleri

### Öncelik 1 (Temel İşlevsellik)
1. Giriş/Kayıt sayfaları
2. Ana ekran
3. Prompt oluşturma sayfası
4. Geçmiş sayfası

### Öncelik 2 (Kullanıcı Deneyimi)
1. Profil sayfası
2. Ayarlar sayfası
3. Prompt detay sayfası
4. Yardım ve destek sayfası

### Öncelik 3 (Gelişmiş Özellikler)
1. Prompt şablonları
2. Analiz sonuçları
3. İstatistikler
4. Özelleştirme seçenekleri

## Teknik Gereksinimler

### Her Sayfa İçin
- MVVM mimari yapısı
- SwiftUI kullanımı
- Combine framework entegrasyonu
- Core Data desteği

### Performans Gereksinimleri
- Sayfa geçiş animasyonları
- Verimli veri yönetimi
- Önbellek kullanımı
- Lazy loading implementasyonu

### Güvenlik Gereksinimleri
- Oturum yönetimi
- Veri şifreleme
- Güvenli API iletişimi
- Kullanıcı doğrulama

### Erişilebilirlik Gereksinimleri
- VoiceOver desteği
- Dinamik yazı tipi boyutları
- Yüksek kontrast modu
- Klavye navigasyonu

## Notlar
- Tüm sayfalar için tutarlı bir tasarım dili kullanılacak
- Sayfa geçişleri için standart animasyonlar belirlenecek
- Her sayfa için hata durumları ve yükleme durumları tanımlanacak
- Offline çalışma desteği tüm sayfalarda sağlanacak 