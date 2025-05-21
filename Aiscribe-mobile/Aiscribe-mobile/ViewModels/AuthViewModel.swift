import Foundation
import Combine
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated: Bool = false
    @Published var authError: String?
    @Published var isLoading: Bool = false
    @Published var savedPrompts: [SavedPrompt] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService.shared
    
    private let keychainTokenKey = "aiscribe_auth_token"
    
    init() {
        // Uygulama başladığında token kontrolü yap
        if let token = retrieveToken() {
            validateToken(token)
        }
    }
    
    // MARK: - Authentication methods
    
    /// Kullanıcı kaydı yapar
    /// - Parameters:
    ///   - email: Kullanıcı e-posta adresi
    ///   - password: Şifre
    ///   - name: İsim (opsiyonel)
    func register(email: String, password: String, name: String?) {
        guard !isLoading else { return }
        isLoading = true
        authError = nil
        
        let registration = UserRegistration(email: email, password: password, name: name)
        
        authService.register(with: registration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.authError = error.localizedDescription
                }
            } receiveValue: { [weak self] tokenResponse in
                self?.user = tokenResponse.user
                self?.isAuthenticated = true
                self?.saveToken(tokenResponse.accessToken)
                // Kullanıcı kaydolduğunda bildirim gönder
                self?.postAuthStateChangedNotification()
            }
            .store(in: &cancellables)
    }
    
    /// Kullanıcı girişi yapar
    /// - Parameters:
    ///   - email: Kullanıcı e-posta adresi
    ///   - password: Şifre
    func login(email: String, password: String) {
        guard !isLoading else { return }
        isLoading = true
        authError = nil
        
        let login = UserLogin(email: email, password: password)
        
        authService.login(with: login)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.authError = error.localizedDescription
                }
            } receiveValue: { [weak self] tokenResponse in
                self?.user = tokenResponse.user
                self?.isAuthenticated = true
                self?.saveToken(tokenResponse.accessToken)
                // Kullanıcı giriş yaptığında bildirim gönder
                self?.postAuthStateChangedNotification()
            }
            .store(in: &cancellables)
    }
    
    /// Kullanıcı çıkışı yapar
    func logout() {
        guard let token = retrieveToken() else {
            // Token yoksa doğrudan çıkış yap
            clearAuthState()
            return
        }
        
        guard !isLoading else { return }
        isLoading = true
        
        authService.logout(token: token)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] completion in
                self.isLoading = false
                // Hata olsa bile çıkış yapalım
                self.clearAuthState()
            } receiveValue: { _ in
                // Zaten completion'da çıkış yapılıyor
            }
            .store(in: &cancellables)
    }
    
    /// Kullanıcı profil bilgilerini getirir
    func fetchUserProfile() {
        guard let token = retrieveToken(), !isLoading else { return }
        isLoading = true
        
        authService.getUserProfile(token: token)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.authError = error.localizedDescription
                    // Token geçersiz olabilir, çıkış yap
                    if let error = error as NSError?, error.code == 401 {
                        self?.clearAuthState()
                    }
                }
            } receiveValue: { [weak self] profile in
                // Profil bilgileri alındı
                print("Profil bilgileri alındı: \(profile.email)")
            }
            .store(in: &cancellables)
    }
    
    /// Kullanıcının kaydettiği promptları getirir
    func fetchSavedPrompts() {
        guard let token = retrieveToken(), !isLoading else { return }
        isLoading = true
        
        authService.getSavedPrompts(token: token)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.authError = error.localizedDescription
                    // Token geçersiz olabilir, çıkış yap
                    if let error = error as NSError?, error.code == 401 {
                        self?.clearAuthState()
                    }
                }
            } receiveValue: { [weak self] promptCollection in
                self?.savedPrompts = promptCollection.prompts
            }
            .store(in: &cancellables)
    }
    
    /// Prompt'u kaydeder
    /// - Parameter promptText: Kaydedilecek prompt metni
    func savePrompt(promptText: String) {
        guard let token = retrieveToken(), !isLoading else { return }
        isLoading = true
        
        authService.savePrompt(promptText: promptText, token: token)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.authError = error.localizedDescription
                    // Token geçersiz olabilir, çıkış yap
                    if let error = error as NSError?, error.code == 401 {
                        self?.clearAuthState()
                    }
                }
            } receiveValue: { [weak self] savedPrompt in
                // Yeni prompt'u listeye ekle
                self?.savedPrompts.insert(savedPrompt, at: 0)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helper methods
    
    /// Token'ı Keychain'e kaydeder
    /// - Parameter token: Kaydedilecek token
    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: keychainTokenKey)
    }
    
    /// Token'ı Keychain'den getirir
    /// - Returns: Token
    private func retrieveToken() -> String? {
        return UserDefaults.standard.string(forKey: keychainTokenKey)
    }
    
    /// Token'ı Keychain'den siler
    private func removeToken() {
        UserDefaults.standard.removeObject(forKey: keychainTokenKey)
    }
    
    /// Kimlik doğrulama durumunu temizler
    private func clearAuthState() {
        user = nil
        isAuthenticated = false
        removeToken()
        savedPrompts = []
        
        // Oturum kapatıldığında bildirim gönder
        postAuthStateChangedNotification()
    }
    
    /// Kullanıcı oturum durumu değiştiğinde bildirim gönder
    private func postAuthStateChangedNotification() {
        NotificationCenter.default.post(name: NSNotification.Name("AuthStateChanged"), object: nil)
    }
    
    /// Kullanıcı oturumunu yeniler (uygulama arka plandan öne geldiğinde çağrılır)
    func refreshUserSession() {
        if let token = retrieveToken() {
            // Mevcut isAuthenticated değerini geçici olarak saklayalım
            let wasAuthenticated = isAuthenticated
            
            // Token'ı kontrol et
            validateToken(token)
            
            // Oturum durumu değişmediyse bile bildirimi zorla gönder
            if wasAuthenticated == isAuthenticated && isAuthenticated {
                // Kullanıcı zaten giriş yapmış ve durum değişmemiş, 
                // ancak bileşenlerin yenilenmesi için bildirimi manuel gönderelim
                postAuthStateChangedNotification()
            }
        }
    }
    
    /// Token'ın geçerliliğini kontrol eder
    /// - Parameter token: Kontrol edilecek token
    private func validateToken(_ token: String) {
        authService.getUserProfile(token: token)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.clearAuthState()
                }
            } receiveValue: { [weak self] profile in
                self?.isAuthenticated = true
                // Kullanıcı bilgilerini profile ile oluştur
                let userJSON: [String: Any] = [
                    "id": profile.id,
                    "email": profile.email,
                    "name": profile.name as Any,
                    "created_at": ISO8601DateFormatter().string(from: Date())
                ]
                
                // JSON'ı Data'ya dönüştür
                if let userData = try? JSONSerialization.data(withJSONObject: userJSON) {
                    // Data'yı User'a dönüştür
                    if let user = try? JSONDecoder().decode(User.self, from: userData) {
                        self?.user = user
                        // Kullanıcı bilgileri yüklendiğinde bildirim gönder
                        self?.postAuthStateChangedNotification()
                    }
                }
            }
            .store(in: &cancellables)
    }
} 