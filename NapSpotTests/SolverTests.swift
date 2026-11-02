import Testing
@testable import NapSpot

@Suite("Solver")
struct SolverTests {
    /// A hand-made 5×5 board with four answers, so not a fair puzzle.
    ///  A A B B B
    ///  A C C B B
    ///  D C C E E
    ///  D D C E E
    ///  D D D E E
    static let regions = [0, 0, 1, 1, 1,
                          0, 2, 2, 1, 1,
                          3, 2, 2, 4, 4,
                          3, 3, 2, 4, 4,
                          3, 3, 3, 4, 4]

    @Test("CellSet basics across both words")
    func cellSet() {
        var s = CellSet([0, 63, 64, 99])
        #expect(s.count == 4)
        #expect(s.contains(63) && s.contains(64) && !s.contains(65))
        #expect(s.cells == [0, 63, 64, 99])
        s.remove(63)
        #expect(s.first == 0)
        #expect(CellSet([64]).isSubset(of: s))
        #expect(!CellSet([63]).isSubset(of: s))
        #expect(s.subtracting(CellSet([0, 64])).cells == [99])
        #expect(s.intersection(CellSet([99, 5])).cells == [99])
        #expect(CellSet().first == nil)
    }

    @Test("Blockers cover row, column, region and neighbours, not the cell itself")
    func blockers() {
        let g = Geometry(size: 5, regions: Self.regions)
        let b = g.blockers[13] // row 2, col 3, region E
        #expect(!b.contains(13))
        for c in 0..<5 where c != 3 { #expect(b.contains(10 + c)) }
        for r in 0..<5 where r != 2 { #expect(b.contains(r * 5 + 3)) }
        #expect(b.contains(7) && b.contains(19)) // diagonal neighbours
        #expect(b.contains(24)) // same region, not in line or touching
        #expect(!b.contains(0) && !b.contains(20))
    }

    @Test("Brute force counts every answer; logic refuses to pick one")
    func brute() {
        #expect(BruteSolver.countSolutions(size: 5, regions: Self.regions, limit: 50) == 4)
        #expect(BruteSolver.countSolutions(size: 5, regions: Self.regions, limit: 2) == 2)
        #expect(!LogicSolver(Geometry(size: 5, regions: Self.regions)).solve().solved)
        // One region over the whole board can't hold five cats.
        #expect(BruteSolver.countSolutions(size: 5, regions: Array(repeating: 0, count: 25), limit: 2) == 0)
    }

    @Test("Logic never contradicts brute force on generated boards")
    func agreesWithBrute() {
        for seed in 1...20 {
            let p = Generator.make(size: 6, seed: UInt64(seed))
            let logic = LogicSolver(Geometry(p)).solve()
            if logic.solved {
                #expect(BruteSolver.countSolutions(size: 6, regions: p.regions) == 1)
            }
        }
    }

    @Test("Every deduction step is sound: it never rules out the answer")
    func soundSteps() {
        for seed in 1...10 {
            let p = Generator.make(size: 7, seed: UInt64(seed) &* 31)
            let solver = LogicSolver(Geometry(p))
            let answer = CellSet(p.solutionCells)
            var state = SolverState(open: Geometry(p).all)
            while let step = solver.nextDeduction(in: state) {
                if let cell = step.placement { #expect(answer.contains(cell)) }
                for cell in step.exclusions { #expect(!answer.contains(cell)) }
                solver.apply(step, to: &state)
                if state.cats.count == p.size { break }
            }
            #expect(state.cats == answer)
        }
    }

    @Test("Hint text names the group")
    func hintText() {
        let step = Deduction(technique: .single, placement: 3, exclusions: [],
                             groups: [Geometry.Group(kind: .row, index: 0)], lines: [])
        #expect(HintText.logic(step).hasPrefix("Row 1 has only one spot left"))
        let region = Geometry.Group(kind: .region, index: 1)
        #expect(HintText.name(region) == "the mint area")
    }
}
