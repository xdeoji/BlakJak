import SwiftUI

struct GameControlsView: View {
    @ObservedObject var gameVM: GameViewModel
    @ObservedObject var walletVM: WalletViewModel
    @State private var confirmAction: ConfirmableAction?

    enum ConfirmableAction {
        case hit, double
    }

    private var needsConfirm: Bool {
        SettingsStore.riskyActionConfirm && gameVM.activeHand.value >= 17
    }

    var body: some View {
        VStack(spacing: 10) {
            // Confirmation banner
            if let action = confirmAction {
                confirmBanner(action: action)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                // Normal controls
                actionButtons
            }
        }
        .animation(.easeOut(duration: 0.2), value: confirmAction == nil)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            gameButton(title: "Hit", enabled: BlackjackRules.canHit(gameVM.activeHand)) {
                if needsConfirm {
                    Haptics.warning()
                    confirmAction = .hit
                } else {
                    gameVM.hit()
                }
            }

            gameButton(title: "Stand", enabled: true) {
                gameVM.stand()
            }

            if BlackjackRules.canDouble(gameVM.activeHand)
                && !gameVM.isDoubledDown[gameVM.activeHandIndex]
                && walletVM.canAfford(gameVM.betAmount) {
                gameButton(title: "Double", enabled: true) {
                    if needsConfirm {
                        Haptics.warning()
                        confirmAction = .double
                    } else {
                        gameVM.doubleDown()
                    }
                }
            }

            if BlackjackRules.canSplit(gameVM.activeHand)
                && gameVM.playerHands.count < GameViewModel.maxHands
                && walletVM.canAfford(gameVM.betAmount) {
                gameButton(title: "Split", enabled: true) {
                    gameVM.split()
                }
            }
        }
    }

    private func confirmBanner(action: ConfirmableAction) -> some View {
        let actionName = action == .hit ? "Hit" : "Double"
        let handValue = gameVM.activeHand.value

        return VStack(spacing: 10) {
            Text("\(actionName) on \(handValue)?")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                Button {
                    confirmAction = nil
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(CasinoTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(CasinoTheme.bgElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(CasinoTheme.border, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)

                Button {
                    confirmAction = nil
                    switch action {
                    case .hit: gameVM.hit()
                    case .double: gameVM.doubleDown()
                    }
                } label: {
                    Text("Confirm")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(CasinoTheme.danger)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func gameButton(title: String, enabled: Bool,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(enabled ? .white : CasinoTheme.textTertiary)
                .frame(maxWidth: .infinity)
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
        .disabled(!enabled)
    }
}
