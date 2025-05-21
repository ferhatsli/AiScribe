import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showRegistration = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arkaplan gradyanı
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.primaryDark, AppColors.background]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Logo ve başlık
                    VStack(spacing: 12) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppColors.primaryLight, lineWidth: 2)
                            )
                            .shadow(color: AppColors.primaryDark.opacity(0.3), radius: 5)
                            .padding(.bottom, 8)
                        
                        Text("AiScribe")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(AppColors.text)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Giriş formu
                    VStack(spacing: 16) {
                        // Email alanı
                        AppTextField(placeholder: "E-posta", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        
                        // Şifre alanı
                        AppTextField(placeholder: "Şifre", text: $password, isSecure: true)
                    }
                    .padding(.horizontal, 24)
                    
                    // Hata mesajı
                    if let error = authViewModel.authError {
                        Text(error)
                            .foregroundColor(AppColors.error)
                            .font(.caption)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }
                    
                    // İşlemler
                    VStack(spacing: 16) {
                        // Giriş butonu
                        PrimaryButton(title: "Giriş Yap") {
                            authViewModel.login(email: email, password: password)
                        }
                        .disabled(authViewModel.isLoading)
                        .opacity(authViewModel.isLoading ? 0.7 : 1.0)
                        
                        // Kayıt olma bağlantısı
                        HStack {
                            Text("Hesabınız yok mu?")
                                .foregroundColor(AppColors.textSecondary)
                                .font(.subheadline)
                            
                            Button(action: {
                                showRegistration = true
                            }) {
                                Text("Kayıt olun")
                                    .foregroundColor(AppColors.primary)
                                    .fontWeight(.bold)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // Yükleme göstergesi
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryLight))
                            .scaleEffect(1.2)
                            .padding(.top, 24)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showRegistration) {
            RegisterView()
                .environmentObject(authViewModel)
        }
    }
} 