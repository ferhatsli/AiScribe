import SwiftUI

struct AppDivider: View {
    var color: Color = AppColors.border
    var height: CGFloat = 1
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
            .edgesIgnoringSafeArea(.horizontal)
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Üst Alan")
        AppDivider()
        Text("Alt Alan")
    }
    .padding()
} 