import AppKit
import SwiftUI
import Combine

@MainActor
public class StatusBarMenuController: NSObject {
    private var statusItem: NSStatusItem?
    private var viewModel: PetViewModel
    private var cancellables = Set<AnyCancellable>()
    public var currentMenu: NSMenu?
    
    public init(viewModel: PetViewModel) {
        self.viewModel = viewModel
        super.init()
        setupStatusItem()
        observeViewModel()
        viewModel.statusBarController = self
    }
    
    private func setupStatusItem() {
        // Use squareLength (~22px width) so macOS never hides item during FaceTime / Screen Sharing calls!
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.autosaveName = "ChirpetStatusItem"
        statusItem?.isVisible = true
        
        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Chirpet") {
                image.isTemplate = true
                button.image = image
            }
            button.imagePosition = .imageOnly
            button.toolTip = "Chirpet Desktop Pet Settings (Right-click pet anytime!)"
        }
        
        updateMenu()
    }
    
    private func observeViewModel() {
        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
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
        
        // Quick Throw Ball Action if in Play Catch Mode
        if viewModel.state == .catchGame {
            let throwBallItem = NSMenuItem(title: "🎾 Throw Ball Now!", action: #selector(throwBallAction), keyEquivalent: "b")
            throwBallItem.target = self
            menu.addItem(throwBallItem)
            menu.addItem(NSMenuItem.separator())
        }
        
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
        
        // SCHEDULED TASKS & REMINDERS SECTION ⏰
        let activeTaskCount = viewModel.scheduledTasks.filter { !$0.isCompleted }.count
        let schedulerHeader = NSMenuItem(title: "Scheduled Tasks & Reminders (\(activeTaskCount)) ⏰", action: nil, keyEquivalent: "")
        schedulerHeader.isEnabled = false
        menu.addItem(schedulerHeader)
        
        // Active Tasks Submenu
        let activeTasksMenu = NSMenu()
        let pendingTasks = viewModel.scheduledTasks.filter { !$0.isCompleted }
        if pendingTasks.isEmpty {
            let emptyItem = NSMenuItem(title: "No upcoming tasks scheduled", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            activeTasksMenu.addItem(emptyItem)
        } else {
            for task in pendingTasks {
                let titleStr = "⏰ \(task.title) [\(task.recurrence.description)] - Due: \(task.timeRemainingString)"
                let item = NSMenuItem(title: titleStr, action: #selector(deleteTaskAction(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = task.id
                item.toolTip = "Click to cancel task"
                activeTasksMenu.addItem(item)
            }
        }
        let viewTasksSubmenuItem = NSMenuItem(title: "View / Cancel Active Tasks (\(pendingTasks.count))", action: nil, keyEquivalent: "")
        viewTasksSubmenuItem.submenu = activeTasksMenu
        menu.addItem(viewTasksSubmenuItem)
        
        // Add Quick Task Submenu
        let quickAddMenu = NSMenu()
        let quickOptions: [(String, String, TaskRecurrence, TimeInterval)] = [
            ("⚡ In 15 seconds (Test)", "Quick Test Task", .oneTime, 15),
            ("⏱️ In 1 minute", "Quick Check 💧", .oneTime, 60),
            ("⏱️ In 3 minutes", "Short Break ☕", .oneTime, 180),
            ("⏱️ In 5 minutes", "Take a 5m Break ☕", .oneTime, 300),
            ("⏱️ In 10 minutes", "Check Email 📧", .oneTime, 600),
            ("⏱️ In 15 minutes", "Stand Up & Stretch 🧘", .oneTime, 900),
            ("⏱️ In 30 minutes", "Drink Water 💧", .oneTime, 1800),
            ("⏱️ In 45 minutes", "Focus Session Done 🎯", .oneTime, 2700),
            ("⏱️ In 1 hour", "Hourly Break ☕", .oneTime, 3600),
            ("⏱️ In 2 hours", "Team Sync Meeting 👥", .oneTime, 7200),
            ("🔄 Every 1 minute (Recurring)", "Water Check 💧", .repetitive(intervalSeconds: 60), 60),
            ("🔄 Every 15 minutes (Recurring)", "Stretch & Hydrate 💧", .repetitive(intervalSeconds: 900), 900),
            ("🔄 Every 30 minutes (Recurring)", "Eye Rest Break 👀", .repetitive(intervalSeconds: 1800), 1800),
            ("🔄 Every 1 hour (Recurring)", "Hourly Stretch 🧘", .repetitive(intervalSeconds: 3600), 3600)
        ]
        for (label, title, recurrence, delay) in quickOptions {
            let item = NSMenuItem(title: label, action: #selector(addQuickTaskAction(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = (title, recurrence, delay)
            quickAddMenu.addItem(item)
        }
        let addQuickTaskSubmenuItem = NSMenuItem(title: "Quick Add Reminder Presets ⚡", action: nil, keyEquivalent: "")
        addQuickTaskSubmenuItem.submenu = quickAddMenu
        menu.addItem(addQuickTaskSubmenuItem)
        
        // Custom Task Dialog
        let customTaskItem = NSMenuItem(title: "Custom Time & Task... 📝", action: #selector(addCustomTaskDialog), keyEquivalent: "m")
        customTaskItem.target = self
        menu.addItem(customTaskItem)
        
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
        
        currentMenu = menu
        statusItem?.menu = menu
    }
    
    public func showMenuAtCursor() {
        if let menu = currentMenu {
            let dummyEvent = NSEvent.mouseEvent(
                with: .rightMouseDown,
                location: NSEvent.mouseLocation,
                modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: 0,
                context: nil,
                eventNumber: 0,
                clickCount: 1,
                pressure: 1.0
            ) ?? NSEvent()
            
            let dummyView = NSView(frame: .zero)
            NSMenu.popUpContextMenu(menu, with: dummyEvent, for: dummyView)
        }
    }
    
    @objc private func selectMode(_ sender: NSMenuItem) {
        if let state = sender.representedObject as? PetState {
            viewModel.state = state
            updateMenu()
        }
    }
    
    @objc private func throwBallAction() {
        viewModel.throwBallFar()
        updateMenu()
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
    
    @objc private func addQuickTaskAction(_ sender: NSMenuItem) {
        if let (title, recurrence, delay) = sender.representedObject as? (String, TaskRecurrence, TimeInterval) {
            viewModel.addScheduledTask(title: title, recurrence: recurrence, delaySeconds: delay)
            updateMenu()
        }
    }
    
    @objc private func deleteTaskAction(_ sender: NSMenuItem) {
        if let taskId = sender.representedObject as? UUID {
            viewModel.removeTask(id: taskId)
            updateMenu()
        }
    }
    
    @objc private func addCustomTaskDialog() {
        let alert = NSAlert()
        alert.messageText = "Custom Scheduled Task ⏰"
        alert.informativeText = "Enter task title and custom delay/interval (in minutes):"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Schedule One-Time Task")
        alert.addButton(withTitle: "Schedule Recurring Task")
        alert.addButton(withTitle: "Cancel")
        
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 75))
        
        let titleLabel = NSTextField(labelWithString: "Task Title:")
        titleLabel.frame = NSRect(x: 0, y: 52, width: 90, height: 20)
        container.addSubview(titleLabel)
        
        let titleField = NSTextField(frame: NSRect(x: 95, y: 50, width: 180, height: 24))
        titleField.placeholderString = "e.g. Drink water / Team sync"
        titleField.stringValue = "Custom Reminder"
        container.addSubview(titleField)
        
        let timeLabel = NSTextField(labelWithString: "Time (Minutes):")
        timeLabel.frame = NSRect(x: 0, y: 17, width: 95, height: 20)
        container.addSubview(timeLabel)
        
        let timeField = NSTextField(frame: NSRect(x: 95, y: 15, width: 180, height: 24))
        timeField.stringValue = "10"
        container.addSubview(timeField)
        
        alert.accessoryView = container
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        
        let taskTitle = titleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = taskTitle.isEmpty ? "Custom Task" : taskTitle
        
        let rawMinutes = Double(timeField.stringValue) ?? 10.0
        let minutes = max(0.1, rawMinutes)
        let delaySeconds = minutes * 60.0
        
        if response == .alertFirstButtonReturn {
            viewModel.addScheduledTask(title: finalTitle, recurrence: .oneTime, delaySeconds: delaySeconds)
            updateMenu()
        } else if response == .alertSecondButtonReturn {
            viewModel.addScheduledTask(title: finalTitle, recurrence: .repetitive(intervalSeconds: delaySeconds), delaySeconds: delaySeconds)
            updateMenu()
        }
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
