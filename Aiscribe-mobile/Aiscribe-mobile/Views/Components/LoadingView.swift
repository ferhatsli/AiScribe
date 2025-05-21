import SwiftUI

struct LoadingView: View {
    var message: String? = nil
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                .scaleEffect(1.5)
            if let message = message {
                Text(message)
                    .foregroundColor(AppColors.textSecondary)
                    .font(.subheadline)
            }
        }
        .padding()
    }
}

#Preview {
    LoadingView(message: "Yükleniyor...")
        .padding()
} 