# 🧠 AI Prompt Assistant

> Dinamik soru-cevap akışıyla görsel prompt üretimini destekleyen, AI Agent mimarili bir metin iyileştirme sistemi.

---

## 🎯 Amaç

Kullanıcının yazdığı kısa bir **text-to-image prompt**'u analiz ederek:
- Eksik alanları tespit eden,
- Bağlama uygun sorular soran,
- Kullanıcı yanıtlarını anlayan,
- Ve sonunda yüksek kaliteli, teknik olarak detaylı bir **final prompt** oluşturan bir AI destekli yardımcı sistemdir.

---

## 🔄 Genel İş Akışı (Workflow)

1. **Prompt Girişi**  
   Kullanıcı kısa bir prompt yazar.  
   Örn: `A girl flying on a futuristic bike at night`

2. **Prompt Analyzer**  
   Prompt içeriği analiz edilir. Hangi modüllere ait olduğu belirlenir:  
   `character`, `setting`, `atmosphere`, `action` (0.0–1.0 skorlarla)

3. **Module Suggester**  
   En alakalı modüller seçilir.  
   Sadece bu modüllere odaklı sorular planlanır.

4. **Question Generator**  
   Seçilen modüllere göre 2–3 örnekli ve yönlendirici soru üretilir.

5. **User Interaction**  
   Kullanıcı bu sorulara serbest metin olarak cevap verir.  
   "Atla" seçeneği de mevcuttur.

6. **Response Analyzer**  
   Kullanıcı yanıtlarının hangi modüle ait olduğu kontrol edilir.  
   Eğer cevap, beklenen modülden farklıysa:
   - Sistem yönlendirir
   - Gerekirse akışı değiştirir

7. **Question Session**  
   Sorular, cevaplar ve modül analizleri session altında saklanır.

8. **Final Prompt Builder**  
   Sistem, tüm girdilere göre yüksek kaliteli bir prompt üretir.

9. **Sonuç Gösterimi**  
   Oluşturulan prompt kullanıcıya sunulur, kopyalama imkanı verilir.

---

## 🧩 Kullanılan Modüller

| Modül        | Açıklama |
|--------------|----------|
| character    | Karakter görünümü, ifadeler, kıyafet |
| setting      | Ortam, mekân, zaman, hava durumu |
| atmosphere   | Ruh hali, stil, duygu, ışık |
| action       | Poz, hareket, akış |
| style*       | Sanatsal/estetik stil (isteğe bağlı) |
| composition* | Kamera açısı, çerçeveleme (isteğe bağlı) |

---

## ✨ Ekstra Özellikler

| Özellik | Açıklama |
|---------|----------|
| AI ile Otomatik Prompt Genişletme | Kullanıcının yazdığı kısa prompt’tan 2–3 öneri versiyon üretir |
| Prompt Tips | Prompt yazarken kullanıcıya küçük öneriler gösterir |
| Benzer Promptlar | Kullanıcının prompt’una benzeyen diğer yaratıcı örnekleri önerir |

---

## 🛠️ Klasör Yapısı 
ai_prompt_assistant/
├── app/
│   ├── agents/
│   │   ├── base_agent.py
│   │   ├── module_suggester.py
│   │   ├── dynamic_question_agent.py
│   │   ├── response_analyzer.py
│   │   └── auto_prompt_expander.py         ← [Yeni]
│   ├── core/
│   │   ├── question_generator.py
│   │   ├── prompt_analyzer.py              ← [Yeni]
│   │   ├── prompt_tips.py                  ← [Yeni]
│   │   ├── prompt_similarity.py            ← [Yeni]
│   │   ├── final_prompt_builder.py
│   │   └── question_session.py
│   ├── api/
│   │   ├── endpoints/
│   │   │   ├── prompt_flow.py              ← (Tüm akış burada)
│   │   │   ├── auto_expand.py              ← Otomatik öneriler
│   │   │   ├── tips.py                     ← Prompt ipuçları
│   │   │   └── similar.py                  ← Benzer promptlar
│   │   └── deps.py                         ← Ortak bağımlılıklar
│   ├── schemas/
│   │   ├── prompt.py
│   │   ├── question.py
│   │   ├── response.py
│   │   └── session.py
│   ├── services/
│   │   ├── openai_client.py
│   │   ├── session_manager.py
│   │   └── utils.py
│   ├── config/
│   │   └── settings.py                     ← API key, modül listesi, vb.
│   └── main.py                             ← FastAPI entrypoint
├── tests/
│   └── ...
├── requirements.txt
├── README.md
└── .env


---

## 🔐 Karar Notları

- Görsel üretimi doğrudan bu sisteme dahil edilmeyecek (şimdilik)
- Soru sayısı 2–3 ile sınırlı tutulmalı
- Cevaplar, beklenen modülden farklıysa sistem yönlendirici olmalı
- Teknik detaylar (ışık, stil, kompozisyon) isteğe bağlı modüllerle toplanabilir
- Kullanıcı her soruya cevap vermek zorunda değil

---

## 🧪 Geliştirme Planı (Yol Haritası)

- [] Modül skor analizi entegre edildi
- [] Soru üretimi akıllı hale getirildi
- [] Cevap analiz yapısı kuruldu
- [] Prompt Tips listesi hazırlandı
- [ ] FinalPromptBuilder çıktısı kalite testine girecek
- [ ] AutoPromptExpander geliştirilecek
- [ ] SimilarPrompt öneri sistemi entegre edilecek
- [ ] API endpoint'leri geliştirilecek (FastAPI)

---

## ✍️ Notlar (Kendine Hatırlat)

- Promptlara örnekler eklemeyi unutma (final çıktı + benzeri)
- Sade ve keyifli bir deneyim > her zaman öncelik
- “Proje detaylarını unutuyorum” → Bu dosya hep güncel tutulmalı