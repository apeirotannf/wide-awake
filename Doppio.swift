import Cocoa
import ServiceManagement

@main
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let menu = NSMenu()
    let defaults = UserDefaults.standard
    var activity: NSObjectProtocol?
    var timer: Timer?
    var startDate = Date()
    var endDate: Date?
    // Menu bar eyes: how open they are now (0 shut, 1 wide), the animation between states, and where they look.
    var shown: CGFloat = 0, from: CGFloat = 0, to: CGFloat = 0, animationStart = Date()
    var animation: Timer?
    var gaze = CGPoint.zero
    var mouseMonitor: Any?

    // Minutes; 0 means no limit.
    let durations = [("Indefinitely", 0), ("5 minutes", 5), ("10 minutes", 10), ("15 minutes", 15),
                     ("30 minutes", 30), ("1 hour", 60), ("2 hours", 120), ("5 hours", 300)]

    var isActive: Bool { activity != nil }
    var defaultMinutes: Int { defaults.integer(forKey: "defaultMinutes") }

    static func main() {
        let delegate = AppDelegate()
        NSApplication.shared.delegate = delegate
        NSApplication.shared.run()
    }

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
        // Blocks idle display and system sleep, dimming and the screensaver.
        // .userInitiated also keeps App Nap from delaying the timer below.
        activity = ProcessInfo.processInfo.beginActivity(options: [.idleDisplaySleepDisabled, .userInitiated],
                                                         reason: "Doppio is active")
        if minutes > 0 {
            let total = TimeInterval(minutes * 60)
            startDate = Date()
            endDate = Date(timeIntervalSinceNow: total)
            // 20 ticks let the eyes droop as time runs out. The last one lands on endDate.
            timer = Timer.scheduledTimer(timeInterval: total / 20, target: self,
                                         selector: #selector(tick), userInfo: nil, repeats: true)
        }
        update()
    }

    func deactivate() {
        if let activity { ProcessInfo.processInfo.endActivity(activity) }
        activity = nil
        timer?.invalidate()
        timer = nil
        endDate = nil
        update()
    }

    @objc func tick() {
        if let endDate, endDate.timeIntervalSinceNow < 1 { deactivate() } else { update() }
    }

    func update() {
        item.button?.toolTip = isActive ? "Doppio is keeping your Mac awake" : "Doppio is off"
        // Wide open when on, drooping to 35% as a timer runs out, shut when off.
        var target: CGFloat = isActive ? 1 : 0
        if isActive, let endDate {
            target = 0.35 + 0.65 * CGFloat(max(0, endDate.timeIntervalSinceNow / endDate.timeIntervalSince(startDate)))
        }
        let still = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        watchMouse(isActive && !still)
        animation?.invalidate()
        if still || shown == target {
            shown = target
            draw()
        } else {
            (from, to, animationStart) = (shown, target, Date())
            animation = Timer.scheduledTimer(timeInterval: 1.0 / 60, target: self,
                                             selector: #selector(step), userInfo: nil, repeats: true)
        }
    }

    @objc func step() {
        let t = min(Date().timeIntervalSince(animationStart) / 0.25, 1)
        shown = from + (to - from) * CGFloat(t * t * (3 - 2 * t))
        draw()
        if t == 1 { animation?.invalidate() }
    }

    func watchMouse(_ on: Bool) {
        if on, mouseMonitor == nil {
            mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
                self?.look()
            }
            look()
        } else if !on, let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
    }

    // Pupils glance toward the pointer, further the further away it is. Quarter-point steps limit redraws.
    func look() {
        guard let icon = item.button?.window?.frame else { return }
        let dx = NSEvent.mouseLocation.x - icon.midX, dy = NSEvent.mouseLocation.y - icon.midY
        let d = max(hypot(dx, dy), 1), reach = min(d / 200, 1) * 1.2
        let p = CGPoint(x: (dx / d * reach * 4).rounded() / 4, y: (dy / d * reach * 4).rounded() / 4)
        if p != gaze {
            gaze = p
            draw()
        }
    }

    func draw() {
        let (o, gaze) = (shown, gaze)
        // Two tall cartoon eyes with brows, one per shot. The upper lid sweeps from a full oval (o = 1)
        // down onto the lower lid (o = 0), and the brows relax with it.
        let image = NSImage(size: NSSize(width: 22, height: 18), flipped: false) { _ in
            // On a dark menu bar the eyes are filled with hollow pupils, so they read as white eyes, dark pupils.
            let dark = NSAppearance.currentDrawing().bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            for (cx, side) in [(6.6, -1.0), (15.4, 1.0)] {
                let cy = 7.2, rx = 3.0, ry = 4.3
                let lower = -(ry * o + rx * 0.8 * (1 - o)) * 4 / 3, upper = lower + (ry * 4 / 3 - lower) * o
                let eye = NSBezierPath()
                eye.move(to: NSPoint(x: cx - rx, y: cy))
                eye.curve(to: NSPoint(x: cx + rx, y: cy), controlPoint1: NSPoint(x: cx - rx, y: cy + upper),
                          controlPoint2: NSPoint(x: cx + rx, y: cy + upper))
                eye.curve(to: NSPoint(x: cx - rx, y: cy), controlPoint1: NSPoint(x: cx + rx, y: cy + lower),
                          controlPoint2: NSPoint(x: cx - rx, y: cy + lower))
                let by = cy + ry + 0.9 + 1.4 * o, arch = (0.3 + 1.1 * o) * 1.3
                let brow = NSBezierPath()
                brow.move(to: NSPoint(x: cx + side * 3.4, y: by))
                brow.curve(to: NSPoint(x: cx - side * 2.4, y: by + 0.5 * o), controlPoint1: NSPoint(x: cx + side * 1.8, y: by + arch),
                           controlPoint2: NSPoint(x: cx - side * 0.8, y: by + arch))
                for path in [eye, brow] {
                    path.lineWidth = 1.3
                    path.lineCapStyle = .round
                    path.lineJoinStyle = .round
                    path.stroke()
                }
                let p = NSPoint(x: cx + gaze.x, y: cy + gaze.y)
                let pupil = NSBezierPath(ovalIn: NSRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4))
                let glint = NSBezierPath(ovalIn: NSRect(x: p.x + 0.35, y: p.y + 0.35, width: 1.4, height: 1.4))
                // Even-odd fill cuts the hollow part: eye minus pupil on dark bars, pupil minus glint on light ones.
                let shape = NSBezierPath()
                shape.append(dark ? eye : pupil)
                shape.append(dark ? pupil : glint)
                shape.windingRule = .evenOdd
                NSGraphicsContext.saveGraphicsState()
                eye.addClip()
                shape.fill()
                if dark { glint.fill() }
                NSGraphicsContext.restoreGraphicsState()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = isActive ? "Doppio on" : "Doppio off"
        item.button?.image = image
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if isActive {
            menu.addItem(withTitle: endDate.map { "On until \(DateFormatter.localizedString(from: $0, dateStyle: .none, timeStyle: .short))" } ?? "On indefinitely",
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
        if #available(macOS 13, *) {
            add("Start at Login", #selector(toggleLogin), to: menu).state =
                SMAppService.mainApp.status == .enabled ? .on : .off
        }
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

    @available(macOS 13, *)
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
