import Foundation

// MARK: - Integration Instructions
//
// Replace the stub below with a real rewarded ad SDK:
//
// AppLovin MAX (recommended):
//   1. Add AppLovin-MAX-Swift-Package via SPM: https://github.com/AppLovin/AppLovin-MAX-Swift-Package
//   2. Add your SDK key to Info.plist under "AppLovinSdkKey"
//   3. Call ALSdk.shared().mediationProvider = "max" and ALSdk.shared().initializeSdk() in BlakJakApp
//   4. Replace loadAd() with MARewardedAd(adUnitIdentifier: adUnitId) setup
//   5. Replace showAd() with rewardedAd.show()
//
// Google AdMob:
//   1. Add GoogleMobileAdsSdkiOS via SPM: https://github.com/googleads/swift-package-manager-google-mobile-ads
//   2. Add GADApplicationIdentifier to Info.plist
//   3. Replace loadAd() with GADRewardedAd.load(...)
//   4. Replace showAd() with rewardedAd?.present(fromRootViewController:userDidEarnRewardHandler:)

@MainActor
class RewardedAdManager: ObservableObject {
    static let shared = RewardedAdManager()

    static let chipReward = 100

    @Published var isAdAvailable = false  // disabled until AppLovin MAX is integrated
    @Published var isLoadingAd = false

    func showAd(onReward: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        // STUB — replace with real SDK call
        // The stub grants the reward immediately after a short delay.
        isAdAvailable = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            onReward()
            onDismiss()
            // Simulate a reload delay before next ad is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                self?.isAdAvailable = true
            }
        }
    }
}
