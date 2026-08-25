import AppKit
import ApplicationServices

private let appName = "Assoluto A/D Key Mapper"
private let qemuExecutableNames: Set<String> = [
    "qemu-system-aarch64",
    "qemu-system-x86_64",
]

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installStatusItem()

        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let trusted = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        guard trusted else {
            updateStatus(title: "AR AD: 権限待ち")
            showPermissionAlert()
            return
        }

        installEventTap()
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "AR AD"

        let menu = NSMenu()
        let description = NSMenuItem(title: "Emulator前面時: A→← / D→→", action: nil, keyEquivalent: "")
        description.isEnabled = false
        menu.addItem(description)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "終了", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    private func updateStatus(title: String) {
        statusItem?.button?.title = title
    }

    private func showPermissionAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "アクセシビリティ権限が必要です"
        alert.informativeText = "システム設定 → プライバシーとセキュリティ → アクセシビリティで「Assoluto A/D Key Mapper」を許可してください。許可後、このアプリを一度終了して再起動します。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func installEventTap() {
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        let context = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let mapper = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()
                return mapper.handle(type: type, event: event)
            },
            userInfo: context
        ) else {
            updateStatus(title: "AR AD: 入力権限待ち")
            showInputMonitoringAlert()
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        updateStatus(title: "AR AD: ON")
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown || type == .keyUp,
              isAndroidEmulatorFrontmost() else {
            return Unmanaged.passUnretained(event)
        }

        switch event.getIntegerValueField(.keyboardEventKeycode) {
        case 0:   // ANSI A
            event.setIntegerValueField(.keyboardEventKeycode, value: 123) // Left Arrow
        case 2:   // ANSI D
            event.setIntegerValueField(.keyboardEventKeycode, value: 124) // Right Arrow
        default:
            break
        }
        return Unmanaged.passUnretained(event)
    }

    private func isAndroidEmulatorFrontmost() -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return false }
        if let executableName = app.executableURL?.lastPathComponent,
           qemuExecutableNames.contains(executableName) {
            return true
        }
        if let localizedName = app.localizedName,
           qemuExecutableNames.contains(localizedName) {
            return true
        }
        return false
    }

    private func showInputMonitoringAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "入力監視の許可が必要です"
        alert.informativeText = "システム設定 → プライバシーとセキュリティ → 入力監視で「Assoluto A/D Key Mapper」を許可してください。許可後、このアプリを一度終了して再起動します。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
