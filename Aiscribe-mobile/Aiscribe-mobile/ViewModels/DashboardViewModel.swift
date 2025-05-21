import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var recentPrompts: [String] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // AuthViewModel'e erişim
    @Published var authViewModel: AuthViewModel?
    
    private let promptViewModel: PromptViewModel
    private let userDefaults = UserDefaults.standard
    private let recentPromptsKeyPrefix = "recentPrompts_"
    
    init(promptViewModel: PromptViewModel) {
        self.promptViewModel = promptViewModel
        loadRecentPrompts()
        
        // Auth değişikliklerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthChange),
            name: NSNotification.Name("AuthStateChanged"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Auth değişimlerini dinle
    @objc private func handleAuthChange() {
        loadRecentPrompts()
    }
    
    // Kullanıcı kimliğine göre kayıt anahtarı oluştur
    private func getRecentPromptsKey() -> String {
        if let authViewModel = authViewModel, let userId = authViewModel.user?.id {
            return "\(recentPromptsKeyPrefix)\(userId)"
        }
        return recentPromptsKeyPrefix
    }
    
    func loadRecentPrompts() {
        let key = getRecentPromptsKey()
        if let savedPrompts = userDefaults.stringArray(forKey: key) {
            recentPrompts = savedPrompts
        } else {
            // Örnek veri (sadece kullanıcı yoksa göster)
            if authViewModel?.user == nil {
                recentPrompts = [
                    "Uzayda yalnız bir astronot...",
                    "Bir kış ormanında tilki...",
                    "Rönesans tarzı portre..."
                ]
            } else {
                recentPrompts = []
            }
        }
    }
    
    func savePrompt(_ prompt: String, resultViewModel: ResultViewModel, style: String? = nil) {
        let key = getRecentPromptsKey()
        if !recentPrompts.contains(prompt) {
            recentPrompts.insert(prompt, at: 0)
            if recentPrompts.count > 5 {
                recentPrompts.removeLast()
            }
            userDefaults.set(recentPrompts, forKey: key)
        }
        resultViewModel.saveResult(forPrompt: prompt, style: style)
    }
    
    func showResult(forPrompt prompt: String, resultViewModel: ResultViewModel) {
        resultViewModel.loadResult(forPrompt: prompt)
    }
    
    func clearRecentPrompts() {
        let key = getRecentPromptsKey()
        recentPrompts.removeAll()
        userDefaults.removeObject(forKey: key)
    }
} 