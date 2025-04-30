import SwiftUI

struct IntervalEditorView: View {
    @Binding var intervals: [TimerInterval]
    @State private var showingAddInterval = false
    @State private var editingInterval: TimerInterval?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Intervals")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingAddInterval = true
                }) {
                    Label("Add", systemImage: "plus.circle.fill")
                }
            }
            
            if intervals.isEmpty {
                Text("No intervals added yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            } else {
                List {
                    ForEach(intervals.indices, id: \.self) { index in
                        IntervalRow(interval: intervals[index])
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingInterval = intervals[index]
                            }
                    }
                    .onDelete(perform: deleteIntervals)
                    .onMove(perform: moveIntervals)
                }
                .frame(minHeight: 200)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            
            VStack(alignment: .leading) {
                Text("Total Duration: \(formatTotalDuration())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Total Intervals: \(intervals.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .sheet(isPresented: $showingAddInterval) {
            IntervalDetailView(
                interval: TimerInterval(
                    name: "",
                    duration: 60,
                    type: .work,
                    color: "#4285F4"
                ),
                isNew: true,
                onSave: { newInterval in
                    intervals.append(newInterval)
                    showingAddInterval = false
                },
                onCancel: {
                    showingAddInterval = false
                }
            )
        }
        .sheet(item: $editingInterval) { interval in
            IntervalDetailView(
                interval: interval,
                isNew: false,
                onSave: { updatedInterval in
                    if let index = intervals.firstIndex(where: { $0.id == updatedInterval.id }) {
                        intervals[index] = updatedInterval
                    }
                    editingInterval = nil
                },
                onCancel: {
                    editingInterval = nil
                }
            )
        }
    }
    
    func deleteIntervals(at offsets: IndexSet) {
        intervals.remove(atOffsets: offsets)
    }
    
    func moveIntervals(from source: IndexSet, to destination: Int) {
        intervals.move(fromOffsets: source, toOffset: destination)
    }
    
    func formatTotalDuration() -> String {
        let totalSeconds = intervals.reduce(0) { $0 + $1.duration }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct IntervalRow: View {
    let interval: TimerInterval
    
    var body: some View {
        HStack {
            Circle()
                .fill(interval.uiColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading) {
                Text(interval.name.isEmpty ? interval.type.rawValue : interval.name)
                    .fontWeight(.medium)
                
                Text(interval.displayDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(interval.type.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

struct IntervalDetailView: View {
    @State private var name: String
    @State private var duration: Int
    @State private var type: IntervalType
    @State private var color: String
    
    private let interval: TimerInterval
    private let isNew: Bool
    private let onSave: (TimerInterval) -> Void
    private let onCancel: () -> Void
    
    // Predefined colors
    private let colors = [
        "#4285F4", // Blue
        "#EA4335", // Red
        "#FBBC05", // Yellow
        "#34A853", // Green
        "#8E44AD", // Purple
        "#F39C12", // Orange
        "#27AE60", // Emerald
        "#E74C3C"  // Crimson
    ]
    
    init(interval: TimerInterval, isNew: Bool, onSave: @escaping (TimerInterval) -> Void, onCancel: @escaping () -> Void) {
        self.interval = interval
        self.isNew = isNew
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize state properties
        _name = State(initialValue: interval.name)
        _duration = State(initialValue: interval.duration)
        _type = State(initialValue: interval.type)
        _color = State(initialValue: interval.color)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Interval Details")) {
                    TextField("Name (optional)", text: $name)
                    
                    Picker("Type", selection: $type) {
                        ForEach(IntervalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    VStack(alignment: .leading) {
                        Text("Duration: \(formattedDuration)")
                            .font(.headline)
                        
                        HStack {
                            Stepper("Minutes", value: $duration, in: 0...3600, step: 60)
                                .labelsHidden()
                            
                            Text("\(duration / 60) min")
                                .frame(width: 60, alignment: .trailing)
                        }
                        
                        HStack {
                            Stepper("Seconds", value: $duration, in: 0...3600, step: 5)
                                .labelsHidden()
                            
                            Text("\(duration % 60) sec")
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(colors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex) ?? .blue)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(colorHex == color ? Color.white : Color.clear, lineWidth: 2)
                                        .padding(2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(colorHex == color ? Color.black : Color.clear, lineWidth: 1)
                                        .padding(3)
                                )
                                .onTapGesture {
                                    color = colorHex
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(isNew ? "Add Interval" : "Edit Interval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updatedInterval = TimerInterval(
                            name: name,
                            duration: duration,
                            type: type,
                            color: color
                        )
                        onSave(updatedInterval)
                    }
                    .disabled(duration <= 0)
                }
            }
        }
    }
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension IntervalType: CaseIterable {
    static var allCases: [IntervalType] {
        [.preparation, .work, .rest]
    }
}

#Preview {
    // Create a binding for the preview
    let intervals: [TimerInterval] = [
        TimerInterval(name: "Warm Up", duration: 180, type: .work, color: "#4285F4"),
        TimerInterval(name: "", duration: 60, type: .rest, color: "#EA4335"),
        TimerInterval(name: "High Intensity", duration: 300, type: .work, color: "#FBBC05")
    ]
    
    IntervalEditorView(intervals: .constant(intervals))
} 