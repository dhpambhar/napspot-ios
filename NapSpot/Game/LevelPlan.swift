import Foundation

/// Which board each level and each day gets. Boards are made from seeds, never stored.
enum LevelPlan {
    static func size(forLevel level: Int) -> Int {
        switch level {
        case ...3: 5
        case ...20: 6
        case ...50: 7
        case ...90: 8
        case ...140: 9
        default: 10
        }
    }

    /// A free cat on the first few boards while people learn the rules.
    static func givens(forLevel level: Int) -> Int {
        level <= 10 ? 1 : 0
    }

    static func seed(forLevel level: Int) -> UInt64 {
        0x4E41_5053_0000_0000 &+ UInt64(level) &* 0x9E37_79B9_7F4A_7C15
    }

    static func puzzle(forLevel level: Int) -> Puzzle {
        Generator.make(size: size(forLevel: level), seed: seed(forLevel: level), givens: givens(forLevel: level))
    }

    // MARK: Daily

    /// Bigger towards the weekend.
    static func dailySize(day: Int) -> Int {
        [7, 7, 8, 8, 8, 9, 9][((day % 7) + 7) % 7]
    }

    static func dailySeed(day: Int) -> UInt64 {
        0x4441_494C_5900_0000 &+ UInt64(bitPattern: Int64(day)) &* 0xD1B5_4A32_D192_ED03
    }

    static func dailyPuzzle(day: Int) -> Puzzle {
        Generator.make(size: dailySize(day: day), seed: dailySeed(day: day))
    }

    /// A number that goes up by one each local calendar day.
    static func dayIndex(for date: Date = .now, calendar: Calendar = .current) -> Int {
        calendar.ordinality(of: .day, in: .era, for: date) ?? 0
    }

    static func date(forDay day: Int, calendar: Calendar = .current) -> Date {
        let today = dayIndex(calendar: calendar)
        return calendar.date(byAdding: .day, value: day - today, to: .now) ?? .now
    }
}
