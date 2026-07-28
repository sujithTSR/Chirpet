import AppKit
import SwiftUI

public class HitTestHostingView<Content: View>: NSHostingView<Content> {
    public weak var viewModel: PetViewModel?
    
    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard let viewModel = viewModel else { return super.hitTest(point) }
        
        // If click-through mode is explicitly enabled, pass ALL clicks through
        if viewModel.isClickThrough {
            return nil
        }
        
        // Calculate distance from center of window frame (110x110)
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = hypot(dx, dy)
        
        // Only intercept mouse clicks if point is within pet avatar circle (radius: 38pt)
        if distance <= 38 {
            return super.hitTest(point)
        } else {
            // Surrounding transparent padding area allows regular clicks through to apps underneath!
            return nil
        }
    }
}

public class PetPanel: NSPanel {
    public init(contentRect: NSRect, viewModel: PetViewModel) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovableByWindowBackground = true
        self.ignoresMouseEvents = false
        
        // Ensure pet is present across all Spaces / Virtual Desktops
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        let hostingView = HitTestHostingView(rootView: PetView(viewModel: viewModel))
        hostingView.viewModel = viewModel
        self.contentView = hostingView
        
        viewModel.window = self
    }
}
