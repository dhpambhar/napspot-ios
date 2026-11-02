import SwiftUI

struct HowToPlayView: View {
    var onDone: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    rule(1, "One cat per row and column",
                         "Every row and every column gets exactly one cat.",
                         example: .lines)
                    rule(2, "One cat per colour",
                         "Each coloured area is one cat's territory. Exactly one cat lives there.",
                         example: .regions)
                    rule(3, "Cats don't touch",
                         "Cats like their space. No two cats can be next to each other, not even diagonally.",
                         example: .touch)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Controls")
                            .font(.system(.title3, design: .rounded, weight: .heavy))
                        control("hand.tap", "Tap once to mark ✕ where a cat can't go.")
                        control("hand.tap.fill", "Tap again to place a cat. A wrong cat costs a heart.")
                        control("hand.draw", "Drag across cells to mark many ✕ at once.")
                        control("lightbulb", "Stuck? A hint shows the next step and explains why.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.card))
                    Text("Every board has one answer, and you never need to guess.")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.inkMuted)
                        .multilineTextAlignment(.center)
                    Button("Let's play") {
                        onDone()
                        dismiss()
                    }
                    .buttonStyle(PillButtonStyle())
                }
                .padding(20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .navigationTitle("How to play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone()
                        dismiss()
                    }
                }
            }
        }
    }

    private func rule(_ number: Int, _ title: String, _ text: String, example: MiniBoard.Example) -> some View {
        HStack(alignment: .center, spacing: 16) {
            MiniBoard(example: example)
                .frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(number). \(title)")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                Text(text)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.card))
    }

    private func control(_ icon: String, _ text: String) -> some View {
        Label {
            Text(text).font(.system(.subheadline, design: .rounded))
        } icon: {
            Image(systemName: icon).foregroundStyle(Theme.accent)
        }
    }
}

/// A tiny 4×4 picture for each rule.
struct MiniBoard: View {
    enum Example {
        case lines, regions, touch
    }

    let example: Example

    private var regions: [Int] {
        [0, 0, 1, 1,
         0, 2, 2, 1,
         3, 2, 2, 1,
         3, 3, 3, 1]
    }

    /// cell -> true for a cat, false for a "no" cross.
    private var marks: [Int: Bool] {
        switch example {
        case .lines: [1: true, 0: false, 2: false, 3: false, 5: false, 9: false, 13: false]
        case .regions: [6: true, 5: false, 9: false, 10: false]
        case .touch: [5: true, 0: false, 1: false, 2: false, 4: false, 6: false, 8: false, 9: false, 10: false]
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let cell = proxy.size.width / 4
            ZStack(alignment: .topLeading) {
                ForEach(0..<16, id: \.self) { i in
                    Rectangle()
                        .fill(RegionPalette.fill(regions[i]))
                        .overlay {
                            if let isCat = marks[i] {
                                if isCat {
                                    CatView().padding(cell * 0.1)
                                } else {
                                    XMark()
                                        .stroke(Theme.heart.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                        .frame(width: cell * 0.3, height: cell * 0.3)
                                }
                            }
                        }
                        .frame(width: cell, height: cell)
                        .offset(x: CGFloat(i % 4) * cell, y: CGFloat(i / 4) * cell)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.ink, lineWidth: 2))
        .accessibilityHidden(true)
    }
}

#Preview {
    HowToPlayView()
}
