from ai_prompt_autogen.agents.user_proxy import user_proxy
from ai_prompt_autogen.agents.prompt_analyzer_agent import prompt_analyzer
from ai_prompt_autogen.agents.module_suggester_agent import module_suggester
from ai_prompt_autogen.agents.question_agent import question_agent
from ai_prompt_autogen.agents.prompt_finalizer_agent import prompt_finalizer
from ai_prompt_autogen.agents.language_detector_agent import language_detector
from ai_prompt_autogen.agents.auto_prompt_expander_agent import auto_prompt_expander
import json
import re
from copy import deepcopy

if __name__ == "__main__":
    # Kullanıcıdan prompt al
    user_input_prompt = input("Lütfen analiz etmek istediğiniz prompt'u girin (varsayılan için Enter): ")
    if not user_input_prompt:
        user_input_prompt = "A lonely astronaut floats through the silent void of space."
        print(f"Boş giriş yapıldı, varsayılan prompt kullanılıyor: '{user_input_prompt}'")

    # 🚀 Auto-Expansion Step
    expand_choice = input("Prompt'unu otomatik olarak genişletmek ister misin? (e/h): ").strip().lower()
    if expand_choice == 'e':
        print("\n✨ Expanding prompt...\n")
        expander_result = user_proxy.initiate_chat(
            recipient=auto_prompt_expander,
            message=user_input_prompt, # Send original prompt
            summary_method=None,
            silent=True
        )

        expansions = []
        if expander_result.chat_history:
            expander_reply = expander_result.chat_history[-1]["content"]
            try:
                expander_json = json.loads(expander_reply)
                expansions = expander_json.get("expansions", [])
                if expansions:
                    print("✅ Prompt expansion successful.")
                else:
                    print("⚠️ AutoExpander did not return any expansions.")
            except json.JSONDecodeError:
                print(f"❌ Failed to parse expansions from AutoExpander response:\n{expander_reply}")
        else:
            print("❌ No chat history found for AutoExpander.")

        if expansions:
            print("\n👇 Choose a prompt to continue with:")
            # Display options
            options = [user_input_prompt] + expansions
            for i, option in enumerate(options):
                print(f"{i}. {option}")
            
            choice = input(f"Hangi prompt ile devam etmek istersin? (0-{len(options)-1}): ")
            try:
                choice_index = int(choice)
                if 0 <= choice_index < len(options):
                    user_input_prompt = options[choice_index]
                    print(f"\n👍 Seçilen prompt: '{user_input_prompt}'")
                else:
                    print("⚠️ Geçersiz seçim. Orijinal prompt ile devam ediliyor.")
            except ValueError:
                print("⚠️ Geçersiz giriş. Orijinal prompt ile devam ediliyor.")
        else:
             print("⚠️ Genişletme başarısız olduğu için orijinal prompt ile devam ediliyor.")

    else:
        print("\n⏭️ Prompt genişletme adımı atlandı.")

    # 🌐 Prompt dilini belirle
    print("\n🌍 Detecting prompt language...\n")
    lang_result = user_proxy.initiate_chat(
        recipient=language_detector,
        message=user_input_prompt, # Uses original or chosen expanded prompt
        summary_method=None,
        silent=True
    )

    # ISO kodu al
    language_code = "en" # Default
    if lang_result.chat_history:
        detected_code = lang_result.chat_history[-1]["content"].strip().lower()
        if len(detected_code) == 2 and detected_code.isalpha():
             language_code = detected_code
             print(f"✅ Detected language code: {language_code}")
        else:
            print(f"⚠️ Invalid language code received: '{detected_code}'. Defaulting to English.")
    else:
        print("⚠️ Language detection failed. Defaulting to English.")

    # 1. Prompt analiz ettir
    prompt = user_input_prompt
    print("\n🔍 Analyzing prompt...\n")
    analyzer_result = user_proxy.initiate_chat(
        recipient=prompt_analyzer,
        message=f"User language: {language_code}. Please analyze this prompt: '{prompt}'",
        summary_method=None,
        silent=True
    )

    # 2. Yanıtı ChatResult.chat_history'den al ve JSON olarak parse et
    module_scores = {}
    categorized_elements = {}
    if analyzer_result.chat_history:
        last_message = analyzer_result.chat_history[-1]["content"]
        try:
            parsed_analysis = json.loads(last_message)
            module_scores = parsed_analysis.get("scores", {})
            categorized_elements = parsed_analysis.get("categorized_elements", {})
            print("\n✅ Module scores extracted from PromptAnalyzer:\n", module_scores)
            print("\n✅ Categorized elements extracted:\n", categorized_elements)
        except json.JSONDecodeError:
            print("\n❌ Failed to parse analysis from PromptAnalyzer response:\n", last_message)
            exit(1)
    else:
        print("\n❌ No chat history found for prompt analyzer.")
        exit(1)

    # 3. Aktif modülleri belirle
    print("\n📊 Determining active modules...\n")
    suggester_result = user_proxy.initiate_chat(
        recipient=module_suggester,
        # Send only scores to the suggester
        message=f"User language: {language_code}. Here are the module scores: {json.dumps(module_scores)}", 
        summary_method=None,
        silent=True
    )

    # 4. ModuleSuggester yanıtını ChatResult.chat_history'den al ve JSON'dan parse et
    active_modules = {}
    if suggester_result.chat_history:
        suggester_reply = suggester_result.chat_history[-1]["content"]
        try:
            suggester_json = json.loads(suggester_reply)
            active_modules = suggester_json.get("active_modules", {})
            print("\n✅ Active modules extracted from ModuleSuggester:\n", active_modules)
        except json.JSONDecodeError:
            try:
                suggester_reply_fixed = re.sub(r",\s*([}\]])", r"\1", suggester_reply)
                suggester_reply_fixed = re.sub(r"//.*", "", suggester_reply_fixed)
                suggester_json = json.loads(suggester_reply_fixed)
                active_modules = suggester_json.get("active_modules", {})
                print("\n✅ Active modules extracted from ModuleSuggester (after fixing JSON):\n", active_modules)
            except Exception as e:
                 print(f"\n❌ Failed to parse active modules from response even after attempting fixes: {e}\nOriginal Response:\n{suggester_reply}")
                 exit(1)
    else:
        print("\n❌ No chat history found for module suggester.")
        exit(1)

    # 5. Aktif modüllere ve elementlere göre soru üret
    print("\n🧠 Generating questions...\n")
    question_input = {
        "active_modules": deepcopy(active_modules),
        "categorized_elements": deepcopy(categorized_elements)
    }
    message_str = f"User language: {language_code}. Question generation input:\n{json.dumps(question_input, indent=2)}"
    
    question_result = user_proxy.initiate_chat(
        recipient=question_agent,
        message=message_str, # Send combined structured input
        summary_method=None,
        silent=True
    )

    # Parse the questions generated by QuestionAgent
    generated_questions = []
    if question_result.chat_history:
        question_reply = question_result.chat_history[-1]["content"]
        try:
            question_json = json.loads(question_reply)
            generated_questions = question_json.get("questions", [])
            print(f"\n✅ Questions extracted from QuestionAgent: {len(generated_questions)} questions.")
        except json.JSONDecodeError:
            print("\n❌ Failed to parse questions from QuestionAgent response:\n", question_reply)
    else:
        print("\n❌ No chat history found for question agent.")

    # 6. Kullanıcı cevaplarını terminalden al
    print("\n🧾 Please answer the following questions (leave blank to skip):\n")
    qa_list = []
    if not generated_questions:
         print("Skipping Q&A as no questions were generated.")
    else:
        for q_data in generated_questions:
            question_text = q_data.get("question", "Unknown Question")
            examples = q_data.get("examples", [])
            prompt_text = f"{question_text}"
            if examples:
                prompt_text += f" (e.g., {', '.join(examples)})"
            ans = input(f"{prompt_text}\n> ")
            if ans.strip():
                qa_list.append({"question": question_text, "answer": ans.strip()})

    # 7. Finalizer input'unu hazırla
    print(f"\nCollected Answers: {len(qa_list)} provided.")
    finalizer_input = {
        "original_prompt": user_input_prompt,
        "categorized_elements": categorized_elements,
        "qa_list": qa_list
    }
    finalizer_message = f"User language: {language_code}. Final prompt generation input:\n{json.dumps(finalizer_input, indent=2)}"

    # 8. PromptFinalizerAgent'a gönder
    print("\n📦 Sending data to PromptFinalizerAgent...\n")
    finalizer_result = user_proxy.initiate_chat(
        recipient=prompt_finalizer,
        message=finalizer_message, # Use the new structured message
        summary_method=None
    )
    if finalizer_result.chat_history:
        final_prompt = finalizer_result.chat_history[-1]["content"]
        print(f"\n✨ Generated Final Prompt: ✨\n\n{final_prompt}\n")
    else:
        print("\n⚠️ No response received from PromptFinalizerAgent.")

    print("\n🏁 Full flow potentially completed! 🏁")

    # Placeholder for initiating the chat
    # The actual initiate_chat() call might need more setup depending on Autogen version and specific use case.
    # For now, we'll just print a message indicating readiness.
    print("UserProxyAgent is ready. To initiate chat, call user_proxy.initiate_chat() with appropriate arguments.")
    # Example (requires another agent to chat with):
    # assistant = AssistantAgent(...) # Define an assistant agent
    # user_proxy.initiate_chat(recipient=assistant, message="Your initial prompt")
    pass # Keep the script running or add chat initiation logic here 