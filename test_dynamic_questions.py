import asyncio
import json
import os
from dotenv import load_dotenv
from agents.prompt_analysis_agent import PromptAnalysisAgent
from agents.module_suggestion_agent import ModuleSuggestionAgent
from agents.dynamic_question_agent import DynamicQuestionAgent

async def test_dynamic_questions():
    # Load environment variables
    load_dotenv()
    
    # Set OpenAI API key in environment
    os.environ["OPENAI_API_KEY"] = os.getenv("OPENAI_API_KEY")
    
    # Create all agents
    analyzer = PromptAnalysisAgent()
    suggester = ModuleSuggestionAgent()
    questioner = DynamicQuestionAgent()
    
    # Test prompt
    initial_prompt = "A mysterious figure in a forest"
    print(f"\nStarting with initial prompt: {initial_prompt}\n")
    print("-" * 50)
    
    try:
        # Step 1: Analyze the prompt
        print("\nStep 1: Prompt Analysis")
        analysis = await analyzer.analyze_prompt(initial_prompt)
        print(json.dumps(analysis, indent=2))
        
        # Step 2: Generate module suggestions
        print("\nStep 2: Module Suggestions")
        suggestions = await suggester.process_prompt_analysis(analysis)
        print(json.dumps(suggestions, indent=2))
        
        # Step 3: Start dynamic question session
        print("\nStep 3: Dynamic Question Generation")
        session = await questioner.process_module_suggestions(suggestions)
        print("\nInitial session setup:")
        print(json.dumps(session, indent=2))
        
        # Simulate multiple question-answer interactions
        print("\nSimulating Q&A interaction:")
        
        # Test responses that don't always match the intended module
        test_responses = [
            # Setting question, but character response
            ("What kind of environment should be depicted?", 
             "A tall figure wearing a dark cloak with a hood obscuring their face"),
            
            # Follow-up on character (adapting to previous response)
            ("Can you tell me more about the figure's appearance or demeanor?",
             "They stand mysteriously in a misty, dark forest with ancient oak trees"),
            
            # Atmosphere/mood question
            ("What mood or atmosphere should the scene convey?",
             "The atmosphere is mysterious and slightly threatening, with shadows playing across the figure"),
            
            # Action question
            ("What is the figure doing in this setting?",
             "The figure is standing still, observing something in the distance through the mist")
        ]
        
        current_question = session['initial_question']
        
        for i, (intended_question, response) in enumerate(test_responses):
            # Override the generated question with our test question for demonstration
            current_question["question"] = intended_question
            
            print(f"\nQ{i+1}: {current_question['question']}")
            print(f"A{i+1}: {response}")
            
            # Analyze the response content
            response_analysis = questioner.analyze_response_content(response)
            print("\nResponse Analysis:")
            print(json.dumps(response_analysis, indent=2))
            
            # Record the response
            questioner.record_response(current_question, response)
            
            # Show progress
            progress = questioner.get_session_progress()
            print("\nProgress update:")
            print(json.dumps(progress, indent=2))
            
            # Generate next question
            if i < len(test_responses) - 1:
                current_question = await questioner.generate_next_question({
                    "question": current_question,
                    "response": response
                })
                print("\nNext question:")
                print(json.dumps(current_question, indent=2))
        
        print("\nQuestion session completed!")
        
    except Exception as e:
        print(f"Error during testing: {str(e)}")
        import traceback
        print(traceback.format_exc())
    
    print("-" * 50)

if __name__ == "__main__":
    asyncio.run(test_dynamic_questions()) 