import AppKit
import SwiftUI

public struct BallView: View {
    let rotation: Double
    
    public var body: some View {
        ZStack {
            // Shadow under ball
            Ellipse()
                .fill(Color.black.opacity(0.25))
                .frame(width: 24, height: 8)
                .offset(y: 16)
                .blur(radius: 2)
            
            // Spinning Tennis Ball
            Text("🎾")
                .font(.system(size: 32))
                .rotationEffect(.degrees(rotation))
                .shadow(color: .black.opacity(0.2), radius: 3)
        }
        .frame(width: 60, height: 60)
    }
}

public class BallPanel: NSPanel {
    @MainActor
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
        self.ignoresMouseEvents = true // Completely non-blocking
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        let hostingView = NSHostingView(rootView: BallHostingView(viewModel: viewModel))
        self.contentView = hostingView
        
        viewModel.ballWindow = self
    }
}

struct BallHostingView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var rotation: Double = 0
    
    var body: some View {
        BallView(rotation: rotation)
            .onChange(of: viewModel.ballPos) { _ in
                withAnimation(.linear(duration: 0.1)) {
                    rotation += 25
                }
            }
    }
}
