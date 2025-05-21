import SwiftUI

struct AppCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    AppCard {
        Text("Kart başlığı").font(.headline)
        Text("Kart içeriği örneği.")
    }
    .padding()
} 