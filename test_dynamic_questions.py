import asyncio
import json
import os
from dotenv import load_dotenv
from agents.prompt_analysis_agent import PromptAnalysisAgent
from agents.module_suggestion_agent import ModuleSuggestionAgent
from agents.dynamic_question_agent import DynamicQuestionAgent

async def interactive_prompt_session():
    # Load environment variables
    load_dotenv()
    
    # Set OpenAI API key in environment
    os.environ["OPENAI_API_KEY"] = os.getenv("OPENAI_API_KEY")
    
    # Create all agents
    analyzer = PromptAnalysisAgent()
    suggester = ModuleSuggestionAgent()
    questioner = DynamicQuestionAgent()
    
    # Get initial prompt from user
    print("\nWelcome to the Interactive Prompt Generator!")
    print("Please enter your initial prompt (e.g., 'A mysterious figure in a forest'):")
    initial_prompt = input("> ").strip()
    
    print(f"\nStarting with initial prompt: {initial_prompt}\n")
    print("-" * 50)
    
    try:
        # Step 1: Analyze the prompt
        print("\nAnalyzing your prompt...")
        analysis = await analyzer.analyze_prompt(initial_prompt)
        
        # Step 2: Generate module suggestions
        print("\nGenerating suggestions...")
        suggestions = await suggester.process_prompt_analysis(analysis)
        
        # Step 3: Start dynamic question session
        print("\nStarting interactive question session...")
        session = await questioner.process_module_suggestions(suggestions)
        
        current_question = session['initial_question']
        
        while True:
            # Display question and options
            print(f"\nQ: {current_question['question']}")
            print("\nOptions (enter the number of your choice):")
            for i, option in enumerate(current_question['options'], 1):
                print(f"{i}. {option}")
            print("\nExample response:")
            print(f"- {current_question['examples'][0]}")
            
            # Get user response
            print("\nEnter option number (or 'done' to finish):")
            response = input("> ").strip()
            
            if response.lower() == 'done':
                break
                
            try:
                # Convert numeric response to actual option text
                option_num = int(response)
                if 1 <= option_num <= len(current_question['options']):
                    response = current_question['options'][option_num - 1]
                else:
                    print("Invalid option number. Please try again.")
                    continue
            except ValueError:
                # If not a number, use the response as-is
                pass
            
            # Record the response
            questioner.record_response(current_question, response)
            
            # Generate next question, ensuring it stays relevant to initial prompt
            next_question = await questioner.generate_next_question({
                "question": current_question,
                "response": response,
                "initial_prompt": initial_prompt  # Pass the initial prompt to maintain context
            })
            
            if next_question:
                current_question = next_question
            else:
                break
        
        print("\nGenerating final prompt...")
        final_prompt = await questioner.generate_final_prompt()
        print("\nYour Final Generated Prompt:")
        print("-" * 50)
        print(final_prompt)
        print("-" * 50)
        
    except Exception as e:
        print(f"Error during session: {str(e)}")
        import traceback
        print(traceback.format_exc())

if __name__ == "__main__":
    asyncio.run(interactive_prompt_session()) 