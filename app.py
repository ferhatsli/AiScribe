import streamlit as st
import asyncio
from dotenv import load_dotenv
import os
from agents.prompt import PromptAnalysisAgent
from agents.module import ModuleSuggestionAgent
from agents.question import DynamicQuestionAgent

# Load environment variables
load_dotenv()
os.environ["OPENAI_API_KEY"] = os.getenv("OPENAI_API_KEY")

# Custom CSS
st.markdown("""
    <style>
        /* Main container */
        .stApp {
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
        }
        
        /* Headers */
        h1 {
            color: #4ecca3 !important;
            font-size: 3.5rem !important;
            font-weight: 700 !important;
            margin-bottom: 2rem !important;
            text-align: center !important;
        }
        
        h2 {
            color: #4ecca3 !important;
            font-weight: 600 !important;
        }
        
        /* Text input */
        .stTextInput input {
            background-color: rgba(255, 255, 255, 0.1) !important;
            color: white !important;
            border: 2px solid #4ecca3 !important;
            border-radius: 10px !important;
            padding: 15px !important;
        }
        
        /* Radio buttons */
        .stRadio > label {
            color: #e2e2e2 !important;
            font-size: 1.1rem !important;
        }
        
        /* Buttons */
        .stButton button {
            background-color: #4ecca3 !important;
            color: #1a1a2e !important;
            border: none !important;
            border-radius: 10px !important;
            padding: 10px 25px !important;
            font-weight: 600 !important;
            transition: all 0.3s ease !important;
        }
        
        .stButton button:hover {
            background-color: #45b393 !important;
            transform: translateY(-2px) !important;
        }
        
        /* Progress bar */
        .question-progress {
            background-color: rgba(78, 204, 163, 0.2);
            padding: 10px;
            border-radius: 10px;
            margin: 20px 0;
            text-align: center;
        }
        
        /* Dividers */
        hr {
            border-color: rgba(78, 204, 163, 0.2) !important;
            margin: 2rem 0 !important;
        }
        
        /* Success message */
        .success-box {
            background-color: rgba(78, 204, 163, 0.1) !important;
            border: 2px solid #4ecca3 !important;
            border-radius: 10px !important;
            padding: 20px !important;
            margin: 20px 0 !important;
        }
        
        /* Description text */
        .app-description {
            color: #e2e2e2;
            font-size: 1.2rem;
            text-align: center;
            margin-bottom: 2rem;
        }
    </style>
""", unsafe_allow_html=True)

# Initialize session state
if 'current_question' not in st.session_state:
    st.session_state.current_question = None
if 'agents' not in st.session_state:
    st.session_state.agents = {
        'analyzer': PromptAnalysisAgent(),
        'suggester': ModuleSuggestionAgent(),
        'questioner': DynamicQuestionAgent()
    }
if 'responses' not in st.session_state:
    st.session_state.responses = []
if 'final_prompt' not in st.session_state:
    st.session_state.final_prompt = None
if 'question_count' not in st.session_state:
    st.session_state.question_count = 0

# Constants
MAX_QUESTIONS = 5

# Main app layout
st.markdown("<h1>🎨 AiScribe</h1>", unsafe_allow_html=True)
st.markdown('<p class="app-description">Transform your ideas into detailed image generation prompts through an interactive journey</p>', unsafe_allow_html=True)

# Initial prompt input
if 'initial_prompt' not in st.session_state:
    st.session_state.initial_prompt = ""

col1, col2, col3 = st.columns([1, 2, 1])
with col2:
    initial_prompt = st.text_input(
        "✨ Enter your initial prompt:",
        value=st.session_state.initial_prompt,
        placeholder="e.g., 'Little Red Riding Hood walking through the forest'"
    )

    # Start button
    if initial_prompt and not st.session_state.current_question:
        if st.button("🚀 Start Generation", use_container_width=True):
            with st.spinner("🔮 Analyzing your prompt..."):
                async def initialize_session():
                    analysis = await st.session_state.agents['analyzer'].analyze_prompt(initial_prompt)
                    suggestions = await st.session_state.agents['suggester'].process_prompt_analysis(analysis)
                    session = await st.session_state.agents['questioner'].process_module_suggestions(suggestions)
                    return session['initial_question']
                
                st.session_state.initial_prompt = initial_prompt
                st.session_state.current_question = asyncio.run(initialize_session())
                st.session_state.question_count = 1
                st.rerun()

# Display current question and options
if st.session_state.current_question:
    st.markdown(f"""
        <div class="question-progress">
            Question {st.session_state.question_count} of {MAX_QUESTIONS}
            <div style="width: 100%; height: 5px; background: rgba(78, 204, 163, 0.2); margin-top: 10px; border-radius: 5px;">
                <div style="width: {(st.session_state.question_count/MAX_QUESTIONS)*100}%; height: 100%; background: #4ecca3; border-radius: 5px;"></div>
            </div>
        </div>
    """, unsafe_allow_html=True)
    
    st.markdown(f"### 💭 {st.session_state.current_question['question']}")
    
    # Display options as radio buttons
    options = st.session_state.current_question['options']
    selected_option = st.radio(
        "Select your choice:",
        options,
        index=None,
        key=f"radio_{st.session_state.question_count}"
    )
    
    # Show example
    with st.expander("💡 See example response"):
        st.write(st.session_state.current_question['examples'][0])
    
    # Submit answer button
    col1, col2, col3 = st.columns([1, 2, 1])
    with col2:
        if st.button("✨ Submit Answer", key=f"submit_{st.session_state.question_count}", use_container_width=True):
            if selected_option:
                with st.spinner("🔮 Processing your answer..."):
                    async def process_answer():
                        st.session_state.agents['questioner'].record_response(
                            st.session_state.current_question,
                            selected_option
                        )
                        
                        if st.session_state.question_count < MAX_QUESTIONS:
                            next_question = await st.session_state.agents['questioner'].generate_next_question({
                                "question": st.session_state.current_question,
                                "response": selected_option,
                                "initial_prompt": st.session_state.initial_prompt
                            })
                        else:
                            next_question = None
                        
                        return next_question
                    
                    st.session_state.responses.append({
                        'question': st.session_state.current_question['question'],
                        'answer': selected_option
                    })
                    
                    next_q = asyncio.run(process_answer())
                    if next_q and st.session_state.question_count < MAX_QUESTIONS:
                        st.session_state.current_question = next_q
                        st.session_state.question_count += 1
                    else:
                        st.session_state.current_question = None
                        async def get_final_prompt():
                            return await st.session_state.agents['questioner'].generate_final_prompt()
                        
                        st.session_state.final_prompt = asyncio.run(get_final_prompt())
                    st.rerun()
            else:
                st.warning("⚠️ Please select an option before submitting.")

# Display final prompt
if st.session_state.final_prompt:
    st.markdown("""
        <div style="text-align: center; margin: 2rem 0;">
            <h2>🎨 Your Generated Prompt</h2>
        </div>
    """, unsafe_allow_html=True)
    
    st.markdown('<div class="success-box">', unsafe_allow_html=True)
    st.markdown(f"✨ {st.session_state.final_prompt}", unsafe_allow_html=True)
    st.markdown('</div>', unsafe_allow_html=True)
    
    # Reset button
    col1, col2, col3 = st.columns([1, 2, 1])
    with col2:
        if st.button("🔄 Start Over", use_container_width=True):
            for key in st.session_state.keys():
                del st.session_state[key]
            st.rerun()

# Display response history
if st.session_state.responses:
    with st.expander("📝 View Response History"):
        for i, qa in enumerate(st.session_state.responses, 1):
            st.markdown(f"""
                <div style="background: rgba(78, 204, 163, 0.1); padding: 15px; border-radius: 10px; margin: 10px 0;">
                    <strong>Q{i}:</strong> {qa['question']}<br>
                    <strong>A{i}:</strong> {qa['answer']}
                </div>
            """, unsafe_allow_html=True) 