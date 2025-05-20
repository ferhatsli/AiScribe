# ai_prompt_autogen Backend Teknik Dokümantasyonu

## Proje Genel Yapısı

`ai_prompt_autogen` klasörü, çok aşamalı bir prompt işleme ve zenginleştirme backend'idir. FastAPI ile REST API sunar ve arka planda çeşitli "agent" (LLM tabanlı yardımcılar) ile çalışır. Amaç, kısa bir prompt'u analiz etmek, genişletmek, eksik detaylar için soru üretmek ve en sonunda görsel üretime uygun, zengin bir metin üretmektir.

---

## Ana Bileşenler ve Dosyalar

### 1. api/endpoints/prompt_flow.py
- **Ana API endpointi**: `/generate`
- **İş Akışı**:
  1. **Prompt genişletme** (AutoExpander): Kısa promptları daha zengin varyantlara dönüştürür.
  2. **Dil tespiti** (LanguageDetector): Prompt'un dilini otomatik algılar.
  3. **Prompt analizi** (PromptAnalyzer): Prompt'tan karakter, mekan, zaman, stil, aksiyon gibi ögeleri ve modül skorlarını çıkarır.
  4. **Modül önerisi** (ModuleSuggester): Hangi modüller için soru sorulması gerektiğine karar verir.
  5. **Soru üretimi** (QuestionAgent): Eksik detaylar için kullanıcıya sorulacak soruları üretir.
  6. **Final prompt üretimi** (PromptFinalizer): Kullanıcı cevapları ve analiz edilen ögelerle, görsel üretime uygun zengin bir metin oluşturur.
- **Yardımcı Fonksiyonlar**:
  - `_safe_json_loads`: LLM'den gelen JSON'u güvenli şekilde parse eder.
  - `_call_agent`: İlgili agent'a mesaj gönderir ve yanıtı döner.
- **Detaylı Akış**:
  - Her adımda, ilgili agent'a mesaj gönderilir ve dönen yanıt işlenir.
  - Soru-cevap akışı ve final prompt üretimi, kullanıcıdan alınan cevaplara göre dallanır.
  - Tüm veri modelleri `schemas/prompt.py` üzerinden tip kontrolüyle işlenir.

### 2. agents/
#### - user_proxy.py
  - Kullanıcıyı temsil eden bir agent. Diğer agent'larla etkileşimi başlatır.
  - `UserProxyAgent` nesnesi, insan kullanıcıyı simüle eder.

#### - prompt_analyzer_agent.py
  - Prompt'u analiz eder, ögeleri ve modül skorlarını çıkarır.
  - Çıktı: `{ "scores": {...}, "categorized_elements": {...} }`
  - Karakter, mekan, zaman, stil, aksiyon gibi ögeleri JSON olarak döner.

#### - module_suggester_agent.py
  - Analiz skorlarına göre hangi modüllerin aktif olacağına karar verir.
  - Çıktı: `{ "active_modules": {...} }`
  - Her modül için true/false döner. (Örn: character, setting, atmosphere, action)

#### - question_agent.py
  - Aktif modüller ve eksik detaylara göre kullanıcıya sorulacak soruları üretir.
  - Çıktı: `{ "questions": [ ... ] }`
  - Her soru, modül adı, soru metni ve örneklerle birlikte gelir.

#### - auto_prompt_expander_agent.py
  - Kısa promptları daha zengin varyantlara dönüştürür.
  - Çıktı: `{ "expansions": [ ... ] }`
  - Her bir expansion, orijinal promptun daha detaylı bir versiyonudur.

#### - prompt_finalizer_agent.py
  - Tüm ögeler ve kullanıcı cevaplarıyla, görsel üretime uygun, tek paragraflık zengin bir metin üretir.
  - Çıktı: Sadece metin (JSON değil).
  - Orijinal prompt, kategorize ögeler ve Q&A ile birleştirilmiş, akıcı ve betimleyici bir sonuç üretir.

#### - language_detector_agent.py
  - Prompt'un dilini tespit eder (ör: "en", "tr").
  - Sadece ISO 639-1 kodu döner.

### 3. schemas/prompt.py
- **Veri modelleri**:
  - `PromptRequest`: API'ye gelen isteklerin şeması (prompt, auto_expand, language_code, style, answers, vs.)
  - `PromptResponse`: API'den dönen yanıtların şeması (status, final_prompt, expansions, questions, categorized_elements, vs.)
  - `QuestionItem`, `AnswerItem`: Soru ve cevapların veri modeli.
- **Örnek**:
```python
class PromptRequest(BaseModel):
    prompt: str
    auto_expand: bool = False
    language_code: Optional[str] = None
    selected_expansion_index: Optional[int] = None
    answers: Optional[List[AnswerItem]] = None
    style: Optional[str] = None
```

### 4. config/settings.py
- LLM (ör: OpenAI) API anahtarı ve model ayarları burada tutulur.
- Tüm agent'lar bu ayarları kullanır.
- `.env` dosyasından anahtarlar çekilir.

### 5. run.py
- Komut satırından adım adım prompt işleme ve agent akışını test etmek için örnek bir script.
- API sunucusu değildir, örnek kullanım ve debugging için kullanılır.
- Her adımda agent'lar çağrılır ve çıktı terminale yazılır.

---

## Akış Özeti

1. **Kullanıcıdan prompt alınır.**
2. (İsteğe bağlı) Prompt genişletilir.
3. Prompt'un dili tespit edilir.
4. Prompt analiz edilir, ögeler ve modül skorları çıkarılır.
5. Hangi modüller için soru sorulacağı belirlenir.
6. Eksik detaylar için kullanıcıya sorular üretilir.
7. Kullanıcı cevapları ile final prompt oluşturulur.
8. Sonuç, görsel üretime uygun, zengin bir metin olarak döner.

---

## Teknik Notlar ve Geliştirici İpuçları

- Tüm agent'lar LLM tabanlıdır ve sistem promptları ile yönlendirilir.
- API endpointi FastAPI ile tanımlanmıştır.
- JSON parsing ve agent çağrıları için yardımcı fonksiyonlar kullanılır.
- Proje, kolayca yeni modüller/agent'lar eklenebilecek şekilde modülerdir.
- Her agent'ın sistem promptu, işlevini ve çıktı formatını net şekilde tanımlar.
- Tüm veri akışı ve tip kontrolü Pydantic modelleriyle güvence altındadır.
- Geliştirici, yeni bir agent eklerken sadece bir Python dosyası ve uygun sistem promptu tanımlamalıdır.

---

Her dosyanın detaylı işlevi ve akıştaki yeri yukarıda özetlenmiştir. Daha fazla detay veya kod örneği isterseniz, belirli bir dosya için derinlemesine açıklama da sağlayabilirim!
