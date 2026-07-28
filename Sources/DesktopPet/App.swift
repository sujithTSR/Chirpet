import AppKit
import SwiftUI

@main
struct DesktopPetApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // Runs cleanly as menu bar app + floating overlay
        app.run()
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var viewModel: PetViewModel!
    private var petPanel: PetPanel!
    private var ballPanel: BallPanel!
    private var statusBarController: StatusBarMenuController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel = PetViewModel()
        
        let initialRect = NSRect(x: 500, y: 500, width: 110, height: 110)
        petPanel = PetPanel(contentRect: initialRect, viewModel: viewModel)
        petPanel.orderFront(nil)
        
        let ballRect = NSRect(x: -200, y: -200, width: 60, height: 60)
        ballPanel = BallPanel(contentRect: ballRect, viewModel: viewModel)
        
        statusBarController = StatusBarMenuController(viewModel: viewModel)
        
        print("🐾 macOS Desktop Pet started successfully!")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }
}
