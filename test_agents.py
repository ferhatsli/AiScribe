import asyncio
import json
import os
from dotenv import load_dotenv
from agents.prompt_analysis_agent import PromptAnalysisAgent
from agents.module_suggestion_agent import ModuleSuggestionAgent

async def test_agents():
    # Load environment variables
    load_dotenv()
    
    # Set OpenAI API key in environment
    os.environ["OPENAI_API_KEY"] = os.getenv("OPENAI_API_KEY")
    
    # Create both agents
    analyzer = PromptAnalysisAgent()
    suggester = ModuleSuggestionAgent()
    
    # Test prompts
    test_prompts = [
        "A wavy sea under the moonlight",
        "Little Red Riding Hood walking through a misty forest at dawn"
    ]
    
    for prompt in test_prompts:
        print(f"\nAnalyzing prompt: {prompt}\n")
        print("-" * 50)
        
        try:
            # Step 1: Analyze the prompt
            print("\nStep 1: Prompt Analysis")
            analysis = await analyzer.analyze_prompt(prompt)
            print(json.dumps(analysis, indent=2))
            
            # Step 2: Generate module suggestions
            print("\nStep 2: Module Suggestions")
            suggestions = await suggester.process_prompt_analysis(analysis)
            print(json.dumps(suggestions, indent=2))
            
        except Exception as e:
            print(f"Error during processing: {str(e)}")
        
        print("-" * 50)

if __name__ == "__main__":
    asyncio.run(test_agents()) 