import Foundation
import Testing
@testable import NapSpot

@MainActor
@Suite("Game")
struct GameModelTests {
    let puzzle = Generator.make(size: 6, seed: 2024)

    func game(autoX: Bool = false) -> GameModel {
        let g = GameModel(puzzle: puzzle, mode: .level(5))
        g.autoX = autoX
        return g
    }

    var wrongCell: Int { (0..<puzzle.cellCount).first { !puzzle.isSolution($0) }! }

    @Test("Tap cycles empty → X → cat → empty")
    func tapCycle() {
        let g = game()
        let cell = puzzle.solutionCells[0]
        g.tap(cell)
        #expect(g.marks[cell] == .x)
        g.tap(cell)
        #expect(g.marks[cell] == .cat)
        g.tap(cell)
        #expect(g.marks[cell] == .empty)
        #expect(g.hearts == 3)
    }

    @Test("A wrong cat costs a heart and turns into an X")
    func wrongCat() {
        let g = game()
        g.placeCat(wrongCell)
        #expect(g.hearts == 2)
        #expect(g.mistakes == 1)
        #expect(g.marks[wrongCell] == .x)
        #expect(g.wrongTick == 1)
    }

    @Test("Three wrong cats lose the board; restart brings the hearts back")
    func lose() {
        let g = game()
        let wrong = (0..<puzzle.cellCount).filter { !puzzle.isSolution($0) }
        for cell in wrong.prefix(3) { g.placeCat(cell) }
        #expect(g.status == .lost)
        g.tap(wrong[5])
        #expect(g.marks[wrong[5]] == .empty, "no input after losing")
        g.restart()
        #expect(g.status == .playing)
        #expect(g.hearts == 3)
        #expect(!g.marks.contains(.x))
    }

    @Test("Placing every cat wins and stops the clock")
    func win() {
        let g = game()
        for cell in puzzle.solutionCells { g.placeCat(cell) }
        #expect(g.status == .won)
        let t = g.elapsed()
        #expect(g.elapsed(at: .now.addingTimeInterval(60)) == t)
    }

    @Test("Auto X marks every spot a cat rules out")
    func autoX() {
        let g = game(autoX: true)
        let cell = puzzle.solutionCells[0]
        g.placeCat(cell)
        for other in g.geometry.blockers[cell].cells { #expect(g.marks[other] == .x) }
    }

    @Test("Painting only flips empty and X, never cats")
    func paint() {
        let g = game()
        let cat = puzzle.solutionCells[1]
        g.placeCat(cat)
        g.beginStroke()
        g.paint(cat, to: .x)
        g.paint(wrongCell, to: .x)
        #expect(g.marks[cat] == .cat)
        #expect(g.marks[wrongCell] == .x)
        g.undo()
        #expect(g.marks[wrongCell] == .empty, "one undo takes back the whole stroke")
    }

    @Test("Undo steps back but never refunds a heart")
    func undo() {
        let g = game()
        g.placeCat(wrongCell)
        g.undo()
        #expect(g.hearts == 2)
        #expect(g.marks[wrongCell] == .empty)
    }

    @Test("Hints alone solve the board without a single wrong cat")
    func hintsSolve() {
        let g = game(autoX: true)
        var guardCount = 0
        while g.status == .playing && guardCount < 200 {
            #expect(g.useHint() != nil)
            guardCount += 1
        }
        #expect(g.status == .won)
        #expect(g.hearts == 3)
        #expect(g.hintsUsed == guardCount)
    }

    @Test("A hint first clears an X sitting on a cat's spot")
    func hintFixesWrongX() {
        let g = game()
        let cell = puzzle.solutionCells[2]
        g.tap(cell) // X
        let hint = g.useHint()
        #expect(hint?.reason == .wrongX)
        #expect(g.marks[cell] == .empty)
    }

    @Test("A saved board resumes where it was left")
    func resume() {
        let g = game()
        g.placeCat(wrongCell)
        g.tap(puzzle.solutionCells[0])
        let saved = g.snapshot
        let again = GameModel(puzzle: puzzle, mode: .level(5), saved: saved)
        #expect(again.marks == g.marks)
        #expect(again.hearts == 2)
        let other = GameModel(puzzle: puzzle, mode: .level(6), saved: saved)
        #expect(other.hearts == 3, "a save for another board is ignored")
    }
}
