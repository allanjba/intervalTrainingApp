import Foundation
import AVFoundation
import UIKit

enum SoundType: String, CaseIterable {
    case startBeep = "StartBeep"
    case endBeep = "EndBeep"
    case intervalChange = "IntervalChange"
    case completed = "Completed"
    
    var displayName: String {
        switch self {
        case .startBeep: return "Start Sound"
        case .endBeep: return "End Sound"
        case .intervalChange: return "Interval Change"
        case .completed: return "Completed"
        }
    }
}

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [SoundType: AVAudioPlayer] = [:]
    private var isEnabled: Bool = true
    private var soundsLoaded: Bool = false
    
    private init() {
        setupAudioSession()
        preloadSounds()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func preloadSounds() {
        var anyLoaded = false
        for soundType in SoundType.allCases {
            if loadSound(type: soundType) {
                anyLoaded = true
            }
        }
        soundsLoaded = anyLoaded
        
        if !soundsLoaded {
            print("⚠️ No sound files found. Audio feedback will be disabled.")
        }
    }
    
    private func loadSound(type: SoundType) -> Bool {
        guard let soundURL = Bundle.main.url(forResource: type.rawValue, withExtension: "mp3") else {
            // Try without extension in case they're in Assets catalog
            guard let assetURL = Bundle.main.url(forResource: type.rawValue, withExtension: nil) else {
                print("Sound file not found: \(type.rawValue)")
                return false
            }
            
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: assetURL)
                audioPlayer.prepareToPlay()
                audioPlayers[type] = audioPlayer
                return true
            } catch {
                print("Failed to load sound: \(error)")
                return false
            }
        }
        
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer.prepareToPlay()
            audioPlayers[type] = audioPlayer
            return true
        } catch {
            print("Failed to load sound: \(error)")
            return false
        }
    }
    
    func playSound(type: SoundType) {
        // If no sounds loaded, don't try to play
        guard soundsLoaded, isEnabled, let player = audioPlayers[type] else { 
            // Fallback to haptic feedback if sounds aren't available
            if isEnabled {
                provideFallbackHapticFeedback()
            }
            return 
        }
        
        player.currentTime = 0
        player.play()
    }
    
    private func provideFallbackHapticFeedback() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
    
    func toggleSound(enabled: Bool) {
        isEnabled = enabled
    }
    
    var soundEnabled: Bool {
        isEnabled
    }
} 