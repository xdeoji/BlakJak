import SwiftUI

struct BetPicker: View {
    @Binding var amount: Int
    let balance: Int
    let onBuyIn: () -> Void

    @State private var isCustom = false
    @State private var customText = ""
    @FocusState private var customFocused: Bool

    private var presets: [Int] {
        if balance >= 1000 {
            return [25, 100, 250]
        } else if balance >= 500 {
            return [25, 50, 100]
        } else if balance >= 100 {
            return [10, 25, 50]
        } else {
            return [10, 25, 50].filter { $0 <= balance }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isCustom {
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
        HStack(spacing: 8) {
            ForEach(presets, id: \.self) { preset in
                BetChip(label: "\(preset)", selected: amount == preset) {
                    amount = preset
                }
                .disabled(preset > balance)
                .opacity(preset > balance ? 0.3 : 1.0)
            }

            BetChip(label: "All In", selected: amount == balance) {
                amount = balance
            }
        }
    }

    private var buyInRow: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    isCustom = true
                }
            } label: {
                Text("\(amount)")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 80)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(CasinoTheme.bgElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(CasinoTheme.borderLight, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)

            Button(action: onBuyIn) {
                Text("Buy In · \(amount) pts")
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
    }

    // MARK: - Custom Input

    private var customInput: some View {
        VStack(spacing: 10) {
            // Display
            HStack {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isCustom = false
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
            // Prevent leading zeros and cap at 6 digits
            if customText == "0" {
                customText = key
            } else if customText.count < 6 {
                customText += key
            }
        }
    }

    private func applyCustom() {
        if let val = Int(customText), val >= 10, val <= balance {
            amount = val
        }
        withAnimation(.easeOut(duration: 0.25)) {
            isCustom = false
        }
    }
}

// MARK: - Bet Chip

struct BetChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(selected ? .black : CasinoTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
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
