import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        if let user = authViewModel.user {
                            // Kullanıcı profil bilgileri
                            VStack(spacing: 16) {
                                // Avatar
                                ZStack {
                                    Circle()
                                        .fill(AppColors.surface)
                                        .frame(width: 100, height: 100)
                                        .shadow(color: AppColors.shadow, radius: 5)
                                    
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 70, height: 70)
                                        .foregroundColor(AppColors.primaryLight)
                                }
                                .padding(.top, 24)
                                
                                // Kullanıcı bilgileri
                                VStack(spacing: 8) {
                                    Text(user.name ?? "İsimsiz Kullanıcı")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.text)
                                    
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            .padding(.bottom, 16)
                            
                            Divider()
                                .background(AppColors.border)
                                .padding(.horizontal)
                            
                            // Kaydedilen promptlar bölümü
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Kaydedilen Promptlar")
                                        .font(.headline)
                                        .foregroundColor(AppColors.text)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        authViewModel.fetchSavedPrompts()
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundColor(AppColors.primaryLight)
                                    }
                                }
                                .padding(.horizontal)
                                
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryLight))
                                        .frame(maxWidth: .infinity, minHeight: 100)
                                        .padding()
                                } else if authViewModel.savedPrompts.isEmpty {
                                    VStack(spacing: 16) {
                                        Text("Henüz kaydedilmiş prompt yok")
                                            .foregroundColor(AppColors.textSecondary)
                                            .padding()
                                        
                                        Button(action: {
                                            // Ana ekrana gitme aksiyonu (TabView seçimi)
                                        }) {
                                            Text("Prompt Oluştur")
                                                .foregroundColor(AppColors.text)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 10)
                                                .background(AppColors.surface)
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(AppColors.primaryLight, lineWidth: 1)
                                                )
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                } else {
                                    // Kaydedilmiş promptlar listesi
                                    VStack(spacing: 10) {
                                        ForEach(authViewModel.savedPrompts) { prompt in
                                            SavedPromptCard(prompt: prompt)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 8)
                            
                            Spacer(minLength: 32)
                            
                            // Çıkış butonu
                            PrimaryButton(title: "Çıkış Yap") {
                                authViewModel.logout()
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                        }
                    }
                }
                .navigationTitle("Profil")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Profil")
                            .font(.headline)
                            .foregroundColor(AppColors.text)
                    }
                }
                .onAppear {
                    authViewModel.fetchSavedPrompts()
                }
            }
        }
    }
}

// Kaydedilmiş prompt kartı
struct SavedPromptCard: View {
    let prompt: SavedPrompt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(prompt.text)
                .font(.callout)
                .lineLimit(2)
                .foregroundColor(AppColors.text)
            
            HStack {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundColor(AppColors.primaryLight)
                
                Text(prompt.createdAt)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Button(action: {
                    // Prompt kopyalama aksiyonu
                    UIPasteboard.general.string = prompt.text
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(AppColors.primaryLight)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
} 