import Foundation
import CryptoKit

struct IntegrityMonitor {

    enum TamperType: String {
        case balanceChecksum = "balance_checksum"
        case memoryPatch     = "memory_patch"
        case clockRollback   = "clock_rollback"
    }

    // MARK: - Jailbreak detection

    /// Checks common jailbreak indicators. Always false on simulator.
    static var isJailbroken: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // Presence of jailbreak-specific paths
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/usr/sbin/sshd",
            "/usr/bin/ssh",
            "/etc/apt",
            "/bin/bash",
            "/private/var/lib/apt/",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/usr/libexec/sftp-server",
            "/usr/lib/TweakInject.dylib",
        ]
        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) { return true }
        }
        // Can we write outside our sandbox?
        let probe = "/private/blakjak_jb_probe_\(Int.random(in: 0...999999))"
        do {
            try "x".write(toFile: probe, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: probe)
            return true
        } catch {}
        return false
        #endif
    }

    // MARK: - Clock rollback detection

    private static let lastTimestampKey = "blakjak_sec_last_ts"
    private static let rollbackFlagKey  = "blakjak_sec_rollback"

    /// Call on every app launch (active scene phase). Records the current time
    /// and sets the rollback flag if the clock has moved backwards by > 60 s.
    static func checkClock() {
        let now  = Date().timeIntervalSince1970
        let last = UserDefaults.standard.double(forKey: lastTimestampKey)

        if last > 0 && now < last - 60 {
            UserDefaults.standard.set(true, forKey: rollbackFlagKey)
            flagTamper(.clockRollback)
        }
        UserDefaults.standard.set(now, forKey: lastTimestampKey)
    }

    static var hasClockRollback: Bool {
        UserDefaults.standard.bool(forKey: rollbackFlagKey)
    }

    // MARK: - Tamper flag log

    private static let tamperFlagsKey = "blakjak_sec_tamper_flags"

    static func flagTamper(_ type: TamperType) {
        var flags = UserDefaults.standard.stringArray(forKey: tamperFlagsKey) ?? []
        if !flags.contains(type.rawValue) {
            flags.append(type.rawValue)
            UserDefaults.standard.set(flags, forKey: tamperFlagsKey)
        }
    }

    static var tamperFlags: [String] {
        UserDefaults.standard.stringArray(forKey: tamperFlagsKey) ?? []
    }

    // MARK: - Balance checksum

    private static let salt = "blakjak_v1_wallet"
    private static let deviceKeyKeychainKey = "blakjak_stable_device_key"

    /// A stable device identifier stored in the Keychain.
    /// Unlike identifierForVendor, this survives reinstalls and never returns nil.
    static var stableDeviceKey: String {
        if let existing = KeychainHelper.read(deviceKeyKeychainKey) { return existing }
        let new = UUID().uuidString
        KeychainHelper.write(new, for: deviceKeyKeychainKey)
        return new
    }

    static func checksum(for balance: Int) -> String {
        let raw = "\(balance):\(stableDeviceKey):\(salt)"
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
