import Foundation
import Observation

/// Everything that survives a relaunch. Small, so UserDefaults is enough.
@Observable
final class ProgressStore {
    private(set) var currentLevel: Int
    /// Best solve time per level, in seconds.
    private(set) var bestTimes: [Int: Double]
    /// Solve time per daily (day index).
    private(set) var dailyTimes: [Int: Double]
    private(set) var dailyStreak: Int
    private(set) var bestStreak: Int
    private(set) var lastDailyDay: Int
    private(set) var hapticsOn: Bool
    private(set) var autoX: Bool
    private(set) var patternsOn: Bool
    private(set) var tutorialDone: Bool
    private(set) var savedGame: SavedGame?

    @ObservationIgnored private let defaults: UserDefaults

    private enum Key {
        static let level = "progress.level"
        static let best = "progress.bestTimes"
        static let daily = "daily.times"
        static let streak = "daily.streak"
        static let bestStreak = "daily.bestStreak"
        static let lastDaily = "daily.lastDay"
        static let haptics = "settings.haptics"
        static let autoX = "settings.autoX"
        static let patterns = "settings.patterns"
        static let tutorial = "progress.tutorialDone"
        static let saved = "progress.savedGame"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        currentLevel = max(1, defaults.integer(forKey: Key.level))
        bestTimes = Self.loadTimes(defaults, Key.best)
        dailyTimes = Self.loadTimes(defaults, Key.daily)
        dailyStreak = defaults.integer(forKey: Key.streak)
        bestStreak = defaults.integer(forKey: Key.bestStreak)
        lastDailyDay = defaults.integer(forKey: Key.lastDaily)
        hapticsOn = defaults.object(forKey: Key.haptics) as? Bool ?? true
        autoX = defaults.object(forKey: Key.autoX) as? Bool ?? true
        patternsOn = defaults.bool(forKey: Key.patterns)
        tutorialDone = defaults.bool(forKey: Key.tutorial)
        savedGame = defaults.data(forKey: Key.saved).flatMap { try? JSONDecoder().decode(SavedGame.self, from: $0) }
    }

    // MARK: Campaign

    /// Records a solved level. Returns true when the time is a new best.
    @discardableResult
    func completeLevel(_ number: Int, time: Double) -> Bool {
        let previous = bestTimes[number]
        let isBest = previous.map { time < $0 } ?? true
        if isBest { bestTimes[number] = time }
        if number >= currentLevel { currentLevel = number + 1 }
        if savedGame?.mode == .level(number) { savedGame = nil }
        save()
        return isBest && previous != nil
    }

    var levelsSolved: Int { bestTimes.count }

    /// Fastest time on any board of this size.
    func bestTime(forSize size: Int) -> Double? {
        bestTimes.filter { LevelPlan.size(forLevel: $0.key) == size }.map(\.value).min()
    }

    // MARK: Daily

    /// Records today's daily. Returns true the first time it's solved (streak +1).
    @discardableResult
    func completeDaily(day: Int, time: Double) -> Bool {
        if savedGame?.mode == .daily(day) { savedGame = nil }
        guard dailyTimes[day] == nil else {
            dailyTimes[day] = min(dailyTimes[day]!, time)
            save()
            return false
        }
        dailyTimes[day] = time
        if day > lastDailyDay {
            dailyStreak = lastDailyDay == day - 1 ? dailyStreak + 1 : 1
            lastDailyDay = day
            bestStreak = max(bestStreak, dailyStreak)
        }
        save()
        return true
    }

    func dailyTime(day: Int) -> Double? { dailyTimes[day] }

    /// The streak as it stands today: broken if yesterday's daily was missed.
    func streak(today day: Int) -> Int {
        lastDailyDay >= day - 1 ? dailyStreak : 0
    }

    // MARK: Board in progress

    func saveGame(_ game: SavedGame?) {
        savedGame = game
        save()
    }

    func savedGame(for mode: GameMode) -> SavedGame? {
        savedGame?.mode == mode ? savedGame : nil
    }

    // MARK: Settings

    func setHaptics(_ on: Bool) {
        hapticsOn = on
        save()
    }

    func setAutoX(_ on: Bool) {
        autoX = on
        save()
    }

    func setPatterns(_ on: Bool) {
        patternsOn = on
        save()
    }

    func finishTutorial() {
        guard !tutorialDone else { return }
        tutorialDone = true
        save()
    }

    func reset() {
        currentLevel = 1
        bestTimes = [:]
        dailyTimes = [:]
        dailyStreak = 0
        bestStreak = 0
        lastDailyDay = 0
        tutorialDone = false
        savedGame = nil
        save()
    }

    // MARK: Storage

    private static func loadTimes(_ defaults: UserDefaults, _ key: String) -> [Int: Double] {
        let stored = defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
        return Dictionary(uniqueKeysWithValues: stored.compactMap { k, v in Int(k).map { ($0, v) } })
    }

    private func save() {
        defaults.set(currentLevel, forKey: Key.level)
        defaults.set(Dictionary(uniqueKeysWithValues: bestTimes.map { (String($0.key), $0.value) }), forKey: Key.best)
        defaults.set(Dictionary(uniqueKeysWithValues: dailyTimes.map { (String($0.key), $0.value) }), forKey: Key.daily)
        defaults.set(dailyStreak, forKey: Key.streak)
        defaults.set(bestStreak, forKey: Key.bestStreak)
        defaults.set(lastDailyDay, forKey: Key.lastDaily)
        defaults.set(hapticsOn, forKey: Key.haptics)
        defaults.set(autoX, forKey: Key.autoX)
        defaults.set(patternsOn, forKey: Key.patterns)
        defaults.set(tutorialDone, forKey: Key.tutorial)
        defaults.set(savedGame.flatMap { try? JSONEncoder().encode($0) }, forKey: Key.saved)
    }
}
