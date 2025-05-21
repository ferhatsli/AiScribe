import SwiftUI

struct LoadingTipsView: View {
    let tips: [String]
    let message: String
    @State private var currentTipIndex = 0
    @State private var timer: Timer? = nil

    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                .scaleEffect(1.5)
            Text(message)
                .foregroundColor(.white)
                .font(.headline)
            Text(tips[currentTipIndex])
                .foregroundColor(AppColors.primaryLight)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(32)
        .background(AppColors.surface.opacity(0.97))
        .cornerRadius(20)
        .shadow(radius: 10)
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                withAnimation {
                    currentTipIndex = (currentTipIndex + 1) % tips.count
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

#Preview {
    LoadingTipsView(
        tips: [
            "Kısa ve net promptlar daha iyi sonuç verir.",
            "Stil belirterek daha özgün görseller elde edebilirsin.",
            "Promptlarında duyguları da tarif etmeyi dene!"
        ],
        message: "Prompt işleniyor..."
    )
    .padding()
    .background(AppColors.primaryDark)
} 