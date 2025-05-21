import Foundation
import Combine
import UIKit

class ResultViewModel: ObservableObject {
    @Published var generatedPrompt: String?
    @Published var categorizedElements: [String: [String]]?
    @Published var languageCode: String?
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    
    // AuthViewModel'e erişim
    @Published var authViewModel: AuthViewModel?
    
    private let userDefaults = UserDefaults.standard
    private let savedResultsKeyPrefix = "savedResults_"
    
    var lastUserPrompt: String? = nil
    var lastSelectedStyle: String? = nil
    
    // Kullanıcı kimliğine göre kayıt anahtarı oluştur
    private func getSavedResultsKey() -> String {
        if let authViewModel = authViewModel, let userId = authViewModel.user?.id {
            return "\(savedResultsKeyPrefix)\(userId)"
        }
        return savedResultsKeyPrefix
    }
    
    func saveResult(forPrompt prompt: String, style: String? = nil) {
        guard let generatedPrompt = generatedPrompt else { return }
        let key = getSavedResultsKey()
        var savedResults = userDefaults.dictionary(forKey: key) as? [String: [String: Any]] ?? [:]
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let result: [String: Any] = [
            "prompt": generatedPrompt,
            "categorizedElements": categorizedElements ?? [:],
            "languageCode": languageCode ?? "tr",
            "style": style ?? ""
        ]
        savedResults[trimmedPrompt] = result
        userDefaults.set(savedResults, forKey: key)
        print("[DEBUG] Sonuç kaydedildi: \(trimmedPrompt) - kullanıcı anahtarı: \(key)")
    }
    
    func loadResult(forPrompt prompt: String) {
        let key = getSavedResultsKey()
        guard let savedResults = userDefaults.dictionary(forKey: key) as? [String: [String: Any]] else {
            print("Kayıtlı sonuç yok - kullanıcı anahtarı: \(key)")
            return
        }
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        print("Kayıtlı anahtarlar:", savedResults.keys)
        guard let result = savedResults[trimmedPrompt] else {
            print("Prompt için sonuç bulunamadı:", trimmedPrompt)
            self.generatedPrompt = nil
            return
        }
        print("[DEBUG] Sonuç bulundu, ekran açılıyor: \(trimmedPrompt)")
        self.generatedPrompt = result["prompt"] as? String
        self.categorizedElements = result["categorizedElements"] as? [String: [String]]
        self.languageCode = result["languageCode"] as? String
    }
    
    func shareResult() {
        guard let prompt = generatedPrompt else { return }
        
        var shareText = "Generated Prompt: \(prompt)\n\n"
        
        if let elements = categorizedElements {
            shareText += "Categories:\n"
            for (category, items) in elements {
                shareText += "\(category): \(items.joined(separator: ", "))\n"
            }
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // UIViewController'ı almak için window scene'den root view controller'ı al
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    func loadSavedResults() -> [[String: Any]] {
        let key = getSavedResultsKey()
        guard let savedResults = userDefaults.dictionary(forKey: key) as? [String: [String: Any]] else {
            return []
        }
        
        return Array(savedResults.values)
    }
    
    func clearSavedResults() {
        let key = getSavedResultsKey()
        userDefaults.removeObject(forKey: key)
    }
    
    func cleanUpOldResults() {
        let key = getSavedResultsKey()
        guard let savedResults = userDefaults.dictionary(forKey: key) as? [String: [String: Any]] else { return }
        let validPrompts = savedResults.keys.filter { !$0.contains("-") } // UUID'ler tire içerir
        let onlyPromptResults = savedResults.filter { validPrompts.contains($0.key) }
        userDefaults.set(onlyPromptResults, forKey: key)
        print("[DEBUG] Eski UUID anahtarlı kayıtlar temizlendi.")
    }
    
    // Otomatik kaydetme fonksiyonu
    func autoSaveIfPossible() {
        if let _ = generatedPrompt, let userPrompt = lastUserPrompt {
            saveResult(forPrompt: userPrompt, style: lastSelectedStyle)
        }
    }
    
    // Oturum değiştiğinde kayıtlı promptları yeniden yükle
    func refreshResults() {
        // Şu anki açık olan prompt için yükleme işlemi yapar
        if let userPrompt = lastUserPrompt {
            loadResult(forPrompt: userPrompt)
        }
    }
} 