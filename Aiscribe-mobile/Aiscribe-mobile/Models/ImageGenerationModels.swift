import Foundation

// MARK: - Request Models
struct ImageGenerationRequest: Codable {
    let prompt: String
    let style: String?
    let size: String
    
    init(prompt: String, style: String? = nil, size: String = "1024x1024") {
        self.prompt = prompt
        self.style = style
        self.size = size
    }
}

// MARK: - Response Models
struct ImageGenerationResponse: Codable {
    let status: String
    let imageUrl: String?
    let promptUsed: String?
    let errorMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case imageUrl = "image_url"
        case promptUsed = "prompt_used"
        case errorMessage = "error_message"
    }
}

// İstemcide görüntü durumlarını yönetmek için yardımcı enum
enum ImageGenerationState {
    case idle
    case loading
    case success(url: URL)
    case error(message: String)
}

// Kaydedilen görüntü verisi
struct SavedImage: Codable, Identifiable {
    let id: UUID
    let prompt: String
    let generatedPrompt: String
    let imageUrl: String
    let createdAt: Date
    
    init(id: UUID = UUID(), prompt: String, generatedPrompt: String, imageUrl: String, createdAt: Date = Date()) {
        self.id = id
        self.prompt = prompt
        self.generatedPrompt = generatedPrompt
        self.imageUrl = imageUrl
        self.createdAt = createdAt
    }
} 