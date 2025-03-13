# AiScribe

AiScribe is an interactive solution to improve text-to-image prompts using AI agents. The system helps users refine and enhance their prompts through a series of intelligent suggestions and improvements.

## Features

1. **Prompt Analysis**: Analyzes user input to identify key elements, structure, and potential improvements
2. **Module-based Suggestions**: Provides targeted suggestions based on different aspects:
   - Character details
   - Setting descriptions
   - Atmosphere and mood
   - Actions and movements

## Project Structure

```
AiScribe/
├── agents/
│   ├── prompt_analysis_agent.py
│   └── module_suggestion_agent.py
├── requirements.txt
└── test_agents.py
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/ferhatsli/AiScribe.git
cd AiScribe
```

2. Create a virtual environment and activate it:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Create a `.env` file with your OpenAI API key:
```
OPENAI_API_KEY=your_api_key_here
```

## Usage

Run the test script to see the agents in action:
```bash
python test_agents.py
```

## License

[MIT License](LICENSE) 