import Foundation
import SwiftData
import SwiftUI

// Definition of interval types
enum IntervalType: String, Codable {
    case preparation = "Preparation"
    case work = "Work"
    case rest = "Rest"
}

// Single interval in a timer sequence
@Model
final class TimerInterval {
    var id: UUID
    var name: String
    var duration: Int  // in seconds
    var type: IntervalType
    var color: String  // Store color as hex string
    var order: Int  // Position in the sequence

    init(name: String, duration: Int, type: IntervalType, color: String, order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.duration = duration
        self.type = type
        self.color = color
        self.order = order
    }

    var displayDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var uiColor: Color {
        Color(hex: color) ?? .blue
    }
}

// Complete timer configuration
@Model
final class TimerConfiguration {
    var id: UUID
    var name: String
    var intervals: [TimerInterval]
    var createdAt: Date
    var lastUsed: Date?
    var favorite: Bool

    init(name: String, intervals: [TimerInterval]) {
        self.id = UUID()
        self.name = name
        self.intervals = intervals
        self.createdAt = Date()
        self.lastUsed = nil
        self.favorite = false
    }

    var totalDuration: Int {
        intervals.reduce(0) { $0 + $1.duration }
    }

    var displayTotalDuration: String {
        let totalSeconds = totalDuration
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    // Helper method to add an interval with proper ordering
    func addInterval(_ interval: TimerInterval) {
        interval.order = intervals.count
        intervals.append(interval)
    }

    // Helper method to reorder intervals after changes
    func reorderIntervals() {
        for (index, interval) in intervals.enumerated() {
            interval.order = index
        }
    }
}

// Extension to create Color from hex string
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        self.init(
            .sRGB,
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0,
            opacity: 1.0
        )
    }
}
