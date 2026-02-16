import SwiftUI

struct AudioLevelMeter: View {
    let level: Float
    let threshold: Double

    private var displayLevel: CGFloat { CGFloat(sqrt(max(0, level))) }
    private var displayThreshold: CGFloat { CGFloat(sqrt(min(threshold / Double(AudioConstants.maxExpectedEnergy), 1.0))) }

    private var barColor: Color {
        if level > 0.5 { return .red }
        if level > 0.15 { return .orange }
        if level > 0.03 { return .green }
        return .green.opacity(0.6)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let barWidth = max(level > 0.001 ? 4 : 0, displayLevel * w)
            let thresholdX = max(0, displayThreshold * w - 1)

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary.opacity(0.5))

                // Solid bar with glow
                RoundedRectangle(cornerRadius: 6)
                    .fill(barColor)
                    .shadow(color: barColor.opacity(level > 0.03 ? 0.5 : 0), radius: 6, y: 0)
                    .frame(width: barWidth)
                    .animation(.easeOut(duration: 0.1), value: level)

                // Threshold marker
                Capsule()
                    .fill(Color.primary.opacity(0.6))
                    .frame(width: 2, height: h - 6)
                    .shadow(color: .black.opacity(0.2), radius: 1)
                    .offset(x: thresholdX)
            }
        }
    }
}
