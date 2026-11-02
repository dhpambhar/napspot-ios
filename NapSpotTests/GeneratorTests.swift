import Foundation
import Testing
@testable import NapSpot

/// Checks a board is a fair puzzle: valid answer, connected regions, one answer, no guessing.
func expectFair(_ p: Puzzle) {
    let n = p.size
    #expect(p.regions.count == n * n)
    #expect(Set(p.solution) == Set(0..<n), "one cat per column")
    for r in 1..<n { #expect(abs(p.solution[r] - p.solution[r - 1]) >= 2, "cats don't touch") }
    #expect(Set(p.solutionCells.map(p.region)) == Set(0..<n), "one cat per region")
    #expect(Generator.regionsAreConnected(n, p.regions))
    for g in p.givens { #expect(p.isSolution(g)) }
    let result = LogicSolver(Geometry(p)).solve(givens: p.givens)
    #expect(result.solved, "logic alone reaches the answer")
    #expect(result.state.cats == CellSet(p.solutionCells))
    if p.givens.isEmpty {
        #expect(BruteSolver.countSolutions(size: n, regions: p.regions) == 1)
    }
}

@Suite("Generator")
struct GeneratorTests {
    @Test("Boards of every campaign size are fair", arguments: [5, 6, 7, 8])
    func fair(size: Int) {
        for seed in 1...6 {
            expectFair(Generator.make(size: size, seed: UInt64(seed) * 7919))
        }
    }

    @Test("9×9 boards are fair")
    func nine() {
        expectFair(Generator.make(size: 9, seed: 42))
    }

    @Test("10×10 boards are fair, even when the givens fallback kicks in")
    func ten() {
        expectFair(Generator.make(size: 10, seed: 7))
    }

    @Test("The same seed always makes the same board")
    func deterministic() {
        #expect(Generator.make(size: 7, seed: 99) == Generator.make(size: 7, seed: 99))
        #expect(Generator.make(size: 7, seed: 99) != Generator.make(size: 7, seed: 100))
    }

    @Test("Asked-for givens are solution cats")
    func givens() {
        let p = Generator.make(size: 6, seed: 3, givens: 1)
        #expect(p.givens.count == 1)
        expectFair(p)
    }

    @Test("SeededRandom is stable across releases")
    func rngGolden() {
        var rng = SeededRandom(seed: 0)
        // SplitMix64 reference values for seed 0.
        #expect(rng.next() == 0xE220_A839_7B1D_CDAF)
        #expect(rng.next() == 0x6E78_9E6A_A1B9_65F4)
    }
}

@Suite("Level plan")
struct LevelPlanTests {
    @Test("Boards grow from 5×5 to 10×10")
    func sizes() {
        #expect(LevelPlan.size(forLevel: 1) == 5)
        #expect(LevelPlan.size(forLevel: 4) == 6)
        #expect(LevelPlan.size(forLevel: 60) == 8)
        #expect(LevelPlan.size(forLevel: 500) == 10)
        var last = 0
        for level in 1...200 {
            let size = LevelPlan.size(forLevel: level)
            #expect(size >= last)
            last = size
        }
    }

    @Test("Early levels get a free cat, later ones don't")
    func givens() {
        #expect(LevelPlan.puzzle(forLevel: 1).givens.count == 1)
        #expect(LevelPlan.givens(forLevel: 30) == 0)
    }

    @Test("Each day has its own daily board")
    func daily() {
        let a = LevelPlan.dailyPuzzle(day: 740_000)
        #expect(a == LevelPlan.dailyPuzzle(day: 740_000))
        #expect(a != LevelPlan.dailyPuzzle(day: 740_001))
        #expect(a.givens.isEmpty)
    }

    @Test("Day index goes up by one per day")
    func dayIndex() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let d = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(LevelPlan.dayIndex(for: d.addingTimeInterval(86_400), calendar: cal) == LevelPlan.dayIndex(for: d, calendar: cal) + 1)
    }
}
