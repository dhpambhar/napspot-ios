import SwiftUI

struct SettingsView: View {
    let store: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Play") {
                    Toggle("Auto ✕ around cats", isOn: Binding(get: { store.autoX }, set: { store.setAutoX($0) }))
                    Toggle("Colour patterns", isOn: Binding(get: { store.patternsOn }, set: { store.setPatterns($0) }))
                }
                Section {
                    Toggle("Vibration", isOn: Binding(get: { store.hapticsOn }, set: {
                        store.setHaptics($0)
                        Haptics.isEnabled = $0
                    }))
                }
                Section {
                    Button("Reset all progress", role: .destructive) { confirmReset = true }
                }
            }
            .tint(Theme.accent)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { store.reset() }
            } message: {
                Text("Levels, best times and your daily streak will be cleared.")
            }
        }
    }
}

struct StatsView: View {
    let store: ProgressStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    row("Levels solved", "\(store.levelsSolved)")
                    row("Dailies solved", "\(store.dailyTimes.count)")
                    row("Current streak", "\(store.streak(today: LevelPlan.dayIndex()))")
                    row("Best streak", "\(store.bestStreak)")
                }
                Section("Best times") {
                    ForEach(5...10, id: \.self) { size in
                        row("\(size) × \(size)", store.bestTime(forSize: size).map(formatTime) ?? "–")
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
