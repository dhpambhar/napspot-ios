import SwiftUI

/// The square board. Tap a cell to cycle empty → X → cat; drag across cells to paint X marks.
struct BoardView: View {
    let game: GameModel
    var patterns = false
    /// Cats bounce in a wave when the board is solved.
    var celebrate = false
    var onChange: (Mark) -> Void = { _ in }

    @State private var strokeStart: Int?
    @State private var painting = false
    @State private var paintMark: Mark = .x

    private var n: Int { game.puzzle.size }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let cell = side / CGFloat(n)
            ZStack(alignment: .topLeading) {
                background(cell: cell)
                ForEach(0..<(n * n), id: \.self) { index in
                    mark(index, cell: cell)
                        .frame(width: cell, height: cell)
                        .offset(x: CGFloat(index % n) * cell, y: CGFloat(index / n) * cell)
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: cell * 0.28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cell * 0.28, style: .continuous)
                    .strokeBorder(Theme.ink, lineWidth: max(2.5, cell * 0.06))
            )
            .contentShape(Rectangle())
            .gesture(drag(cell: cell))
            .frame(width: proxy.size.width, height: proxy.size.height)
            .accessibilityElement(children: .contain)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: Drawing

    private func background(cell: CGFloat) -> some View {
        let focus = Set(game.hint?.focus ?? [])
        let regions = game.puzzle.regions
        return Canvas { gc, _ in
            for index in 0..<(n * n) {
                let rect = CGRect(x: CGFloat(index % n) * cell, y: CGFloat(index / n) * cell, width: cell, height: cell)
                gc.fill(Path(rect), with: .color(RegionPalette.fill(regions[index])))
                if focus.contains(index) {
                    gc.fill(Path(rect.insetBy(dx: cell * 0.06, dy: cell * 0.06)), with: .color(Theme.focus.opacity(0.85)))
                }
                if patterns, game.marks[index] == .empty {
                    let glyph = gc.resolve(Image(systemName: RegionPalette.glyph(regions[index])))
                    let g = cell * 0.22
                    gc.opacity = 0.22
                    gc.draw(glyph, in: CGRect(x: rect.minX + cell * 0.08, y: rect.minY + cell * 0.08, width: g, height: g))
                    gc.opacity = 1
                }
            }
            // Thin grid
            var grid = Path()
            for i in 1..<n {
                let v = CGFloat(i) * cell
                grid.move(to: CGPoint(x: v, y: 0)); grid.addLine(to: CGPoint(x: v, y: CGFloat(n) * cell))
                grid.move(to: CGPoint(x: 0, y: v)); grid.addLine(to: CGPoint(x: CGFloat(n) * cell, y: v))
            }
            gc.stroke(grid, with: .color(Theme.grid), lineWidth: 1)
            // Thick region borders
            var walls = Path()
            for r in 0..<n {
                for c in 0..<n {
                    let k = regions[r * n + c]
                    if c < n - 1, regions[r * n + c + 1] != k {
                        let x = CGFloat(c + 1) * cell
                        walls.move(to: CGPoint(x: x, y: CGFloat(r) * cell))
                        walls.addLine(to: CGPoint(x: x, y: CGFloat(r + 1) * cell))
                    }
                    if r < n - 1, regions[(r + 1) * n + c] != k {
                        let y = CGFloat(r + 1) * cell
                        walls.move(to: CGPoint(x: CGFloat(c) * cell, y: y))
                        walls.addLine(to: CGPoint(x: CGFloat(c + 1) * cell, y: y))
                    }
                }
            }
            gc.stroke(walls, with: .color(Theme.ink), style: StrokeStyle(lineWidth: max(2, cell * 0.055), lineCap: .round))
        }
    }

    @ViewBuilder
    private func mark(_ index: Int, cell: CGFloat) -> some View {
        let wave = Double(index / n + index % n) * 0.05
        ZStack {
            switch game.marks[index] {
            case .empty:
                Color.clear
            case .x:
                XMark()
                    .stroke(Theme.ink.opacity(0.55), style: StrokeStyle(lineWidth: max(1.5, cell * 0.06), lineCap: .round))
                    .frame(width: cell * 0.28, height: cell * 0.28)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            case .cat:
                CatView(awake: celebrate)
                    .padding(cell * 0.1)
                    .overlay(alignment: .bottomTrailing) {
                        if game.isGiven(index) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: cell * 0.16, weight: .bold))
                                .foregroundStyle(Theme.ink.opacity(0.45))
                                .padding(cell * 0.06)
                        }
                    }
                    .scaleEffect(celebrate ? 1.12 : 1)
                    .animation(.spring(response: 0.35, dampingFraction: 0.45).delay(wave), value: celebrate)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: game.marks[index])
        .accessibilityElement()
        .accessibilityLabel(spokenLabel(index))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { game.tap(index); onChange(game.marks[index]) }
    }

    private func spokenLabel(_ index: Int) -> String {
        let what = switch game.marks[index] {
        case .empty: "empty"
        case .x: "crossed out"
        case .cat: "cat"
        }
        return "Row \(index / n + 1), column \(index % n + 1), \(RegionPalette.name(game.puzzle.regions[index])) area, \(what)"
    }

    // MARK: Input

    private func cellAt(_ point: CGPoint, cell: CGFloat) -> Int? {
        let c = Int(point.x / cell), r = Int(point.y / cell)
        guard point.x >= 0, point.y >= 0, r < n, c < n else { return nil }
        return r * n + c
    }

    private func drag(cell: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard let index = cellAt(value.location, cell: cell) else { return }
                guard let start = strokeStart else {
                    strokeStart = cellAt(value.startLocation, cell: cell) ?? index
                    return
                }
                if !painting, index != start {
                    // Became a drag: paint X over empty cells, or wipe X if it started on one.
                    switch game.marks[start] {
                    case .empty: paintMark = .x
                    case .x: paintMark = .empty
                    case .cat: return
                    }
                    painting = true
                    game.beginStroke()
                    paint(start)
                }
                if painting { paint(index) }
            }
            .onEnded { value in
                defer {
                    strokeStart = nil
                    painting = false
                }
                guard !painting else { return }
                guard let start = strokeStart ?? cellAt(value.startLocation, cell: cell) else { return }
                game.tap(start)
                onChange(game.marks[start])
            }
    }

    private func paint(_ index: Int) {
        let target: Mark = paintMark
        let current = game.marks[index]
        guard current != .cat, current != target else { return }
        game.paint(index, to: target)
        Haptics.mark()
    }
}

struct XMark: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}

/// Side-to-side shake, driven by a counter.
struct Shake: GeometryEffect {
    var amount: CGFloat = 8
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * 4), y: 0))
    }
}
