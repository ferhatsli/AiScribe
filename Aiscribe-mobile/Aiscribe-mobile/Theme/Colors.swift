import SwiftUI

struct AppColors {
    // Ana Renkler
    static let primary = Color(hex: "#8C56A2")
    static let primaryLight = Color(hex: "#BCA4E5")
    static let primaryDark = Color(hex: "#2D0B4E")
    
    // Koyu Mod Yüzeyler
    static let background = Color(hex: "#1A1027")
    static let surface = Color(hex: "#24123A")
    
    // Metin Renkleri
    static let text = Color.white
    static let textSecondary = Color(hex: "#BCA4E5")
    
    // Durum Renkleri
    static let success = Color(hex: "#4CAF50")
    static let error = Color(hex: "#F44336")
    static let warning = Color(hex: "#FFC107")
    static let info = Color(hex: "#2196F3")
    
    // Gölge ve Kenar Renkleri
    static let shadow = Color.black.opacity(0.2)
    static let border = Color(hex: "#3A2A4D")
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 