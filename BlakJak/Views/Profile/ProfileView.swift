import SwiftUI

struct ProfileView: View {
    @ObservedObject var walletVM: WalletViewModel
    @ObservedObject var streakVM: StreakViewModel
    @StateObject private var statsVM = StatsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CasinoTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header

                    // Risk Profile Card
                    riskProfileCard

                    // PnL
                    pnlCard

                    // Stats Grid
                    statsGrid

                    // Win/Loss breakdown
                    outcomeBar

                    // Streaks
                    streakSettings

                    // Settings
                    gameSettings

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { statsVM.reload() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Profile")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("\(statsVM.handsPlayed) hands played")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(CasinoTheme.textTertiary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(CasinoTheme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(CasinoTheme.bgElevated)
                            .overlay(Circle().strokeBorder(CasinoTheme.border, lineWidth: 1))
                    )
            }
        }
    }

    private var riskProfileCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RISK PROFILE")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(CasinoTheme.textTertiary)
                .tracking(1.5)

            Text(statsVM.riskProfile.rawValue)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(riskColor)

            Text(statsVM.riskProfile.description)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(CasinoTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CasinoTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(riskColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var pnlCard: some View {
        VStack(spacing: 6) {
            Text("P&L")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(CasinoTheme.textTertiary)
                .tracking(1.5)

            Text(pnlText)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(pnlColor)

            Text("pts")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(CasinoTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CasinoTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(CasinoTheme.border, lineWidth: 1)
                )
        )
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            statCell(label: "Total Wagered", value: "\(statsVM.totalWagered)")
            statCell(label: "Total Returned", value: "\(statsVM.totalReturned)")
            statCell(label: "Avg Bet", value: "\(statsVM.avgBet)")
            statCell(label: "Avg Multiplier", value: String(format: "%.1fx", statsVM.avgMultiplier))
            statCell(label: "Biggest Win", value: "+\(statsVM.biggestWin)")
            statCell(label: "Biggest Loss", value: "\(statsVM.biggestLoss)")
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(CasinoTheme.textTertiary)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CasinoTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(CasinoTheme.border, lineWidth: 1)
                )
        )
    }

    private var outcomeBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OUTCOMES")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(CasinoTheme.textTertiary)
                .tracking(1.5)

            if statsVM.handsPlayed > 0 {
                GeometryReader { geo in
                    let total = CGFloat(statsVM.handsPlayed)
                    let winW = geo.size.width * CGFloat(statsVM.winCount) / total
                    let pushW = geo.size.width * CGFloat(statsVM.pushCount) / total
                    // lossW fills the rest

                    HStack(spacing: 2) {
                        if statsVM.winCount > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(CasinoTheme.success)
                                .frame(width: max(winW, 4))
                        }
                        if statsVM.pushCount > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(CasinoTheme.textTertiary)
                                .frame(width: max(pushW, 4))
                        }
                        if statsVM.lossCount > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(CasinoTheme.danger)
                        }
                    }
                }
                .frame(height: 8)

                HStack(spacing: 16) {
                    outcomeLabel(color: CasinoTheme.success, text: "\(statsVM.winCount)W")
                    outcomeLabel(color: CasinoTheme.textTertiary, text: "\(statsVM.pushCount)P")
                    outcomeLabel(color: CasinoTheme.danger, text: "\(statsVM.lossCount)L")
                    Spacer()
                    Text(String(format: "%.0f%%", statsVM.winRate * 100))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(CasinoTheme.textSecondary)
                }
            } else {
                Text("No hands played yet")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(CasinoTheme.textTertiary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CasinoTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(CasinoTheme.border, lineWidth: 1)
                )
        )
    }

    private func outcomeLabel(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(CasinoTheme.textSecondary)
        }
    }

    // MARK: - Helpers

    private var pnlText: String {
        let pnl = statsVM.pnl
        if pnl >= 0 { return "+\(pnl)" }
        return "\(pnl)"
    }

    private var pnlColor: Color {
        if statsVM.pnl > 0 { return CasinoTheme.success }
        if statsVM.pnl < 0 { return CasinoTheme.danger }
        return CasinoTheme.textSecondary
    }

    private var riskColor: Color {
        switch statsVM.riskProfile {
        case .conservative: return CasinoTheme.success
        case .balanced: return CasinoTheme.accent
        case .aggressive: return CasinoTheme.warning
        case .degenerate: return CasinoTheme.danger
        }
    }

    private var streakSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("STREAKS")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(CasinoTheme.textTertiary)
                .tracking(1.5)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Streak Bonuses")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(streakVM.enabled ? "Win & loss streaks give payout bonuses" : "Disabled")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(CasinoTheme.textTertiary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { streakVM.enabled },
                    set: { _ in streakVM.toggleEnabled() }
                ))
                .labelsHidden()
                .tint(CasinoTheme.success)
            }

            if streakVM.enabled {
                HStack(spacing: 16) {
                    streakStat(icon: "flame.fill", label: "Win", count: streakVM.winStreak, color: CasinoTheme.success)
                    streakStat(icon: "arrow.up.circle.fill", label: "Loss", count: streakVM.lossStreak, color: CasinoTheme.warning)
                }

                if let wb = streakVM.activeWinBonus {
                    Text(wb.label)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(CasinoTheme.success)
                }
                if let lb = streakVM.activeLossBonus {
                    Text(lb.label)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(CasinoTheme.warning)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CasinoTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(CasinoTheme.border, lineWidth: 1)
                )
        )
    }

    private func streakStat(icon: String, label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
            Text("\(label): \(count)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    @State private var riskyConfirm = SettingsStore.riskyActionConfirm

    private var gameSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SETTINGS")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(CasinoTheme.textTertiary)
                .tracking(1.5)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Confirm Risky Actions")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Ask before hitting or doubling on 17+")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(CasinoTheme.textTertiary)
                }
                Spacer()
                Toggle("", isOn: $riskyConfirm)
                    .labelsHidden()
                    .tint(CasinoTheme.success)
                    .onChange(of: riskyConfirm) { _, val in
                        SettingsStore.riskyActionConfirm = val
                    }
            }

            // Reset
            resetButton
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CasinoTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(CasinoTheme.border, lineWidth: 1)
                )
        )
    }

    @State private var showResetConfirm = false

    private var resetButton: some View {
        VStack(spacing: 0) {
            Divider()
                .background(CasinoTheme.border)
                .padding(.vertical, 14)

            Button {
                showResetConfirm = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                    Text("Reset Profile")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(CasinoTheme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(CasinoTheme.danger.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(CasinoTheme.danger.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .confirmationDialog("Reset everything?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    resetAll()
                }
            } message: {
                Text("This will reset your balance to 1,000, clear all stats, streaks, and history. This cannot be undone.")
            }
        }
    }

    private func resetAll() {
        // Balance
        WalletStore.balance = 1000
        walletVM.balance = 1000

        // Stats
        StatsStore.records = []
        statsVM.reload()

        // Streaks
        StreakStore.winStreak = 0
        StreakStore.lossStreak = 0
        streakVM.winStreak = 0
        streakVM.lossStreak = 0

        // Settings stay as-is

        Haptics.medium()
        dismiss()
    }
}
