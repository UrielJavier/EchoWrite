import Cocoa
import CoreGraphics

final class HotkeyManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let onToggle: () -> Void
    var keyCode: UInt16 = 1
    var modifiers: NSEvent.ModifierFlags = [.command, .function]
    var isEnabled = true

    // Static reference for the C callback (CGEventTapCallBack can't capture context)
    private static weak var current: HotkeyManager?

    init(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle
    }

    func register() {
        unregister()
        HotkeyManager.current = self

        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: HotkeyManager.tapCallback,
            userInfo: nil
        )

        guard let tap = eventTap else { return }
        runLoopSource = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func unregister() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
        if HotkeyManager.current === self {
            HotkeyManager.current = nil
        }
    }

    private static let tapCallback: CGEventTapCallBack = { _, type, event, _ in
        // Re-enable if system disabled the tap due to timeout
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let mgr = HotkeyManager.current, let tap = mgr.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown,
              let mgr = HotkeyManager.current,
              mgr.isEnabled else {
            return Unmanaged.passUnretained(event)
        }

        guard let nsEvent = NSEvent(cgEvent: event),
              !nsEvent.isARepeat else {
            return Unmanaged.passUnretained(event)
        }

        let mask: NSEvent.ModifierFlags = [.command, .shift, .option, .control, .function]
        let eventMods = nsEvent.modifierFlags.intersection(mask)
        let targetMods = mgr.modifiers.intersection(mask)

        if nsEvent.keyCode == mgr.keyCode && eventMods == targetMods {
            mgr.onToggle()
            return nil // consume the event — no system beep
        }

        return Unmanaged.passUnretained(event)
    }

    deinit {
        unregister()
    }
}
