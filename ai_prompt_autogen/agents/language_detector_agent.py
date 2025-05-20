from autogen import AssistantAgent
from ..config.settings import LLM_CONFIG

LANGUAGE_DETECTOR_PROMPT = """You are a language detection agent.

You will receive a user prompt, and your job is to detect which language it is written in.

Return only the ISO 639-1 code of the detected language. For example:
	•	“en” for English
	•	“tr” for Turkish
	•	“fr” for French
	•	“de” for German

Do not explain. Respond only with the 2-letter code."""

language_detector = AssistantAgent(
    name="language_detector",
    llm_config=LLM_CONFIG,
    system_message=LANGUAGE_DETECTOR_PROMPT,
    description="Detects the language of the user's prompt and returns the ISO code."
) 