import SwiftUI

@main
struct BlakJakApp: App {
    @State private var showOnboarding = !SettingsStore.hasOnboarded
    @State private var iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if !iCloudAvailable {
                iCloudRequiredView()
            } else if showOnboarding {
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
                // Re-check iCloud each time app becomes active — user may have signed in via Settings
                withAnimation(.easeOut(duration: 0.3)) {
                    iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
                }
                guard iCloudAvailable else { return }
                NSUbiquitousKeyValueStore.default.synchronize()
                IntegrityMonitor.checkClock()
                AnalyticsManager.shared.startSession(balance: WalletStore.balance)
            case .background:
                guard iCloudAvailable else { return }
                AnalyticsManager.shared.endSession(balance: WalletStore.balance)
            default:
                break
            }
        }
    }
}
