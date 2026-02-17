import SwiftUI

struct FloatingRecordingView: View {
    @State var appState: AppState

    private var timerText: String {
        let m = appState.recordingSeconds / 60
        let s = appState.recordingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        VStack(spacing: 4) {
            WaveformView(level: appState.audioLevel)

            Text(timerText)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.5))
                .fixedSize()
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
}

private struct WaveformView: View {
    let level: Float
    private static let barCount = 30
    private let barWidth: CGFloat = 3
    private let spacing: CGFloat = 1.5
    private let maxHeight: CGFloat = 18

    @State private var samples: [CGFloat] = Array(repeating: 0, count: Self.barCount)

    var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(0..<Self.barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.white.opacity(0.6))
                    .frame(width: barWidth, height: max(2, samples[i] * maxHeight))
            }
        }
        .frame(height: maxHeight, alignment: .bottom)
        .onChange(of: level) {
            samples.removeFirst()
            samples.append(min(1, CGFloat(sqrt(max(0, level))) * 2.5))
        }
    }
}
