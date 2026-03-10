import Foundation
import Combine

/// Manages the Pomodoro timer state and logic
@Observable
class TimerManager {
    // MARK: - Properties
    
    /// Current time remaining in seconds
    var timeRemaining: TimeInterval
    
    /// Current session type
    var currentSession: SessionType = .work
    
    /// Whether the timer is currently running
    var isRunning: Bool = false
    
    /// Number of completed pomodoros in the current cycle
    var completedPomodoros: Int = 0
    
    /// Total pomodoros before a long break
    let pomodorosBeforeLongBreak: Int = 4
    
    /// Auto-mode: automatically start next session
    var isAutoMode: Bool = false
    
    /// Whether to show the countdown overlay (last 5 seconds)
    var showCountdownOverlay: Bool {
        return isRunning && timeRemaining <= 5 && timeRemaining > 0
    }
    
    /// Current countdown number for overlay (3, 2, or 1)
    var countdownNumber: Int {
        return Int(ceil(timeRemaining))
    }
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var notificationManager = NotificationManager()
    private let settings: SettingsManager
    
    // MARK: - Initialization
    
    init(settings: SettingsManager) {
        self.settings = settings
        self.timeRemaining = settings.duration(for: .work)
        
        setupNotificationActions()
    }
    
    private func setupNotificationActions() {
        notificationManager.onAction = { [weak self] action in
            DispatchQueue.main.async {
                self?.handleNotificationAction(action)
            }
        }
    }
    
    private func handleNotificationAction(_ action: String) {
        switch action {
        case "ACTION_REST", "ACTION_CONTINUE":
            start()
        case "ACTION_PAUSE":
            pause()
        default:
            break
        }
    }
    
    // MARK: - Computed Properties
    
    /// Formatted time string (MM:SS)
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Progress from 0.0 to 1.0
    var progress: Double {
        let total = settings.duration(for: currentSession)
        return (total - timeRemaining) / total
    }
    

    // MARK: - Timer Controls
    
    /// Start or resume the timer
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    /// Pause the timer
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    /// Toggle between start and pause
    func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    /// Reset the current session
    func reset() {
        pause()
        timeRemaining = settings.duration(for: currentSession)
    }
    
    /// Skip to the next session
    func skip() {
        pause()
        if currentSession == .work {
            completedPomodoros += 1
        }
        moveToNextSession()
    }
    
    /// Refresh duration from settings (call when settings change)
    func refreshDuration() {
        if !isRunning {
            timeRemaining = settings.duration(for: currentSession)
        }
    }
    
    // MARK: - Private Methods
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            sessionCompleted()
        }
    }
    
    private func sessionCompleted() {
        pause()
        
        // Send notification
        notificationManager.sendSessionCompleteNotification(session: currentSession)
        
        // Update completed pomodoros if work session finished
        if currentSession == .work {
            completedPomodoros += 1
        }
        
        moveToNextSession()
        
        // Auto-start next session if enabled
        if isAutoMode {
            start()
        }
    }
    
    private func moveToNextSession() {
        switch currentSession {
        case .work:
            // Check if it's time for a long break
            if completedPomodoros > 0 && completedPomodoros % pomodorosBeforeLongBreak == 0 {
                currentSession = .longBreak
            } else {
                currentSession = .shortBreak
            }
        case .shortBreak, .longBreak:
            currentSession = .work
        }
        
        timeRemaining = settings.duration(for: currentSession)
    }
    
    /// Reset everything to initial state
    func resetAll() {
        pause()
        completedPomodoros = 0
        currentSession = .work
        timeRemaining = settings.duration(for: currentSession)
    }
}
