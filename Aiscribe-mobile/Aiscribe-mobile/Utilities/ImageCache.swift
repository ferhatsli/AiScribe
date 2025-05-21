import Foundation
import SwiftUI

class ImageCache {
    static let shared = ImageCache()
    
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        // Önbellek boyutu sınırlamaları
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func removeAll() {
        cache.removeAllObjects()
    }
}

// SwiftUI görsel önbelleği için özel bir görüntü bileşeni
struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content
    
    init(url: URL?, scale: CGFloat = 1.0, transaction: Transaction = Transaction(), @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
    }
    
    var body: some View {
        if let url = url, let cachedImage = ImageCache.shared.get(forKey: url.absoluteString) {
            // Önbellekte varsa doğrudan kullan
            content(.success(Image(uiImage: cachedImage)))
        } else {
            // Önbellekte yoksa indir ve önbelleğe al
            AsyncImage(url: url, scale: scale, transaction: transaction) { phase in
                // Başarılı ise önbelleğe al
                if case .success(let image) = phase {
                    let uiImage = cacheAndReturnUIImage(image: image)
                    content(.success(Image(uiImage: uiImage)))
                } else {
                    content(phase)
                }
            }
        }
    }
    
    // UIImage'a dönüştür ve önbelleğe al
    private func cacheAndReturnUIImage(image: Image) -> UIImage {
        let renderer = ImageRenderer(content: image)
        if let uiImage = renderer.uiImage {
            if let url = url {
                ImageCache.shared.set(uiImage, forKey: url.absoluteString)
            }
            return uiImage
        }
        // Fallback için boş bir görüntü
        return UIImage()
    }
}

// Kullanım örneği:
// CachedAsyncImage(url: URL(string: "https://example.com/image.jpg")) { phase in
//     if let image = phase.image {
//         image.resizable().aspectRatio(contentMode: .fill)
//     } else if phase.error != nil {
//         Color.red // Hata durumu
//     } else {
//         ProgressView() // Yükleniyor
//     }
// } 