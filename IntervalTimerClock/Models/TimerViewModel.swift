import Combine
import Foundation
// Import the models module
@preconcurrency import SwiftData
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

// No forward declarations - using model types directly from the module

enum TimerState {
    case ready
    case running
    case paused
    case finished
}

class TimerViewModel: ObservableObject {
    @Published var timerConfiguration: TimerConfiguration?
    @Published var currentState: TimerState = .ready
    @Published var currentIntervalIndex: Int = 0
    @Published var totalTimeRemaining: Int = 0
    @Published var currentIntervalTimeRemaining: Int = 0

    @Published var progress: CGFloat = 0
    @Published var currentColor: Color = .blue

    // The timer implementation
    private var timer: Timer?
    private var startTime: Date?
    private var elapsedTimeBeforePause: TimeInterval = 0
    private var pausedTimeRemaining: Int = 0

    // Additional variables for drift compensation
    private var initialIntervalDuration: Int = 0
    private var initialTotalDuration: Int = 0

    // Track if we were running when app went to background
    private var wasRunningBeforeBackground = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.setupBindings()
        self.setupNotifications()
    }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func setupBindings() {
        $currentIntervalIndex
            .sink { [weak self] index in
                guard let self = self,
                    let configuration = self.timerConfiguration,
                    !configuration.intervals.isEmpty
                else { return }

                // Get sorted intervals
                let sortedIntervals = configuration.intervals.sorted { $0.order < $1.order }

                guard index < sortedIntervals.count else { return }

                let interval = sortedIntervals[index]
                self.currentColor = interval.uiColor
            }
            .store(in: &cancellables)
    }

    private func setupNotifications() {
        #if canImport(UIKit)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAppDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAppWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
        #endif
    }

    @objc private func handleAppDidEnterBackground() {
        // Remember if we were running
        wasRunningBeforeBackground = (currentState == .running)

        if wasRunningBeforeBackground {
            // Save the time we went to background
            if let start = startTime {
                elapsedTimeBeforePause += Date().timeIntervalSince(start)
            }

            // Cancel the timer while in background
            timer?.invalidate()
            timer = nil
        }
    }

    @objc private func handleAppWillEnterForeground() {
        if wasRunningBeforeBackground {
            // Reset the start time and restart the timer
            setupNewTimer()
            currentState = .running
        }
    }

    func setConfiguration(_ configuration: TimerConfiguration) {
        // Create a sorted copy of the intervals based on the order property
        var sortedConfig = configuration
        sortedConfig.intervals.sort { $0.order < $1.order }

        self.timerConfiguration = sortedConfig
        resetTimer()
    }

    func startTimer() {
        guard let configuration = timerConfiguration, !configuration.intervals.isEmpty else {
            return
        }

        switch currentState {
        case .ready:
            // Starting fresh
            resetTimer()
            setupNewTimer()
            playSound("startBeep")

        case .paused:
            // Resuming from pause
            currentIntervalTimeRemaining = pausedTimeRemaining
            setupNewTimer()

        case .running, .finished:
            return
        }

        currentState = .running
    }

    func pauseTimer() {
        guard currentState == .running else { return }

        timer?.invalidate()
        timer = nil
        pausedTimeRemaining = currentIntervalTimeRemaining
        currentState = .paused
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        currentState = .finished
        playSound("completed")
    }

    func resetTimer() {
        timer?.invalidate()
        timer = nil
        currentState = .ready
        currentIntervalIndex = 0
        elapsedTimeBeforePause = 0

        guard let configuration = timerConfiguration else { return }

        totalTimeRemaining = configuration.totalDuration
        initialTotalDuration = configuration.totalDuration

        if !configuration.intervals.isEmpty {
            // Get sorted intervals
            let sortedIntervals = configuration.intervals.sorted { $0.order < $1.order }

            currentIntervalTimeRemaining = sortedIntervals[0].duration
            initialIntervalDuration = sortedIntervals[0].duration
            currentColor = sortedIntervals[0].uiColor
        }

        // Reset progress
        progress = 0
    }

    private func setupNewTimer() {
        // Reset elapsed time tracking
        self.startTime = Date()
        self.elapsedTimeBeforePause = 0  // Clear any previously accumulated time

        // IMPORTANT: The issue is that we're using a 0.5 second timer but only updating
        // when elapsed > 0, which could lead to missed updates and slower timing.
        // Instead, use a 0.1 second interval for better precision.
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateTimerPrecisely()
        }

        // Make sure the timer runs even when scrolling
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func updateTimerPrecisely() {
        guard let configuration = timerConfiguration,
            !configuration.intervals.isEmpty,
            let start = startTime
        else {
            stopTimer()
            return
        }

        // Get sorted intervals by order
        let sortedIntervals = configuration.intervals.sorted { $0.order < $1.order }

        // Make sure currentIntervalIndex is within bounds
        guard currentIntervalIndex < sortedIntervals.count else {
            stopTimer()
            return
        }

        let now = Date()
        // Calculate elapsed time with high precision
        let elapsedSeconds = now.timeIntervalSince(start) + elapsedTimeBeforePause

        // Convert to whole seconds for display purposes
        let currentWholeSeconds = Int(floor(elapsedSeconds))

        // Calculate time remaining with one-second precision for display
        let currentInterval = sortedIntervals[currentIntervalIndex]
        let intervalDuration = currentInterval.duration
        let remainingSeconds = max(0, intervalDuration - currentWholeSeconds)

        // Only update the display if the whole second has changed
        if remainingSeconds != currentIntervalTimeRemaining {
            currentIntervalTimeRemaining = remainingSeconds

            // Also update total time remaining
            let totalElapsed =
                sortedIntervals[0..<currentIntervalIndex].reduce(0) { $0 + $1.duration }
                + (intervalDuration - remainingSeconds)
            totalTimeRemaining = configuration.totalDuration - totalElapsed

            // Update progress for current interval with high precision
            progress = CGFloat(elapsedSeconds / Double(intervalDuration))
            progress = min(1.0, progress)  // Ensure we don't exceed 1.0

            // Check if current interval completed
            if remainingSeconds <= 0 {
                if currentIntervalIndex < sortedIntervals.count - 1 {
                    moveToNextInterval(sortedIntervals: sortedIntervals)

                    // Reset timer for the next interval
                    self.startTime = Date()
                    self.elapsedTimeBeforePause = 0
                } else {
                    // Last interval complete
                    self.progress = 1.0  // Ensure progress shows completion
                    playSound("completed")
                    stopTimer()
                }
            }
        }
    }

    private func moveToNextInterval(sortedIntervals: [TimerInterval]? = nil) {
        currentIntervalIndex += 1

        // Get sorted intervals if not provided
        let intervals =
            sortedIntervals ?? timerConfiguration?.intervals.sorted { $0.order < $1.order } ?? []

        // Play sound for interval change
        if currentIntervalIndex < intervals.count {
            let nextInterval = intervals[currentIntervalIndex]

            // Play different sounds depending on the type of interval
            switch nextInterval.type {
            case .preparation:
                playSound("startBeep")
            case .work:
                playSound("intervalChange")
            case .rest:
                playSound("endBeep")
            }

            // Set time for the next interval
            currentIntervalTimeRemaining = nextInterval.duration
        } else {
            // Timer complete
            playSound("completed")
            stopTimer()
        }
    }

    // Helper function to format time
    func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var currentIntervalName: String {
        guard let configuration = timerConfiguration,
            !configuration.intervals.isEmpty
        else {
            return "Ready"
        }

        // Get sorted intervals
        let sortedIntervals = configuration.intervals.sorted { $0.order < $1.order }

        guard currentIntervalIndex < sortedIntervals.count else {
            return "Ready"
        }

        let interval = sortedIntervals[currentIntervalIndex]
        return interval.name.isEmpty ? interval.type.rawValue : interval.name
    }

    var currentIntervalType: IntervalType {
        guard let configuration = timerConfiguration,
            !configuration.intervals.isEmpty
        else {
            return .preparation
        }

        // Get sorted intervals
        let sortedIntervals = configuration.intervals.sorted { $0.order < $1.order }

        guard currentIntervalIndex < sortedIntervals.count else {
            return .preparation
        }

        return sortedIntervals[currentIntervalIndex].type
    }

    // Internal wrapper method to play sounds
    private func playSound(_ soundType: String) {
        // Use string-based representation to avoid direct enum references
        // This helps bypass compilation issues
        switch soundType {
        case "startBeep":
            // Handle start beep sound
            #if DEBUG
                print("Playing start beep sound")
            #endif
        case "endBeep":
            // Handle end beep sound
            #if DEBUG
                print("Playing end beep sound")
            #endif
        case "intervalChange":
            // Handle interval change sound
            #if DEBUG
                print("Playing interval change sound")
            #endif
        case "completed":
            // Handle completed sound
            #if DEBUG
                print("Playing completed sound")
            #endif
        default:
            break
        }
    }
}
