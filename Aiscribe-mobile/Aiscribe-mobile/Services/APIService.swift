import Foundation

enum ServiceAPIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(message: String, statusCode: Int)
}

class APIService {
    // TODO: Bu URL'i konfigüre edilebilir yap (örneğin bir plist'ten veya build setting'den)
    // Geliştirme sırasında backend localhost:8000'de çalışıyorsa ve simülatör kullanıyorsan bu URL doğru.
    // Fiziksel cihazda test ederken bilgisayarının yerel ağ IP adresini kullanmalısın.
    private let baseURL = URL(string: "http://127.0.0.1:8000/api/v1")!
    
    // UserDefaults'tan token'ı al
    private func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "aiscribe_auth_token")
    }

    func generatePrompt(requestData: PromptRequest, completion: @escaping (Result<PromptResponse, ServiceAPIError>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("prompt/generate")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Token ekle
        if let token = getAuthToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("[DEBUG] Token eklendi: Bearer \(token.prefix(10))...")
        } else {
            print("[WARN] Kullanıcı tokenı bulunamadı!")
        }

        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .useDefaultKeys
            let jsonData = try encoder.encode(requestData)
            urlRequest.httpBody = jsonData
            // Stil ve giden JSON'u yazdır
            print("[DEBUG] Seçilen stil: \(requestData.style ?? "-none-")")
            print("[DEBUG] Giden JSON: \(String(data: jsonData, encoding: .utf8) ?? "<no data>")")
        } catch {
            completion(.failure(ServiceAPIError.decodingError(error))) // Aslında encoding error ama decodingError altında topladım şimdilik
            return
        }

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(ServiceAPIError.requestFailed(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(ServiceAPIError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(ServiceAPIError.invalidResponse)) // No data
                return
            }
            
            // Debug: Gelen ham veriyi yazdırmak istersen
            print("[DEBUG] HTTP durum kodu: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Sunucu yanıtı: \(responseString)")
            }

            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let decoder = JSONDecoder()
                    // Pydantic'ten gelen snake_case anahtarları Swift'teki camelCase'e çevirmek için
                    // Eğer PromptResponse ve alt modellerindeki CodingKeys'i doğru ayarladıysak bu satıra gerek kalmaz.
                    // Ancak bazen Pydantic'in default JSON output'u ile Swift'in default beklentisi arasında
                    // uyumsuzluklar olabiliyor, o yüzden bu bir seçenek. Şimdilik CodingKeys'e güveniyoruz.
                    // decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    let decodedResponse = try decoder.decode(PromptResponse.self, from: data)
                    completion(.success(decodedResponse))
                } catch {
                    // Debug: Decode hatasında gelen veriyi ve hatayı yazdırmak faydalı olabilir
                    print("Decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Failed to decode JSON: \(jsonString)")
                    }
                    completion(.failure(ServiceAPIError.decodingError(error)))
                }
            } else {
                // Sunucudan gelen hata mesajını parse etmeye çalışabiliriz
                // Örneğin, FastAPI'nin default HTTPValidationErrors gibi
                // Şimdilik genel bir serverError dönüyoruz.
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown server error"
                print("Server Error (\(httpResponse.statusCode)): \(errorMessage)")
                completion(.failure(ServiceAPIError.serverError(message: errorMessage, statusCode: httpResponse.statusCode)))
            }
        }.resume()
    }
    
    func generateImage(requestData: ImageGenerationRequest, completion: @escaping (Result<ImageGenerationResponse, ServiceAPIError>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("image/generate")
        
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Token ekle
        if let token = getAuthToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("[DEBUG] Token eklendi: Bearer \(token.prefix(10))...")
        } else {
            print("[WARN] Kullanıcı tokenı bulunamadı!")
        }
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(requestData)
            urlRequest.httpBody = jsonData
            print("[DEBUG] Resim isteği gönderiliyor: \(String(data: jsonData, encoding: .utf8) ?? "<no data>")")
        } catch {
            completion(.failure(ServiceAPIError.decodingError(error)))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(ServiceAPIError.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(ServiceAPIError.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(ServiceAPIError.invalidResponse)) // No data
                return
            }
            
            // Debug: Gelen ham veriyi yazdırmak istersen
            print("[DEBUG] HTTP durum kodu: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Sunucu yanıtı: \(responseString)")
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let decoder = JSONDecoder()
                    let decodedResponse = try decoder.decode(ImageGenerationResponse.self, from: data)
                    completion(.success(decodedResponse))
                } catch {
                    print("Resim yanıtını decode etme hatası: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Decode edilemeyen JSON: \(jsonString)")
                    }
                    completion(.failure(ServiceAPIError.decodingError(error)))
                }
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown server error"
                print("Resim sunucu hatası (\(httpResponse.statusCode)): \(errorMessage)")
                completion(.failure(ServiceAPIError.serverError(message: errorMessage, statusCode: httpResponse.statusCode)))
            }
        }.resume()
    }
} 