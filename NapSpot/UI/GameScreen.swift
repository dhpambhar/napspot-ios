import SwiftUI

/// Makes boards off the main thread and keeps the next one ready.
@MainActor
final class PuzzleCache {
    static let shared = PuzzleCache()

    private var tasks: [GameMode: Task<Puzzle, Never>] = [:]
    private var order: [GameMode] = []

    func puzzle(for mode: GameMode) async -> Puzzle {
        await task(for: mode).value
    }

    func prefetch(_ mode: GameMode) {
        _ = task(for: mode)
    }

    private func task(for mode: GameMode) -> Task<Puzzle, Never> {
        if let task = tasks[mode] { return task }
        let task = Task.detached(priority: .userInitiated) { () -> Puzzle in
            switch mode {
            case .level(let n): LevelPlan.puzzle(forLevel: n)
            case .daily(let d): LevelPlan.dailyPuzzle(day: d)
            }
        }
        tasks[mode] = task
        order.append(mode)
        if order.count > 6 { tasks[order.removeFirst()] = nil }
        return task
    }
}

/// Shows a short "making the board" state, then the game.
struct GameLoader: View {
    let mode: GameMode
    let store: ProgressStore
    let onNext: (GameMode) -> Void
    let onExit: () -> Void

    @State private var puzzle: Puzzle?

    var body: some View {
        Group {
            if let puzzle {
                GameScreen(puzzle: puzzle, mode: mode, store: store, onNext: onNext, onExit: onExit)
                    .id(mode)
            } else {
                ZStack {
                    Theme.background.ignoresSafeArea()
                    VStack(spacing: 16) {
                        CatView().frame(width: 80, height: 80)
                        ProgressView().tint(Theme.ink)
                        Text("Fluffing the cushions…")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Theme.inkMuted)
                    }
                }
            }
        }
        .task(id: mode) {
            puzzle = nil
            puzzle = await PuzzleCache.shared.puzzle(for: mode)
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct GameScreen: View {
    let store: ProgressStore
    let onNext: (GameMode) -> Void
    let onExit: () -> Void

    @State private var game: GameModel
    @State private var newBest = false
    @State private var celebrate = false
    @State private var showResult = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(puzzle: Puzzle, mode: GameMode, store: ProgressStore,
         onNext: @escaping (GameMode) -> Void, onExit: @escaping () -> Void) {
        self.store = store
        self.onNext = onNext
        self.onExit = onExit
        let game = GameModel(puzzle: puzzle, mode: mode, saved: store.savedGame(for: mode))
        game.autoX = store.autoX
        _game = State(initialValue: game)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: sizeClass == .regular ? 22 : 14) {
                topBar
                hearts
                BoardView(game: game, patterns: store.patternsOn, celebrate: celebrate) { mark in
                    switch mark {
                    case .cat: Haptics.cat()
                    default: Haptics.mark()
                    }
                }
                .modifier(Shake(animatableData: CGFloat(game.wrongTick)))
                .animation(.linear(duration: 0.4), value: game.wrongTick)
                .frame(maxWidth: 680, maxHeight: 680)
                .layoutPriority(1)
                hintBanner
                toolbar
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: 760)

            if showResult {
                Color.black.opacity(0.25).ignoresSafeArea().transition(.opacity)
                resultCard
                    .padding(24)
                    .frame(maxWidth: 440)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .onAppear {
            Haptics.isEnabled = store.hapticsOn
            if case .level(let n) = game.mode { PuzzleCache.shared.prefetch(.level(n + 1)) }
        }
        .onDisappear { saveProgress() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { game.resume() } else { game.pause(); saveProgress() }
        }
        .onChange(of: game.wrongTick) { _, _ in Haptics.wrong() }
        .onChange(of: game.status) { _, status in finished(status) }
    }

    // MARK: Pieces

    private var title: String {
        switch game.mode {
        case .level(let n): "Level \(n)"
        case .daily(let d): "Daily · " + LevelPlan.date(forDay: d).formatted(.dateTime.month(.abbreviated).day())
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                Haptics.tap()
                onExit()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.card))
            }
            .accessibilityLabel("Back")
            Spacer()
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                Text("\(game.puzzle.size) × \(game.puzzle.size)")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.inkMuted)
            }
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(formatTime(game.elapsed(at: context.date)))
                    .font(.system(.headline, design: .rounded, weight: .bold).monospacedDigit())
                    .frame(minWidth: 64, minHeight: 44)
                    .padding(.horizontal, 6)
                    .background(Capsule().fill(Theme.card))
            }
            .accessibilityLabel("Time")
        }
        .foregroundStyle(Theme.ink)
    }

    private var hearts: some View {
        HStack(spacing: 8) {
            ForEach(0..<GameModel.startingHearts, id: \.self) { i in
                Image(systemName: i < game.hearts ? "heart.fill" : "heart")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(i < game.hearts ? Theme.heart : Theme.inkMuted.opacity(0.5))
                    .scaleEffect(i < game.hearts ? 1 : 0.8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: game.hearts)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.hearts) hearts left")
    }

    private var hintBanner: some View {
        ZStack {
            if let hint = game.hint {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill").foregroundStyle(Theme.accent)
                    Text(HintText.describe(hint, puzzle: game.puzzle))
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.card))
                .onTapGesture { game.dismissHint() }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Text("Tap once for ✕, twice for a cat. Drag to mark many.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(minHeight: 56)
        .animation(.spring(response: 0.3), value: game.hint)
    }

    private var toolbar: some View {
        HStack(spacing: 0) {
            ToolButton(title: "Undo", systemImage: "arrow.uturn.backward", enabled: game.canUndo) {
                Haptics.tap()
                game.undo()
            }
            .frame(maxWidth: .infinity)
            ToolButton(title: "Clear ✕", systemImage: "eraser", enabled: game.hasXs && game.status == .playing) {
                Haptics.tap()
                game.clearXs()
            }
            .frame(maxWidth: .infinity)
            ToolButton(title: "Hint", systemImage: "lightbulb", enabled: game.status == .playing) {
                Haptics.tap()
                game.useHint()
            }
            .frame(maxWidth: .infinity)
            ToolButton(title: "Restart", systemImage: "arrow.counterclockwise", enabled: game.status == .playing) {
                Haptics.tap()
                game.restart()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var resultCard: some View {
        if game.status == .won {
            WinCard(time: game.elapsed(), best: bestTime, newBest: newBest, mistakes: game.mistakes,
                    hints: game.hintsUsed, isDaily: isDaily,
                    streak: isDaily ? store.streak(today: LevelPlan.dayIndex()) : nil,
                    next: nextAction, home: onExit)
        } else if game.status == .lost {
            LostCard(retry: {
                withAnimation(.spring) { showResult = false }
                game.restart()
            }, home: onExit)
        }
    }

    // MARK: Logic

    private var isDaily: Bool {
        if case .daily = game.mode { return true }
        return false
    }

    private var bestTime: Double? {
        switch game.mode {
        case .level(let n): store.bestTimes[n]
        case .daily(let d): store.dailyTime(day: d)
        }
    }

    private var nextAction: (() -> Void)? {
        guard case .level(let n) = game.mode else { return nil }
        return { onNext(.level(n + 1)) }
    }

    private func finished(_ status: GameModel.Status) {
        switch status {
        case .won:
            Haptics.solved()
            let time = game.elapsed()
            switch game.mode {
            case .level(let n): newBest = store.completeLevel(n, time: time)
            case .daily(let d): store.completeDaily(day: d, time: time)
            }
            celebrate = true
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75).delay(0.9)) { showResult = true }
        case .lost:
            store.saveGame(nil)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75).delay(0.4)) { showResult = true }
        case .playing:
            celebrate = false
        }
    }

    private func saveProgress() {
        if game.status == .playing {
            store.saveGame(game.snapshot)
        } else if store.savedGame?.mode == game.mode {
            store.saveGame(nil)
        }
    }
}
