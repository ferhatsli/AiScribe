import SwiftUI

struct MyImagesView: View {
    @ObservedObject var imageViewModel: ImageViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedImage: SavedImage? = nil
    @State private var isDetailViewPresented = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arkaplan
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.primaryDark, AppColors.primary]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    // İçerik
                    if imageViewModel.savedImages.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(AppColors.primaryLight.opacity(0.5))
                            
                            Text("Henüz kaydedilmiş görüntü yok")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Prompt oluşturduktan sonra görüntü oluştur butonunu kullanarak yeni görüntüler oluşturabilirsiniz.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.primaryLight)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(imageViewModel.savedImages) { savedImage in
                                    Button(action: {
                                        print("Görsel seçildi: \(savedImage.id)")
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
                                                            .cornerRadius(12)
                                                    } else if phase.error != nil {
                                                        Image(systemName: "exclamationmark.triangle")
                                                            .font(.system(size: 40))
                                                            .foregroundColor(.red)
                                                            .frame(height: 120)
                                                            .frame(maxWidth: .infinity)
                                                            .background(Color.black.opacity(0.1))
                                                            .cornerRadius(12)
                                                    } else {
                                                        ProgressView()
                                                            .frame(height: 120)
                                                            .frame(maxWidth: .infinity)
                                                            .background(Color.black.opacity(0.1))
                                                            .cornerRadius(12)
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
                                                .lineLimit(2)
                                                .padding(.horizontal, 4)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .background(AppColors.surface.opacity(0.3))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("Görsellerim")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedImage) { image in
            ImageDetailView(image: image)
        }
        .onAppear {
            // Görünüm her açıldığında authViewModel'i imageViewModel'e atayarak
            // doğru kullanıcı için görselleri yükle
            imageViewModel.authViewModel = authViewModel
            imageViewModel.refreshImages()
        }
    }
}

// Görsel detay görünümü
struct ImageDetailView: View {
    let image: SavedImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Arkaplan
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Başlık
                Text("Görsel Detayı")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top)
                
                // Görsel
                if let url = URL(string: image.imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(height: 300)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                        case .failure:
                            VStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 40))
                                Text("Görsel yüklenemedi")
                                    .foregroundColor(.red)
                            }
                            .frame(height: 300)
                        @unknown default:
                            Text("Bilinmeyen durum")
                                .foregroundColor(.orange)
                        }
                    }
                    .onAppear {
                        // URL'yi önbelleğe alarak tekrar yüklenmesini önle
                        if let urlString = url.absoluteString as NSString? {
                            URLCache.shared.diskCapacity = 50 * 1024 * 1024 // 50 MB
                            URLCache.shared.memoryCapacity = 100 * 1024 * 1024 // 100 MB
                        }
                    }
                    .frame(maxHeight: 400)
                    .padding()
                    .id(image.id) // Ensure view refreshes when image changes
                }
                
                // Prompt bilgileri
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Orijinal Prompt:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(image.prompt)
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        Text("Oluşturulan Prompt:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(image.generatedPrompt)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Kapatma butonu
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Kapat")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 30)
                        .background(AppColors.primary)
                        .cornerRadius(8)
                }
                .padding(.bottom)
            }
        }
        .onAppear {
            print("Görsel detayı açıldı. ID: \(image.id), URL: \(image.imageUrl)")
        }
    }
}

struct MyImagesView_Previews: PreviewProvider {
    static var previews: some View {
        let imageVM = ImageViewModel()
        return MyImagesView(imageViewModel: imageVM)
    }
} 