import SwiftUI

struct ImageGenerationView: View {
    @ObservedObject var imageViewModel: ImageViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let generatedPrompt: String
    let originalPrompt: String
    let style: String?
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAuthAlert = false
    @State private var promptSaved = false
    
    var body: some View {
        ZStack {
            // Arkaplan
            LinearGradient(
                gradient: Gradient(colors: [AppColors.primaryDark, AppColors.primary]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Ana içerik
            VStack(spacing: 20) {
                // Başlık
                Text("Görsel Oluşturma")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Prompt bilgisi
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Kullanılacak Prompt:")
                                    .font(.headline)
                                    .foregroundColor(AppColors.primaryLight)
                                
                                Spacer()
                                
                                // Prompt kaydetme butonu
                                Button(action: {
                                    savePrompt()
                                }) {
                                    HStack {
                                        Image(systemName: promptSaved ? "bookmark.fill" : "bookmark")
                                            .foregroundColor(promptSaved ? .yellow : AppColors.primaryLight)
                                        
                                        Text(promptSaved ? "Kaydedildi" : "Kaydet")
                                            .font(.caption)
                                            .foregroundColor(promptSaved ? .yellow : AppColors.primaryLight)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                                }
                            }
                            
                            Text(generatedPrompt)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding()
                                .background(AppColors.surface.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Görsel gösterimi veya durum
                        ZStack {
                            switch imageViewModel.imageState {
                            case .idle:
                                VStack {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(AppColors.primaryLight.opacity(0.5))
                                    
                                    Text("Görsel oluşturmak için aşağıdaki butona basın")
                                        .font(.caption)
                                        .foregroundColor(AppColors.primaryLight)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .background(AppColors.surface.opacity(0.3))
                                .cornerRadius(16)
                                
                            case .loading:
                                VStack {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryLight))
                                        .padding()
                                    
                                    Text("Görsel oluşturuluyor...")
                                        .font(.headline)
                                        .foregroundColor(AppColors.primaryLight)
                                        .padding()
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .background(AppColors.surface.opacity(0.3))
                                .cornerRadius(16)
                                
                            case .success(let url):
                                VStack {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .cornerRadius(12)
                                        } else if phase.error != nil {
                                            Text("Görsel yüklenemedi")
                                                .foregroundColor(.red)
                                        } else {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryLight))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    
                                    if let promptUsed = imageViewModel.currentPromptUsed {
                                        Text("Kullanılan prompt: \(promptUsed)")
                                            .font(.caption)
                                            .foregroundColor(AppColors.primaryLight)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                        
                                        Text("Görsel otomatik olarak kaydedildi.")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .padding(.top, 4)
                                    }
                                }
                                
                            case .error(let message):
                                VStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.red)
                                        .padding()
                                    
                                    Text("Hata: \(message)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .background(AppColors.surface.opacity(0.3))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Butonlar
                        VStack(spacing: 16) {
                            // Durum: Başlangıç -> Görsel oluştur butonu
                            if case .idle = imageViewModel.imageState {
                                PrimaryButton(title: "Görsel Oluştur") {
                                    imageViewModel.generateImage(prompt: generatedPrompt, style: style, userPrompt: originalPrompt)
                                }
                                .padding(.horizontal, 32)
                            }
                            
                            // Durum: Başarılı -> Paylaş butonu
                            if case .success = imageViewModel.imageState {
                                PrimaryButton(title: "Paylaş") {
                                    imageViewModel.shareCurrentImage()
                                }
                                .padding(.horizontal)
                                
                                PrimaryButton(title: "Yeni Görsel Oluştur") {
                                    imageViewModel.resetState()
                                }
                                .padding(.horizontal)
                            }
                            
                            // Durum: Hata -> Tekrar dene butonu
                            if case .error = imageViewModel.imageState {
                                PrimaryButton(title: "Tekrar Dene") {
                                    imageViewModel.generateImage(prompt: generatedPrompt, style: style, userPrompt: originalPrompt)
                                }
                                .padding(.horizontal, 32)
                            }
                            
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Kapat")
                                    .foregroundColor(AppColors.primaryLight)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.bottom)
                    }
                }
            }
            
            // Notification when image is saved
            if let notification = imageViewModel.savedNotification {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(notification)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(AppColors.primaryDark.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: imageViewModel.savedNotification)
            }
        }
        .onAppear {
            // Sayfa açıldığında durumu sıfırla ve kullanıcı bilgisini güncelle
            imageViewModel.resetState()
            imageViewModel.authViewModel = authViewModel
        }
        .alert(isPresented: $showingAuthAlert) {
            Alert(
                title: Text("Giriş Yapın"),
                message: Text("Prompt'u kaydetmek için lütfen giriş yapın veya kaydolun."),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
    
    // Prompt'u kaydetme fonksiyonu
    private func savePrompt() {
        if authViewModel.isAuthenticated {
            authViewModel.savePrompt(promptText: generatedPrompt)
            promptSaved = true
        } else {
            showingAuthAlert = true
        }
    }
}

struct ImageGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        ImageGenerationView(
            imageViewModel: ImageViewModel(),
            generatedPrompt: "Yüksek bir ağaç evde oturan sevimli küçük bir robot, etrafı güneş ışınlarıyla aydınlanmış çam ormanı",
            originalPrompt: "Ağaç evde duran robot",
            style: "Cartoon"
        )
    }
} 