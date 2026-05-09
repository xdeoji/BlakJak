import Foundation
import CryptoKit
import PostHog

/// Lightweight analytics manager.
///
/// Events are written to a local JSONL queue at Library/Application Support/blakjak_events.jsonl.
/// Each line is a self-contained JSON object — safe to tail, grep, or bulk-upload.
///
/// Each event includes a `seq` counter and a `prev_hash` (SHA256 of the previous line's raw JSON).
/// Editing, deleting, or reordering any event breaks the chain, detectable on upload.
///
/// PostHog integration: add the PostHog iOS SDK via Xcode → File → Add Package Dependencies.
/// Then search for each `// POSTHOG:` comment and uncomment the relevant line.
///
///   import PostHog                                          // POSTHOG: uncomment
///   PostHogSDK.shared.setup(PostHogConfig(apiKey: "YOUR_KEY", host: "https://app.posthog.com"))   // POSTHOG: in startSession
///   PostHogSDK.shared.capture(name, properties: props)     // POSTHOG: in enqueue()

final class AnalyticsManager {
    static let shared = AnalyticsManager()

    // MARK: - Session state

    private(set) var sessionID: String = UUID().uuidString
    private var sessionStartTime: Date = Date()
    private var sessionStartBalance: Int = 0
    private var sessionHandsPlayed: Int = 0
    private var sessionHandsSkipped: Int = 0
    private var sessionNetChips: Int = 0

    // MARK: - Chain state

    private var seq: Int = 0
    private var prevHash: String = ""   // SHA256 of the previous event's raw JSON line

    // MARK: - Local queue

    private lazy var queueURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        return support.appendingPathComponent("blakjak_events.jsonl")
    }()

    private let appVersion: String = {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }()

    private init() {
        let config = PostHogConfig(projectToken: "phc_uJt57srN8moQyzpypA2XdofWCRrJChNcbcZCFozmB8pd",
                                   host: "https://us.i.posthog.com")
        config.flushAt = 1
        config.flushIntervalSeconds = 5
        config.captureApplicationLifecycleEvents = false
        config.captureScreenViews = false
        PostHogSDK.shared.setup(config)
    }

    // MARK: - Session lifecycle

    func startSession(balance: Int) {
        sessionID = UUID().uuidString
        sessionStartTime = Date()
        sessionStartBalance = balance
        sessionHandsPlayed = 0
        sessionHandsSkipped = 0
        sessionNetChips = 0
        seq = 0
        prevHash = sessionID   // chain is seeded with the session ID
    }

    func endSession(balance: Int) {
        let duration = Int(Date().timeIntervalSince(sessionStartTime))
        let pnl = balance - sessionStartBalance
        let tamperFlags = IntegrityMonitor.tamperFlags

        enqueue("session_ended", props: [
            "session_id": sessionID,
            "duration_seconds": duration,
            "hands_played": sessionHandsPlayed,
            "hands_skipped": sessionHandsSkipped,
            "session_pnl": pnl,
            "start_balance": sessionStartBalance,
            "end_balance": balance,
            "is_jailbroken": IntegrityMonitor.isJailbroken,
            "clock_rollback": IntegrityMonitor.hasClockRollback,
            "tamper_flags": tamperFlags.joined(separator: ",")
        ])
    }

    // MARK: - Hand events

    func trackHandSkipped(hand: BlackjackHand, consecutiveSkips: Int) {
        sessionHandsSkipped += 1

        enqueue("hand_skipped", props: [
            "session_id": sessionID,
            "hand_feed_index": hand.feedIndex,
            "hand_lifetime_index": hand.lifetimeIndex,
            "consecutive_skips": consecutiveSkips,
            "player_total": hand.playerTotal,
            "player_is_soft": hand.playerIsSoft,
            "dealer_upcard": hand.dealerUpcard.rank.rawValue,
            "win_probability": round(hand.winProbability * 1000) / 10,
            "multiplier": hand.multiplier
        ])
    }

    func trackHandStarted(hand: BlackjackHand, betAmount: Int, balance: Int,
                          consecutiveSkipsBefore: Int, returnedToSkipped: Bool) {
        enqueue("hand_started", props: [
            "session_id": sessionID,
            "hand_feed_index": hand.feedIndex,
            "hand_lifetime_index": hand.lifetimeIndex,
            "bet_amount": betAmount,
            "balance_before": balance,
            "consecutive_skips_before": consecutiveSkipsBefore,
            "returned_to_skipped": returnedToSkipped,
            "player_total": hand.playerTotal,
            "player_is_soft": hand.playerIsSoft,
            "dealer_upcard": hand.dealerUpcard.rank.rawValue,
            "win_probability": round(hand.winProbability * 1000) / 10,
            "multiplier": hand.multiplier
        ])
    }

    func trackHandCompleted(hand: BlackjackHand, betAmount: Int, netChips: Int,
                            outcome: String, actions: [String]) {
        sessionHandsPlayed += 1
        sessionNetChips += netChips

        enqueue("hand_completed", props: [
            "session_id": sessionID,
            "hand_feed_index": hand.feedIndex,
            "hand_lifetime_index": hand.lifetimeIndex,
            "bet_amount": betAmount,
            "net_chips": netChips,
            "outcome": outcome,
            "actions": actions.joined(separator: ","),
            "action_count": actions.count,
            "player_total": hand.playerTotal,
            "player_is_soft": hand.playerIsSoft,
            "dealer_upcard": hand.dealerUpcard.rank.rawValue,
            "win_probability": round(hand.winProbability * 1000) / 10,
            "multiplier": hand.multiplier
        ])
    }

    // MARK: - Monetization events

    func trackChipsPurchased(productID: String, chips: Int, balanceBefore: Int) {
        enqueue("chips_purchased", props: [
            "session_id": sessionID,
            "product_id": productID,
            "chips": chips,
            "balance_before": balanceBefore
        ])
    }

    func trackBonusClaimed(chips: Int, balance: Int) {
        enqueue("bonus_claimed", props: [
            "session_id": sessionID,
            "chips": chips,
            "balance_after": balance
        ])
    }

    // MARK: - Queue

    private func enqueue(_ name: String, props: [String: Any]) {
        seq += 1
        var payload = props
        payload["event"] = name
        payload["ts"] = ISO8601DateFormatter().string(from: Date())
        payload["seq"] = seq
        payload["prev_hash"] = prevHash
        payload["app_version"] = appVersion

        // Stable sort keys so the serialized string is deterministic
        guard let data = try? JSONSerialization.data(withJSONObject: payload,
                                                     options: .sortedKeys),
              let line = String(data: data, encoding: .utf8) else { return }

        // Hash this event's JSON — becomes prev_hash for the next event
        prevHash = sha256(line)

        let entry = line + "\n"

        if FileManager.default.fileExists(atPath: queueURL.path) {
            if let handle = try? FileHandle(forWritingTo: queueURL) {
                handle.seekToEndOfFile()
                handle.write(entry.data(using: .utf8) ?? Data())
                try? handle.close()
            }
        } else {
            try? entry.write(to: queueURL, atomically: true, encoding: .utf8)
        }

        PostHogSDK.shared.capture(name, properties: props as [String: Any])
    }

    private func sha256(_ string: String) -> String {
        let digest = SHA256.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
