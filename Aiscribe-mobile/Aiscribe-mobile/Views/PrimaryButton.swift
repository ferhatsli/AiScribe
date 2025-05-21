import SwiftUI

struct PrimaryButton: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.background)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppColors.primary)
                .cornerRadius(12)
        }
    }
}

#Preview {
    PrimaryButton(title: "Devam Et", action: {})
        .padding()
        .background(Color.gray.opacity(0.2))
} 