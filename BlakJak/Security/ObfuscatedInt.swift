import Foundation

/// XOR-obfuscated integer — the real value is never stored as a plain Int in memory.
/// Defeats memory-scanning tools (e.g. GameGuardian) that search RAM for known values.
/// A fresh random XOR mask is generated on every assignment, so the same value
/// looks different in memory each time it's written.
struct ObfuscatedInt {
    private let key: Int
    private let store: Int  // value ^ key

    init(_ value: Int = 0) {
        var k = Int.random(in: Int.min...Int.max)
        if k == 0 { k = 0x5A5A5A5A }  // avoid XOR identity
        key = k
        store = value ^ k
    }

    var value: Int { store ^ key }
}

extension ObfuscatedInt: Equatable {
    static func == (lhs: ObfuscatedInt, rhs: ObfuscatedInt) -> Bool {
        lhs.value == rhs.value
    }
}
