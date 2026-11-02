import SwiftUI

struct WinCard: View {
    let time: Double
    let best: Double?
    let newBest: Bool
    let mistakes: Int
    let hints: Int
    let isDaily: Bool
    let streak: Int?
    /// Nil for the daily: there's no "next" one until tomorrow.
    let next: (() -> Void)?
    let home: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            CatView(awake: true)
                .frame(width: 84, height: 84)
            Text(isDaily ? "Daily done!" : "Purr-fect!")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
            if newBest {
                Text("New best time")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.onAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.accent))
            }
            HStack(spacing: 10) {
                stat("Time", formatTime(time))
                stat("Best", best.map(formatTime) ?? formatTime(time))
                stat("Mistakes", "\(mistakes)")
            }
            if hints > 0 {
                Text(hints == 1 ? "1 hint used" : "\(hints) hints used")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.inkMuted)
            }
            if let streak, streak > 0 {
                Label("\(streak)-day streak", systemImage: "flame.fill")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.accentDeep)
            }
            VStack(spacing: 12) {
                if let next {
                    Button("Next level", action: next)
                        .buttonStyle(PillButtonStyle())
                }
                Button("Home", action: home)
                    .buttonStyle(PillButtonStyle(fill: Theme.pill, shadow: Theme.inkMuted.opacity(0.4), foreground: Theme.ink))
            }
        }
        .foregroundStyle(Theme.ink)
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Theme.card))
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .heavy).monospacedDigit())
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(Theme.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.pill.opacity(0.6)))
    }
}

struct LostCard: View {
    let retry: () -> Void
    let home: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Theme.heart)
            Text("Out of hearts")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
            Text("The cats got grumpy. Take a breath and try this board again.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
            VStack(spacing: 12) {
                Button("Try again", action: retry)
                    .buttonStyle(PillButtonStyle())
                Button("Home", action: home)
                    .buttonStyle(PillButtonStyle(fill: Theme.pill, shadow: Theme.inkMuted.opacity(0.4), foreground: Theme.ink))
            }
        }
        .foregroundStyle(Theme.ink)
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Theme.card))
    }
}
