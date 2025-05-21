import SwiftUI

struct SplashScreenView: View {
    @State private var size = 0.8
    @State private var opacity = 0.5
    var onSplashFinished: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [AppColors.primaryDark, AppColors.background]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.primaryLight, lineWidth: 3)
                    )
                    .shadow(color: AppColors.primaryDark.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Text("AiScribe")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(AppColors.text)
                    .padding(.top, 20)
            }
            .scaleEffect(size)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.2)) {
                    self.size = 1.0
                    self.opacity = 1.0
                }
                
                // Zaman aşımından sonra callback'i çağır
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        onSplashFinished()
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(onSplashFinished: {})
} 