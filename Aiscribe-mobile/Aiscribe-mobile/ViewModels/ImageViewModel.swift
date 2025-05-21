import Foundation
import Combine
import UIKit
import SwiftUI

class ImageViewModel: ObservableObject {
    // APIService'e erişim
    private let apiService = APIService()
    // Kimlik doğrulama servisi referansı
    @Published var authViewModel: AuthViewModel?
    
    // UI'ın dinleyeceği @Published değişkenler
    @Published var imageState: ImageGenerationState = .idle
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var generatedImageURL: URL? = nil
    @Published var currentPromptUsed: String? = nil
    @Published var savedNotification: String? = nil
    
    // Kaydedilen görsellerin yerel depolanması için
    private let userDefaults = UserDefaults.standard
    private let savedImagesKeyPrefix = "savedImages_"
    
    @Published var savedImages: [SavedImage] = []
    
    // Current request tracking
    private var currentUserPrompt: String? = nil
    
    init() {
        // Observer ekleyerek auth durumundaki değişiklikleri izle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthChange),
            name: NSNotification.Name("AuthStateChanged"),
            object: nil
        )
    }
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        loadSavedImages()
        
        // Observer ekleyerek auth durumundaki değişiklikleri izle
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
        loadSavedImages()
    }
    
    // Kullanıcı kimliğine dayalı kayıt anahtarını oluştur
    private func getSavedImagesKey() -> String {
        if let authViewModel = authViewModel, let userId = authViewModel.user?.id {
            return "\(savedImagesKeyPrefix)\(userId)"
        }
        return savedImagesKeyPrefix
    }
    
    // Oluşturulmuş prompttan görsel oluşturma işlemini başlatır
    func generateImage(prompt: String, style: String? = nil, size: String = "1024x1024", userPrompt: String? = nil) {
        errorMessage = nil
        isLoading = true
        imageState = .loading
        
        // Store the original user prompt for later use when saving
        self.currentUserPrompt = userPrompt ?? prompt
        
        let request = ImageGenerationRequest(prompt: prompt, style: style, size: size)
        
        apiService.generateImage(requestData: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.handleImageResponse(response)
                case .failure(let error):
                    self?.handleAPIError(error)
                }
            }
        }
    }
    
    // API yanıtını işler
    private func handleImageResponse(_ response: ImageGenerationResponse) {
        if response.status == "success", let imageUrlString = response.imageUrl, let url = URL(string: imageUrlString) {
            self.generatedImageURL = url
            self.currentPromptUsed = response.promptUsed
            self.imageState = .success(url: url)
            
            // Automatically save the image when successfully generated
            if let generatedPrompt = response.promptUsed, let userPrompt = self.currentUserPrompt {
                self.saveImage(userPrompt: userPrompt, generatedPrompt: generatedPrompt)
            }
        } else if let errorMessage = response.errorMessage {
            self.errorMessage = errorMessage
            self.imageState = .error(message: errorMessage)
        } else {
            self.errorMessage = "Beklenmeyen bir hata oluştu"
            self.imageState = .error(message: "Beklenmeyen bir hata oluştu")
        }
    }
    
    // API hata durumlarını işler
    private func handleAPIError(_ error: ServiceAPIError) {
        switch error {
        case .invalidURL:
            self.errorMessage = "Geçersiz API URL'i."
            self.imageState = .error(message: "Geçersiz API URL'i.")
        case .requestFailed(let err):
            self.errorMessage = "İstek başarısız: \(err.localizedDescription)"
            self.imageState = .error(message: "İstek başarısız: \(err.localizedDescription)")
        case .invalidResponse:
            self.errorMessage = "Sunucudan geçersiz yanıt."
            self.imageState = .error(message: "Sunucudan geçersiz yanıt.")
        case .decodingError(let err):
            self.errorMessage = "Sunucu yanıtını işleme hatası: \(err.localizedDescription)"
            self.imageState = .error(message: "Sunucu yanıtını işleme hatası: \(err.localizedDescription)")
        case .serverError(let message, let statusCode):
            self.errorMessage = "Sunucu hatası (\(statusCode)): \(message)"
            self.imageState = .error(message: "Sunucu hatası (\(statusCode)): \(message)")
        }
    }
    
    // Görüntüyü kaydeder
    func saveImage(userPrompt: String, generatedPrompt: String) {
        guard let imageUrl = generatedImageURL?.absoluteString else { return }
        
        let newImage = SavedImage(
            prompt: userPrompt,
            generatedPrompt: generatedPrompt,
            imageUrl: imageUrl
        )
        
        savedImages.append(newImage)
        saveToDisk()
        
        // Show saved notification
        savedNotification = "Görsel kaydedildi"
        
        // Hide notification after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.savedNotification = nil
        }
    }
    
    // Kaydedilen görüntüleri diske kaydeder
    private func saveToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(savedImages)
            userDefaults.set(data, forKey: getSavedImagesKey())
        } catch {
            print("Resimleri kaydetme hatası: \(error.localizedDescription)")
        }
    }
    
    // Kaydedilen görüntüleri diskten yükler
    private func loadSavedImages() {
        // Önce array'i temizle
        savedImages = []
        
        let key = getSavedImagesKey()
        guard let data = userDefaults.data(forKey: key) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self.savedImages = try decoder.decode([SavedImage].self, from: data)
        } catch {
            print("Kaydedilen resimleri yükleme hatası: \(error.localizedDescription)")
        }
    }
    
    // Kaydedilen bir görüntüyü siler
    func deleteImage(at indexSet: IndexSet) {
        savedImages.remove(atOffsets: indexSet)
        saveToDisk()
    }
    
    // Mevcut görüntüyü paylaşır
    func shareCurrentImage() {
        guard let imageUrl = generatedImageURL else { return }
        
        // URL'den resmi yükleme
        URLSession.shared.dataTask(with: imageUrl) { [weak self] data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Görüntü paylaşılamadı: \(error?.localizedDescription ?? "Bilinmeyen hata")"
                }
                return
            }
            
            DispatchQueue.main.async {
                let text = "AiScribe ile oluşturulmuş görüntü"
                let itemsToShare: [Any] = [text, image]
                let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(activityVC, animated: true)
                }
            }
        }.resume()
    }
    
    // Durum sıfırlama
    func resetState() {
        imageState = .idle
        errorMessage = nil
        generatedImageURL = nil
        currentPromptUsed = nil
        currentUserPrompt = nil
        savedNotification = nil
    }
    
    // Kullanıcı değiştiğinde veya çıkış yapıldığında görüntüleri tekrar yükle
    func refreshImages() {
        loadSavedImages()
    }
} 