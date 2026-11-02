import Foundation
import Observation

enum Mark: Int, Codable, Sendable {
    case empty, x, cat
}

enum GameMode: Hashable, Codable, Sendable {
    case level(Int)
    case daily(Int)

    var key: String {
        switch self {
        case .level(let n): "level-\(n)"
        case .daily(let d): "daily-\(d)"
        }
    }
}

/// A board in progress, as saved when you leave it.
struct SavedGame: Codable, Equatable {
    let mode: GameMode
    let marks: [Mark]
    let hearts: Int
    let elapsed: TimeInterval
    let mistakes: Int
    let hintsUsed: Int
}

/// A hint, ready to show: what changed and why.
struct Hint: Equatable {
    enum Reason: Equatable {
        /// An X sits where a cat belongs.
        case wrongX
        /// Empty cells that a placed cat already rules out.
        case cleanup(cat: Int)
        case logic(Deduction)
    }

    let reason: Reason
    /// Cells the hint changed.
    let cells: [Int]
    /// Cells to highlight while the hint is shown.
    let focus: [Int]
}

@MainActor
@Observable
final class GameModel {
    enum Status: Equatable {
        case playing, won, lost
    }

    static let startingHearts = 3

    let puzzle: Puzzle
    let mode: GameMode
    let geometry: Geometry

    private(set) var marks: [Mark]
    private(set) var hearts: Int
    private(set) var mistakes: Int
    private(set) var hintsUsed: Int
    private(set) var status: Status = .playing
    /// Bumps on every wrong cat so the view can shake.
    private(set) var wrongTick = 0
    private(set) var wrongCell: Int?
    private(set) var hint: Hint?
    /// Mark X around a cat automatically.
    var autoX = true

    private var history: [[Mark]] = []
    private var accumulated: TimeInterval
    private var runningSince: Date?

    init(puzzle: Puzzle, mode: GameMode, saved: SavedGame? = nil, now: Date = .now) {
        self.puzzle = puzzle
        self.mode = mode
        geometry = Geometry(puzzle)
        if let saved, saved.mode == mode, saved.marks.count == puzzle.cellCount {
            marks = saved.marks
            hearts = saved.hearts
            accumulated = saved.elapsed
            mistakes = saved.mistakes
            hintsUsed = saved.hintsUsed
        } else {
            marks = Array(repeating: .empty, count: puzzle.cellCount)
            for cell in puzzle.givens { marks[cell] = .cat }
            hearts = Self.startingHearts
            accumulated = 0
            mistakes = 0
            hintsUsed = 0
        }
        runningSince = now
    }

    var catCount: Int { marks.filter { $0 == .cat }.count }
    var canUndo: Bool { !history.isEmpty && status == .playing }
    var hasXs: Bool { marks.contains(.x) }

    func isGiven(_ cell: Int) -> Bool { puzzle.givens.contains(cell) }

    var snapshot: SavedGame {
        SavedGame(mode: mode, marks: marks, hearts: hearts, elapsed: elapsed(), mistakes: mistakes, hintsUsed: hintsUsed)
    }

    // MARK: Timer

    func elapsed(at now: Date = .now) -> TimeInterval {
        accumulated + (runningSince.map { now.timeIntervalSince($0) } ?? 0)
    }

    func pause(at now: Date = .now) {
        guard let since = runningSince else { return }
        accumulated += now.timeIntervalSince(since)
        runningSince = nil
    }

    func resume(at now: Date = .now) {
        guard status == .playing, runningSince == nil else { return }
        runningSince = now
    }

    // MARK: Input

    /// Tap cycle: empty → X → cat → empty.
    func tap(_ cell: Int) {
        guard status == .playing, !isGiven(cell) else { return }
        hint = nil
        switch marks[cell] {
        case .empty:
            record()
            marks[cell] = .x
        case .x:
            placeCat(cell)
        case .cat:
            record()
            marks[cell] = .empty
        }
    }

    /// Starts a drag that paints X marks (or wipes them).
    func beginStroke() {
        guard status == .playing else { return }
        hint = nil
        record()
    }

    /// Paints one cell during a drag. Only flips between empty and X.
    func paint(_ cell: Int, to mark: Mark) {
        guard status == .playing, mark != .cat, marks[cell] != .cat else { return }
        marks[cell] = mark
    }

    func placeCat(_ cell: Int) {
        guard status == .playing, marks[cell] != .cat else { return }
        record()
        if puzzle.isSolution(cell) {
            marks[cell] = .cat
            if autoX {
                for other in geometry.blockers[cell].cells where marks[other] == .empty {
                    marks[other] = .x
                }
            }
            if catCount == puzzle.size { win() }
        } else {
            marks[cell] = .x
            hearts -= 1
            mistakes += 1
            wrongCell = cell
            wrongTick += 1
            if hearts <= 0 { lose() }
        }
    }

    func undo() {
        guard status == .playing, let previous = history.popLast() else { return }
        hint = nil
        marks = previous
    }

    func clearXs() {
        guard status == .playing, hasXs else { return }
        hint = nil
        record()
        for cell in marks.indices where marks[cell] == .x { marks[cell] = .empty }
    }

    func restart(at now: Date = .now) {
        marks = Array(repeating: .empty, count: puzzle.cellCount)
        for cell in puzzle.givens { marks[cell] = .cat }
        hearts = Self.startingHearts
        mistakes = 0
        hintsUsed = 0
        history = []
        hint = nil
        wrongCell = nil
        status = .playing
        accumulated = 0
        runningSince = now
    }

    // MARK: Hints

    /// Works out the next step from the board as the player has it, applies it and explains it.
    @discardableResult
    func useHint() -> Hint? {
        guard status == .playing else { return nil }
        guard let next = nextHint() else { return nil }
        record()
        hintsUsed += 1
        switch next.reason {
        case .wrongX:
            for cell in next.cells { marks[cell] = .empty }
        case .cleanup:
            for cell in next.cells { marks[cell] = .x }
        case .logic(let step):
            if let cell = step.placement {
                marks[cell] = .cat
                if autoX {
                    for other in geometry.blockers[cell].cells where marks[other] == .empty { marks[other] = .x }
                }
            } else {
                for cell in step.exclusions where marks[cell] == .empty { marks[cell] = .x }
            }
        }
        hint = next
        if catCount == puzzle.size { win() }
        return next
    }

    /// The hint that would be given now, without applying it.
    func nextHint() -> Hint? {
        // An X on a cat's spot blocks every deduction after it.
        if let cell = puzzle.solutionCells.first(where: { marks[$0] == .x }) {
            return Hint(reason: .wrongX, cells: [cell], focus: [cell])
        }
        let cats = CellSet(marks.indices.filter { marks[$0] == .cat })
        for cat in cats.cells {
            let stale = geometry.blockers[cat].cells.filter { marks[$0] == .empty }
            if !stale.isEmpty {
                return Hint(reason: .cleanup(cat: cat), cells: stale, focus: [cat] + stale)
            }
        }
        var state = SolverState(open: CellSet(marks.indices.filter { marks[$0] == .empty }))
        state.cats = cats
        let solver = LogicSolver(geometry)
        if let step = solver.nextDeduction(in: state) {
            let changed = step.placement.map { [$0] } ?? step.exclusions
            var focus = CellSet(changed)
            for group in step.groups { focus = focus.union(geometry.cells(of: group)) }
            return Hint(reason: .logic(step), cells: changed, focus: focus.cells)
        }
        // Shouldn't happen on a generated board; fall back to showing a cat.
        guard let cell = puzzle.solutionCells.first(where: { marks[$0] != .cat }) else { return nil }
        let step = Deduction(technique: .single, placement: cell, exclusions: [],
                             groups: [Geometry.Group(kind: .region, index: puzzle.region(cell))], lines: [])
        return Hint(reason: .logic(step), cells: [cell], focus: [cell])
    }

    func dismissHint() {
        hint = nil
    }

    // MARK: Private

    private func record() {
        history.append(marks)
        if history.count > 200 { history.removeFirst() }
    }

    private func win() {
        pause()
        status = .won
        hint = nil
    }

    private func lose() {
        pause()
        status = .lost
    }
}
