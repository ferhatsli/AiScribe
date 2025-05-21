import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            saveSettings()
        }
    }
    
    @Published var autoExpandPrompts: Bool {
        didSet {
            saveSettings()
        }
    }
    
    @Published var defaultLanguage: String {
        didSet {
            saveSettings()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let darkModeKey = "isDarkMode"
    private let autoExpandKey = "autoExpandPrompts"
    private let languageKey = "defaultLanguage"
    
    init() {
        // Varsayılan değerleri yükle
        self.isDarkMode = userDefaults.bool(forKey: darkModeKey)
        self.autoExpandPrompts = userDefaults.bool(forKey: autoExpandKey)
        self.defaultLanguage = userDefaults.string(forKey: languageKey) ?? "tr"
    }
    
    func saveSettings() {
        userDefaults.set(isDarkMode, forKey: darkModeKey)
        userDefaults.set(autoExpandPrompts, forKey: autoExpandKey)
        userDefaults.set(defaultLanguage, forKey: languageKey)
    }
    
    func resetToDefaults() {
        isDarkMode = true
        autoExpandPrompts = true
        defaultLanguage = "tr"
        saveSettings()
    }
} 