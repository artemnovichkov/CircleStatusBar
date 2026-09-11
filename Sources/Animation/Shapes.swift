import SwiftUI

/// A round-capped stroke with continuously variable curvature.
///
/// With `bend == 0` it is a straight vertical line (the collapsed battery);
/// as `bend` grows it curls into an arc of radius `1 / bend`. The arc's center of curvature
/// lies to the left of the shape's center, so rotating the shape around the ring keeps it on the ring.
struct BendingStroke: Shape {
    var bend: Double
    var length: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard bend > 0.00001 else {
            path.move(to: CGPoint(x: rect.midX, y: rect.midY - length / 2))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.midY + length / 2))
            return path
        }
        let radius = 1 / bend
        let halfAngle = length / radius / 2
        path.addArc(
            center: CGPoint(x: rect.midX - radius, y: rect.midY),
            radius: radius,
            startAngle: .radians(-halfAngle),
            endAngle: .radians(halfAngle),
            clockwise: false
        )
        return path
    }
}

/// Wi-Fi symbol drawn in a 140×110 design space and scaled to fit the rect.
struct WiFiGlyph: Shape {
    private static let designSize = CGSize(width: 140, height: 110)

    func path(in rect: CGRect) -> Path {
        let arcStyle = StrokeStyle(lineWidth: 18, lineCap: .round)
        var result = Path()

        var outerArc = Path()
        outerArc.move(to: CGPoint(x: 15, y: 38))
        outerArc.addQuadCurve(to: CGPoint(x: 125, y: 38), control: CGPoint(x: 70, y: -6))
        result.addPath(outerArc.strokedPath(arcStyle))

        var innerArc = Path()
        innerArc.move(to: CGPoint(x: 38, y: 62))
        innerArc.addQuadCurve(to: CGPoint(x: 102, y: 62), control: CGPoint(x: 70, y: 37))
        result.addPath(innerArc.strokedPath(arcStyle))

        // Rounded wedge at the bottom.
        var wedge = Path()
        wedge.move(to: CGPoint(x: 55, y: 80))
        wedge.addQuadCurve(to: CGPoint(x: 85, y: 80), control: CGPoint(x: 70, y: 70))
        wedge.addQuadCurve(to: CGPoint(x: 86, y: 88), control: CGPoint(x: 90, y: 83))
        wedge.addLine(to: CGPoint(x: 76, y: 99))
        wedge.addQuadCurve(to: CGPoint(x: 64, y: 99), control: CGPoint(x: 70, y: 106))
        wedge.addLine(to: CGPoint(x: 54, y: 88))
        wedge.addQuadCurve(to: CGPoint(x: 55, y: 80), control: CGPoint(x: 50, y: 83))
        wedge.closeSubpath()
        result.addPath(wedge)

        let scale = CGAffineTransform(
            scaleX: rect.width / Self.designSize.width,
            y: rect.height / Self.designSize.height
        )
        return result.applying(scale)
    }
}

/// The small bump on the right side of the battery.
struct BatteryTerminal: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control1: CGPoint(x: rect.minX + rect.width * 1.3, y: rect.minY + rect.height * 0.15),
            control2: CGPoint(x: rect.minX + rect.width * 1.3, y: rect.minY + rect.height * 0.85)
        )
        path.closeSubpath()
        return path
    }
}
