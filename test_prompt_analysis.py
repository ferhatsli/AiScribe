import asyncio
import json
import os
from dotenv import load_dotenv
from agents.prompt_analysis_agent import PromptAnalysisAgent

async def test_prompt_analysis():
    # Load environment variables
    load_dotenv()
    
    # Set OpenAI API key in environment
    os.environ["OPENAI_API_KEY"] = os.getenv("OPENAI_API_KEY")
    
    # Create the analysis agent (it will create its own model client)
    analyzer = PromptAnalysisAgent()
    
    # Test prompt
    test_prompt = "A wavy sea under the moonlight"
    
    print(f"Analyzing prompt: {test_prompt}\n")
    
    try:
        # Get the analysis
        analysis = await analyzer.analyze_prompt(test_prompt)
        
        # Print the results
        print("Analysis Results:")
        print(json.dumps(analysis, indent=2))
    except Exception as e:
        print(f"Error during analysis: {str(e)}")

if __name__ == "__main__":
    asyncio.run(test_prompt_analysis()) 