import SwiftUI

private final class MonitorHolder {
    var localMonitor: Any?
    var globalMonitor: Any?
    func install(matching: NSEvent.EventTypeMask = .keyDown,
                 handler: @escaping (NSEvent) -> NSEvent?) {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: matching, handler: handler)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: matching) { event in
            _ = handler(event)
        }
    }
    func remove() {
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
    }
    deinit { remove() }
}

struct HotkeyRecorderButton: View {
    @Binding var keyCode: UInt16
    @Binding var modifiers: UInt
    var onStartRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?

    @State private var isRecording = false
    @State private var holder = MonitorHolder()
    @State private var pendingKeyCode: UInt16?
    @State private var pendingModifiers: UInt?
    @State private var countdown = 0
    @State private var countdownTask: Task<Void, Never>?

    var body: some View {
        Button {
            if isRecording { cancel() } else { startRecording() }
        } label: {
            HStack {
                if isRecording, let pk = pendingKeyCode, let pm = pendingModifiers {
                    Text(hotkeyLabel(keyCode: pk, modifiers: NSEvent.ModifierFlags(rawValue: pm)))
                        .font(.callout).foregroundStyle(.orange)
                    Text("\(countdown)").font(.callout.monospacedDigit())
                        .foregroundStyle(.orange.opacity(0.6))
                } else if isRecording {
                    Text("Press shortcut...")
                        .font(.callout).foregroundStyle(.orange)
                } else {
                    Text(hotkeyLabel(keyCode: keyCode, modifiers: NSEvent.ModifierFlags(rawValue: modifiers)))
                        .font(.callout).foregroundStyle(.primary)
                }
                Spacer()
                if isRecording {
                    Text("ESC to cancel").font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isRecording ? Color.orange.opacity(0.1) : Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .onDisappear { cancel() }
    }

    private func startRecording() {
        isRecording = true
        pendingKeyCode = nil
        pendingModifiers = nil
        countdown = 0
        onStartRecording?()
        holder.install { event in
            if event.keyCode == 53 { cancel(); return nil }
            let mask: NSEvent.ModifierFlags = [.command, .shift, .option, .control, .function]
            let mods = event.modifierFlags.intersection(mask)
            guard !mods.isEmpty else { return nil }
            pendingKeyCode = event.keyCode
            pendingModifiers = mods.rawValue
            startCountdown()
            return nil
        }
    }

    private func startCountdown() {
        countdownTask?.cancel()
        countdown = 3
        countdownTask = Task { @MainActor in
            for i in (0..<3).reversed() {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                countdown = i
            }
            if let pk = pendingKeyCode, let pm = pendingModifiers {
                keyCode = pk
                modifiers = pm
            }
            finish()
        }
    }

    private func finish() {
        countdownTask?.cancel()
        countdownTask = nil
        holder.remove()
        pendingKeyCode = nil
        pendingModifiers = nil
        countdown = 0
        isRecording = false
        onStopRecording?()
    }

    private func cancel() {
        countdownTask?.cancel()
        countdownTask = nil
        holder.remove()
        guard isRecording else { return }
        pendingKeyCode = nil
        pendingModifiers = nil
        countdown = 0
        isRecording = false
        onStopRecording?()
    }
}
