# 🐾 DesktopPet - Native macOS Floating Companion & Fetch Game

> A vibrant, interactive, transparent macOS desktop pet companion built natively with **Swift**, **AppKit**, and **SwiftUI**. Your pet floats over all desktop windows and virtual spaces, follows your mouse pointer, fetches tennis balls across your screen, carries text notes, and rests cozy in screen corners!

---

## 🌟 Key Features & Interactive Modes

| Mode / Feature | Icon | Description |
| :--- | :---: | :--- |
| **Active Mode** | 📍 | **Follow Mouse Pointer**: Pet continuously tracks the cursor location in real time with smooth lerp physics and direction flipping. |
| **Play Catch (Fetch Game)** | 🎾 | **2-Phase Fetch Sequence**: Click the pet to throw a tennis ball (`🎾`) across your screen. The ball glides to its landing spot, the pet pauses in excitement, sprints full speed with dust particles (`💨`), picks up the ball in its mouth (`🎾🐶`), and returns it to your cursor! Tracks your **Fetch Score** (`Catches: 5 🎾`). |
| **Home Corner Mode** | 🏠 | **Screen Corner Rest**: Pet walks automatically to a designated screen corner (Bottom-Right, Bottom-Left, Top-Right, Top-Left) and enters a cozy sleeping Zzz animation. |
| **Disable (Hidden)** | 👁️‍🗨️ | **Hidden Overlay**: Hides the floating windows completely and pauses update timers to conserve CPU and battery. |
| **Text Note Carrier** | 📝 | **Attach Reminders**: Attach text notes or reminders to your pet via the menu bar. The pet carries an interactive note speech bubble over its head! |
| **Pet Soundboard & Audio** | 🔊 | **Native Audio Reactions**: Integrated macOS sound effects (`NSSound` bark, purr, hero roar, pop) when petted, fetching the ball, or attaching notes. |
| **Ghost Mode / Hit-Testing** | 👻 | **Pass-Through Clicks**: Transparent window margins allow clicks straight through to desktop icons and background apps. Toggle 100% Click-Through anytime! |
| **macOS Status Item** | 🐾 | **Menu Bar Control**: Quick toggle status item in the top macOS menu bar with character selection, speed sliders, corner picks, and sound controls. |

---

## 🐶 Character Roster

- 🐶 **Golden Retriever (Default)**: Prettier animated golden coat, bouncy floppy ears, sparkle eyes, wagging tail, running paws, and pink wagging tongue!
- 🐱 **Orange Tabby Cat**: Cute pointy ears, whisker mouth (`ω`), and wiggling tail.
- 🐉 **Pixel Dragon**: Mint wings, emerald scales, and yellow horns.
- 🐰 **Fluffy Bunny**: Soft white fur, tall pink-lined ears, and cute pink nose.

---

## 🛠️ Technology Stack & Architecture

- **Language**: Swift 6 (Strict Concurrency & `@MainActor` safe)
- **UI Frameworks**: SwiftUI (Procedural Vector Graphics & Animation Engine) + AppKit (`NSPanel`, `NSStatusItem`, `NSApplication`)
- **System APIs**: `NSEvent.mouseLocation`, `NSSound`, `NSScreen`
- **Build System**: Swift Package Manager (`Package.swift`)
- **Window Architecture**:
  - **`PetPanel`**: Transparent borderless `NSPanel` floating at `.floating` window level with `.canJoinAllSpaces` so the pet stays visible across all macOS Spaces / Virtual Desktops. Custom `HitTestHostingView` ensures transparent margins pass clicks directly through to underlying macOS applications.
  - **`BallPanel`**: Standalone floating `NSPanel` for the tennis ball (`🎾`), rendering spinning flight animations and ground shadow across the screen.

---

## 📁 Project Structure

```text
DesktopPet/
├── Package.swift               # Swift Package Manager Manifest (macOS 13.0+)
├── README.md                   # Complete Documentation & Features Showcase
└── Sources/
    └── DesktopPet/
        ├── App.swift           # Application entry point (@main) & NSApplicationDelegate
        ├── PetPanel.swift      # Borderless transparent NSPanel with precise hit-testing
        ├── BallPanel.swift     # Standalone floating tennis ball window & spin animation
        ├── PetViewModel.swift  # Core state machine, lerp physics, 2-phase fetch game, audio
        ├── PetView.swift       # SwiftUI avatar vector graphics (Dog, Cat, Dragon, Bunny)
        └── StatusBarMenu.swift # macOS Menu Bar Status Item (NSStatusItem) & controls
```

---

## 🚀 Getting Started

### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 14.0+ or Swift 5.9+ Command Line Tools (`swift --version`)

### Build & Run Instructions

1. Open your terminal and navigate to the project directory:
   ```bash
   cd /Users/sujitroyal/Documents/PersonalProjects/DesktopPet
   ```

2. Build the project:
   ```bash
   swift build
   ```

3. Launch DesktopPet:
   ```bash
   swift run
   ```

---

## 🎮 Controls & Shortcuts

| Action | Shortcut / Method |
| :--- | :--- |
| **Play Catch / Throw Ball** | Click the pet while in `Play Catch 🎾` mode |
| **Pet / Give Love** | Click the pet in `Active` mode (triggers heart FX ❤️) |
| **Drag Pet** | Click and drag the pet anywhere on screen |
| **Attach / Edit Note** | Menu Bar 🐾 -> **Attach Text Note 📝** (or `⌘ + N`) |
| **Pass-Through Clicks (Ghost Mode)** | Menu Bar 🐾 -> **Pass-Through Clicks** (or `⌘ + T`) |
| **Quit Application** | Menu Bar 🐾 -> **Quit Desktop Pet** (or `⌘ + Q`) |

---

## 📄 License

Created for personal desktop enjoyment. Free to customize, extend, and share! 🐾
