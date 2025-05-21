import SwiftUI

struct AppLabel: View {
    var text: String
    var font: Font = .body
    var color: Color = AppColors.text
    var weight: Font.Weight = .regular
    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(weight)
            .foregroundColor(color)
    }
}

#Preview {
    VStack(spacing: 8) {
        AppLabel(text: "Başlık", font: .title, weight: .bold)
        AppLabel(text: "Açıklama metni", font: .subheadline, color: AppColors.textSecondary)
    }
    .padding()
} 