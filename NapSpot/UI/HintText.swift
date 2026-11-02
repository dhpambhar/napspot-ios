import Foundation

/// Turns a hint into one plain sentence.
enum HintText {
    static func describe(_ hint: Hint, puzzle: Puzzle) -> String {
        switch hint.reason {
        case .wrongX:
            return "A cat belongs under this X. It's been cleared for you."
        case .cleanup:
            return "Cats need their own row, column and area, and never touch. These spots are out."
        case .logic(let step):
            return logic(step)
        }
    }

    static func logic(_ step: Deduction) -> String {
        let group = step.groups.first.map(name) ?? "This area"
        switch step.technique {
        case .single:
            return "\(group.capitalizedFirst) has only one spot left, so the cat goes there."
        case .confinement:
            let line = step.lines.first.map(name) ?? "that line"
            return "\(group.capitalizedFirst) can only use spots in \(line), so the rest of \(line) is out."
        case .touch:
            return "A cat here would leave \(group) with nowhere to nap."
        case .pigeonhole:
            let groups = list(step.groups.map(name))
            let lines = list(step.lines.map(name))
            return "\(groups.capitalizedFirst) all fit inside \(lines). Those lines are taken, so other spots in them are out."
        }
    }

    static func name(_ group: Geometry.Group) -> String {
        switch group.kind {
        case .row: "row \(group.index + 1)"
        case .col: "column \(group.index + 1)"
        case .region: "the \(RegionPalette.name(group.index)) area"
        }
    }

    private static func list(_ items: [String]) -> String {
        switch items.count {
        case 0: ""
        case 1: items[0]
        default: items.dropLast().joined(separator: ", ") + " and " + items.last!
        }
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
