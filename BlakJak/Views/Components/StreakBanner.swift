import SwiftUI

struct StreakBanner: View {
    @ObservedObject var streakVM: StreakViewModel
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 6) {
            // Pills row
            HStack(spacing: 8) {
                if streakVM.winStreak >= 3 {
                    streakPill(
                        icon: "flame.fill",
                        text: "\(streakVM.winStreak)",
                        color: CasinoTheme.success
                    )
                }
                if streakVM.lossStreak >= 3 {
                    streakPill(
                        icon: "arrow.up.circle.fill",
                        text: "\(streakVM.lossStreak)",
                        color: CasinoTheme.warning
                    )
                }
            }
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.2)) {
                    expanded.toggle()
                }
            }

            // Expanded detail
            if expanded {
                VStack(alignment: .leading, spacing: 4) {
                    if let wb = streakVM.activeWinBonus {
                        bonusRow(icon: "flame.fill", text: wb.label, color: CasinoTheme.success)
                    }
                    if let lb = streakVM.activeLossBonus {
                        bonusRow(icon: "arrow.up.circle.fill", text: lb.label, color: CasinoTheme.warning)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(CasinoTheme.bgElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(CasinoTheme.border, lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func streakPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(color.opacity(0.5))
                .rotationEffect(expanded ? .degrees(180) : .zero)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
                .overlay(
                    Capsule()
                        .strokeBorder(color.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func bonusRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(CasinoTheme.textSecondary)
        }
    }
}
