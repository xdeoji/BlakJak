import SwiftUI

struct ProfileView: View {
    @ObservedObject var walletVM: WalletViewModel
    @ObservedObject var streakVM: StreakViewModel
    @StateObject private var statsVM = StatsViewModel()
    @State private var bankBalance = BankStore.balance
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CasinoTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header

                    // PnL
                    pnlCard

                    // Stats Grid
                    statsGrid

                    // Win/Loss breakdown
                    outcomeBar

                    // Bank
                    bankCard

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
            statCell(label: "Total Wagered", value: statsVM.totalWagered.chipFormatted)
            statCell(label: "Total Returned", value: statsVM.totalReturned.chipFormatted)
            statCell(label: "Avg Bet", value: statsVM.avgBet.chipFormatted)
            statCell(label: "Avg Multiplier", value: String(format: "%.1fx", statsVM.avgMultiplier))
            statCell(label: "Biggest Win", value: "+\(statsVM.biggestWin.chipFormatted)")
            statCell(label: "Biggest Loss", value: statsVM.biggestLoss.chipFormatted)
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
        if pnl >= 0 { return "+\(pnl.chipFormatted)" }
        return pnl.chipFormatted
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

    // MARK: - Bank

    @State private var showDepositInput = false
    @State private var depositText = ""
    @State private var showWithdrawInput = false
    @State private var withdrawText = ""

    private var bankCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BANK")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(CasinoTheme.textTertiary)
                .tracking(1.5)

            // Balances row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(bankBalance.formatted())")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("banked")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(CasinoTheme.textTertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(walletVM.balance.formatted())")
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(CasinoTheme.textSecondary)
                    Text("in wallet")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(CasinoTheme.textTertiary)
                }
            }

            if showDepositInput {
                depositInputView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if showWithdrawInput {
                withdrawInputView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                HStack(spacing: 10) {
                    // Deposit
                    Button {
                        depositText = ""
                        withAnimation(.easeOut(duration: 0.2)) { showDepositInput = true }
                    } label: {
                        Label("Deposit", systemImage: "arrow.down.circle")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(CasinoTheme.success)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(CasinoTheme.success.opacity(0.1))
                                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(CasinoTheme.success.opacity(0.25), lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(walletVM.balance <= 0)
                    .opacity(walletVM.balance <= 0 ? 0.4 : 1)

                    // Withdraw
                    Button {
                        withdrawText = ""
                        withAnimation(.easeOut(duration: 0.2)) { showWithdrawInput = true }
                    } label: {
                        Label("Withdraw", systemImage: "arrow.up.circle")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(CasinoTheme.warning)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(CasinoTheme.warning.opacity(0.1))
                                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(CasinoTheme.warning.opacity(0.25), lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(bankBalance <= 0)
                    .opacity(bankBalance <= 0 ? 0.4 : 1)
                }
                .transition(.opacity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CasinoTheme.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(CasinoTheme.border, lineWidth: 1))
        )
        .animation(.easeOut(duration: 0.2), value: showDepositInput)
        .animation(.easeOut(duration: 0.2), value: showWithdrawInput)
    }

    private var depositInputView: some View {
        VStack(spacing: 10) {
            // Amount display + Max button
            HStack {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { showDepositInput = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CasinoTheme.textTertiary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(depositText.isEmpty ? "0" : depositText)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())

                Spacer()

                Button {
                    depositText = "\(walletVM.balance)"
                    Haptics.tick()
                } label: {
                    Text("MAX")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(CasinoTheme.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(CasinoTheme.success.opacity(0.12))
                                .overlay(Capsule().strokeBorder(CasinoTheme.success.opacity(0.3), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
            }

            Text("available: \(walletVM.balance.formatted())")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(CasinoTheme.textTertiary)

            // Numpad
            let keys: [[String]] = [["1","2","3"],["4","5","6"],["7","8","9"],["C","0","⌫"]]
            VStack(spacing: 6) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(row, id: \.self) { key in
                            Button {
                                handleDepositKey(key)
                            } label: {
                                Text(key)
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundColor(key == "C" ? CasinoTheme.danger : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(CasinoTheme.bgElevated))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Confirm deposit
            let depositAmount = Int(depositText) ?? 0
            Button {
                guard depositAmount > 0, depositAmount <= walletVM.balance else { return }
                BankStore.balance += depositAmount
                bankBalance = BankStore.balance
                walletVM.credit(-depositAmount)
                Haptics.heavy()
                withAnimation(.easeOut(duration: 0.2)) { showDepositInput = false }
            } label: {
                Text(depositAmount > 0 ? "Deposit \(depositAmount.formatted())" : "Enter Amount")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(depositAmount > 0 && depositAmount <= walletVM.balance ? .black : CasinoTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(depositAmount > 0 && depositAmount <= walletVM.balance ? Color.white : CasinoTheme.bgElevated)
                    )
            }
            .buttonStyle(.plain)
            .disabled(depositAmount <= 0 || depositAmount > walletVM.balance)
        }
    }

    private func handleDepositKey(_ key: String) {
        Haptics.tick()
        switch key {
        case "C": depositText = ""
        case "⌫":
            if !depositText.isEmpty { depositText.removeLast() }
        default:
            if depositText == "0" { depositText = key }
            else if depositText.count < 9 { depositText += key }
        }
    }

    private var withdrawInputView: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { showWithdrawInput = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CasinoTheme.textTertiary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(withdrawText.isEmpty ? "0" : withdrawText)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())

                Spacer()

                Button {
                    withdrawText = "\(bankBalance)"
                    Haptics.tick()
                } label: {
                    Text("MAX")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(CasinoTheme.warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(CasinoTheme.warning.opacity(0.12))
                                .overlay(Capsule().strokeBorder(CasinoTheme.warning.opacity(0.3), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
            }

            Text("available: \(bankBalance.formatted())")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(CasinoTheme.textTertiary)

            let keys: [[String]] = [["1","2","3"],["4","5","6"],["7","8","9"],["C","0","⌫"]]
            VStack(spacing: 6) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(row, id: \.self) { key in
                            Button { handleWithdrawKey(key) } label: {
                                Text(key)
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundColor(key == "C" ? CasinoTheme.danger : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(CasinoTheme.bgElevated))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            let withdrawAmount = Int(withdrawText) ?? 0
            Button {
                guard withdrawAmount > 0, withdrawAmount <= bankBalance else { return }
                BankStore.balance -= withdrawAmount
                bankBalance = BankStore.balance
                walletVM.credit(withdrawAmount)
                Haptics.heavy()
                withAnimation(.easeOut(duration: 0.2)) { showWithdrawInput = false }
            } label: {
                Text(withdrawAmount > 0 ? "Withdraw \(withdrawAmount.formatted())" : "Enter Amount")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(withdrawAmount > 0 && withdrawAmount <= bankBalance ? .black : CasinoTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(withdrawAmount > 0 && withdrawAmount <= bankBalance ? Color.white : CasinoTheme.bgElevated)
                    )
            }
            .buttonStyle(.plain)
            .disabled(withdrawAmount <= 0 || withdrawAmount > bankBalance)
        }
    }

    private func handleWithdrawKey(_ key: String) {
        Haptics.tick()
        switch key {
        case "C": withdrawText = ""
        case "⌫":
            if !withdrawText.isEmpty { withdrawText.removeLast() }
        default:
            if withdrawText == "0" { withdrawText = key }
            else if withdrawText.count < 9 { withdrawText += key }
        }
    }

    // MARK: - Reset

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
            .confirmationDialog("Reset stats?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    resetAll()
                }
            } message: {
                Text("This will clear all stats and streaks. Your balance and bank are not affected.")
            }
        }
    }

    private func resetAll() {
        // Stats only — balance and bank are intentionally preserved
        StatsStore.records = []
        statsVM.reload()

        // Streaks
        StreakStore.winStreak = 0
        StreakStore.lossStreak = 0
        streakVM.winStreak = 0
        streakVM.lossStreak = 0

        Haptics.medium()
        dismiss()
    }
}

// MARK: - Int formatting

private extension Int {
    /// Comma-separated below 10M, shorthand above (10.2M, 1.3B).
    var chipFormatted: String {
        let a = Swift.abs(self)
        let sign = self < 0 ? "-" : ""
        switch a {
        case 0..<10_000_000:
            return self.formatted()          // e.g. 1,234,567
        case 10_000_000..<1_000_000_000:
            return "\(sign)\(String(format: "%.1f", Double(a) / 1_000_000))M"
        default:
            return "\(sign)\(String(format: "%.1f", Double(a) / 1_000_000_000))B"
        }
    }
}
