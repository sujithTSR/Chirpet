import AppKit
import SwiftUI

public class HitTestHostingView<Content: View>: NSHostingView<Content> {
    public weak var viewModel: PetViewModel?
    
    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard let viewModel = viewModel else { return super.hitTest(point) }
        
        if viewModel.isClickThrough {
            return nil
        }
        
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = hypot(dx, dy)
        
        if distance <= 38 {
            return super.hitTest(point)
        } else {
            return nil
        }
    }
    
    public override func rightMouseDown(with event: NSEvent) {
        viewModel?.showSettingsMenu()
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
        
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        let hostingView = HitTestHostingView(rootView: PetView(viewModel: viewModel))
        hostingView.viewModel = viewModel
        self.contentView = hostingView
        
        viewModel.window = self
    }
}
