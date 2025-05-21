import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var resultViewModel = ResultViewModel()
    @StateObject private var promptViewModel: PromptViewModel
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var imageViewModel = ImageViewModel()
    
    // Görüntü oluşturma ekranı durumu
    @State private var isImageGenerationViewPresented = false
    @State private var isMyImagesViewPresented = false
    @State private var isDetailViewPresented = false
    @State private var selectedImage: SavedImage? = nil
    
    // Akış durumları
    enum FlowState {
        case idle
        case loadingPrompt
        case questionFlow
        case loadingResult
        case result
    }
    
    // Kategori için simge seç
    private func getIconForCategory(category: String) -> String {
        switch category.lowercased() {
        case "actions":
            return "figure.run"
        case "characters":
            return "person.fill"
        case "places":
            return "map.fill"
        case "time":
            return "clock.fill"
        case "style":
            return "paintbrush.fill"
        case "objects":
            return "cube.fill"
        case "emotions":
            return "heart.fill"
        case "colors":
            return "paintpalette.fill"
        default:
            return "tag.fill"
        }
    }
    
    // Kategori için renk seç
    private func getColorForCategory(category: String) -> Color {
        switch category.lowercased() {
        case "actions":
            return Color.blue.opacity(0.7)
        case "characters":
            return Color.purple.opacity(0.7)
        case "places":
            return Color.green.opacity(0.7)
        case "time":
            return Color.orange.opacity(0.7)
        case "style":
            return Color.indigo.opacity(0.7)
        case "objects":
            return Color.pink.opacity(0.7)
        case "emotions":
            return Color.red.opacity(0.7)
        case "colors":
            return Color.teal.opacity(0.7)
        default:
            return AppColors.primary.opacity(0.7)
        }
    }
    
    init() {
        let resultVM = ResultViewModel()
        let promptVM = PromptViewModel(resultViewModel: resultVM)
        let dashboardVM = DashboardViewModel(promptViewModel: promptVM)
        
        _resultViewModel = StateObject(wrappedValue: resultVM)
        _promptViewModel = StateObject(wrappedValue: promptVM)
        _dashboardViewModel = StateObject(wrappedValue: dashboardVM)
    }
    
    var body: some View {
        ZStack {
            // Ana ekran
            if promptViewModel.questions == nil && resultViewModel.generatedPrompt == nil {
                VStack(spacing: 0) {
                    // HEADER
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image("AppLogo")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.primaryLight, lineWidth: 1)
                                )
                                .shadow(color: AppColors.primaryDark.opacity(0.3), radius: 2)
                            Text("AiScribe")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.primaryLight)
                        }
                        .padding(.leading, 20)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    // --- Kanca Cümle ---
                    HStack(spacing: 0) {
                        Text("Hayal gücünü ")
                            .foregroundColor(.white)
                            .font(.title3)
                            .fontWeight(.regular)
                        Text("özgür bırak!")
                            .foregroundColor(AppColors.primary)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .padding(.bottom, 24)
                    
                    // --- Prompt Giriş Alanı ---
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppColors.primaryLight.opacity(0.35), lineWidth: 1.5)
                        TextEditor(text: $promptViewModel.userInputPrompt)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundColor(AppColors.primaryLight)
                            .font(.body)
                            .frame(height: 40)
                            .padding(.horizontal, 8)
                        if promptViewModel.userInputPrompt.isEmpty {
                            Text("Ağaç evde duran...")
                                .foregroundColor(AppColors.primaryLight.opacity(0.6))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .font(.body)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    
                    // --- Style Seçici ---
                    let styles: [(name: String, image: String)] = [
                        ("Cartoon", "styles_cartoon"),
                        ("Realist", "styles_realist"),
                        ("Anime", "styles_anime"),
                        ("Watercolor", "styles_watercolor"),
                        ("Pixel Art", "styles_pixelart"),
                        ("Sketch", "styles_sketch"),
                        ("Minimalist", "styles_minimalist")
                    ]
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stil Seçimi")
                            .font(.subheadline)
                            .foregroundColor(AppColors.primaryLight)
                            .padding(.leading, 4)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(styles, id: \ .name) { style in
                                    Button(action: {
                                        promptViewModel.selectedStyle = style.name
                                    }) {
                                        VStack(spacing: 6) {
                                            Image(style.image)
                                                .resizable()
                                                .aspectRatio(1, contentMode: .fit)
                                                .frame(width: 64, height: 64)
                                                .background(
                                                    promptViewModel.selectedStyle == style.name ? AppColors.primary.opacity(0.2) : Color.clear
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(promptViewModel.selectedStyle == style.name ? AppColors.primary : AppColors.primary.opacity(0.2), lineWidth: 2)
                                                )
                                            Text(style.name)
                                                .font(.caption)
                                                .foregroundColor(promptViewModel.selectedStyle == style.name ? AppColors.primary : AppColors.primaryLight)
                                        }
                                        .padding(.vertical, 4)
                                        .frame(width: 72)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    
                    // --- Prompt Gönder Butonu ---
                    PrimaryButton(title: "Promptu Gönder") {
                        promptViewModel.processInitialPrompt()
                        if !promptViewModel.userInputPrompt.isEmpty {
                            dashboardViewModel.savePrompt(promptViewModel.userInputPrompt, resultViewModel: resultViewModel, style: promptViewModel.selectedStyle)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                    
                    // --- Görsellerim ---
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Görsellerim")
                                .font(.headline)
                                .foregroundColor(AppColors.primaryLight)
                                .padding(.leading, 4)
                            
                            Spacer()
                            
                            Button(action: {
                                isMyImagesViewPresented = true
                            }) {
                                Text("Tümünü Gör")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.primary)
                            }
                            .padding(.trailing, 4)
                        }
                        
                        if imageViewModel.savedImages.isEmpty {
                            // Eğer görsel yoksa
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(AppColors.primaryLight.opacity(0.3))
                                
                                Text("Henüz kaydedilmiş görsel bulunmuyor")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.primaryLight.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(AppColors.surface.opacity(0.3))
                            .cornerRadius(12)
                        } else {
                            // En fazla 4 görseli (2x2 grid olarak) göster
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(imageViewModel.savedImages.prefix(4)) { savedImage in
                                    Button(action: {
                                        // Görsele tıklandığında detay sayfasına git
                                        selectedImage = savedImage
                                        isDetailViewPresented = true
                                    }) {
                                        VStack {
                                            if let url = URL(string: savedImage.imageUrl) {
                                                AsyncImage(url: url) { phase in
                                                    if let image = phase.image {
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(height: 120)
                                                            .clipped()
                                                            .cornerRadius(10)
                                                    } else if phase.error != nil {
                                                        Image(systemName: "exclamationmark.triangle")
                                                            .font(.system(size: 30))
                                                            .foregroundColor(.red)
                                                            .frame(height: 120)
                                                            .frame(maxWidth: .infinity)
                                                            .background(Color.black.opacity(0.1))
                                                            .cornerRadius(10)
                                                    } else {
                                                        ProgressView()
                                                            .frame(height: 120)
                                                            .frame(maxWidth: .infinity)
                                                            .background(Color.black.opacity(0.1))
                                                            .cornerRadius(10)
                                                    }
                                                }
                                                .onAppear {
                                                    // URL'yi önbelleğe alarak tekrar yüklenmesini önle
                                                    if let urlString = url.absoluteString as NSString? {
                                                        URLCache.shared.diskCapacity = 50 * 1024 * 1024 // 50 MB
                                                        URLCache.shared.memoryCapacity = 100 * 1024 * 1024 // 100 MB
                                                    }
                                                }
                                            }
                                            
                                            Text(savedImage.prompt)
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                                .padding(.horizontal, 4)
                                                .padding(.top, 4)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .background(AppColors.surface.opacity(0.3))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // --- Son Promptlar ---
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Son Promptlar")
                            .font(.headline)
                            .foregroundColor(AppColors.primaryLight)
                            .padding(.leading, 4)
                        
                        ForEach(dashboardViewModel.recentPrompts, id: \.self) { prompt in
                            Button(action: {
                                resultViewModel.generatedPrompt = nil
                                dashboardViewModel.showResult(forPrompt: prompt, resultViewModel: resultViewModel)
                                promptViewModel.questions = nil
                                promptViewModel.userInputPrompt = prompt
                            }) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(AppColors.primary)
                                        .font(.system(size: 18, weight: .bold))
                                        .padding(.top, 2)
                                    Text(prompt)
                                        .foregroundColor(.white)
                                        .font(.body)
                                        .lineLimit(2)
                                        .truncationMode(.tail)
                                    Spacer()
                                }
                                .padding(12)
                                .background(AppColors.surface.opacity(0.85))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.primary.opacity(0.15), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    Spacer()
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [AppColors.primaryDark, AppColors.primary]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
            
            // Loading prompt
            if promptViewModel.isLoading {
                LoadingTipsView(
                    tips: [
                        "Kısa ve net promptlar daha iyi sonuç verir.",
                        "Stil belirterek daha özgün görseller elde edebilirsin.",
                        "Promptlarında duyguları da tarif etmeyi dene!"
                    ],
                    message: "Prompt işleniyor..."
                )
            }
            
            // Soru akışı
            if let questions = promptViewModel.questions {
                QuestionStepView(
                    question: questions[promptViewModel.currentQuestionIndex].question,
                    examples: questions[promptViewModel.currentQuestionIndex].examples,
                    answer: Binding(
                        get: { promptViewModel.userAnswers[promptViewModel.currentQuestionIndex] },
                        set: { promptViewModel.userAnswers[promptViewModel.currentQuestionIndex] = $0 }
                    ),
                    step: promptViewModel.currentQuestionIndex + 1,
                    total: questions.count,
                    onBack: {
                        if promptViewModel.currentQuestionIndex > 0 {
                            promptViewModel.currentQuestionIndex -= 1
                        }
                    },
                    onNext: {
                        if promptViewModel.currentQuestionIndex < questions.count - 1 {
                            promptViewModel.currentQuestionIndex += 1
                        } else {
                            promptViewModel.submitAnswers()
                        }
                    }
                )
            }
            
            // Sonuç ekranı
            if let finalPrompt = resultViewModel.generatedPrompt {
                ZStack {
                    // Tam ekran koyu arka plan
                    Color.black.opacity(0.9)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        // Kapat butonu
                        HStack {
                            Spacer()
                            Button(action: {
                                // Otomatik kaydet
                                resultViewModel.saveResult(forPrompt: promptViewModel.userInputPrompt, style: promptViewModel.selectedStyle)
                                // Ekranı kapat
                                promptViewModel.userInputPrompt = ""
                                promptViewModel.questions = nil
                                resultViewModel.generatedPrompt = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 28))
                            }
                            .padding(.trailing, 16)
                            .padding(.top, 8)
                        }
                        
                        // Başlık
                        Text("Sonuçlar hazır!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primaryLight)
                            .padding(.top, -8)
                        
                        // Prompt metni
                        ScrollView {
                            Text(finalPrompt)
                                .foregroundColor(.white)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                            
                            // Kategorileri daha minimal göster
                            if let elements = resultViewModel.categorizedElements {
                                ForEach(Array(elements.keys.sorted()), id: \.self) { category in
                                    if let items = elements[category], !items.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(category)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .padding(.leading, 4)
                                                .padding(.top, 8)
                                            
                                            FlowLayout(data: items, spacing: 8) { item in
                                                HStack(spacing: 4) {
                                                    Image(systemName: getIconForCategory(category: category))
                                                        .font(.system(size: 10))
                                                        .foregroundColor(.white)
                                                    
                                                    Text(item)
                                                        .font(.caption)
                                                        .foregroundColor(.white)
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(
                                                    Capsule()
                                                        .fill(getColorForCategory(category: category))
                                                )
                                            }
                                        }
                                        .padding(.bottom, 4)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                            }
                        }
                        
                        Spacer()
                        
                        // Görsel oluşturma butonu
                        Button(action: {
                            isImageGenerationViewPresented = true
                        }) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 18))
                                Text("Görsel Oluştur")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [AppColors.primary, AppColors.primary.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: AppColors.primary.opacity(0.4), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                        
                        // Başa dön butonu
                        Button(action: {
                            // Otomatik kaydet
                            resultViewModel.saveResult(forPrompt: promptViewModel.userInputPrompt, style: promptViewModel.selectedStyle)
                            // Temizle
                            promptViewModel.userInputPrompt = ""
                            promptViewModel.questions = nil
                            resultViewModel.generatedPrompt = nil
                        }) {
                            Text("Başa Dön")
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.gray.opacity(0.25))
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                }
                .sheet(isPresented: $isImageGenerationViewPresented) {
                    // Görsel oluşturma ekranı
                    ImageGenerationView(
                        imageViewModel: imageViewModel,
                        generatedPrompt: finalPrompt,
                        originalPrompt: promptViewModel.userInputPrompt,
                        style: promptViewModel.selectedStyle
                    )
                }
            }
            
            // Hata mesajı
            if let errorMessage = promptViewModel.errorMessage {
                ErrorMessageView(message: errorMessage)
            }
        }
        .onAppear {
            // Kullanıcı bilgisini ResultViewModel'e bağla
            resultViewModel.authViewModel = authViewModel
            resultViewModel.refreshResults()
            
            // Kullanıcı bilgisini ImageViewModel'e bağla
            imageViewModel.authViewModel = authViewModel
            imageViewModel.refreshImages()
            
            // Kullanıcı bilgisini DashboardViewModel'e bağla
            dashboardViewModel.authViewModel = authViewModel
            
            // Son promptları kullanıcı için yükle
            dashboardViewModel.loadRecentPrompts()
        }
        .sheet(isPresented: $isMyImagesViewPresented) {
            // Görsellerim ekranı
            MyImagesView(imageViewModel: imageViewModel)
        }
        .sheet(isPresented: $isDetailViewPresented) {
            // Görsel detay ekranı
            if let image = selectedImage {
                ImageDetailView(image: image)
            }
        }
    }
}

#Preview {
    DashboardView()
}
