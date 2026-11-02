import SwiftUI

/// Region colours. Placeholder palette until /replica-brand; our own, not the original's.
enum RegionPalette {
    static let fills: [Color] = [0xFFC9B5, 0xBDE8CF, 0xB9DBF7, 0xD9C8F2, 0xFFE59E,
                                 0xF7B9D2, 0xCFE3A8, 0xFFB38A, 0xA9E0E3, 0xE6D3B8].map(Color.init(hex:))
    static let names = ["peach", "mint", "sky", "lilac", "butter",
                        "rose", "sage", "apricot", "lagoon", "oat"]
    /// Pattern mode: one distinct shape per region, for colour-blind players.
    static let glyphs = ["circle.fill", "triangle.fill", "square.fill", "diamond.fill", "star.fill",
                         "heart.fill", "suit.club.fill", "moon.fill", "drop.fill", "leaf.fill"]

    static func fill(_ index: Int) -> Color { fills[index % fills.count] }
    static func name(_ index: Int) -> String { names[index % names.count] }
    static func glyph(_ index: Int) -> String { glyphs[index % glyphs.count] }
}

/// Cosy look: warm paper, cocoa ink, a marmalade accent.
enum Theme {
    static let backgroundTop = Color(hex: 0xFFF8EC)
    static let backgroundBottom = Color(hex: 0xF6E7CF)
    static let ink = Color(hex: 0x3F2E26)
    static let inkMuted = Color(hex: 0x8C7363)
    static let card = Color(hex: 0xFFFDF8)
    static let pill = Color(hex: 0xF3E2C7)
    static let accent = Color(hex: 0xF08A24)
    static let accentDeep = Color(hex: 0xC66A10)
    static let onAccent = Color.white
    static let heart = Color(hex: 0xE5484D)
    static let grid = Color(hex: 0x3F2E26).opacity(0.18)
    static let focus = Color(hex: 0xFFF3B0)
    static let cat = Color(hex: 0x3F2E26)
    static let catFace = Color(hex: 0xFFF8EC)

    static let background = LinearGradient(colors: [backgroundTop, backgroundBottom],
                                           startPoint: .top, endPoint: .bottom)
}

extension Color {
    init(hex: Int) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// Big rounded pill with a pressed state.
struct PillButtonStyle: ButtonStyle {
    var fill: Color = Theme.accent
    var shadow: Color = Theme.accentDeep
    var foreground: Color = Theme.onAccent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title3, design: .rounded, weight: .bold))
            .foregroundStyle(foreground)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(fill)
                    .shadow(color: shadow, radius: 0, y: configuration.isPressed ? 1 : 5)
            )
            .offset(y: configuration.isPressed ? 4 : 0)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
    }
}

/// Small round tool button with a caption under it.
struct ToolButton: View {
    let title: String
    let systemImage: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(Theme.card).shadow(color: Theme.ink.opacity(0.15), radius: 0, y: 3))
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(Theme.ink)
            .opacity(enabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(title)
    }
}

/// Formats seconds as m:ss (or h:mm:ss).
func formatTime(_ seconds: Double) -> String {
    let total = Int(seconds)
    let h = total / 3600, m = (total % 3600) / 60, s = total % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
}
