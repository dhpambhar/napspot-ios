import SwiftUI

struct HomeView: View {
    let store: ProgressStore
    let play: (GameMode) -> Void

    @State private var sheet: Sheet?

    enum Sheet: Identifiable {
        case howTo, stats, settings
        var id: Self { self }
    }

    private var today: Int { LevelPlan.dayIndex() }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    header
                    playCard
                    dailyCard
                    HStack(spacing: 0) {
                        ToolButton(title: "How to play", systemImage: "questionmark") { open(.howTo) }
                            .frame(maxWidth: .infinity)
                        ToolButton(title: "Stats", systemImage: "chart.bar.fill") { open(.stats) }
                            .frame(maxWidth: .infinity)
                        ToolButton(title: "Settings", systemImage: "gearshape.fill") { open(.settings) }
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(Theme.ink)
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .howTo: HowToPlayView { store.finishTutorial() }
            case .stats: StatsView(store: store)
            case .settings: SettingsView(store: store)
            }
        }
        .onAppear {
            if !store.tutorialDone { sheet = .howTo }
            PuzzleCache.shared.prefetch(.level(store.currentLevel))
        }
    }

    private func open(_ s: Sheet) {
        Haptics.tap()
        sheet = s
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: -10) {
                CatView(color: Color(hex: 0xE9873A)).frame(width: 64, height: 64).rotationEffect(.degrees(-8))
                CatView().frame(width: 80, height: 80).zIndex(1)
                CatView(color: Color(hex: 0x8C8C9A)).frame(width: 64, height: 64).rotationEffect(.degrees(8))
            }
            Text("NapSpot")
                .font(.system(size: 46, weight: .heavy, design: .rounded))
            Text("Every cat needs its own spot")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.inkMuted)
        }
        .accessibilityElement(children: .combine)
    }

    private var playCard: some View {
        let level = store.currentLevel
        let resuming = store.savedGame?.mode == .level(level)
        let size = LevelPlan.size(forLevel: level)
        return VStack(spacing: 14) {
            Text("Level \(level)")
                .font(.system(.title, design: .rounded, weight: .heavy))
            Text("\(size) × \(size) board · \(size) cats")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(Theme.inkMuted)
            Button(resuming ? "Continue" : "Play") {
                Haptics.tap()
                play(.level(level))
            }
            .buttonStyle(PillButtonStyle())
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.card))
    }

    private var dailyCard: some View {
        let done = store.dailyTime(day: today)
        let streak = store.streak(today: today)
        return Button {
            Haptics.tap()
            play(.daily(today))
        } label: {
            HStack(spacing: 14) {
                Image(systemName: done == nil ? "calendar" : "checkmark.seal.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(done == nil ? Theme.accent : Color(hex: 0x3BA55C))
                    .frame(width: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily puzzle")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Text(done.map { "Solved in \(formatTime($0)) · play again" } ?? "Same board for everyone today")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Theme.inkMuted)
                }
                Spacer()
                if streak > 0 {
                    Label("\(streak)", systemImage: "flame.fill")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(Theme.accentDeep)
                        .accessibilityLabel("\(streak)-day streak")
                }
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.card))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.ink)
    }
}
