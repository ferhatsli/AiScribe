import os
import openai
import asyncio
from dotenv import load_dotenv
import logging

# Logging yapılandırması
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# .env dosyasını yükle
load_dotenv()

# OpenAI API anahtarını ve organizasyonunu ayarla
openai.api_key = os.getenv("OPENAI_API_KEY")
# Gerekirse organizasyon ID'sini de ayarlayın:
# openai.organization = os.getenv("OPENAI_ORG_ID")

async def analyze_prompt(prompt: str) -> dict[str, float]:
    """
    Verilen prompt'u OpenAI kullanarak analiz eder ve belirli modüller için skorlar döndürür.
    Başarısız olursa temel anahtar kelime taraması yapar.

    Args:
        prompt: Analiz edilecek metin prompt'u.

    Returns:
        Skorları içeren bir dictionary. Örn: {"character": 0.9, "setting": 0.8, ...}
    """
    scores = {
        "character": 0.0,
        "setting": 0.0,
        "atmosphere": 0.0,
        "action": 0.0
    }

    if not openai.api_key:
        logger.warning("OpenAI API anahtarı bulunamadı. Fallback mekanizması kullanılacak.")
        return _fallback_analysis(prompt)

    try:
        # TODO: OpenAI API çağrısını daha spesifik ve yapılandırılmış hale getir.
        # Örneğin, function calling veya daha detaylı bir sistem prompt'u kullanılabilir.
        system_prompt = """
        You are an expert text analyzer. Analyze the provided prompt and rate the importance
        of the following aspects on a scale from 0.0 to 1.0:
        - character: Focus on character descriptions, dialogue, emotions, motivations.
        - setting: Focus on the environment, location, time period, world-building details.
        - atmosphere: Focus on the mood, tone, feeling, sensory details (sound, smell, sight).
        - action: Focus on events, plot progression, conflicts, movements, verbs indicating activity.

        Respond ONLY with a JSON object containing these four keys and their corresponding scores.
        Example: {"character": 0.8, "setting": 0.6, "atmosphere": 0.7, "action": 0.9}
        """
        response = await asyncio.to_thread(
            openai.chat.completions.create,
            model="gpt-3.5-turbo", # Veya daha gelişmiş bir model: "gpt-4"
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt}
            ],
            temperature=0.2,
            max_tokens=100 # Yanıtın kısa ve sadece JSON olmasını sağlamak için
        )

        # Yanıtı işle ve skorları çıkar
        # Not: response.choices[0].message.content genellikle JSON string'i içerir.
        # Daha sağlam bir yapı için JSON parse etme ve doğrulama eklenmeli.
        # Örnek olarak, yanıtın doğrudan JSON içerdiğini varsayalım:
        content = response.choices[0].message.content
        logger.info(f"OpenAI response content: {content}")
        try:
            # JSON parse etmeye çalış
            import json
            parsed_scores = json.loads(content)
            # Skorları güncelle, eksik anahtarlar için varsayılan 0.0 kullan
            for key in scores:
                scores[key] = parsed_scores.get(key, 0.0)
            logger.info(f"Prompt '{prompt[:30]}...' için OpenAI analizi başarılı.")
            return scores
        except json.JSONDecodeError:
            logger.error(f"OpenAI yanıtı JSON formatında değil: {content}")
            logger.info("Fallback mekanizması kullanılıyor.")
            return _fallback_analysis(prompt)
        except Exception as e:
            logger.error(f"OpenAI yanıtı işlenirken hata oluştu: {e}")
            logger.info("Fallback mekanizması kullanılıyor.")
            return _fallback_analysis(prompt)


    except openai.OpenAIError as e:
        logger.error(f"OpenAI API hatası: {e}")
        logger.info("Fallback mekanizması kullanılıyor.")
        return _fallback_analysis(prompt)
    except Exception as e:
        logger.error(f"Beklenmedik bir hata oluştu: {e}")
        logger.info("Fallback mekanizması kullanılıyor.")
        return _fallback_analysis(prompt)

def _fallback_analysis(prompt: str) -> dict[str, float]:
    """
    Temel anahtar kelime taraması ile fallback analizi yapar.
    """
    logger.info(f"Prompt '{prompt[:30]}...' için fallback analizi yapılıyor.")
    scores = {
        "character": 0.0,
        "setting": 0.0,
        "atmosphere": 0.0,
        "action": 0.0
    }
    lower_prompt = prompt.lower()

    # Çok basit anahtar kelime kontrolleri (geliştirilebilir)
    if any(kw in lower_prompt for kw in ["character", "person", "he", "she", "they", "name", "dialogue"]):
        scores["character"] = 0.6
    if any(kw in lower_prompt for kw in ["setting", "place", "environment", "city", "forest", "room", "time"]):
        scores["setting"] = 0.5
    if any(kw in lower_prompt for kw in ["mood", "atmosphere", "dark", "bright", "tense", "calm", "sound", "smell"]):
        scores["atmosphere"] = 0.4
    if any(kw in lower_prompt for kw in ["action", "fight", "run", "jump", "event", "plot", "conflict", "move"]):
        scores["action"] = 0.7

    # Skorları normalize et (isteğe bağlı, burada basitçe bırakıyoruz)

    return scores

# Örnek kullanım için (doğrudan çalıştırıldığında)
async def main():
    test_prompt = "A lone knight confronts a dragon in a dark, misty cave filled with the smell of sulfur. The knight raises his sword, ready for action."
    # test_prompt_no_api = "Describe a character walking through a bustling market."
    analysis_result = await analyze_prompt(test_prompt)
    print("Analysis Result:")
    print(analysis_result)

if __name__ == "__main__":
    # OPENAI_API_KEY ortam değişkenini ayarladığınızdan emin olun.
    # Örneğin bir .env dosyası oluşturup içine OPENAI_API_KEY="sk-..." yazın.
    if not os.getenv("OPENAI_API_KEY"):
        print("Uyarı: OPENAI_API_KEY ortam değişkeni ayarlanmamış.")
        print("Fallback mekanizması kullanılacak veya API çağrısı başarısız olacak.")
    
    asyncio.run(main()) 