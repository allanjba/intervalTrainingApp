import SwiftData
import SwiftUI

struct TimerConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var intervals: [TimerInterval] = []
    @State private var isShowingPresetOptions = false

    var editConfiguration: TimerConfiguration?
    var onSave: ((TimerConfiguration) -> Void)?

    init(configuration: TimerConfiguration? = nil, onSave: ((TimerConfiguration) -> Void)? = nil) {
        self.editConfiguration = configuration
        self.onSave = onSave

        if let config = configuration {
            _name = State(initialValue: config.name)
            _intervals = State(initialValue: config.intervals)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Timer Name", text: $name)
                        .font(.title2)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)

                    // Quick preset button
                    Button(action: {
                        isShowingPresetOptions = true
                    }) {
                        HStack {
                            Image(systemName: "clock.fill")
                            Text("Apply Preset")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }

                    IntervalEditorView(intervals: $intervals)
                }
                .padding()
            }
            .navigationTitle(editConfiguration == nil ? "New Timer" : "Edit Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConfiguration()
                    }
                    .disabled(name.isEmpty || intervals.isEmpty)
                }
            }
            .actionSheet(isPresented: $isShowingPresetOptions) {
                ActionSheet(
                    title: Text("Timer Presets"),
                    message: Text("Choose a preset template"),
                    buttons: [
                        .default(Text("Tabata Workout (4 min)")) {
                            applyTabataPreset()
                        },
                        .default(Text("5x5 Strength (25 min)")) {
                            apply5x5Preset()
                        },
                        .default(Text("3 Rounds Circuit (15 min)")) {
                            applyCircuitPreset()
                        },
                        .cancel(),
                    ]
                )
            }
        }
    }

    private func saveConfiguration() {
        if let editConfig = editConfiguration {
            // Update existing configuration
            editConfig.name = name
            editConfig.intervals = intervals

            onSave?(editConfig)
        } else {
            // Create new configuration
            let newConfig = TimerConfiguration(name: name, intervals: intervals)
            modelContext.insert(newConfig)

            onSave?(newConfig)
        }

        dismiss()
    }

    // MARK: - Preset Templates

    private func applyTabataPreset() {
        name = "Tabata Workout"

        intervals = [
            TimerInterval(
                name: "Prepare", duration: 10, type: .preparation, color: "#8E44AD", order: 0),
            TimerInterval(
                name: "Exercise 1", duration: 20, type: .work, color: "#4285F4", order: 1),
            TimerInterval(name: "Rest", duration: 10, type: .rest, color: "#EA4335", order: 2),
            TimerInterval(
                name: "Exercise 2", duration: 20, type: .work, color: "#4285F4", order: 3),
            TimerInterval(name: "Rest", duration: 10, type: .rest, color: "#EA4335", order: 4),
            TimerInterval(
                name: "Exercise 3", duration: 20, type: .work, color: "#4285F4", order: 5),
            TimerInterval(name: "Rest", duration: 10, type: .rest, color: "#EA4335", order: 6),
            TimerInterval(
                name: "Exercise 4", duration: 20, type: .work, color: "#4285F4", order: 7),
            TimerInterval(name: "Rest", duration: 10, type: .rest, color: "#EA4335", order: 8),
            TimerInterval(
                name: "Final Sprint", duration: 20, type: .work, color: "#4285F4", order: 9),
            TimerInterval(
                name: "Cool Down", duration: 30, type: .rest, color: "#34A853", order: 10),
        ]
    }

    private func apply5x5Preset() {
        name = "5x5 Strength Training"

        intervals = [
            TimerInterval(
                name: "Prepare", duration: 30, type: .preparation, color: "#8E44AD", order: 0),
            TimerInterval(name: "Set 1", duration: 180, type: .work, color: "#4285F4", order: 1),
            TimerInterval(name: "Rest", duration: 90, type: .rest, color: "#EA4335", order: 2),
            TimerInterval(name: "Set 2", duration: 180, type: .work, color: "#4285F4", order: 3),
            TimerInterval(name: "Rest", duration: 90, type: .rest, color: "#EA4335", order: 4),
            TimerInterval(name: "Set 3", duration: 180, type: .work, color: "#4285F4", order: 5),
            TimerInterval(name: "Rest", duration: 90, type: .rest, color: "#EA4335", order: 6),
            TimerInterval(name: "Set 4", duration: 180, type: .work, color: "#4285F4", order: 7),
            TimerInterval(name: "Rest", duration: 90, type: .rest, color: "#EA4335", order: 8),
            TimerInterval(name: "Set 5", duration: 180, type: .work, color: "#4285F4", order: 9),
            TimerInterval(
                name: "Cool Down", duration: 180, type: .rest, color: "#34A853", order: 10),
        ]
    }

    private func applyCircuitPreset() {
        name = "3 Rounds Circuit"

        intervals = [
            TimerInterval(
                name: "Prepare", duration: 30, type: .preparation, color: "#8E44AD", order: 0),
            TimerInterval(name: "Round 1", duration: 180, type: .work, color: "#4285F4", order: 1),
            TimerInterval(name: "Rest", duration: 60, type: .rest, color: "#EA4335", order: 2),
            TimerInterval(name: "Round 2", duration: 180, type: .work, color: "#4285F4", order: 3),
            TimerInterval(name: "Rest", duration: 60, type: .rest, color: "#EA4335", order: 4),
            TimerInterval(name: "Round 3", duration: 180, type: .work, color: "#4285F4", order: 5),
            TimerInterval(
                name: "Cool Down", duration: 120, type: .rest, color: "#34A853", order: 6),
        ]
    }
}

#Preview("Configuration View") {
    TimerConfigurationView()
        .modelContainer(for: [TimerConfiguration.self, TimerInterval.self], inMemory: true)
}
