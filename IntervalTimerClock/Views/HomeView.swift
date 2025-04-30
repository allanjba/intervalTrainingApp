import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [TimerConfiguration]
    
    @State private var showingNewTimer = false
    @State private var editingConfiguration: TimerConfiguration?
    @State private var searchText = ""
    
    var filteredConfigurations: [TimerConfiguration] {
        if searchText.isEmpty {
            return configurations
        } else {
            return configurations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Top welcome section
                welcomeSection
                
                // Saved timers
                if filteredConfigurations.isEmpty {
                    emptyStateView
                } else {
                    timerList
                }
            }
            .navigationTitle("Interval Timer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewTimer = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search timers")
            .sheet(isPresented: $showingNewTimer) {
                TimerConfigurationView()
            }
            .sheet(item: $editingConfiguration) { config in
                TimerConfigurationView(configuration: config)
            }
        }
    }
    
    // MARK: - View Sections
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome to Interval Timer")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Create custom interval timers for your workouts.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "timer")
                .font(.system(size: 70))
                .foregroundColor(.secondary.opacity(0.7))
            
            Text("No Timers Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Tap + to create your first interval timer")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingNewTimer = true
            }) {
                Text("Create Timer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)
            
            Spacer()
        }
        .padding()
    }
    
    private var timerList: some View {
        List {
            if !recentTimers.isEmpty {
                Section(header: Text("Recent")) {
                    ForEach(recentTimers) { config in
                        TimerRow(configuration: config)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTimer(config)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    editingConfiguration = config
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
            
            Section(header: Text("All Timers")) {
                ForEach(filteredConfigurations.filter { !recentTimers.contains($0) }) { config in
                    TimerRow(configuration: config)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteTimer(config)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                editingConfiguration = config
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    var recentTimers: [TimerConfiguration] {
        // Get timers that have been used in the last 7 days
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return filteredConfigurations
            .filter { $0.lastUsed != nil && $0.lastUsed! > lastWeek }
            .sorted { $0.lastUsed! > $1.lastUsed! }
            .prefix(3)
            .map { $0 }
    }
    
    private func deleteTimer(_ config: TimerConfiguration) {
        modelContext.delete(config)
    }
}

struct TimerRow: View {
    let configuration: TimerConfiguration
    
    var body: some View {
        NavigationLink(destination: TimerRunView(configuration: configuration)) {
            HStack(spacing: 15) {
                // Color indicator based on first interval
                Circle()
                    .fill(configuration.intervals.first?.uiColor ?? .gray)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(configuration.name)
                        .font(.headline)
                    
                    HStack {
                        Text("\(configuration.intervals.count) intervals")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(configuration.displayTotalDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Show recently used indicator if applicable
                if let lastUsed = configuration.lastUsed {
                    if Calendar.current.isDateInToday(lastUsed) {
                        Text("Today")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview("Home View") {
    // Mock a HomeView with an empty container
    HomeView()
        .modelContainer(for: [TimerConfiguration.self, TimerInterval.self], inMemory: true)
}

// Helper function to create sample data for preview
func createSampleTimers() -> [TimerConfiguration] {
    let warmupInterval = TimerInterval(name: "Warm Up", duration: 180, type: .work, color: "#4285F4")
    let restInterval = TimerInterval(name: "", duration: 60, type: .rest, color: "#EA4335")
    let workInterval = TimerInterval(name: "High Intensity", duration: 300, type: .work, color: "#FBBC05")
    
    let timer1 = TimerConfiguration(name: "HIIT Workout", intervals: [warmupInterval, restInterval, workInterval])
    timer1.lastUsed = Date()
    
    let timer2 = TimerConfiguration(name: "Quick Stretch", intervals: [
        TimerInterval(name: "Preparation", duration: 30, type: .preparation, color: "#34A853"),
        TimerInterval(name: "Stretch 1", duration: 60, type: .work, color: "#8E44AD"),
        TimerInterval(name: "Rest", duration: 15, type: .rest, color: "#E74C3C")
    ])
    timer2.lastUsed = Calendar.current.date(byAdding: .day, value: -1, to: Date())
    
    return [timer1, timer2]
} 