import Foundation
import Security

/// Minimal Keychain wrapper for storing small string values.
/// Keychain persists across app reinstalls (unlike UserDefaults), making it
/// suitable for stable device identifiers.
struct KeychainHelper {

    static func read(_ key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func write(_ value: String, for key: String) -> Bool {
        let data = Data(value.utf8)
        // Try update first, then add
        let updateQuery: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        let attrs: [CFString: Any] = [kSecValueData: data]
        if SecItemUpdate(updateQuery as CFDictionary, attrs as CFDictionary) == errSecSuccess {
            return true
        }
        let addQuery: [CFString: Any] = [
            kSecClass:                  kSecClassGenericPassword,
            kSecAttrAccount:            key,
            kSecAttrAccessible:         kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData:              data
        ]
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }
}
