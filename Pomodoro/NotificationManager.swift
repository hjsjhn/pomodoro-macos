import Foundation
import UserNotifications

/// Manages system notifications for the Pomodoro app
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    var onAction: ((String) -> Void)?
    
    override init() {
        super.init()
        setupCategories()
        requestPermission()
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func setupCategories() {
        let restAction = UNNotificationAction(identifier: "ACTION_REST", title: "休息", options: [])
        let pauseAction = UNNotificationAction(identifier: "ACTION_PAUSE", title: "暂停", options: [])
        let continueAction = UNNotificationAction(identifier: "ACTION_CONTINUE", title: "继续", options: [])
        
        let workCategory = UNNotificationCategory(identifier: "WORK_COMPLETE", actions: [restAction, pauseAction], intentIdentifiers: [], options: [])
        let breakCategory = UNNotificationCategory(identifier: "BREAK_COMPLETE", actions: [continueAction, pauseAction], intentIdentifiers: [], options: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([workCategory, breakCategory])
    }
    
    /// Request notification permissions from the user
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Send a notification when a session completes
    func sendSessionCompleteNotification(session: SessionType) {
        let content = UNMutableNotificationContent()
        
        switch session {
        case .work:
            content.title = "工作结束！ \(session.iconEmoji)"
            content.body = "做得好！该休息一下了。"
            content.sound = .default
            content.categoryIdentifier = "WORK_COMPLETE"
        case .shortBreak:
            content.title = "休息结束！ \(session.iconEmoji)"
            content.body = "准备好再次专注了吗？"
            content.sound = .default
            content.categoryIdentifier = "BREAK_COMPLETE"
        case .longBreak:
            content.title = "长休息结束！ \(session.iconEmoji)"
            content.body = "感觉神清气爽？我们继续工作吧！"
            content.sound = .default
            content.categoryIdentifier = "BREAK_COMPLETE"
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        
        if actionIdentifier == UNNotificationDefaultActionIdentifier {
            // User clicked the notification directly
            onAction?("ACTION_CONTINUE") // This acts as both 'Rest' and 'Continue' since TimerManager just calls start()
        } else {
            onAction?(actionIdentifier)
        }
        
        completionHandler()
    }
}
