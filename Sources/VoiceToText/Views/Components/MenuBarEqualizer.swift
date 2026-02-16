import SwiftUI

struct MenuBarEqualizer: View {
    let level: Float
    private let barCount = 4
    private let barWidth: CGFloat = 2
    private let spacing: CGFloat = 1.5

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { i in
                let scale = barHeight(for: i)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.red)
                    .frame(width: barWidth, height: max(2, scale * 13))
                    .animation(.easeOut(duration: 0.12), value: level)
            }
        }
        .frame(width: CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * spacing, height: 14)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base = CGFloat(sqrt(max(0, level)))
        let offsets: [CGFloat] = [0.7, 1.0, 0.85, 0.6]
        return min(1, base * offsets[index])
    }
}
