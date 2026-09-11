import SwiftUI

/// Status bar icons that morph into a ring around the Wi-Fi glyph.
///
/// The view is stateless: it renders the pose for `time` and scales the 1280×720 canvas to fit.
/// Glyphs use the current foreground style.
///
/// ```swift
/// CircleStatusBar(time: 2.6)
///     .frame(width: 640, height: 360)
/// ```
struct CircleStatusBar: View {
    var time: TimeInterval

    var body: some View {
        GeometryReader { proxy in
            let canvas = Choreography.canvasSize
            let scale = min(proxy.size.width / canvas.width, proxy.size.height / canvas.height)
            PoseCanvas(pose: StatusBarPose(time: time))
                .frame(width: canvas.width, height: canvas.height)
                .scaleEffect(scale, anchor: .topLeading)
                .offset(x: (proxy.size.width - canvas.width * scale) / 2,
                        y: (proxy.size.height - canvas.height * scale) / 2)
        }
        .accessibilityElement()
        .accessibilityLabel("Cellular signal and battery morph into a ring around Wi-Fi")
    }
}

/// Draws a pose in canvas coordinates.
private struct PoseCanvas: View {
    typealias C = Choreography
    let pose: StatusBarPose

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(pose.bars.indices, id: \.self) { index in
                let bar = pose.bars[index]
                Capsule()
                    .fill(.foreground)
                    .frame(width: C.Bars.width, height: bar.height)
                    .position(bar.center)
            }

            WiFiGlyph()
                .fill(.foreground)
                .frame(width: C.WiFi.size.width, height: C.WiFi.size.height)
                .scaleEffect(pose.wifi.scale)
                .position(pose.wifi.center)

            battery

            BatteryTerminal()
                .fill(.foreground)
                .frame(width: C.Battery.terminalSize.width * pose.terminalScale,
                       height: C.Battery.terminalSize.height * pose.terminalScale)
                .position(x: C.Battery.terminalX, y: C.Battery.centerY)
                .opacity(pose.terminalScale)
        }
    }

    @ViewBuilder
    private var battery: some View {
        switch pose.battery {
        case let .body(center, width):
            RoundedRectangle(cornerRadius: min(C.Battery.cornerRadius, width / 2), style: .continuous)
                .fill(.foreground)
                .frame(width: width, height: C.Battery.height)
                .position(center)
        case let .stroke(center, rotation, bend, length):
            // The frame only defines the local origin; the path may extend past it.
            BendingStroke(bend: bend, length: length)
                .stroke(.foreground, style: StrokeStyle(lineWidth: C.lineWidth, lineCap: .round))
                .frame(width: 500, height: 500)
                .rotationEffect(.degrees(rotation))
                .position(center)
        }
    }
}

#Preview("Key poses", traits: .fixedLayout(width: 600, height: 700)) {
    VStack(spacing: 0) {
        ForEach([0, 1.3, 1.7, 2.1, Choreography.duration], id: \.self) { time in
            CircleStatusBar(time: time)
                .overlay(alignment: .topLeading) {
                    Text(time, format: .number.precision(.fractionLength(2)))
                        .font(.caption.monospaced())
                        .padding(8)
                }
        }
    }
    .background(PlayerView.background)
    .foregroundStyle(.black)
}
