import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    
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
                
                // İçerik - merkezde
                GeometryReader { geometry in
                    ScrollView {
                        VStack {
                            VStack(spacing: 24) {
                                // Başlık
                                VStack(spacing: 12) {
                                    Image("AppLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(AppColors.primaryLight, lineWidth: 2)
                                        )
                                        .shadow(color: AppColors.primaryDark.opacity(0.3), radius: 5)
                                        .padding(.bottom, 8)
                                    
                                    Text("Yeni Hesap Oluştur")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(AppColors.text)
                                }
                                .padding(.top, 20)
                                .padding(.bottom, 24)
                                
                                // Kayıt formu
                                VStack(spacing: 16) {
                                    // İsim alanı
                                    AppTextField(placeholder: "İsim (Opsiyonel)", text: $name)
                                    
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
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                        .padding(.top, 8)
                                }
                                
                                // Kayıt ol butonu
                                PrimaryButton(title: "Kayıt Ol") {
                                    authViewModel.register(
                                        email: email,
                                        password: password,
                                        name: name.isEmpty ? nil : name
                                    )
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                                .disabled(authViewModel.isLoading)
                                .opacity(authViewModel.isLoading ? 0.7 : 1.0)
                                
                                // Yükleme göstergesi
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryLight))
                                        .scaleEffect(1.2)
                                        .padding(.top, 16)
                                }
                            }
                            .frame(minHeight: geometry.size.height)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppColors.primaryLight)
                    Text("Geri")
                        .foregroundColor(AppColors.primaryLight)
                }
            })
        }
        // Giriş işlemi başarılı olduğunda ekranı kapat
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
} 