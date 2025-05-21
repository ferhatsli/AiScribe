import SwiftUI

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    @ViewBuilder let content: (Data.Element) -> Content
    
    init(data: Data, spacing: CGFloat = 8, alignment: HorizontalAlignment = .leading, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: 10) {
            GeometryReader { geometry in
                self.flowLayout(in: geometry)
            }
        }
    }
    
    private func flowLayout(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        var lastHeight: CGFloat = 0
        let rowSpacing: CGFloat = 8
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(data.enumerated()), id: \.element) { index, item in
                content(item)
                    .padding(.all, 0)
                    .alignmentGuide(.leading) { dimension in
                        // Eğer bu öğe satıra sığmazsa yeni satıra geç
                        if width + dimension.width + spacing > geometry.size.width {
                            width = 0
                            height = height + lastHeight + rowSpacing
                            lastHeight = 0
                        }
                        
                        let result = width
                        
                        // Bir sonraki öğe için pozisyonu güncelle
                        if lastHeight < dimension.height {
                            lastHeight = dimension.height
                        }
                        
                        width = width + dimension.width + spacing
                        return -result
                    }
                    .alignmentGuide(.top) { dimension in
                        -height
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: estimatedHeight(in: geometry))
    }
    
    // Tahmini yükseklik - basit bir hesaplama
    private func estimatedHeight(in geometry: GeometryProxy) -> CGFloat {
        // Ortalama bir etiket yüksekliği (varsayım)
        let estimatedItemHeight: CGFloat = 30
        
        // Etiket başına ortalama genişlik (varsayım)
        let estimatedItemWidth: CGFloat = 80
        
        // Bir satıra tahmini kaç etiket sığar
        let itemsPerRow = max(1, Int(geometry.size.width / (estimatedItemWidth + spacing)))
        
        // Kaç satır olacak
        let rowCount = ceil(Double(data.count) / Double(itemsPerRow))
        
        // Toplam yükseklik - satırlar arası boşluk dahil
        return CGFloat(rowCount) * (estimatedItemHeight + spacing)
    }
}

// Örnek kullanım:
// FlowLayout(data: ["Swift", "SwiftUI", "iOS", "Xcode"]) { item in
//     Text(item)
//         .padding(.horizontal, 12)
//         .padding(.vertical, 6)
//         .background(Color.blue.opacity(0.2))
//         .cornerRadius(16)
// }

struct FlowLayout_Previews: PreviewProvider {
    static var previews: some View {
        FlowLayout(data: ["Swift", "SwiftUI", "iOS", "Xcode", "Apple", "Development"], spacing: 8) { tag in
            Text(tag)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(16)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 