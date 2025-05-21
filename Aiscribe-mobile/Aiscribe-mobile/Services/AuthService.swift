import Foundation
import Combine

class AuthService {
    private let baseURL = "http://127.0.0.1:8000/api/v1"
    private let session = URLSession.shared
    private let jsonDecoder: JSONDecoder
    
    // Singleton instance
    static let shared = AuthService()
    
    private init() {
        jsonDecoder = JSONDecoder()
        
        // Daha esnek tarih çözümlemesi için özel strateji
        jsonDecoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            
            do {
                // Önce ISO8601 formatını dene
                let dateStr = try container.decode(String.self)
                
                // ISO8601DateFormatter'ı dene
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = isoFormatter.date(from: dateStr) {
                    return date
                }
                
                // Daha basit ISO8601 formatını dene (fractional seconds olmadan)
                let simpleIsoFormatter = ISO8601DateFormatter()
                if let date = simpleIsoFormatter.date(from: dateStr) {
                    return date
                }
                
                // Alternatif formatları dene
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                if let date = formatter.date(from: dateStr) {
                    return date
                }
                
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                if let date = formatter.date(from: dateStr) {
                    return date
                }
                
                // Son çare: şu anki tarihi kullan
                print("⚠️ Tarih ayrıştırılamadı: \(dateStr)")
                return Date()
                
            } catch {
                // Tarih bir metin değilse, sayı olarak dene (timestamp)
                do {
                    let timestamp = try container.decode(Double.self)
                    return Date(timeIntervalSince1970: timestamp)
                } catch {
                    // Son çare: şu anki tarihi kullan
                    return Date()
                }
            }
        }
    }
    
    // MARK: - Authentication methods
    
    /// Kullanıcı kaydı yapar
    /// - Parameter registration: Kayıt bilgileri
    /// - Returns: TokenResponse publisher
    func register(with registration: UserRegistration) -> AnyPublisher<TokenResponse, Error> {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(registration)
            request.httpBody = jsonData
            print("[DEBUG] Kayıt isteği: \(String(data: jsonData, encoding: .utf8) ?? "<veri okunamadı>")")
        } catch {
            print("[ERROR] Kayıt verisi kodlanamadı: \(error.localizedDescription)")
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[ERROR] HTTP yanıtı alınamadı")
                    throw URLError(.badServerResponse)
                }
                
                print("[DEBUG] HTTP durum kodu: \(httpResponse.statusCode)")
                
                // Yanıtı konsola yazdır (Debug için)
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[DEBUG] Sunucu yanıtı: \(responseString)")
                }
                
                if httpResponse.statusCode == 400 {
                    let errorResponse = try? JSONDecoder().decode(APIError.self, from: data)
                    print("[ERROR] 400 hatası: \(errorResponse?.detail ?? "Detay yok")")
                    throw NSError(domain: "Auth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse?.detail ?? "Kayıt başarısız oldu."])
                }
                
                if httpResponse.statusCode != 201 {
                    print("[ERROR] Beklenmeyen durum kodu: \(httpResponse.statusCode)")
                    throw URLError(.badServerResponse)
                }
                
                return data
            }
            .decode(type: TokenResponse.self, decoder: jsonDecoder)
            .mapError { error in
                if let decodingError = error as? DecodingError {
                    print("[ERROR] Decode hatası: \(decodingError)")
                    
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("[ERROR] Tip uyuşmazlığı: \(type) - \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("[ERROR] Değer bulunamadı: \(type) - \(context.codingPath)")
                    case .keyNotFound(let key, let context):
                        print("[ERROR] Anahtar bulunamadı: \(key.stringValue) - \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("[ERROR] Veri bozuk: \(context)")
                    @unknown default:
                        print("[ERROR] Bilinmeyen decode hatası")
                    }
                    
                    return NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Sunucu yanıtı işlenemedi: \(decodingError.localizedDescription)"])
                }
                return error
            }
            .eraseToAnyPublisher()
    }
    
    /// Kullanıcı girişi yapar
    /// - Parameter login: Giriş bilgileri
    /// - Returns: TokenResponse publisher
    func login(with login: UserLogin) -> AnyPublisher<TokenResponse, Error> {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(login)
            request.httpBody = jsonData
            print("[DEBUG] Giriş isteği: \(String(data: jsonData, encoding: .utf8) ?? "<veri okunamadı>")")
        } catch {
            print("[ERROR] Giriş verisi kodlanamadı: \(error.localizedDescription)")
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                print("[DEBUG] HTTP durum kodu: \(httpResponse.statusCode)")
                
                // Yanıtı konsola yazdır (Debug için)
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[DEBUG] Sunucu yanıtı: \(responseString)")
                }
                
                if httpResponse.statusCode == 401 {
                    let errorResponse = try? JSONDecoder().decode(APIError.self, from: data)
                    throw NSError(domain: "Auth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse?.detail ?? "Geçersiz email veya şifre."])
                }
                
                if httpResponse.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                
                return data
            }
            .decode(type: TokenResponse.self, decoder: jsonDecoder)
            .mapError { error in
                if let decodingError = error as? DecodingError {
                    print("[ERROR] Decode hatası: \(decodingError)")
                    return NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Giriş yanıtı işlenemedi: \(decodingError.localizedDescription)"])
                }
                return error
            }
            .eraseToAnyPublisher()
    }
    
    /// Kullanıcı çıkışı yapar
    /// - Parameter token: Kullanıcı token'ı
    /// - Returns: Empty publisher
    func logout(token: String) -> AnyPublisher<Void, Error> {
        let url = URL(string: "\(baseURL)/auth/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Void in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if httpResponse.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                
                return ()
            }
            .eraseToAnyPublisher()
    }
    
    /// Kullanıcı profilini getirir
    /// - Parameter token: Kullanıcı token'ı
    /// - Returns: User publisher
    func getUserProfile(token: String) -> AnyPublisher<UserProfile, Error> {
        let url = URL(string: "\(baseURL)/protected/user-data")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if httpResponse.statusCode == 401 {
                    throw NSError(domain: "Auth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Kimlik doğrulama gerekli."])
                }
                
                if httpResponse.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                
                return data
            }
            .decode(type: UserProfile.self, decoder: jsonDecoder)
            .eraseToAnyPublisher()
    }
    
    /// Kullanıcının kaydettiği promptları getirir
    /// - Parameter token: Kullanıcı token'ı
    /// - Returns: UserPromptCollection publisher
    func getSavedPrompts(token: String) -> AnyPublisher<UserPromptCollection, Error> {
        let url = URL(string: "\(baseURL)/protected/my-prompts")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if httpResponse.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                
                return data
            }
            .decode(type: UserPromptCollection.self, decoder: jsonDecoder)
            .eraseToAnyPublisher()
    }
    
    // Prompt kaydı için yanıt modeli
    private struct SavePromptResponse: Codable {
        let status: String
        let message: String
        let id: String
        let prompt: String
    }
    
    /// Prompt'u kaydeder
    /// - Parameters:
    ///   - promptText: Kaydedilecek prompt metni
    ///   - token: Kullanıcı token'ı
    /// - Returns: SavedPrompt publisher
    func savePrompt(promptText: String, token: String) -> AnyPublisher<SavedPrompt, Error> {
        let url = URL(string: "\(baseURL)/protected/save-prompt")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let promptData = ["prompt": promptText]
        
        do {
            let jsonData = try JSONEncoder().encode(promptData)
            request.httpBody = jsonData
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if httpResponse.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                
                return data
            }
            .decode(type: SavePromptResponse.self, decoder: jsonDecoder)
            .map { response in
                SavedPrompt(
                    id: response.id,
                    text: response.prompt,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
            }
            .eraseToAnyPublisher()
    }
} 