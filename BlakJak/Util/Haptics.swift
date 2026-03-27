import UIKit
import AVFoundation

struct Haptics {
    private static let impact = {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.prepare()
        return gen
    }()

    private static let lightImpact = {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        return gen
    }()

    private static let heavyImpact = {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.prepare()
        return gen
    }()

    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()

    static func tap() { lightImpact.impactOccurred() }
    static func medium() { impact.impactOccurred() }
    static func heavy() { heavyImpact.impactOccurred() }
    static func success() { notification.notificationOccurred(.success) }
    static func error() { notification.notificationOccurred(.error) }
    static func warning() { notification.notificationOccurred(.warning) }
    static func tick() { selection.selectionChanged() }
}

// MARK: - Sound

final class SoundManager {
    static let shared = SoundManager()

    private var players: [String: AVAudioPlayer] = [:]
    private let volume: Float = 0.3

    private init() {
        // Set audio session to ambient so it mixes with other audio
        // and respects the hardware volume / silent switch
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        preloadSounds()
    }

    private func preloadSounds() {
        // Generate simple synthesized tones as WAV data
        players["cardDeal"] = tonePlayer(frequency: 800, duration: 0.04)
        players["cardFlip"] = tonePlayer(frequency: 600, duration: 0.06)
        players["chipTap"] = tonePlayer(frequency: 1000, duration: 0.03)
        players["win"] = tonePlayer(frequency: 880, duration: 0.15)
        players["lose"] = tonePlayer(frequency: 220, duration: 0.15)
        players["push"] = tonePlayer(frequency: 440, duration: 0.08)
        players["buyIn"] = tonePlayer(frequency: 660, duration: 0.08)
        players["streak"] = tonePlayer(frequency: 1100, duration: 0.2)
    }

    private func play(_ name: String) {
        guard let player = players[name] else { return }
        player.volume = volume
        player.currentTime = 0
        player.play()
    }

    func cardDeal() { play("cardDeal") }
    func cardFlip() { play("cardFlip") }
    func chipTap() { play("chipTap") }
    func win() { play("win") }
    func lose() { play("lose") }
    func push() { play("push") }
    func buyIn() { play("buyIn") }
    func streak() { play("streak") }

    // MARK: - Tone Generator

    private func tonePlayer(frequency: Double, duration: Double) -> AVAudioPlayer? {
        let sampleRate = 44100.0
        let samples = Int(sampleRate * duration)
        var data = Data()

        // WAV header
        let dataSize = samples * 2
        let fileSize = 36 + dataSize
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // PCM
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // mono
        data.append(contentsOf: withUnsafeBytes(of: UInt32(44100).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(88200).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) })
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        // Generate sine wave with fade-out envelope
        for i in 0..<samples {
            let t = Double(i) / sampleRate
            let envelope = 1.0 - (Double(i) / Double(samples)) // linear fade out
            let sample = sin(2.0 * .pi * frequency * t) * envelope * 0.4
            let intSample = Int16(clamping: Int(sample * 32767.0))
            data.append(contentsOf: withUnsafeBytes(of: intSample.littleEndian) { Array($0) })
        }

        return try? AVAudioPlayer(data: data)
    }
}
