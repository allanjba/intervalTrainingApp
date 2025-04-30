import SwiftUI

struct TimerFaceView: View {
    var currentTime: String
    var intervalName: String
    var intervalType: IntervalType
    var progress: CGFloat
    var color: Color
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 15)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
            
            // Text content
            VStack(spacing: 10) {
                Text(intervalName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(intervalType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(currentTime)
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .padding()
        }
        .padding()
        .aspectRatio(1, contentMode: .fit)
    }
}

struct TimerControlsView: View {
    var timerState: TimerState
    var onStart: () -> Void
    var onPause: () -> Void
    var onStop: () -> Void
    var onReset: () -> Void
    
    var body: some View {
        HStack(spacing: 30) {
            // Reset button
            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Main action button (play/pause)
            Button(action: {
                if timerState == .running {
                    onPause()
                } else {
                    onStart()
                }
            }) {
                Image(systemName: timerState == .running ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            
            // Stop button
            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 44, height: 44)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
    }
}

#Preview {
    VStack {
        TimerFaceView(
            currentTime: "02:30",
            intervalName: "Warm Up",
            intervalType: .work,
            progress: 0.65,
            color: .blue
        )
        
        TimerControlsView(
            timerState: .running,
            onStart: {},
            onPause: {},
            onStop: {},
            onReset: {}
        )
    }
    .padding()
} 