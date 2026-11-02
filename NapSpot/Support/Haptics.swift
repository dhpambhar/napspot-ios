import UIKit

/// Off when the player turns vibration off.
@MainActor
enum Haptics {
    static var isEnabled = true

    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let notify = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()

    /// An X going on or off.
    static func mark() {
        guard isEnabled else { return }
        selection.selectionChanged()
    }

    /// A cat settling into its spot.
    static func cat() {
        guard isEnabled else { return }
        soft.impactOccurred(intensity: 0.9)
    }

    static func wrong() {
        guard isEnabled else { return }
        notify.notificationOccurred(.error)
    }

    static func solved() {
        guard isEnabled else { return }
        notify.notificationOccurred(.success)
    }

    static func tap() {
        guard isEnabled else { return }
        light.impactOccurred()
    }
}
