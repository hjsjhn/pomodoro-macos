import AppKit
import SwiftUI

/// Manages the fullscreen countdown overlay window
class CountdownOverlayWindow {
    private var window: NSWindow?
    
    /// Show the countdown overlay on all screens
    func show(number: Int, sessionType: SessionType) {
        // If window already exists, just update it
        if let window = window {
            updateContent(number: number, sessionType: sessionType)
            return
        }
        
        // Get the main screen bounds
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        
        // Create a borderless, transparent window
        let window = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .screenSaver  // Above everything
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true  // Click-through
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Set the SwiftUI content
        window.contentView = NSHostingView(rootView: CountdownOverlayView(number: number, sessionType: sessionType))
        
        // Show the window
        window.orderFrontRegardless()
        
        self.window = window
    }
    
    /// Update the countdown number
    func updateContent(number: Int, sessionType: SessionType) {
        window?.contentView = NSHostingView(rootView: CountdownOverlayView(number: number, sessionType: sessionType))
    }
    
    /// Hide and release the overlay window
    func hide() {
        window?.orderOut(nil)
        window = nil
    }
    
    /// Check if overlay is currently visible
    var isVisible: Bool {
        return window != nil
    }
}
