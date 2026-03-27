import SwiftUI

struct GameControlsView: View {
    @ObservedObject var gameVM: GameViewModel

    var body: some View {
        HStack(spacing: 12) {
            gameButton(title: "Hit", enabled: BlackjackRules.canHit(gameVM.activeHand)) {
                gameVM.hit()
            }

            gameButton(title: "Stand", enabled: true) {
                gameVM.stand()
            }

            if BlackjackRules.canDouble(gameVM.activeHand) && !gameVM.isDoubledDown[gameVM.activeHandIndex] {
                gameButton(title: "Double", enabled: true) {
                    gameVM.doubleDown()
                }
            }

            if BlackjackRules.canSplit(gameVM.activeHand) && gameVM.playerHands.count < GameViewModel.maxHands {
                gameButton(title: "Split", enabled: true) {
                    gameVM.split()
                }
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
