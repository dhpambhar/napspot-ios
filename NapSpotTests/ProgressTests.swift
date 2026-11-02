import Foundation
import Testing
@testable import NapSpot

private func freshDefaults() -> UserDefaults {
    UserDefaults(suiteName: "NapSpotTests-\(UUID().uuidString)")!
}

@Suite("Progress")
struct ProgressTests {
    @Test("Solving a level unlocks the next and keeps the best time across launches")
    func levels() {
        let defaults = freshDefaults()
        let store = ProgressStore(defaults: defaults)
        #expect(store.currentLevel == 1)
        #expect(store.completeLevel(1, time: 50) == false, "a first clear isn't a 'new best'")
        #expect(store.completeLevel(1, time: 40) == true)
        #expect(store.completeLevel(1, time: 70) == false)
        #expect(store.currentLevel == 2)
        let reloaded = ProgressStore(defaults: defaults)
        #expect(reloaded.bestTimes[1] == 40)
        #expect(reloaded.currentLevel == 2)
    }

    @Test("Replaying an old level doesn't move the current level back")
    func replay() {
        let store = ProgressStore(defaults: freshDefaults())
        for n in 1...5 { store.completeLevel(n, time: 10) }
        store.completeLevel(2, time: 5)
        #expect(store.currentLevel == 6)
    }

    @Test("Daily streak grows on consecutive days and breaks on a gap")
    func streak() {
        let store = ProgressStore(defaults: freshDefaults())
        #expect(store.completeDaily(day: 100, time: 60))
        #expect(store.completeDaily(day: 101, time: 60))
        #expect(!store.completeDaily(day: 101, time: 30), "replaying today doesn't count twice")
        #expect(store.dailyTime(day: 101) == 30)
        #expect(store.streak(today: 101) == 2)
        #expect(store.streak(today: 102) == 2)
        #expect(store.streak(today: 103) == 0)
        store.completeDaily(day: 104, time: 60)
        #expect(store.streak(today: 104) == 1)
        #expect(store.bestStreak == 2)
    }

    @Test("Board in progress survives a relaunch and clears when solved")
    func savedGame() {
        let defaults = freshDefaults()
        let store = ProgressStore(defaults: defaults)
        let saved = SavedGame(mode: .level(3), marks: [.x, .cat, .empty], hearts: 2, elapsed: 12, mistakes: 1, hintsUsed: 0)
        store.saveGame(saved)
        #expect(ProgressStore(defaults: defaults).savedGame(for: .level(3)) == saved)
        #expect(store.savedGame(for: .level(4)) == nil)
        store.completeLevel(3, time: 20)
        #expect(ProgressStore(defaults: defaults).savedGame == nil)
    }

    @Test("Settings persist and reset clears progress but not settings")
    func settings() {
        let defaults = freshDefaults()
        let store = ProgressStore(defaults: defaults)
        store.setAutoX(false)
        store.setPatterns(true)
        store.completeLevel(1, time: 9)
        store.reset()
        let reloaded = ProgressStore(defaults: defaults)
        #expect(reloaded.autoX == false)
        #expect(reloaded.patternsOn == true)
        #expect(reloaded.currentLevel == 1)
        #expect(reloaded.bestTimes.isEmpty)
    }
}
