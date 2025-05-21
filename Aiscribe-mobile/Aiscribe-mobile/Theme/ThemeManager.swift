import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool = false
    
    private init() {
        // Kullanıcının sistem teması tercihini al
        isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
    }
    
    // Tema değişikliği için fonksiyon
    func toggleTheme() {
        isDarkMode.toggle()
        // Burada tema değişikliği ile ilgili ek işlemler yapılabilir
    }
    
    // Renk getirme fonksiyonları
    func getBackgroundColor() -> Color {
        return isDarkMode ? Color(hex: "#121212") : AppColors.background
    }
    
    func getSurfaceColor() -> Color {
        return isDarkMode ? Color(hex: "#1E1E1E") : AppColors.surface
    }
    
    func getTextColor() -> Color {
        return isDarkMode ? Color(hex: "#FFFFFF") : AppColors.text
    }
    
    func getSecondaryTextColor() -> Color {
        return isDarkMode ? Color(hex: "#B0B0B0") : AppColors.textSecondary
    }
} 