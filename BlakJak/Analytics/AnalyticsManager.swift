import Foundation

/// Lightweight analytics manager.
///
/// Events are written to a local JSONL queue at Documents/blakjak_events.jsonl.
/// Each line is a self-contained JSON object — safe to tail, grep, or bulk-upload.
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
    private var sessionNetChips: Int = 0   // running PnL

    // MARK: - Local queue

    private lazy var queueURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("blakjak_events.jsonl")
    }()

    private init() {}

    // MARK: - Session lifecycle

    func startSession(balance: Int) {
        sessionID = UUID().uuidString
        sessionStartTime = Date()
        sessionStartBalance = balance
        sessionHandsPlayed = 0
        sessionHandsSkipped = 0
        sessionNetChips = 0

        // POSTHOG: PostHogSDK.shared.setup(PostHogConfig(apiKey: "YOUR_KEY", host: "https://app.posthog.com"))
    }

    func endSession(balance: Int) {
        let duration = Int(Date().timeIntervalSince(sessionStartTime))
        let pnl = balance - sessionStartBalance

        enqueue("session_ended", props: [
            "session_id": sessionID,
            "duration_seconds": duration,
            "hands_played": sessionHandsPlayed,
            "hands_skipped": sessionHandsSkipped,
            "session_pnl": pnl,
            "start_balance": sessionStartBalance,
            "end_balance": balance
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
            "win_probability": round(hand.winProbability * 1000) / 10,  // e.g. 62.3
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

    // MARK: - Queue

    private func enqueue(_ name: String, props: [String: Any]) {
        var payload = props
        payload["event"] = name
        payload["ts"] = ISO8601DateFormatter().string(from: Date())

        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let line = String(data: data, encoding: .utf8) else { return }

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

        // POSTHOG: PostHogSDK.shared.capture(name, properties: props.mapValues { AnyCodable($0) })
    }
}
