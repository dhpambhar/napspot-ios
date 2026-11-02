import Foundation

/// One board: an N×N grid split into N regions, with exactly one answer.
struct Puzzle: Equatable, Codable, Sendable {
    let size: Int
    /// Region index per cell, row-major.
    let regions: [Int]
    /// Column of the cat in each row.
    let solution: [Int]
    /// Cats placed for free at the start.
    let givens: [Int]
    /// Hardest technique the logic solver needed (1...4).
    let difficulty: Int

    var cellCount: Int { size * size }

    func row(_ cell: Int) -> Int { cell / size }
    func col(_ cell: Int) -> Int { cell % size }
    func cell(row: Int, col: Int) -> Int { row * size + col }
    func region(_ cell: Int) -> Int { regions[cell] }

    func isSolution(_ cell: Int) -> Bool { solution[row(cell)] == col(cell) }

    var solutionCells: [Int] { solution.enumerated().map { cell(row: $0.offset, col: $0.element) } }
}

/// What a board's shape implies, precomputed once per board.
struct Geometry: Sendable {
    enum Kind: Int, Sendable, Codable { case row, col, region }

    struct Group: Hashable, Sendable, Codable {
        let kind: Kind
        let index: Int
    }

    let size: Int
    let regions: [Int]
    /// Rows, then columns, then regions.
    let groups: [Group]
    let groupCells: [CellSet]
    /// The cells a cat on this cell rules out: its row, column, region and neighbours.
    let blockers: [CellSet]
    let all: CellSet

    init(size: Int, regions: [Int]) {
        self.size = size
        self.regions = regions
        var groups: [Group] = []
        var sets: [CellSet] = []
        for r in 0..<size {
            groups.append(Group(kind: .row, index: r))
            sets.append(CellSet((0..<size).map { r * size + $0 }))
        }
        for c in 0..<size {
            groups.append(Group(kind: .col, index: c))
            sets.append(CellSet((0..<size).map { $0 * size + c }))
        }
        var regionSets = Array(repeating: CellSet(), count: size)
        for (cell, k) in regions.enumerated() { regionSets[k].insert(cell) }
        for k in 0..<size {
            groups.append(Group(kind: .region, index: k))
            sets.append(regionSets[k])
        }
        self.groups = groups
        groupCells = sets
        all = CellSet(0..<(size * size))

        var blockers: [CellSet] = []
        for cell in 0..<(size * size) {
            let r = cell / size, c = cell % size
            var s = sets[r].union(sets[size + c]).union(regionSets[regions[cell]])
            for dr in -1...1 {
                for dc in -1...1 {
                    let rr = r + dr, cc = c + dc
                    if rr >= 0, cc >= 0, rr < size, cc < size { s.insert(rr * size + cc) }
                }
            }
            s.remove(cell)
            blockers.append(s)
        }
        self.blockers = blockers
    }

    init(_ puzzle: Puzzle) {
        self.init(size: puzzle.size, regions: puzzle.regions)
    }

    func cells(of group: Group) -> CellSet {
        switch group.kind {
        case .row: groupCells[group.index]
        case .col: groupCells[size + group.index]
        case .region: groupCells[2 * size + group.index]
        }
    }
}
