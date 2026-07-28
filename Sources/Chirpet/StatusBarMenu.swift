import AppKit
import SwiftUI

@MainActor
public class StatusBarMenuController: NSObject {
    private var statusItem: NSStatusItem?
    private var viewModel: PetViewModel
    
    public init(viewModel: PetViewModel) {
        self.viewModel = viewModel
        super.init()
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Desktop Pet") {
                image.isTemplate = true
                button.image = image
            }
            button.title = " Pet"
            button.imagePosition = .imageLeft
            button.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        }
        
        updateMenu()
    }
    
    public func updateMenu() {
        let menu = NSMenu()
        
        // Header / Status Info
        let headerItem = NSMenuItem(title: "🐾 Chirpet (\(viewModel.character.rawValue))", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        let statusSubItem = NSMenuItem(title: "Status: \(viewModel.statusMessage)", action: nil, keyEquivalent: "")
        statusSubItem.isEnabled = false
        menu.addItem(statusSubItem)
        
        let petsCountItem = NSMenuItem(title: "Pets: \(viewModel.petCount) ❤️  |  Catches: \(viewModel.fetchScore) 🎾", action: nil, keyEquivalent: "")
        petsCountItem.isEnabled = false
        menu.addItem(petsCountItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Mode Options (Active, Play Catch, Home, Disabled)
        let modeHeader = NSMenuItem(title: "Select State / Mode:", action: nil, keyEquivalent: "")
        modeHeader.isEnabled = false
        menu.addItem(modeHeader)
        
        for stateOption in PetState.allCases {
            let item = NSMenuItem(title: stateOption.rawValue, action: #selector(selectMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = stateOption
            item.state = (viewModel.state == stateOption) ? .on : .off
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Note Carrier Submenu / Action
        let noteItem = NSMenuItem(title: viewModel.noteText.isEmpty ? "Attach Text Note 📝" : "Edit Text Note 📝 (\"\(viewModel.noteText)\")", action: #selector(attachNote), keyEquivalent: "n")
        noteItem.target = self
        menu.addItem(noteItem)
        
        if !viewModel.noteText.isEmpty {
            let clearNoteItem = NSMenuItem(title: "Clear Note 🗑️", action: #selector(clearNote), keyEquivalent: "")
            clearNoteItem.target = self
            menu.addItem(clearNoteItem)
        }
        
        // Audio Toggle Option
        let soundToggleItem = NSMenuItem(title: "Sound Effects 🔊", action: #selector(toggleSound), keyEquivalent: "")
        soundToggleItem.target = self
        soundToggleItem.state = viewModel.soundEnabled ? .on : .off
        menu.addItem(soundToggleItem)
        
        // Click-Through Toggle Option
        let clickThroughItem = NSMenuItem(
            title: "Pass-Through Clicks (Ghost Mode)",
            action: #selector(toggleClickThrough),
            keyEquivalent: "t"
        )
        clickThroughItem.target = self
        clickThroughItem.state = viewModel.isClickThrough ? .on : .off
        menu.addItem(clickThroughItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Character Selector Submenu
        let characterMenu = NSMenu()
        for charOption in PetCharacter.allCases {
            let item = NSMenuItem(title: charOption.rawValue, action: #selector(selectCharacter(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = charOption
            item.state = (viewModel.character == charOption) ? .on : .off
            characterMenu.addItem(item)
        }
        let characterSubmenuItem = NSMenuItem(title: "Change Pet Character", action: nil, keyEquivalent: "")
        characterSubmenuItem.submenu = characterMenu
        menu.addItem(characterSubmenuItem)
        
        // Home Corner Submenu
        let cornerMenu = NSMenu()
        for cornerOption in ScreenCorner.allCases {
            let item = NSMenuItem(title: cornerOption.rawValue, action: #selector(selectCorner(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = cornerOption
            item.state = (viewModel.homeCorner == cornerOption) ? .on : .off
            cornerMenu.addItem(item)
        }
        let cornerSubmenuItem = NSMenuItem(title: "Home Resting Corner", action: nil, keyEquivalent: "")
        cornerSubmenuItem.submenu = cornerMenu
        menu.addItem(cornerSubmenuItem)
        
        // Speed Submenu
        let speedMenu = NSMenu()
        let speedOptions: [(String, Double)] = [("Slow", 0.08), ("Normal", 0.15), ("Fast", 0.25)]
        for (name, speedVal) in speedOptions {
            let item = NSMenuItem(title: name, action: #selector(selectSpeed(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = speedVal
            item.state = (abs(viewModel.followSpeed - speedVal) < 0.01) ? .on : .off
            speedMenu.addItem(item)
        }
        let speedSubmenuItem = NSMenuItem(title: "Follow Speed", action: nil, keyEquivalent: "")
        speedSubmenuItem.submenu = speedMenu
        menu.addItem(speedSubmenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Action: Pet the animal directly from menu
        let petActionItem = NSMenuItem(title: "Give Love / Pet (❤️)", action: #selector(petAction), keyEquivalent: "p")
        petActionItem.target = self
        menu.addItem(petActionItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(title: "Quit Chirpet", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func selectMode(_ sender: NSMenuItem) {
        if let state = sender.representedObject as? PetState {
            viewModel.state = state
            updateMenu()
        }
    }
    
    @objc private func toggleClickThrough() {
        viewModel.isClickThrough.toggle()
        updateMenu()
    }
    
    @objc private func toggleSound() {
        viewModel.soundEnabled.toggle()
        if viewModel.soundEnabled {
            viewModel.playSound()
        }
        updateMenu()
    }
    
    @objc private func attachNote() {
        let alert = NSAlert()
        alert.messageText = "Attach Note / Audio Text to Pet 📝"
        alert.informativeText = "Enter a text note or reminder for your pet to carry:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Attach")
        alert.addButton(withTitle: "Cancel")
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        inputTextField.stringValue = viewModel.noteText
        alert.accessoryView = inputTextField
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            viewModel.noteText = inputTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !viewModel.noteText.isEmpty {
                viewModel.playSound()
            }
            updateMenu()
        }
    }
    
    @objc private func clearNote() {
        viewModel.noteText = ""
        updateMenu()
    }
    
    @objc private func selectCharacter(_ sender: NSMenuItem) {
        if let char = sender.representedObject as? PetCharacter {
            viewModel.character = char
            updateMenu()
        }
    }
    
    @objc private func selectCorner(_ sender: NSMenuItem) {
        if let corner = sender.representedObject as? ScreenCorner {
            viewModel.homeCorner = corner
            updateMenu()
        }
    }
    
    @objc private func selectSpeed(_ sender: NSMenuItem) {
        if let speed = sender.representedObject as? Double {
            viewModel.followSpeed = speed
            updateMenu()
        }
    }
    
    @objc private func petAction() {
        viewModel.petTheAnimal()
        updateMenu()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
