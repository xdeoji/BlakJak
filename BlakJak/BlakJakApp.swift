import SwiftUI

@main
struct BlakJakApp: App {
    @State private var showOnboarding = !SettingsStore.hasOnboarded

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
    }
}
