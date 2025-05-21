import SwiftUI

struct SecondaryButton: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppColors.primary.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.primary, lineWidth: 1)
                )
        }
    }
}

#Preview {
    SecondaryButton(title: "İptal", action: {})
        .padding()
        .background(Color.gray.opacity(0.2))
} 