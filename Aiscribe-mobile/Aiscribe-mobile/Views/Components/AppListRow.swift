import SwiftUI

struct AppListRow<Content: View>: View {
    let content: Content
    var showChevron: Bool = true
    init(showChevron: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.showChevron = showChevron
    }
    var body: some View {
        HStack {
            content
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(AppColors.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        AppListRow {
            Text("Prompt Geçmişi")
        }
        AppListRow(showChevron: false) {
            Text("Açıklama satırı")
        }
    }
    .padding()
} 