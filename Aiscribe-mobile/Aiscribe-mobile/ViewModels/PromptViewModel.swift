import Foundation
import Combine // SwiftUI'da @Published gibi property wrapper'lar için

// ViewModel, ObservableObject protokolüne uymalı ki SwiftUI View'ları onu dinleyebilsin.
class PromptViewModel: ObservableObject {
    
    // APIService'e erişim
    private let apiService = APIService() // Dependency injection daha iyi bir pratik olabilir ama şimdilik direkt oluşturuyoruz.
    
    // UI'ın dinleyeceği @Published değişkenler
    @Published var userInputPrompt: String = "" // Kullanıcının girdiği ilk prompt
    
    @Published var isLoading: Bool = false // API çağrısı sırasında yüklenme durumunu göstermek için
    @Published var errorMessage: String? = nil // Hata mesajlarını UI'da göstermek için
    
    @Published var expansions: [String]? = nil // Backend'den gelen genişletilmiş prompt seçenekleri
    @Published var questions: [QuestionItem]? = nil // Backend'den gelen sorular
    @Published var userAnswers: [AnswerItem] = [] // Kullanıcının sorulara verdiği cevaplar (UI'da doldurulacak)
    @Published var currentQuestionIndex: Int = 0
    
    @Published var selectedStyle: String? = nil
    
    // Bu değişkenler ResultViewModel'e taşındı
    // @Published var finalGeneratedPrompt: String? = nil
    // @Published var currentCategorizedElements: [String: [String]]? = nil
    // @Published var currentLanguageCode: String? = nil
    
    private let resultViewModel: ResultViewModel
    
    init(resultViewModel: ResultViewModel) {
        self.resultViewModel = resultViewModel
    }
    
    // Bu fonksiyon, kullanıcı ilk prompt'u girdiğinde veya genişletilmiş bir prompt seçtiğinde çağrılabilir.
    func processInitialPrompt() {
        guard !userInputPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a prompt."
            return
        }
        
        // Son prompt ve stil bilgisini kaydet
        resultViewModel.lastUserPrompt = userInputPrompt
        resultViewModel.lastSelectedStyle = selectedStyle
        
        isLoading = true
        errorMessage = nil
        questions = nil
        expansions = nil
        userAnswers = []

        let request = PromptRequest(prompt: userInputPrompt, autoExpand: true, style: selectedStyle)
        
        apiService.generatePrompt(requestData: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    self?.handlePromptResponse(response)
                case .failure(let error):
                    self?.handleAPIError(error)
                }
            }
        }
    }
    
    // Kullanıcı soruları cevapladıktan sonra bu fonksiyon çağrılabilir.
    func submitAnswers() {
        guard !userInputPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Original prompt is missing."
            return
        }

        // Son prompt ve stil bilgisini kaydet
        resultViewModel.lastUserPrompt = userInputPrompt
        resultViewModel.lastSelectedStyle = selectedStyle

        isLoading = true
        errorMessage = nil
        
        let request = PromptRequest(prompt: userInputPrompt, answers: userAnswers, style: selectedStyle)
        
        apiService.generatePrompt(requestData: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    self?.handlePromptResponse(response)
                case .failure(let error):
                    self?.handleAPIError(error)
                }
            }
        }
    }
    
    private func handlePromptResponse(_ response: PromptResponse) {
        resultViewModel.categorizedElements = response.categorizedElements
        resultViewModel.languageCode = response.languageCode
        
        self.expansions = response.expansions
        
        if response.status == "questions_generated" {
            if let newQuestions = response.questions, !newQuestions.isEmpty {
                self.questions = newQuestions.map { QuestionItem(from: $0) }
                // Her soru için boş bir AnswerItem oluştur
                self.userAnswers = newQuestions.map { question in
                    AnswerItem(question: question.question, answer: "")
                }
                self.currentQuestionIndex = 0 // Soru akışı başında index sıfırla
            } else {
                if let finalPrompt = response.finalPrompt {
                    resultViewModel.generatedPrompt = finalPrompt
                    resultViewModel.autoSaveIfPossible()
                    self.questions = nil
                    self.currentQuestionIndex = 0 // Sonuç ekranına geçerken index sıfırla
                } else {
                    self.errorMessage = "Questions were expected but not received, and no final prompt."
                    self.currentQuestionIndex = 0 // Hata durumunda da index sıfırla
                }
            }
        } else if response.status == "prompt_finalized" {
            resultViewModel.generatedPrompt = response.finalPrompt
            resultViewModel.autoSaveIfPossible()
            self.questions = nil
            self.currentQuestionIndex = 0 // Sonuç ekranına geçerken index sıfırla
        } else {
            if response.expansions != nil && response.questions == nil && response.finalPrompt == nil {
                print("Received expansions. User should select one.")
            } else {
                self.errorMessage = "Received an unexpected response status: \(response.status)"
            }
            self.currentQuestionIndex = 0 // Diğer durumlarda da index sıfırla
        }
    }
    
    private func handleAPIError(_ error: ServiceAPIError) {
        switch error {
        case .invalidURL:
            self.errorMessage = "Invalid API URL."
        case .requestFailed(let err):
            self.errorMessage = "Request failed: \(err.localizedDescription)"
        case .invalidResponse:
            self.errorMessage = "Invalid response from server."
        case .decodingError(let err):
            self.errorMessage = "Failed to decode server response: \(err.localizedDescription)"
        case .serverError(let message, let statusCode):
            self.errorMessage = "Server error (\(statusCode)): \(message)"
        }
    }

    // UI'dan seçilen bir genişletmeyi işlemek için yardımcı fonksiyon
    func selectExpansion(selectedPrompt: String) {
        self.userInputPrompt = selectedPrompt
        self.processInitialPromptAfterExpansionSelection()
    }

    private func processInitialPromptAfterExpansionSelection() {
        isLoading = true
        errorMessage = nil
        questions = nil
        userAnswers = []

        let request = PromptRequest(prompt: userInputPrompt, autoExpand: false, style: selectedStyle)
        
        apiService.generatePrompt(requestData: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    self?.handlePromptResponse(response)
                case .failure(let error):
                    self?.handleAPIError(error)
                }
            }
        }
    }
} 
