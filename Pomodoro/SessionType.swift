import Foundation
import AppKit

/// Represents the different types of Pomodoro sessions
// 修改 1：将基础类型从 NSImage 改回 String
enum SessionType: String, CaseIterable {
    case work = "Work Session"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    /// Duration in seconds for each session type
    var duration: TimeInterval {
        switch self {
        case .work:
            return 25 * 60  // 25 minutes
        case .shortBreak:
            return 5 * 60   // 5 minutes
        case .longBreak:
            return 15 * 60  // 15 minutes
        }
    }
    
    var imageName: String {
        switch self {
        case .work:
            return "tomato"
        case .shortBreak:
            return "coffee"
        case .longBreak:
            return "palmtree"
        }
    }
    
    var runningImageName: String {
        switch self {
        case .work:
            return "tomato_running"
        case .shortBreak:
            return "coffee_running"
        case .longBreak:
            return "palmtree_running"
        }
    }
    
    func iconImage(isRunning: Bool) -> NSImage? {
        let name = isRunning ? runningImageName : imageName
        let image = NSImage(named: name)
        image?.size = NSSize(width: 18, height: 18)
        image?.isTemplate = true
        return image
    }
    
    // （可选）如果你在系统通知（Notification）里依然需要用到 Emoji 文本
    // 你可以额外加一个属性专门用来返回 String
    var iconEmoji: String {
        switch self {
        case .work: return "🍅"
        case .shortBreak: return "☕️"
        case .longBreak: return "🌴"
        }
    }
}
