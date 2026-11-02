import SwiftUI

@main
struct NapSpotApp: App {
    @State private var store = ProgressStore()

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .onAppear { Haptics.isEnabled = store.hapticsOn }
        }
    }
}

struct RootView: View {
    let store: ProgressStore
    @State private var path: [GameMode] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(store: store) { mode in path = [mode] }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: GameMode.self) { mode in
                    GameLoader(mode: mode, store: store,
                               onNext: { next in path = [next] },
                               onExit: { path = [] })
                }
        }
        .tint(Theme.accent)
        .preferredColorScheme(.light)
    }
}
