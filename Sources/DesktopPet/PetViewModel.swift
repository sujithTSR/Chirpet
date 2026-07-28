import Foundation
import Combine
import AppKit

public enum PetState: String, CaseIterable, Identifiable {
    case active = "Active (Follow Mouse)"
    case catchGame = "Play Catch 🎾"
    case home = "Home (Resting in Corner)"
    case disabled = "Disabled (Hidden)"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .active: return "location.fill"
        case .catchGame: return "tennisball.fill"
        case .home: return "house.fill"
        case .disabled: return "eye.slash.fill"
        }
    }
}

public enum FetchPhase: Equatable {
    case idle
    case ballFlying
    case reactionPause(until: Date)
    case sprintingToBall
    case pickUpPause(until: Date)
    case returningToCursor
    
    public var isBallOnScreen: Bool {
        switch self {
        case .ballFlying, .reactionPause, .sprintingToBall:
            return true
        default:
            return false
        }
    }
}

public enum PetCharacter: String, CaseIterable, Identifiable {
    case cat = "🐱 Cat"
    case dog = "🐶 Dog"
    case dragon = "🐉 Dragon"
    case bunny = "🐰 Bunny"
    
    public var id: String { rawValue }
}

public enum ScreenCorner: String, CaseIterable, Identifiable {
    case bottomRight = "Bottom Right"
    case bottomLeft = "Bottom Left"
    case topRight = "Top Right"
    case topLeft = "Top Left"
    
    public var id: String { rawValue }
}

public struct Particle: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var opacity: Double = 1.0
    public var scale: CGFloat = 1.0
    public let symbol: String
}

@MainActor
public class PetViewModel: ObservableObject {
    @Published public var state: PetState = .active {
        didSet {
            onStateChanged()
        }
    }
    @Published public var character: PetCharacter = .dog
    @Published public var homeCorner: ScreenCorner = .bottomRight
    @Published public var followSpeed: Double = 0.15
    @Published public var facingLeft: Bool = false
    @Published public var isMoving: Bool = false
    @Published public var isSleeping: Bool = false
    @Published public var animationFrame: Int = 0
    @Published public var isClickThrough: Bool = false {
        didSet {
            window?.ignoresMouseEvents = isClickThrough
            statusMessage = isClickThrough ? "Click-through mode ON" : "Interactive mode"
        }
    }
    @Published public var particles: [Particle] = []
    @Published public var petCount: Int = 0
    @Published public var statusMessage: String = "Following mouse!"
    
    // Play Catch (Fetch) state variables
    @Published public var ballPos: CGPoint? = nil
    @Published public var ballTargetPos: CGPoint? = nil
    @Published public var fetchPhase: FetchPhase = .idle
    @Published public var isHoldingBall: Bool = false
    @Published public var fetchScore: Int = 0
    
    // Note & Audio state variables
    @Published public var noteText: String = ""
    @Published public var soundEnabled: Bool = true
    
    public var currentPos: CGPoint = CGPoint(x: 500, y: 500)
    public var targetPos: CGPoint = CGPoint(x: 500, y: 500)
    
    private var timer: AnyCancellable?
    private var frameCounter: Int = 0
    public weak var window: NSWindow?
    public weak var ballWindow: NSWindow?
    
    public init() {
        startLoop()
    }
    
    private func startLoop() {
        timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.update()
            }
    }
    
    private func onStateChanged() {
        switch state {
        case .active:
            isSleeping = false
            ballPos = nil
            ballTargetPos = nil
            fetchPhase = .idle
            isHoldingBall = false
            ballWindow?.setIsVisible(false)
            statusMessage = "Following mouse cursor"
            if let win = window {
                win.setIsVisible(true)
                win.orderFront(nil)
            }
        case .catchGame:
            isSleeping = false
            fetchPhase = .idle
            statusMessage = "Click pet to throw ball! 🎾"
            if let win = window {
                win.setIsVisible(true)
                win.orderFront(nil)
            }
        case .home:
            ballPos = nil
            ballTargetPos = nil
            fetchPhase = .idle
            isHoldingBall = false
            ballWindow?.setIsVisible(false)
            statusMessage = "Heading to home corner"
            if let win = window {
                win.setIsVisible(true)
                win.orderFront(nil)
            }
        case .disabled:
            isSleeping = false
            ballWindow?.setIsVisible(false)
            statusMessage = "Pet disabled"
            window?.setIsVisible(false)
        }
    }
    
    private func update() {
        guard state != .disabled else { return }
        
        frameCounter += 1
        if frameCounter % 6 == 0 {
            animationFrame = (animationFrame + 1) % 4
        }
        
        let mouseLoc = NSEvent.mouseLocation
        
        // Update physics & targets based on mode
        switch state {
        case .active:
            targetPos = CGPoint(x: mouseLoc.x + 20, y: mouseLoc.y - 20)
            isSleeping = false
            
        case .catchGame:
            isSleeping = false
            
            switch fetchPhase {
            case .idle:
                targetPos = CGPoint(x: mouseLoc.x + 20, y: mouseLoc.y - 20)
                
            case .ballFlying:
                // STEP 1: Ball glides smoothly across desktop; pet stands eager & watches!
                if let target = ballTargetPos, let currentBall = ballPos {
                    let bdx = target.x - currentBall.x
                    let bdy = target.y - currentBall.y
                    let bdist = hypot(bdx, bdy)
                    
                    facingLeft = bdx < 0
                    targetPos = currentPos // Stay in place watching ball flight
                    
                    if bdist > 12 {
                        // Smooth, readable gliding speed across desktop
                        ballPos = CGPoint(x: currentBall.x + bdx * 0.08, y: currentBall.y + bdy * 0.08)
                    } else {
                        ballPos = target
                        // Ball landed! Enter 0.8s reaction gap
                        let pauseUntil = Date().addingTimeInterval(0.8)
                        fetchPhase = .reactionPause(until: pauseUntil)
                        statusMessage = "Ball landed! Ready to sprint! 🎾"
                        spawnParticle(symbol: "✨", xOffset: 0, yOffset: 15)
                    }
                }
                
            case .reactionPause(let until):
                // STEP 2: Gap pause after ball lands so user sees pet get ready!
                targetPos = currentPos
                if Date() >= until {
                    fetchPhase = .sprintingToBall
                    statusMessage = "Sprinting after ball! 🎾💨"
                }
                
            case .sprintingToBall:
                // STEP 3: Pet sprints full speed to fetch the ball!
                if let ball = ballPos {
                    targetPos = ball
                    let distToBall = hypot(ball.x - currentPos.x, ball.y - currentPos.y)
                    
                    if frameCounter % 3 == 0 {
                        spawnParticle(symbol: "💨", xOffset: facingLeft ? 20 : -20, yOffset: -10)
                    }
                    
                    if distToBall < 25 {
                        isHoldingBall = true
                        ballPos = nil
                        ballTargetPos = nil
                        fetchScore += 1
                        playSound()
                        spawnParticle(symbol: "🎾", xOffset: 0, yOffset: 30)
                        spawnParticle(symbol: "💖", xOffset: 15, yOffset: 20)
                        
                        // Pick-up pause gap so user sees pet holding ball!
                        let pauseUntil = Date().addingTimeInterval(0.7)
                        fetchPhase = .pickUpPause(until: pauseUntil)
                        statusMessage = "Got the ball! Score: \(fetchScore) 🎾"
                    }
                } else {
                    fetchPhase = .idle
                }
                
            case .pickUpPause(let until):
                // STEP 4: Gap pause with ball in mouth before returning!
                targetPos = currentPos
                if Date() >= until {
                    fetchPhase = .returningToCursor
                    statusMessage = "Bringing ball back to you! 🐾"
                }
                
            case .returningToCursor:
                // STEP 5: Pet carries ball back to mouse cursor
                targetPos = CGPoint(x: mouseLoc.x + 20, y: mouseLoc.y - 20)
                let distToCursor = hypot(targetPos.x - currentPos.x, targetPos.y - currentPos.y)
                if distToCursor < 35 {
                    isHoldingBall = false
                    fetchPhase = .idle
                    statusMessage = "Dropped ball! Click pet to throw again 🎾"
                    spawnParticle(symbol: "❤️", xOffset: 0, yOffset: 20)
                }
            }
            
        case .home:
            targetPos = calculateHomePosition()
            let distToHome = hypot(targetPos.x - currentPos.x, targetPos.y - currentPos.y)
            if distToHome < 15 {
                isSleeping = true
                isMoving = false
                statusMessage = "Sleeping cozy at home zzz..."
            } else {
                isSleeping = false
                statusMessage = "Walking home..."
            }
            
        case .disabled:
            return
        }
        
        // Lerp movement towards target
        let dx = targetPos.x - currentPos.x
        let dy = targetPos.y - currentPos.y
        let distance = hypot(dx, dy)
        
        if distance > 10 && !isSleeping {
            let actualSpeed = (fetchPhase == .sprintingToBall) ? max(CGFloat(followSpeed), 0.20) : CGFloat(followSpeed)
            currentPos.x += dx * actualSpeed
            currentPos.y += dy * actualSpeed
            isMoving = true
            facingLeft = dx < 0
        } else {
            isMoving = false
        }
        
        // Update NSWindow frame position for Pet
        if let window = window, state != .disabled {
            let windowWidth: CGFloat = 110
            let windowHeight: CGFloat = 110
            let origin = CGPoint(x: currentPos.x - windowWidth / 2, y: currentPos.y - windowHeight / 2)
            window.setFrameOrigin(origin)
        }
        
        // Update standalone Ball NSWindow frame position
        if let ballWin = ballWindow {
            if let ball = ballPos, fetchPhase.isBallOnScreen {
                let ballOrigin = CGPoint(x: ball.x - 30, y: ball.y - 30)
                ballWin.setFrameOrigin(ballOrigin)
                ballWin.setIsVisible(true)
                ballWin.orderFront(nil)
            } else {
                ballWin.setIsVisible(false)
            }
        }
        
        // Update particles
        updateParticles()
        
        // Spawn periodic Zzz particles when sleeping
        if isSleeping && frameCounter % 45 == 0 {
            spawnParticle(symbol: "💤", xOffset: facingLeft ? -15 : 15, yOffset: 25)
        }
    }
    
    public func throwBallFar() {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        
        // Pick a far location across the screen (500pt - 850pt away!)
        let angle = Double.random(in: 0...(2 * .pi))
        let throwDistance = CGFloat.random(in: 500...850)
        
        var targetX = currentPos.x + cos(angle) * throwDistance
        var targetY = currentPos.y + sin(angle) * throwDistance
        
        // Clamp to screen bounds with padding so ball lands cleanly on screen
        let padding: CGFloat = 100
        targetX = max(visibleFrame.minX + padding, min(visibleFrame.maxX - padding, targetX))
        targetY = max(visibleFrame.minY + padding, min(visibleFrame.maxY - padding, targetY))
        
        ballPos = currentPos
        ballTargetPos = CGPoint(x: targetX, y: targetY)
        isHoldingBall = false
        fetchPhase = .ballFlying
        statusMessage = "Watching ball fly across desktop... 🎾"
        playSound()
    }
    
    private func calculateHomePosition() -> CGPoint {
        guard let screen = NSScreen.main else {
            return CGPoint(x: 1000, y: 100)
        }
        
        let visibleFrame = screen.visibleFrame
        let padding: CGFloat = 70
        
        switch homeCorner {
        case .bottomRight:
            return CGPoint(x: visibleFrame.maxX - padding, y: visibleFrame.minY + padding)
        case .bottomLeft:
            return CGPoint(x: visibleFrame.minX + padding, y: visibleFrame.minY + padding)
        case .topRight:
            return CGPoint(x: visibleFrame.maxX - padding, y: visibleFrame.maxY - padding)
        case .topLeft:
            return CGPoint(x: visibleFrame.minX + padding, y: visibleFrame.maxY - padding)
        }
    }
    
    public func petTheAnimal() {
        petCount += 1
        spawnParticle(symbol: "❤️", xOffset: 0, yOffset: 30)
        spawnParticle(symbol: "✨", xOffset: -20, yOffset: 15)
        spawnParticle(symbol: "💖", xOffset: 20, yOffset: 20)
        playSound()
        
        if state == .catchGame && fetchPhase == .idle {
            // Throw ball far across the screen!
            throwBallFar()
        } else if isSleeping {
            isSleeping = false
            statusMessage = "Woke up from petting!"
        } else {
            statusMessage = "Petting! (\(petCount) pets)"
        }
    }
    
    public func playSound() {
        guard soundEnabled else { return }
        let soundName: String
        switch character {
        case .cat: soundName = "Purr"
        case .dog: soundName = "Submarine"
        case .dragon: soundName = "Hero"
        case .bunny: soundName = "Pop"
        }
        
        if let sound = NSSound(named: soundName) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    private func spawnParticle(symbol: String, xOffset: CGFloat, yOffset: CGFloat) {
        let p = Particle(
            x: currentPos.x + xOffset,
            y: currentPos.y + yOffset,
            opacity: 1.0,
            scale: 0.8,
            symbol: symbol
        )
        particles.append(p)
    }
    
    private func updateParticles() {
        for i in particles.indices {
            particles[i].y += 1.5
            particles[i].opacity -= 0.03
            particles[i].scale += 0.02
        }
        particles.removeAll(where: { $0.opacity <= 0 })
    }
}
