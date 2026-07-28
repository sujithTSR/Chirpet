import SwiftUI
import AppKit

public struct PetView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var bounceOffset: CGFloat = 0
    
    public init(viewModel: PetViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            // Particle system overlay
            ForEach(viewModel.particles) { particle in
                Text(particle.symbol)
                    .font(.system(size: 20))
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .offset(y: -particle.y + viewModel.currentPos.y)
                    .allowsHitTesting(false)
            }
            
            VStack(spacing: 2) {
                // Speech / Note / Status Bubble
                if !viewModel.noteText.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                        Text(viewModel.noteText)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .lineLimit(2)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 3)
                    .transition(.scale.combined(with: .opacity))
                } else if viewModel.isSleeping {
                    Text("💤 Zzz...")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 3)
                        .transition(.scale.combined(with: .opacity))
                } else if viewModel.state == .catchGame && viewModel.fetchScore > 0 {
                    Text("🎾 Catches: \(viewModel.fetchScore)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 2)
                }
                
                // Pet Avatar Container
                ZStack {
                    // Soft glow shadow underneath pet
                    Ellipse()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 45, height: 12)
                        .offset(y: 28)
                        .blur(radius: 2)
                    
                    // Main Avatar Visual
                    PetAvatarGraphic(
                        character: viewModel.character,
                        isMoving: viewModel.isMoving,
                        isSleeping: viewModel.isSleeping,
                        animationFrame: viewModel.animationFrame,
                        facingLeft: viewModel.facingLeft
                    )
                    .scaleEffect(viewModel.facingLeft ? -1.0 : 1.0, anchor: .center)
                    .offset(y: bounceOffset)
                    
                    // Tennis ball held in mouth during Catch Mode!
                    if viewModel.isHoldingBall {
                        Text("🎾")
                            .font(.system(size: 18))
                            .offset(x: viewModel.facingLeft ? -18 : 18, y: 4)
                            .transition(.scale)
                    }
                }
                .frame(width: 80, height: 80)
                .contentShape(Rectangle())
                .onTapGesture {
                    triggerPettingAnimation()
                }
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            viewModel.currentPos = CGPoint(
                                x: viewModel.currentPos.x + gesture.translation.width,
                                y: viewModel.currentPos.y - gesture.translation.height
                            )
                        }
                )
            }
        }
        .frame(width: 110, height: 110)
        .onChange(of: viewModel.animationFrame) { _ in
            if viewModel.isMoving && !viewModel.isSleeping {
                withAnimation(.easeInOut(duration: 0.15)) {
                    bounceOffset = (viewModel.animationFrame % 2 == 0) ? -4 : 0
                }
            } else {
                bounceOffset = 0
            }
        }
    }
    
    private func triggerPettingAnimation() {
        viewModel.petTheAnimal()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            bounceOffset = -12
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                bounceOffset = 0
            }
        }
    }
}

// Custom rendered vector pet avatars for Cat, Dog, Dragon, and Bunny
struct PetAvatarGraphic: View {
    let character: PetCharacter
    let isMoving: Bool
    let isSleeping: Bool
    let animationFrame: Int
    let facingLeft: Bool
    
    var body: some View {
        ZStack {
            switch character {
            case .cat:
                CatGraphic(isSleeping: isSleeping, isMoving: isMoving, frame: animationFrame)
            case .dog:
                DogGraphic(isSleeping: isSleeping, isMoving: isMoving, frame: animationFrame)
            case .dragon:
                DragonGraphic(isSleeping: isSleeping, isMoving: isMoving, frame: animationFrame)
            case .bunny:
                BunnyGraphic(isSleeping: isSleeping, isMoving: isMoving, frame: animationFrame)
            }
        }
    }
}

// 🐱 Cat Graphic
struct CatGraphic: View {
    let isSleeping: Bool
    let isMoving: Bool
    let frame: Int
    
    var body: some View {
        ZStack {
            // Body
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .top, endPoint: .bottom))
                .frame(width: 44, height: 40)
            
            // Ears
            HStack(spacing: 24) {
                Triangle().fill(Color.orange).frame(width: 12, height: 14)
                Triangle().fill(Color.orange).frame(width: 12, height: 14)
            }
            .offset(y: -22)
            
            // Inner ears
            HStack(spacing: 26) {
                Triangle().fill(Color.pink.opacity(0.7)).frame(width: 6, height: 8)
                Triangle().fill(Color.pink.opacity(0.7)).frame(width: 6, height: 8)
            }
            .offset(y: -21)
            
            // Eyes
            if isSleeping {
                HStack(spacing: 12) {
                    Text("◡").font(.system(size: 14, weight: .bold)).foregroundColor(.brown)
                    Text("◡").font(.system(size: 14, weight: .bold)).foregroundColor(.brown)
                }
                .offset(y: -4)
            } else {
                HStack(spacing: 12) {
                    Circle().fill(Color.black).frame(width: 6, height: 6)
                    Circle().fill(Color.black).frame(width: 6, height: 6)
                }
                .offset(y: -4)
                
                HStack(spacing: 14) {
                    Circle().fill(Color.white).frame(width: 2, height: 2).offset(x: 1, y: -1)
                    Circle().fill(Color.white).frame(width: 2, height: 2).offset(x: 1, y: -1)
                }
                .offset(y: -4)
            }
            
            // Nose & Whiskers
            VStack(spacing: 2) {
                Triangle()
                    .fill(Color.pink)
                    .frame(width: 5, height: 4)
                    .rotationEffect(.degrees(180))
                
                Text("ω")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.brown)
                    .offset(y: -4)
            }
            .offset(y: 4)
            
            // Cheeks
            HStack(spacing: 24) {
                Circle().fill(Color.pink.opacity(0.5)).frame(width: 7, height: 7)
                Circle().fill(Color.pink.opacity(0.5)).frame(width: 7, height: 7)
            }
            .offset(y: 2)
            
            // Tail
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(to: CGPoint(x: 15, y: -15), control: CGPoint(x: 15, y: 0))
            }
            .stroke(Color.orange, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            .offset(x: -20, y: 10)
            .rotationEffect(.degrees(isMoving ? Double(frame * 10) : 0))
        }
    }
}

// 🐶 Prettier Dog Graphic
struct DogGraphic: View {
    let isSleeping: Bool
    let isMoving: Bool
    let frame: Int
    
    var body: some View {
        ZStack {
            // Wagging Tail
            Capsule()
                .fill(Color(red: 0.85, green: 0.55, blue: 0.22))
                .frame(width: 10, height: 24)
                .offset(x: -24, y: 4)
                .rotationEffect(.degrees(isMoving ? Double(frame * 18 - 25) : -30))
            
            // Paws / Running Legs
            HStack(spacing: 16) {
                Capsule()
                    .fill(Color(red: 0.75, green: 0.45, blue: 0.18))
                    .frame(width: 10, height: 14)
                    .offset(y: isMoving ? CGFloat((frame % 2 == 0) ? 14 : 10) : 14)
                Capsule()
                    .fill(Color(red: 0.75, green: 0.45, blue: 0.18))
                    .frame(width: 10, height: 14)
                    .offset(y: isMoving ? CGFloat((frame % 2 != 0) ? 14 : 10) : 14)
            }
            .offset(y: 8)
            
            // Main Body (Golden Retriever Coat)
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.72, blue: 0.38),
                            Color(red: 0.85, green: 0.55, blue: 0.22)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 48, height: 44)
                .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
            
            // Creamy Chest Patch
            Ellipse()
                .fill(Color(red: 0.98, green: 0.95, blue: 0.88))
                .frame(width: 22, height: 26)
                .offset(y: 6)
            
            // Floppy Bouncing Ears
            HStack(spacing: 36) {
                Capsule()
                    .fill(Color(red: 0.55, green: 0.32, blue: 0.12))
                    .frame(width: 13, height: 28)
                    .rotationEffect(.degrees(isMoving ? Double(frame * 8 - 10) : 12))
                
                Capsule()
                    .fill(Color(red: 0.55, green: 0.32, blue: 0.12))
                    .frame(width: 13, height: 28)
                    .rotationEffect(.degrees(isMoving ? Double(-frame * 8 + 10) : -12))
            }
            .offset(y: -10)
            
            // Eyes
            if isSleeping {
                HStack(spacing: 14) {
                    Text("◡").font(.system(size: 15, weight: .bold)).foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                    Text("◡").font(.system(size: 15, weight: .bold)).foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                }
                .offset(y: -6)
            } else {
                HStack(spacing: 14) {
                    Circle().fill(Color(red: 0.2, green: 0.1, blue: 0.05)).frame(width: 7, height: 7)
                    Circle().fill(Color(red: 0.2, green: 0.1, blue: 0.05)).frame(width: 7, height: 7)
                }
                .offset(y: -6)
                
                // Sparkle eye highlights
                HStack(spacing: 16) {
                    Circle().fill(Color.white).frame(width: 2.5, height: 2.5).offset(x: 1, y: -1)
                    Circle().fill(Color.white).frame(width: 2.5, height: 2.5).offset(x: 1, y: -1)
                }
                .offset(y: -6)
            }
            
            // Cute White Muzzle
            Ellipse()
                .fill(Color(red: 0.98, green: 0.95, blue: 0.88))
                .frame(width: 22, height: 16)
                .offset(y: 4)
            
            // Black Heart Nose & Wagging Pink Tongue
            VStack(spacing: 0) {
                Triangle()
                    .fill(Color(red: 0.15, green: 0.1, blue: 0.05))
                    .frame(width: 7, height: 5)
                    .rotationEffect(.degrees(180))
                
                if isMoving {
                    Capsule()
                        .fill(Color.pink)
                        .frame(width: 6, height: 9)
                        .offset(y: -1)
                } else {
                    Text("ω")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.25, blue: 0.1))
                        .offset(y: -4)
                }
            }
            .offset(y: 2)
            
            // Rosy Cheeks
            HStack(spacing: 26) {
                Circle().fill(Color.pink.opacity(0.4)).frame(width: 6, height: 6)
                Circle().fill(Color.pink.opacity(0.4)).frame(width: 6, height: 6)
            }
            .offset(y: 2)
        }
    }
}

// 🐉 Dragon Graphic
struct DragonGraphic: View {
    let isSleeping: Bool
    let isMoving: Bool
    let frame: Int
    
    var body: some View {
        ZStack {
            // Wings
            HStack(spacing: 32) {
                Image(systemName: "wing")
                    .font(.system(size: 20))
                    .foregroundColor(.mint)
                    .rotationEffect(.degrees(isMoving ? Double(frame * 15 - 15) : 0))
                Image(systemName: "wing")
                    .font(.system(size: 20))
                    .foregroundColor(.mint)
                    .scaleEffect(x: -1, y: 1)
                    .rotationEffect(.degrees(isMoving ? Double(-frame * 15 + 15) : 0))
            }
            .offset(y: -12)
            
            // Body
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Color.emeraldGreen, Color.teal], startPoint: .top, endPoint: .bottom))
                .frame(width: 42, height: 38)
            
            // Horns
            HStack(spacing: 20) {
                Triangle().fill(Color.yellow).frame(width: 8, height: 12)
                Triangle().fill(Color.yellow).frame(width: 8, height: 12)
            }
            .offset(y: -22)
            
            // Eyes
            if isSleeping {
                Text("u  u").font(.system(size: 12, weight: .bold)).foregroundColor(.yellow).offset(y: -4)
            } else {
                HStack(spacing: 14) {
                    Circle().fill(Color.yellow).frame(width: 7, height: 7)
                    Circle().fill(Color.yellow).frame(width: 7, height: 7)
                }
                .offset(y: -4)
            }
        }
    }
}

// 🐰 Bunny Graphic
struct BunnyGraphic: View {
    let isSleeping: Bool
    let isMoving: Bool
    let frame: Int
    
    var body: some View {
        ZStack {
            // Ears
            HStack(spacing: 12) {
                Capsule().fill(Color.white).frame(width: 10, height: 30)
                Capsule().fill(Color.white).frame(width: 10, height: 30)
            }
            .offset(y: -24)
            
            HStack(spacing: 12) {
                Capsule().fill(Color.pink.opacity(0.6)).frame(width: 5, height: 22)
                Capsule().fill(Color.pink.opacity(0.6)).frame(width: 5, height: 22)
            }
            .offset(y: -24)
            
            // Body
            Circle()
                .fill(Color.white)
                .frame(width: 42, height: 42)
                .shadow(color: .black.opacity(0.1), radius: 2)
            
            // Eyes
            if isSleeping {
                Text("-  -").font(.system(size: 14, weight: .bold)).foregroundColor(.black).offset(y: -4)
            } else {
                HStack(spacing: 12) {
                    Circle().fill(Color.black).frame(width: 5, height: 5)
                    Circle().fill(Color.black).frame(width: 5, height: 5)
                }
                .offset(y: -4)
            }
            
            // Nose
            Triangle().fill(Color.pink).frame(width: 4, height: 4).rotationEffect(.degrees(180)).offset(y: 2)
            
            // Cheeks
            HStack(spacing: 22) {
                Circle().fill(Color.pink.opacity(0.4)).frame(width: 6, height: 6)
                Circle().fill(Color.pink.opacity(0.4)).frame(width: 6, height: 6)
            }
            .offset(y: 2)
        }
    }
}

// Helper Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

extension Color {
    static let emeraldGreen = Color(red: 0.1, green: 0.7, blue: 0.4)
}
