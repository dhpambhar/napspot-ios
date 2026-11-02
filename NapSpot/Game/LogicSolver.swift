import Foundation

/// The deductions a person makes, easiest first. The raw value is the difficulty.
enum Technique: Int, Comparable, Sendable, Codable {
    /// A row, column or region has one open cell left.
    case single = 1
    /// All open cells of one group sit inside another group, so the rest of that group is out.
    case confinement
    /// A cat here would leave some group with nowhere to go.
    case touch
    /// k regions squeezed into k rows (or the reverse) own those rows.
    case pigeonhole

    static func < (a: Technique, b: Technique) -> Bool { a.rawValue < b.rawValue }
}

/// One step of reasoning: either a cat that must go somewhere, or cells that can't hold one.
struct Deduction: Equatable, Sendable {
    let technique: Technique
    let placement: Int?
    let exclusions: [Int]
    /// The groups the reasoning is about, for highlighting and the hint text.
    let groups: [Geometry.Group]
    /// Pigeonhole: which lines the groups are squeezed into.
    let lines: [Geometry.Group]
}

struct SolverState: Equatable, Sendable {
    var cats = CellSet()
    /// Cells that may still hold a cat (no cat, not ruled out).
    var open: CellSet

    init(open: CellSet) {
        self.open = open
    }
}

struct LogicSolver: Sendable {
    let geometry: Geometry

    init(_ geometry: Geometry) {
        self.geometry = geometry
    }

    struct Result: Sendable {
        let solved: Bool
        let hardest: Technique?
        let steps: Int
        let state: SolverState
    }

    func place(_ cell: Int, in state: inout SolverState) {
        state.cats.insert(cell)
        state.open.remove(cell)
        state.open = state.open.subtracting(geometry.blockers[cell])
    }

    func apply(_ step: Deduction, to state: inout SolverState) {
        if let cell = step.placement {
            place(cell, in: &state)
        } else {
            for cell in step.exclusions { state.open.remove(cell) }
        }
    }

    /// Solves from the givens using logic only. `solved` means the answer is unique.
    func solve(givens: [Int] = []) -> Result {
        var state = SolverState(open: geometry.all)
        for cell in givens { place(cell, in: &state) }
        var hardest: Technique?
        var steps = 0
        while state.cats.count < geometry.size {
            guard let step = nextDeduction(in: state) else {
                return Result(solved: false, hardest: hardest, steps: steps, state: state)
            }
            hardest = max(hardest ?? step.technique, step.technique)
            steps += 1
            apply(step, to: &state)
        }
        return Result(solved: true, hardest: hardest, steps: steps, state: state)
    }

    /// The easiest next step, or nil if logic is stuck or the state is contradictory.
    func nextDeduction(in state: SolverState) -> Deduction? {
        let live = geometry.groups.indices.filter { !geometry.groupCells[$0].intersects(state.cats) }
        let openOf = live.map { geometry.groupCells[$0].intersection(state.open) }

        // Single
        for (i, g) in live.enumerated() {
            let open = openOf[i]
            if open.isEmpty { return nil }
            if open.count == 1, let cell = open.first {
                return Deduction(technique: .single, placement: cell, exclusions: [],
                                 groups: [geometry.groups[g]], lines: [])
            }
        }

        // Confinement
        for (i, a) in live.enumerated() {
            for (j, b) in live.enumerated() where i != j && geometry.groups[a].kind != geometry.groups[b].kind {
                guard openOf[i].isSubset(of: geometry.groupCells[b]) else { continue }
                let out = openOf[j].subtracting(openOf[i])
                if !out.isEmpty {
                    return Deduction(technique: .confinement, placement: nil, exclusions: out.cells,
                                     groups: [geometry.groups[a]], lines: [geometry.groups[b]])
                }
            }
        }

        // Touch
        for cell in state.open.cells {
            let blocked = geometry.blockers[cell]
            for (i, g) in live.enumerated() where !geometry.groupCells[g].contains(cell) {
                if openOf[i].isSubset(of: blocked) {
                    return Deduction(technique: .touch, placement: nil, exclusions: [cell],
                                     groups: [geometry.groups[g]], lines: [])
                }
            }
        }

        // Pigeonhole
        let pairs: [(Geometry.Kind, Geometry.Kind)] = [(.region, .row), (.region, .col), (.row, .region),
                                                       (.col, .region), (.row, .col), (.col, .row)]
        for (kindA, kindB) in pairs {
            let a = live.indices.filter { geometry.groups[live[$0]].kind == kindA }
            let b = live.indices.filter { geometry.groups[live[$0]].kind == kindB }
            guard a.count >= 3 else { continue }
            // Which B-lines each A-group touches, as a bitmask over b.
            let masks: [Int] = a.map { ai in
                var m = 0
                for (bi, bIndex) in b.enumerated() where openOf[ai].intersects(geometry.groupCells[live[bIndex]]) {
                    m |= 1 << bi
                }
                return m
            }
            for subset in 1..<(1 << a.count) {
                let k = subset.nonzeroBitCount
                guard k >= 2, k < a.count else { continue }
                var lineMask = 0
                var inside = CellSet()
                for bit in 0..<a.count where subset & (1 << bit) != 0 {
                    lineMask |= masks[bit]
                    inside = inside.union(openOf[a[bit]])
                }
                guard lineMask.nonzeroBitCount == k else { continue }
                var out = CellSet()
                var lineGroups: [Geometry.Group] = []
                for (bi, bIndex) in b.enumerated() where lineMask & (1 << bi) != 0 {
                    out = out.union(openOf[bIndex])
                    lineGroups.append(geometry.groups[live[bIndex]])
                }
                out = out.subtracting(inside)
                if !out.isEmpty {
                    let groups = (0..<a.count).filter { subset & (1 << $0) != 0 }.map { geometry.groups[live[a[$0]]] }
                    return Deduction(technique: .pigeonhole, placement: nil, exclusions: out.cells,
                                     groups: groups, lines: lineGroups)
                }
            }
        }
        return nil
    }
}

/// Counts answers by trying every placement, row by row. Stops at `limit`.
enum BruteSolver {
    static func countSolutions(size n: Int, regions: [Int], limit: Int = 2) -> Int {
        var count = 0
        var usedCols = 0
        var usedRegions = 0
        func go(_ r: Int, _ prev: Int) {
            if count >= limit { return }
            if r == n {
                count += 1
                return
            }
            for c in 0..<n {
                let k = regions[r * n + c]
                if usedCols & (1 << c) != 0 || usedRegions & (1 << k) != 0 { continue }
                if r > 0, abs(prev - c) < 2 { continue }
                usedCols |= 1 << c
                usedRegions |= 1 << k
                go(r + 1, c)
                usedCols &= ~(1 << c)
                usedRegions &= ~(1 << k)
            }
        }
        go(0, -10)
        return count
    }
}
