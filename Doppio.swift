import Cocoa
import IOKit.pwr_mgt
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let menu = NSMenu()
    let defaults = UserDefaults.standard
    var assertion: IOPMAssertionID = 0
    var timer: Timer?
    var endDate: Date?

    // Minutes; 0 means no limit.
    let durations = [("Indefinitely", 0), ("5 minutes", 5), ("10 minutes", 10), ("15 minutes", 15),
                     ("30 minutes", 30), ("1 hour", 60), ("2 hours", 120), ("5 hours", 300)]

    var isActive: Bool { assertion != 0 }
    var defaultMinutes: Int { defaults.integer(forKey: "defaultMinutes") }

    func applicationDidFinishLaunching(_ notification: Notification) {
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        menu.delegate = self
        update()
        if defaults.bool(forKey: "activateOnLaunch") { activate(minutes: defaultMinutes) }
    }

    func applicationWillTerminate(_ notification: Notification) { deactivate() }

    // Left click toggles; right, control or command click opens the menu.
    @objc func clicked() {
        // No mouse event means VoiceOver or another accessibility press, which toggles.
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.intersection([.command, .control]).isEmpty == false {
            item.menu = menu
            item.button?.performClick(nil)
            item.menu = nil
        } else if isActive {
            deactivate()
        } else {
            activate(minutes: defaultMinutes)
        }
    }

    func activate(minutes: Int) {
        deactivate()
        // Display-sleep assertion also blocks idle system sleep, dimming and the screensaver.
        if IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                                       IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                       "Doppio is active" as CFString, &assertion) != kIOReturnSuccess {
            assertion = 0
        }
        if isActive && minutes > 0 {
            endDate = Date(timeIntervalSinceNow: TimeInterval(minutes * 60))
            timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.deactivate() }
            }
        }
        update()
    }

    func deactivate() {
        if isActive { IOPMAssertionRelease(assertion) }
        assertion = 0
        timer?.invalidate()
        timer = nil
        endDate = nil
        update()
    }

    func update() {
        item.button?.image = NSImage(systemSymbolName: isActive ? "cup.and.saucer.fill" : "cup.and.saucer",
                                     accessibilityDescription: isActive ? "Doppio on" : "Doppio off")
        item.button?.toolTip = isActive ? "Doppio is keeping your Mac awake" : "Doppio is off"
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if isActive {
            menu.addItem(withTitle: endDate.map { "On until \($0.formatted(date: .omitted, time: .shortened))" } ?? "On indefinitely",
                         action: nil, keyEquivalent: "")
            add("Turn Off", #selector(turnOff), to: menu)
            menu.addItem(.separator())
        }
        menu.addItem(withTitle: "Activate for", action: nil, keyEquivalent: "")
        for (title, minutes) in durations {
            let i = add(title, #selector(activateFor), to: menu)
            i.tag = minutes
            i.indentationLevel = 1
        }
        menu.addItem(.separator())

        let defaultMenu = NSMenu()
        for (title, minutes) in durations {
            let i = add(title, #selector(setDefault), to: defaultMenu)
            i.tag = minutes
            i.state = minutes == defaultMinutes ? .on : .off
        }
        menu.setSubmenu(defaultMenu, for: menu.addItem(withTitle: "Default Duration", action: nil, keyEquivalent: ""))
        add("Activate at Launch", #selector(toggleActivateOnLaunch), to: menu).state =
            defaults.bool(forKey: "activateOnLaunch") ? .on : .off
        add("Start at Login", #selector(toggleLogin), to: menu).state =
            SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(.separator())
        add("Quit Doppio", #selector(NSApplication.terminate), to: menu, key: "q").target = NSApp
    }

    @discardableResult
    func add(_ title: String, _ action: Selector, to menu: NSMenu, key: String = "") -> NSMenuItem {
        let i = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
        i.target = self
        return i
    }

    @objc func turnOff() { deactivate() }
    @objc func activateFor(_ sender: NSMenuItem) { activate(minutes: sender.tag) }
    @objc func setDefault(_ sender: NSMenuItem) { defaults.set(sender.tag, forKey: "defaultMinutes") }
    @objc func toggleActivateOnLaunch() {
        defaults.set(!defaults.bool(forKey: "activateOnLaunch"), forKey: "activateOnLaunch")
    }

    @objc func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}

MainActor.assumeIsolated {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    NSApplication.shared.run()
}
