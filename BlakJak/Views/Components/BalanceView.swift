import SwiftUI

struct BalanceView: View {
    let balance: Int
    @State private var displayedBalance: Int = 0

    var body: some View {
        HStack(spacing: 5) {
            Text("\(displayedBalance)")
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .contentTransition(.numericText())
            Text("pts")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(CasinoTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(CasinoTheme.bgElevated)
                .overlay(
                    Capsule()
                        .strokeBorder(CasinoTheme.border, lineWidth: 1)
                )
        )
        .onAppear { displayedBalance = balance }
        .onChange(of: balance) { _, newValue in
            withAnimation(.spring(response: 0.4)) {
                displayedBalance = newValue
            }
        }
    }
}
