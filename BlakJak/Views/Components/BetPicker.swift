import SwiftUI

struct BetPicker: View {
    @Binding var amount: Int
    let balance: Int
    let onBuyIn: () -> Void

    @State private var isEditingCustom = false
    @State private var customText = ""
    @State private var customAmount: Int = SettingsStore.customBetAmount

    private let pctTiers: [(label: String, pct: Double)] = [
        ("2%", 0.02), ("5%", 0.05), ("10%", 0.10), ("25%", 0.25), ("50%", 0.50)
    ]

    private var presets: [(label: String, value: Int)] {
        var result: [(label: String, value: Int)] = []
        for tier in pctTiers {
            let raw = Int(Double(balance) * tier.pct)
            let nice = max(10, roundToNice(raw))
            if nice <= balance {
                // Avoid duplicates
                if !result.contains(where: { $0.value == nice }) {
                    result.append((tier.label, nice))
                }
            }
        }
        if result.isEmpty { result = [("MIN", 10)] }
        return result
    }

    private func roundToNice(_ value: Int) -> Int {
        switch value {
        case ..<10:      return 10
        case ..<25:      return value / 5 * 5        // 10, 15, 20
        case ..<100:     return value / 25 * 25       // 25, 50, 75
        case ..<500:     return value / 50 * 50       // 100, 150, 200...
        case ..<1000:    return value / 100 * 100     // 500, 600, 700...
        case ..<5000:    return value / 250 * 250     // 1000, 1250, 1500...
        case ..<10000:   return value / 500 * 500     // 5000, 5500...
        case ..<50000:   return value / 1000 * 1000   // 10000, 11000...
        case ..<100000:  return value / 5000 * 5000   // 50000, 55000...
        default:         return value / 10000 * 10000
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isEditingCustom {
                customInput
            } else {
                normalPicker
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            CasinoTheme.bgCard
                .overlay(
                    Rectangle()
                        .fill(CasinoTheme.border)
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }

    // MARK: - Normal

    private var normalPicker: some View {
        VStack(spacing: 10) {
            presetsRow
            buyInRow
        }
    }

    private var presetsRow: some View {
        VStack(spacing: 8) {
            // Percentage presets
            HStack(spacing: 6) {
                ForEach(presets, id: \.value) { preset in
                    BetChip(label: preset.label, sublabel: "\(preset.value)", selected: amount == preset.value) {
                        amount = preset.value
                    }
                }
            }

            // Custom + All In
            HStack(spacing: 6) {
                // Custom — tap to select, tap again (or long press) to edit
                Button {
                    if amount == min(customAmount, balance) {
                        Haptics.medium()
                        withAnimation(.easeOut(duration: 0.25)) {
                            isEditingCustom = true
                        }
                    } else {
                        let clamped = min(customAmount, balance)
                        if clamped >= 10 {
                            amount = clamped
                        }
                    }
                } label: {
                    VStack(spacing: 1) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(amount == customAmount ? .black.opacity(0.6) : CasinoTheme.accent)
                        Text("\(min(customAmount, balance))")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(amount == customAmount ? .black : CasinoTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(amount == customAmount ? Color.white : CasinoTheme.bgElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                amount == customAmount ? Color.clear : CasinoTheme.accent.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                        Haptics.medium()
                        withAnimation(.easeOut(duration: 0.25)) {
                            isEditingCustom = true
                        }
                    }
                )

                BetChip(label: "All In", sublabel: "\(balance)", selected: amount == balance) {
                    amount = balance
                }
            }
        }
    }

    private var buyInRow: some View {
        Button(action: onBuyIn) {
            Text("Buy In · \(amount)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white)
                )
        }
        .buttonStyle(.plain)
        .disabled(amount > balance)
        .opacity(amount > balance ? 0.4 : 1.0)
    }

    // MARK: - Custom Input

    private var customInput: some View {
        VStack(spacing: 10) {
            // Display
            HStack {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isEditingCustom = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CasinoTheme.textTertiary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(customText.isEmpty ? "0" : customText)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())

                Spacer()

                Button {
                    applyCustom()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.white))
                }
                .buttonStyle(.plain)
            }

            Text("min 10 · max \(balance)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(CasinoTheme.textTertiary)

            // Numpad
            numpad
        }
        .onAppear {
            customText = ""
        }
    }

    private var numpad: some View {
        let keys: [[String]] = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["C", "0", "⌫"]
        ]

        return VStack(spacing: 6) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            handleKey(key)
                        } label: {
                            Text(key)
                                .font(.system(size: 20, weight: .medium, design: .monospaced))
                                .foregroundColor(key == "C" ? CasinoTheme.danger : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(CasinoTheme.bgElevated)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func handleKey(_ key: String) {
        Haptics.tick()
        switch key {
        case "C":
            customText = ""
        case "⌫":
            if !customText.isEmpty {
                customText.removeLast()
            }
        default:
            if customText == "0" {
                customText = key
            } else {
                customText += key
            }
        }
    }

    private func applyCustom() {
        if let val = Int(customText), val >= 10, val <= balance {
            customAmount = val
            amount = val
            SettingsStore.customBetAmount = val
        }
        withAnimation(.easeOut(duration: 0.25)) {
            isEditingCustom = false
        }
    }
}

// MARK: - Bet Chip

struct BetChip: View {
    let label: String
    var sublabel: String? = nil
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(selected ? .black : CasinoTheme.textSecondary)
                if let sub = sublabel {
                    Text(sub)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(selected ? .black.opacity(0.6) : CasinoTheme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selected ? Color.white : CasinoTheme.bgElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        selected ? Color.clear : CasinoTheme.border,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
