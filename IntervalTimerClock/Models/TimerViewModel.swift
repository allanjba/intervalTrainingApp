import Foundation
import SwiftUI
import Combine

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
    
    private var timer: Timer?
    private var startTime: Date?
    private var elapsedTimeBeforePause: TimeInterval = 0
    private var pausedTimeRemaining: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.setupBindings()
    }
    
    private func setupBindings() {
        $currentIntervalIndex
            .sink { [weak self] index in
                guard let self = self,
                      let configuration = self.timerConfiguration,
                      index < configuration.intervals.count else { return }
                
                let interval = configuration.intervals[index]
                self.currentColor = interval.uiColor
            }
            .store(in: &cancellables)
    }
    
    func setConfiguration(_ configuration: TimerConfiguration) {
        self.timerConfiguration = configuration
        resetTimer()
    }
    
    func startTimer() {
        guard let configuration = timerConfiguration, !configuration.intervals.isEmpty else { return }
        
        switch currentState {
        case .ready:
            // Starting fresh
            resetTimer()
            setupNewTimer()
            SoundManager.shared.playSound(type: .startBeep)
            
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
        SoundManager.shared.playSound(type: .completed)
    }
    
    func resetTimer() {
        timer?.invalidate()
        timer = nil
        currentState = .ready
        currentIntervalIndex = 0
        
        guard let configuration = timerConfiguration else { return }
        
        totalTimeRemaining = configuration.totalDuration
        
        if !configuration.intervals.isEmpty {
            currentIntervalTimeRemaining = configuration.intervals[0].duration
            currentColor = configuration.intervals[0].uiColor
        }
        
        // Reset progress
        progress = 0
    }
    
    private func setupNewTimer() {
        startTime = Date()
        
        // Use a 0.5 second timer for better performance than 0.1 second
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        
        // Make sure the timer runs even when scrolling
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func updateTimer() {
        guard let configuration = timerConfiguration, 
              currentIntervalIndex < configuration.intervals.count else {
            stopTimer()
            return
        }
        
        // Decrement counters - but do it only once per second
        let now = Date()
        let elapsed = Int(now.timeIntervalSince(startTime ?? now))
        
        if elapsed > 0 {
            // Update current interval time
            currentIntervalTimeRemaining -= 1
            totalTimeRemaining -= 1
            
            // Update progress for current interval
            let currentInterval = configuration.intervals[currentIntervalIndex]
            let totalIntervalDuration = currentInterval.duration
            progress = 1.0 - CGFloat(currentIntervalTimeRemaining) / CGFloat(totalIntervalDuration)
            
            // Reset start time to track next second
            startTime = now
            
            // Check if current interval completed
            if currentIntervalTimeRemaining <= 0 {
                moveToNextInterval()
            }
            
            // Check if entire timer completed
            if totalTimeRemaining <= 0 || currentIntervalIndex >= configuration.intervals.count {
                stopTimer()
            }
        }
    }
    
    private func moveToNextInterval() {
        currentIntervalIndex += 1
        
        // Play sound for interval change
        if currentIntervalIndex < timerConfiguration?.intervals.count ?? 0 {
            let nextInterval = timerConfiguration!.intervals[currentIntervalIndex]
            
            // Play different sounds depending on the type of interval
            switch nextInterval.type {
            case .preparation:
                SoundManager.shared.playSound(type: .startBeep)
            case .work:
                SoundManager.shared.playSound(type: .intervalChange)
            case .rest:
                SoundManager.shared.playSound(type: .endBeep)
            }
            
            // Set time for the next interval
            currentIntervalTimeRemaining = nextInterval.duration
        } else {
            // Timer complete
            SoundManager.shared.playSound(type: .completed)
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
              currentIntervalIndex < configuration.intervals.count else {
            return "Ready"
        }
        
        return configuration.intervals[currentIntervalIndex].name.isEmpty ? 
               configuration.intervals[currentIntervalIndex].type.rawValue :
               configuration.intervals[currentIntervalIndex].name
    }
    
    var currentIntervalType: IntervalType {
        guard let configuration = timerConfiguration,
              currentIntervalIndex < configuration.intervals.count else {
            return .preparation
        }
        
        return configuration.intervals[currentIntervalIndex].type
    }
} 