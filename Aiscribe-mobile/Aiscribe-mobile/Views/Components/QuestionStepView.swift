import SwiftUI

struct QuestionStepView: View {
    let question: String
    let examples: [String]
    @Binding var answer: AnswerItem
    let step: Int
    let total: Int
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            // İlerleme göstergesi
            Text("Soru \(step) / \(total)")
                .foregroundColor(AppColors.primaryLight)
                .font(.caption)
                .padding(.top, 8)
            // Soru metni
            Text(question)
                .foregroundColor(.white)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            // Örnekler
            if !examples.isEmpty {
                Text("Örnek: \(examples.joined(separator: ", "))")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            // Cevap alanı
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.primaryLight.opacity(0.35), lineWidth: 1.2)
                TextEditor(text: Binding(
                    get: { answer.answer },
                    set: { newValue in
                        answer = AnswerItem(question: answer.question, answer: newValue)
                    }
                ))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(AppColors.primaryLight)
                    .font(.body)
                    .frame(height: 48)
                    .padding(.horizontal, 6)
                if answer.answer.isEmpty {
                    Text("Cevabınızı yazın...")
                        .foregroundColor(AppColors.primaryLight.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .font(.body)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 24)
            // Butonlar
            HStack(spacing: 20) {
                if step > 1 {
                    SecondaryButton(title: "Geri", action: onBack)
                        .frame(maxWidth: .infinity)
                }
                PrimaryButton(title: step == total ? "Bitir" : "İleri", action: onNext)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 32)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [AppColors.primaryDark, AppColors.primary]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    QuestionStepView(
        question: "Bir uzaylıyı nasıl tarif edersin?",
        examples: ["Yeşil, büyük gözlü", "Dost canlısı"],
        answer: .constant(AnswerItem(question: "Bir uzaylıyı nasıl tarif edersin?", answer: "")),
        step: 1,
        total: 3,
        onBack: {},
        onNext: {}
    )
} 