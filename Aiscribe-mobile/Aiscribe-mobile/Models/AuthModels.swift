import Foundation

// MARK: - User models

/// Kullanıcı kaydı için model
struct UserRegistration: Codable {
    let email: String
    let password: String
    let name: String?
}

/// Kullanıcı girişi için model
struct UserLogin: Codable {
    let email: String
    let password: String
}

/// Kullanıcı bilgilerini temsil eden model
struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let name: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case createdAt = "created_at"
    }
    
    // Özel bir init ekleyerek farklı tarih formatlarıyla başa çıkmak
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        
        // Tarih alanını çeşitli formatlarda çözmeyi dene
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            if let date = ISO8601DateFormatter().date(from: dateString) {
                createdAt = date
            } else {
                // Alternatif tarih formatlarını dene (örneğin: yyyy-MM-dd'T'HH:mm:ss)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                if let date = formatter.date(from: dateString) {
                    createdAt = date
                } else {
                    // Son çare: şu anki tarihi kullan
                    print("⚠️ Tarih formatı çözülemedi: \(dateString)")
                    createdAt = Date()
                }
            }
        } else {
            // Tarih alanı yoksa şu anki tarihi kullan
            createdAt = Date()
        }
    }
}

/// API'den dönen token yanıtı
struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
    }
}

/// Kullanıcı profil bilgilerini temsil eden model
struct UserProfile: Codable {
    let id: String
    let email: String
    let name: String?
    let isAuthenticated: Bool
    let preferences: UserPreferences?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case isAuthenticated = "is_authenticated"
        case preferences
    }
}

/// Kullanıcı tercihlerini temsil eden model
struct UserPreferences: Codable {
    let language: String
    let theme: String
}

/// Hata durumunu temsil eden model
struct APIError: Codable {
    let detail: String
}

/// Kullanıcının prompt koleksiyonunu temsil eden model
struct UserPromptCollection: Codable {
    let prompts: [SavedPrompt]
    let total: Int
}

/// Kaydedilmiş prompt modelini temsil eden model
struct SavedPrompt: Codable, Identifiable {
    let id: String
    let text: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case createdAt = "created_at"
    }
}

/// Kullanıcı durumu
enum AuthState {
    case signedIn
    case signedOut
} 