import SwiftUI

struct ErrorMessageView: View {
    var message: String
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.error)
            Text(message)
                .foregroundColor(AppColors.error)
                .font(.subheadline)
        }
        .padding()
        .background(AppColors.error.opacity(0.08))
        .cornerRadius(10)
    }
}

#Preview {
    ErrorMessageView(message: "Bir hata oluştu. Lütfen tekrar deneyin.")
        .padding()
} 