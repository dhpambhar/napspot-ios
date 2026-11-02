import Foundation

/// Makes boards with exactly one answer that logic alone can reach.
///
/// 1. Place N cats: one per row and column, none touching.
/// 2. Grow one region around each cat.
/// 3. Hill-climb: move a border cell into a neighbouring region and keep the move
///    if the board didn't get more ambiguous. Done when the logic solver finishes it.
/// 4. After `maxRestarts` fresh starts, hand out solution cats as givens until it can.
enum Generator {
    static let maxRestarts = 30
    static let movesPerRestart = 1500
    /// Solution counting stops here; more than this only means "very ambiguous".
    static let countLimit = 40

    static func make(size n: Int, seed: UInt64, givens wanted: Int = 0) -> Puzzle {
        var rng = SeededRandom(seed: seed)
        var last: (regions: [Int], cols: [Int])?
        for _ in 0..<maxRestarts {
            let cols = solutionColumns(n, &rng)
            var regions = growRegions(n, cols, &rng)
            if climb(n, cols, &regions, &rng) {
                return finish(n, regions, cols, wanted, &rng)
            }
            last = (regions, cols)
        }
        // Rare (mostly 10×10): give away cats until logic can finish.
        let (regions, cols) = last!
        return finish(n, regions, cols, wanted, &rng)
    }

    // MARK: Steps

    static func solutionColumns(_ n: Int, _ rng: inout SeededRandom) -> [Int] {
        var cols = Array(repeating: 0, count: n)
        var used = Array(repeating: false, count: n)
        func go(_ r: Int) -> Bool {
            if r == n { return true }
            for c in rng.shuffled(Array(0..<n)) {
                if used[c] || (r > 0 && abs(cols[r - 1] - c) < 2) { continue }
                used[c] = true
                cols[r] = c
                if go(r + 1) { return true }
                used[c] = false
            }
            return false
        }
        _ = go(0)
        return cols
    }

    static func growRegions(_ n: Int, _ cols: [Int], _ rng: inout SeededRandom) -> [Int] {
        var regions = Array(repeating: -1, count: n * n)
        for r in 0..<n { regions[r * n + cols[r]] = r }
        var left = n * n - n
        while left > 0 {
            let k = rng.int(n)
            var options: [Int] = []
            for cell in 0..<(n * n) where regions[cell] == k {
                for nb in sideNeighbours(cell, n) where regions[nb] == -1 { options.append(nb) }
            }
            guard !options.isEmpty else { continue }
            regions[options[rng.int(options.count)]] = k
            left -= 1
        }
        return regions
    }

    /// Lower is better; 0 means one answer and logic reaches it.
    static func score(_ n: Int, _ regions: [Int]) -> Int {
        let count = BruteSolver.countSolutions(size: n, regions: regions, limit: countLimit)
        if count > 1 { return count * 1000 }
        let result = LogicSolver(Geometry(size: n, regions: regions)).solve()
        return result.solved ? 0 : 1 + result.state.open.count
    }

    static func climb(_ n: Int, _ cols: [Int], _ regions: inout [Int], _ rng: inout SeededRandom) -> Bool {
        let seeds = Set(cols.enumerated().map { $0.offset * n + $0.element })
        var current = score(n, regions)
        var moves = 0
        while current > 0 && moves < movesPerRestart {
            moves += 1
            let cell = rng.int(n * n)
            if seeds.contains(cell) { continue }
            let from = regions[cell]
            let targets = sideNeighbours(cell, n).map { regions[$0] }.filter { $0 != from }
            guard !targets.isEmpty, canGiveAway(cell, from: from, n, regions) else { continue }
            regions[cell] = targets[rng.int(targets.count)]
            let next = score(n, regions)
            if next <= current {
                current = next
            } else {
                regions[cell] = from
            }
        }
        return current == 0
    }

    static func finish(_ n: Int, _ regions: [Int], _ cols: [Int], _ wanted: Int,
                       _ rng: inout SeededRandom) -> Puzzle {
        let solver = LogicSolver(Geometry(size: n, regions: regions))
        let cats = cols.enumerated().map { $0.offset * n + $0.element }
        var givens: [Int] = []
        var order = rng.shuffled(cats)
        while givens.count < min(wanted, n - 1), let next = order.popLast() { givens.append(next) }
        var result = solver.solve(givens: givens)
        while !result.solved, let next = order.popLast() {
            givens.append(next)
            result = solver.solve(givens: givens)
        }
        return Puzzle(size: n, regions: regions, solution: cols, givens: givens.sorted(),
                      difficulty: result.hardest?.rawValue ?? 1)
    }

    // MARK: Helpers

    static func sideNeighbours(_ cell: Int, _ n: Int) -> [Int] {
        let r = cell / n, c = cell % n
        var out: [Int] = []
        if r > 0 { out.append(cell - n) }
        if r < n - 1 { out.append(cell + n) }
        if c > 0 { out.append(cell - 1) }
        if c < n - 1 { out.append(cell + 1) }
        return out
    }

    /// The region keeps at least two cells and stays in one piece without this cell.
    static func canGiveAway(_ cell: Int, from k: Int, _ n: Int, _ regions: [Int]) -> Bool {
        let rest = (0..<(n * n)).filter { regions[$0] == k && $0 != cell }
        guard rest.count >= 2 else { return false }
        var seen: Set<Int> = [rest[0]]
        var stack = [rest[0]]
        while let x = stack.popLast() {
            for nb in sideNeighbours(x, n) where nb != cell && regions[nb] == k && !seen.contains(nb) {
                seen.insert(nb)
                stack.append(nb)
            }
        }
        return seen.count == rest.count
    }

    /// Every region is one connected piece.
    static func regionsAreConnected(_ n: Int, _ regions: [Int]) -> Bool {
        for k in 0..<n {
            let cells = (0..<(n * n)).filter { regions[$0] == k }
            guard let start = cells.first else { return false }
            var seen: Set<Int> = [start]
            var stack = [start]
            while let x = stack.popLast() {
                for nb in sideNeighbours(x, n) where regions[nb] == k && !seen.contains(nb) {
                    seen.insert(nb)
                    stack.append(nb)
                }
            }
            if seen.count != cells.count { return false }
        }
        return true
    }
}
