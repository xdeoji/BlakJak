import SwiftUI

@main
struct BlakJakApp: App {
    @State private var showOnboarding = !SettingsStore.hasOnboarded
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if showOnboarding {
                OnboardingView {
                    SettingsStore.hasOnboarded = true
                    withAnimation(.easeOut(duration: 0.4)) {
                        showOnboarding = false
                    }
                }
            } else {
                FeedView()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                AnalyticsManager.shared.startSession(balance: WalletStore.balance)
            case .background:
                AnalyticsManager.shared.endSession(balance: WalletStore.balance)
            default:
                break
            }
        }
    }
}
