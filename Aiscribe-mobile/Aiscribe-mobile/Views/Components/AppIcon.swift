import SwiftUI

struct AppIcon: View {
    var systemName: String
    var color: Color = AppColors.primary
    var size: CGFloat = 28
    var body: some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundColor(color)
            .padding(8)
            .background(color.opacity(0.08))
            .clipShape(Circle())
    }
}

#Preview {
    HStack(spacing: 16) {
        AppIcon(systemName: "star.fill")
        AppIcon(systemName: "bolt.fill", color: .yellow)
    }
} 