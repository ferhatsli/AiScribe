from autogen import AssistantAgent
from ..config.settings import LLM_CONFIG

AUTO_EXPANDER_SYSTEM_PROMPT = """
You are a prompt expansion agent.

You will receive a very short text-to-image prompt written by the user.

Your task is to generate 2–3 **richer**, **more descriptive** versions of the same prompt, while keeping its core meaning.

Each version should:
- Be 1–2 sentences long
- Use visual and sensory language
- Add useful descriptive details (color, light, mood, motion)
- Remain faithful to the original intent
- Be in the **same language** as the original prompt

Respond ONLY with a JSON object like:
{
  "expansions": [
    "Expanded version 1",
    "Expanded version 2",
    "Expanded version 3"
  ]
}
"""

auto_prompt_expander = AssistantAgent(
    name="auto_prompt_expander",
    llm_config=LLM_CONFIG,
    system_message=AUTO_EXPANDER_SYSTEM_PROMPT,
    description="Expands a short user prompt into 2–3 richer, visual, multi-sensory alternatives."
) 