import SwiftUI

struct AppTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(AppColors.primaryLight.opacity(0.8))
                        .padding(.leading, 16)
                }
                
                if isSecure {
                    SecureField("", text: $text)
                        .padding(.leading, 16)
                } else {
                    TextField("", text: $text)
                        .padding(.leading, 16)
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .foregroundColor(AppColors.text)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

struct AppTextFieldPreview: View {
    @State var text = ""
    var body: some View {
        VStack(spacing: 16) {
            AppTextField(placeholder: "E-posta", text: $text)
            AppTextField(placeholder: "Şifre", text: $text, isSecure: true)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

#Preview {
    AppTextFieldPreview()
} 