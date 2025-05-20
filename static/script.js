document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('prompt-form');
    const promptInput = document.getElementById('prompt-input');
    const autoExpandCheckbox = document.getElementById('auto-expand-checkbox');
    const submitButton = document.getElementById('submit-button');
    const loadingSpinner = document.getElementById('loading-spinner');
    const resultArea = document.getElementById('result-area');
    const expansionsSection = document.getElementById('expansions-section');
    const expansionsList = document.getElementById('expansions-list');
    const questionsSection = document.getElementById('questions-section');
    const answersForm = document.getElementById('answers-form');
    const submitAnswersButton = document.getElementById('submit-answers-button');
    const loadingSpinnerAnswers = document.getElementById('loading-spinner-answers');
    const finalPromptSection = document.getElementById('final-prompt-section');
    const finalPromptText = document.getElementById('final-prompt-text');
    const errorSection = document.getElementById('error-section');
    const errorMessage = document.getElementById('error-message');

    let currentPromptData = {}; // To store data between steps

    // --- Helper Functions --- 
    const setLoading = (isLoading, button, spinner) => {
        if (isLoading) {
            button.disabled = true;
            button.classList.add('opacity-50', 'cursor-not-allowed');
            spinner.classList.remove('hidden');
        } else {
            button.disabled = false;
            button.classList.remove('opacity-50', 'cursor-not-allowed');
            spinner.classList.add('hidden');
        }
    };

    const hideAllResultSections = () => {
        resultArea.classList.add('hidden');
        expansionsSection.classList.add('hidden');
        questionsSection.classList.add('hidden');
        finalPromptSection.classList.add('hidden');
        errorSection.classList.add('hidden');
        expansionsList.innerHTML = '';
        answersForm.innerHTML = '';
        finalPromptText.textContent = '';
        errorMessage.textContent = '';
    };

    const displayError = (message) => {
        hideAllResultSections();
        errorMessage.textContent = message || 'Bilinmeyen bir hata oluştu.';
        errorSection.classList.remove('hidden');
        resultArea.classList.remove('hidden');
    };

    // --- API Call Function --- 
    const callApi = async (payload) => {
        setLoading(true, submitButton, loadingSpinner);
        setLoading(true, submitAnswersButton, loadingSpinnerAnswers); // Also disable second button if visible
        hideAllResultSections();
        currentPromptData = payload; // Store current request data

        try {
            const response = await fetch('/api/v1/generate', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify(payload)
            });

            if (!response.ok) {
                let errorMsg = `API Hatası: ${response.status} ${response.statusText}`;
                try {
                    const errorData = await response.json();
                    errorMsg = errorData.detail || errorMsg;
                } catch (e) { /* Ignore parsing error */ }
                throw new Error(errorMsg);
            }

            const data = await response.json();
            handleApiResponse(data);

        } catch (error) {
            console.error('API Çağrısı Hatası:', error);
            displayError(error.message);
        } finally {
            setLoading(false, submitButton, loadingSpinner);
             setLoading(false, submitAnswersButton, loadingSpinnerAnswers);
        }
    };

    // --- API Response Handler --- 
    const handleApiResponse = (data) => {
        hideAllResultSections(); // Clear previous results first
        resultArea.classList.remove('hidden');
        currentPromptData.language_code = data.language_code; // Update language code
        currentPromptData.categorized_elements = data.categorized_elements;

        if (data.status === 'error') {
            displayError(data.error_message);
            return;
        }

        // Display expansions if they exist
        if (data.expansions && data.expansions.length > 0) {
            expansionsList.innerHTML = ''; // Clear previous
            data.expansions.forEach((exp, index) => {
                const div = document.createElement('div');
                div.className = 'p-2 border rounded bg-gray-50 text-sm';
                div.textContent = exp;
                expansionsList.appendChild(div);
            });
            expansionsSection.classList.remove('hidden');
            // Note: We don't automatically use expansions yet per API design
        }

        // Display questions if they exist
        if (data.status === 'questions_generated' && data.questions && data.questions.length > 0) {
            answersForm.innerHTML = ''; // Clear previous questions
            data.questions.forEach((q, index) => {
                const div = document.createElement('div');
                div.className = 'mb-3';
                const label = document.createElement('label');
                label.htmlFor = `answer-${index}`;
                label.className = 'block text-sm font-medium text-gray-700 mb-1';
                label.textContent = q.question;
                if (q.examples && q.examples.length > 0) {
                     label.textContent += ` (Örn: ${q.examples.join(', ')})`;
                }
                
                const input = document.createElement('input');
                input.type = 'text';
                input.id = `answer-${index}`;
                input.name = q.question; // Use question as name to map back
                 input.dataset.module = q.module; // Store module if needed
                input.className = 'w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-transparent text-sm';
                
                div.appendChild(label);
                div.appendChild(input);
                answersForm.appendChild(div);
            });
            questionsSection.classList.remove('hidden');
        }

        // Display final prompt if it exists
        if (data.status === 'prompt_finalized' && data.final_prompt) {
            finalPromptText.textContent = data.final_prompt;
            finalPromptSection.classList.remove('hidden');
        }
        
         // If questions were generated but the list is empty (or status wasn't finalized)
         if (data.status === 'questions_generated' && (!data.questions || data.questions.length === 0)) {
             // Maybe trigger finalization automatically if no questions needed?
             // For now, let's assume the API might return this status without questions
             // We could potentially directly call the finalizer here, but let's display a message.
             console.log("No questions generated, attempting to finalize...");
             // OR Display a message: "No further questions needed. Finalizing..."
             // Let's call finalize directly if no questions
             if (currentPromptData && currentPromptData.prompt) {
                 callApi({ ...currentPromptData, answers: [] }); // Call again with empty answers
             } else {
                 displayError("Prompt verisi eksik, final prompt oluşturulamıyor.");
             }
         }
    };

    // --- Event Listeners --- 
    form.addEventListener('submit', (event) => {
        event.preventDefault();
        const promptText = promptInput.value.trim();
        if (!promptText) {
            displayError('Lütfen bir prompt girin.');
            return;
        }
        const payload = {
            prompt: promptText,
            auto_expand: autoExpandCheckbox.checked,
            answers: null // Initial request has no answers
        };
        callApi(payload);
    });

    submitAnswersButton.addEventListener('click', () => {
        const answers = [];
        const inputs = answersForm.querySelectorAll('input[type="text"]');
        inputs.forEach(input => {
            const answerText = input.value.trim();
            if (answerText) {
                answers.push({ question: input.name, answer: answerText });
            }
        });

        if (answers.length === 0) {
            // Optionally allow submitting with no answers to finalize
            console.log("Cevap verilmedi, yine de finalize ediliyor.");
            // displayError('Lütfen en az bir soruya cevap verin.');
            // return;
        }

        const payload = {
            prompt: currentPromptData.prompt, // Use the initial prompt that led to questions
            auto_expand: false, // Don't re-expand
            language_code: currentPromptData.language_code,
            answers: answers,
             // We don't need to resend categorized_elements, API re-analyzes if needed, 
             // or the finalizer uses the elements from the original prompt context.
        };
        callApi(payload);
    });
}); 