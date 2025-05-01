import SwiftUI

struct TimerRunView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.dismiss) private var dismiss

    let configuration: TimerConfiguration

    @State private var showingFinishAlert = false
    @State private var soundEnabled = true

    init(configuration: TimerConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        ZStack {
            // Dynamic background color
            viewModel.currentColor
                .opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Top info bar
                HStack {
                    VStack(alignment: .leading) {
                        Text(configuration.name)
                            .font(.headline)

                        Text("Total: \(viewModel.formatTime(viewModel.totalTimeRemaining))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        soundEnabled.toggle()
                        SoundManager.shared.toggleSound(enabled: soundEnabled)
                    }) {
                        Image(
                            systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
                        )
                        .font(.title2)
                        .foregroundColor(soundEnabled ? .blue : .secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                // Timer face
                TimerFaceView(
                    currentTime: viewModel.formatTime(viewModel.currentIntervalTimeRemaining),
                    intervalName: viewModel.currentIntervalName,
                    intervalType: viewModel.currentIntervalType,
                    progress: viewModel.progress,
                    color: viewModel.currentColor
                )

                // Interval indicator
                if let config = viewModel.timerConfiguration {
                    IntervalIndicatorView(
                        intervals: config.intervals,
                        currentIndex: viewModel.currentIntervalIndex
                    )
                    .padding()
                }

                Spacer()

                // Control buttons
                TimerControlsView(
                    timerState: viewModel.currentState,
                    onStart: { viewModel.startTimer() },
                    onPause: { viewModel.pauseTimer() },
                    onStop: {
                        viewModel.stopTimer()
                        showingFinishAlert = true
                    },
                    onReset: { viewModel.resetTimer() }
                )
            }
            .padding()
        }
        .navigationBarBackButtonHidden(viewModel.currentState == .running)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.currentState == .running ? "Timer Running" : "Timer")
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if viewModel.currentState == .running {
                        viewModel.pauseTimer()
                    }
                    dismiss()
                }) {
                    Text("Close")
                }
            }
        }
        .onAppear {
            viewModel.setConfiguration(configuration)
            SoundManager.shared.toggleSound(enabled: soundEnabled)
        }
        .alert(isPresented: $showingFinishAlert) {
            Alert(
                title: Text("Workout Complete!"),
                message: Text("You've completed your \(configuration.name) training."),
                primaryButton: .default(Text("Save & Close")) {
                    // Save usage data
                    configuration.lastUsed = Date()
                    dismiss()
                },
                secondaryButton: .default(Text("Restart")) {
                    viewModel.resetTimer()
                }
            )
        }
    }
}

struct IntervalIndicatorView: View {
    let intervals: [TimerInterval]
    let currentIndex: Int

    var body: some View {
        // Get a sorted list of intervals by order
        let sortedIntervals = intervals.sorted { $0.order < $1.order }

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(sortedIntervals.enumerated()), id: \.element.id) { index, interval in
                    let isActive = index == currentIndex
                    let width =
                        interval.type == .preparation ? 20 : (interval.type == .rest ? 15 : 25)

                    Rectangle()
                        .fill(interval.uiColor)
                        .frame(width: CGFloat(width), height: 8)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isActive ? Color.white : Color.clear, lineWidth: 2)
                        )
                        .shadow(
                            color: isActive ? interval.uiColor.opacity(0.7) : Color.clear, radius: 3
                        )
                        .scaleEffect(isActive ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: isActive)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview("Timer View") {
    // Create the timer configuration directly without SwiftData
    let intervals = [
        TimerInterval(name: "Prepare", duration: 10, type: .preparation, color: "#8E44AD"),
        TimerInterval(name: "Warm Up", duration: 30, type: .work, color: "#4285F4"),
        TimerInterval(name: "Rest", duration: 15, type: .rest, color: "#EA4335"),
        TimerInterval(name: "Exercise", duration: 60, type: .work, color: "#FBBC05"),
    ]

    let timerConfig = TimerConfiguration(name: "Test Timer", intervals: intervals)

    NavigationStack {
        TimerRunView(configuration: timerConfig)
    }
}
