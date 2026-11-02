import Foundation

/// SplitMix64. Our own shuffle on top of it, because the standard library's
/// shuffle algorithm may change between OS versions and the daily board must not.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// 0..<n
    mutating func int(_ n: Int) -> Int {
        Int(next() % UInt64(n))
    }

    mutating func shuffle<T>(_ items: inout [T]) {
        guard items.count > 1 else { return }
        for i in stride(from: items.count - 1, to: 0, by: -1) {
            items.swapAt(i, int(i + 1))
        }
    }

    mutating func shuffled<T>(_ items: [T]) -> [T] {
        var copy = items
        shuffle(&copy)
        return copy
    }
}
