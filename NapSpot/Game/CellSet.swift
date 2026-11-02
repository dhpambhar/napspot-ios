import Foundation

/// A set of board cells (0..<128) as two words. Boards are at most 10×10.
struct CellSet: Hashable, Sendable {
    private(set) var lo: UInt64 = 0
    private(set) var hi: UInt64 = 0

    init() {}

    init<S: Sequence>(_ cells: S) where S.Element == Int {
        for cell in cells { insert(cell) }
    }

    static let empty = CellSet()

    var isEmpty: Bool { lo == 0 && hi == 0 }
    var count: Int { lo.nonzeroBitCount + hi.nonzeroBitCount }

    func contains(_ cell: Int) -> Bool {
        cell < 64 ? lo & (1 << UInt64(cell)) != 0 : hi & (1 << UInt64(cell - 64)) != 0
    }

    mutating func insert(_ cell: Int) {
        if cell < 64 { lo |= 1 << UInt64(cell) } else { hi |= 1 << UInt64(cell - 64) }
    }

    mutating func remove(_ cell: Int) {
        if cell < 64 { lo &= ~(1 << UInt64(cell)) } else { hi &= ~(1 << UInt64(cell - 64)) }
    }

    func union(_ other: CellSet) -> CellSet {
        var s = self
        s.lo |= other.lo
        s.hi |= other.hi
        return s
    }

    func intersection(_ other: CellSet) -> CellSet {
        var s = self
        s.lo &= other.lo
        s.hi &= other.hi
        return s
    }

    func subtracting(_ other: CellSet) -> CellSet {
        var s = self
        s.lo &= ~other.lo
        s.hi &= ~other.hi
        return s
    }

    func isSubset(of other: CellSet) -> Bool {
        lo & ~other.lo == 0 && hi & ~other.hi == 0
    }

    func intersects(_ other: CellSet) -> Bool {
        lo & other.lo != 0 || hi & other.hi != 0
    }

    var first: Int? {
        if lo != 0 { return lo.trailingZeroBitCount }
        if hi != 0 { return 64 + hi.trailingZeroBitCount }
        return nil
    }

    /// Cells in ascending order.
    var cells: [Int] {
        var out: [Int] = []
        var w = lo
        while w != 0 {
            out.append(w.trailingZeroBitCount)
            w &= w - 1
        }
        w = hi
        while w != 0 {
            out.append(64 + w.trailingZeroBitCount)
            w &= w - 1
        }
        return out
    }
}
