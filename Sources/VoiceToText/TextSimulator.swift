import Cocoa
import CoreGraphics

enum TextSimulator {
    /// Types the given text at the current cursor position using CGEvent.
    /// Requires Accessibility permissions to be granted.
    static func simulateTyping(text: String) {
        let source = CGEventSource(stateID: .hidSystemState)

        for char in text {
            let str = String(char)
            let unichars = Array(str.utf16)

            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)

            keyDown?.keyboardSetUnicodeString(stringLength: unichars.count, unicodeString: unichars)
            keyUp?.keyboardSetUnicodeString(stringLength: unichars.count, unicodeString: unichars)

            keyDown?.post(tap: .cgAnnotatedSessionEventTap)
            keyUp?.post(tap: .cgAnnotatedSessionEventTap)

            // Small delay to ensure events are processed in order
            usleep(5000) // 5ms
        }
    }

    /// Selects `count` characters to the left, then deletes them with a single backspace.
    /// More reliable than repeated backspaces across different apps (editors, terminals, etc).
    static func deleteCharacters(count: Int) {
        guard count > 0 else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        let leftArrow: CGKeyCode = 0x7B
        let backspace: CGKeyCode = 0x33

        // Shift+Left × count to select
        for _ in 0..<count {
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: leftArrow, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: leftArrow, keyDown: false)
            keyDown?.flags = .maskShift
            keyUp?.flags = .maskShift
            keyDown?.post(tap: .cgAnnotatedSessionEventTap)
            keyUp?.post(tap: .cgAnnotatedSessionEventTap)
            usleep(3000)
        }

        usleep(10000) // let selection settle

        // Single backspace to delete selection
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: backspace, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: backspace, keyDown: false)
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
        usleep(5000)
    }

    /// Copies text to the system clipboard and optionally pastes it.
    static func copyToClipboard(text: String, autoPaste: Bool = false) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        if autoPaste {
            let source = CGEventSource(stateID: .hidSystemState)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)  // V key
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
            keyDown?.post(tap: .cgAnnotatedSessionEventTap)
            keyUp?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }

    /// Checks if accessibility permissions are granted.
    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts the user to grant accessibility permissions.
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
