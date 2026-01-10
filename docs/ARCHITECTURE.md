# AiScribe Architecture Documentation

## Overview
AiScribe is an AI-powered interactive prompt generation system that helps users create detailed and effective image generation prompts. The system uses a multi-agent architecture to analyze, process, and enhance user inputs through a guided question-answer flow.

## Project Structure
```
AiScribe/
├── agents/                     # Core agent system
│   ├── base/                  # Base agent functionality
│   ├── prompt/               # Prompt analysis components
│   ├── module/               # Module management components
│   ├── question/            # Question generation and handling
│   └── utils/               # Shared utilities
├── app.py                    # Main Streamlit application
└── docs/                    # Documentation
```

## Agent System Architecture

### 1. Base Agent (`agents/base/`)
- **BaseAgent**: Abstract base class that provides common functionality for all agents
  - Inherits from `AssistantAgent` (Autogen framework)
  - Handles OpenAI API client initialization
  - Provides common utility methods

### 2. Prompt Analysis (`agents/prompt/`)
- **PromptAnalysisAgent**: Analyzes initial user prompts
  - Breaks down prompts into structured components
  - Identifies key elements (characters, settings, actions, emotions)
  - Evaluates prompt effectiveness
  - Suggests potential improvements

### 3. Module Management (`agents/module/`)
- **ModuleSuggestionAgent**: Manages different aspects of prompt generation
  - Determines which modules should be active
  - Generates module-specific suggestions
  - Modules include:
    - Character Module: Appearance, expressions, clothing
    - Setting Module: Environment, weather, time
    - Atmosphere Module: Mood, lighting, style
    - Action Module: Movement, poses, interactions

### 4. Question System (`agents/question/`)
- **DynamicQuestionAgent**: Main orchestrator for the Q&A flow
  - Generates contextual questions
  - Processes user responses
  - Maintains session state
  - Generates final enhanced prompts

#### Question System Components:
1. **QuestionSession**: Manages session state and progress
   - Tracks active modules
   - Records responses
   - Maintains question history
   - Monitors progress

2. **ResponseAnalyzer**: Analyzes user responses
   - Determines relevance to different modules
   - Calculates module relevance scores
   - Provides fallback analysis

3. **QuestionGenerator**: Generates dynamic questions
   - Creates context-sensitive questions
   - Uses templates for fallback
   - Maintains question flow

4. **QuestionTemplates**: Predefined question structures
   - Module-specific templates
   - Follow-up questions
   - Example responses

## Data Flow

1. **Initial Prompt Analysis**
   ```
   User Input → PromptAnalysisAgent → Structured Analysis
   ```

2. **Module Activation**
   ```
   Analysis → ModuleSuggestionAgent → Active Modules + Suggestions
   ```

3. **Question Flow**
   ```
   Active Modules → DynamicQuestionAgent → Questions → User Responses → Analysis → Next Question
   ```

4. **Final Generation**
   ```
   Question History + Responses → DynamicQuestionAgent → Enhanced Final Prompt
   ```

## Key Features

### 1. Adaptive Questioning
- Questions adapt based on previous responses
- Context-aware follow-up questions
- Dynamic difficulty adjustment

### 2. Modular Design
- Independent module system
- Extensible architecture
- Plug-and-play components

### 3. Fallback Mechanisms
- Template-based fallbacks
- Error handling at each level
- Graceful degradation

### 4. Session Management
- Persistent state tracking
- Progress monitoring
- Response history

## Integration with External Services

### 1. OpenAI Integration
- Uses GPT-4o-mini model
- Async API calls
- Error handling and retries

### 2. Streamlit Interface
- Real-time updates
- Interactive components
- Responsive design

## Best Practices

1. **Error Handling**
   - Comprehensive error catching
   - Fallback responses
   - User-friendly error messages

2. **State Management**
   - Clear state transitions
   - Session persistence
   - Progress tracking

3. **Code Organization**
   - Clear separation of concerns
   - Modular components
   - Consistent naming conventions

## Future Extensions

1. **New Modules**
   - Additional specialized modules
   - Custom module creation
   - Module priority system

2. **Enhanced Analysis**
   - More detailed prompt analysis
   - Style recognition
   - Theme detection

3. **Advanced Features**
   - Multi-session support
   - Prompt versioning
   - Collaborative editing

## Performance Considerations

1. **Optimization**
   - Async operations
   - Caching mechanisms
   - Resource management

2. **Scalability**
   - Modular architecture
   - Independent components
   - Stateless design where possible

## Security

1. **API Security**
   - Secure API key handling
   - Environment variable management
   - Request validation

2. **Data Protection**
   - Session isolation
   - Input sanitization
   - Secure state management 