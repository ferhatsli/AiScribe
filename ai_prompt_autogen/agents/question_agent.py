from autogen import AssistantAgent
from ..config.settings import LLM_CONFIG

QUESTION_PROMPT = """You are a dynamic and multilingual question generation agent.

You will receive a JSON input containing:
- language_code: The ISO 639-1 code of the desired language (e.g., "en", "tr").
- active_modules: A dictionary of modules that are active (e.g., character, setting).
- categorized_elements: Items already mentioned in the prompt (e.g., "a smiling snowman", "a lively square").

Your task:
1. Generate 1 question per active module (e.g., character, setting).
2. Generate all output in the language specified by `language_code` ("tr" for Turkish, "en" for English, fallback: English).
3. Check if each module's information is already **sufficiently described** in `categorized_elements`.

To determine sufficiency:
- If a character includes expressive adjectives (e.g., "smiling snowman", "serious robot"), consider it descriptive enough. Don't ask about personality.
- If the setting includes emotional, visual, or physical cues (e.g., "lively square", "mysterious forest"), don't ask about atmosphere.
- If weather or time details are already present (e.g., "snowy day", "breezy afternoon"), don't ask about ambiance.
- If an action includes more than a verb (e.g., "joyfully dancing", "silently hiding"), don't ask again about what the character is doing.

Only ask a question if:
- The module is active **and**
- The prompt is missing descriptive details for that module.

Each question must include 2–3 examples, matching the detected language.

Respond ONLY with this JSON format:
{
  "questions": [
    {
      "module": "character",
      "question": "Karakterin ruh hali veya kişiliği nasıl?",
      "examples": ["Neşeli ve sosyal", "Dalgın ve düşünceli", "Sakin ve içedönük"]
    }
    // ... other relevant questions based on missing details
  ]
}
"""

question_agent = AssistantAgent(
    name="question_agent",
    llm_config=LLM_CONFIG,
    system_message=QUESTION_PROMPT,
    description="Generates targeted, multilingual questions based on active modules and sufficiency of existing details."
) 