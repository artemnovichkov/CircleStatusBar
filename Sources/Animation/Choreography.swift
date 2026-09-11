import CoreGraphics
import Foundation

/// Every number of the animation lives here.
///
/// Coordinates are in pixels of the 1280×720 reference video, times are in seconds
/// from its first frame (30 fps), so values can be measured straight from the original.
enum Choreography {

    static let duration: TimeInterval = 3.267

    // MARK: - Layout

    static let canvasSize = CGSize(width: 1280, height: 720)

    /// The final ring is centered on the Wi-Fi glyph.
    static let ringCenter = CGPoint(x: 640, y: 359.5)
    static let ringRadius = 109.0
    static let lineWidth = 16.0

    enum Bars {
        static let count = 4
        static let width = 23.5
        static let heights = [44.0, 59, 76, 93]
        static let firstX = 376.0
        static let spacing = 38.5
        static let baselineY = 410.0
        /// Each dot lands in the ring's bottom gap, from left (120°) to right (60°).
        static func finalAngle(_ index: Int) -> Double { 120 - Double(index) * 20 }
    }

    enum WiFi {
        static let size = CGSize(width: 140, height: 110)
        static let startCenter = CGPoint(x: 623, y: 360)
        static let finalScale = 0.81
    }

    enum Battery {
        static let height = 92.0
        static let cornerRadius = 34.0
        static let startWidth = 178.0
        static let startX = 832.5
        static let centerY = 359.5
        /// The body shrinks into a vertical stroke that sits exactly on the ring's right edge.
        static let collapsedWidth = lineWidth
        static let collapsedX = ringCenter.x + ringRadius
        static let terminalSize = CGSize(width: 12, height: 28)
        static let terminalX = 931.0
    }

    enum Stroke {
        /// The round caps add `lineWidth` to the path, so this matches the collapsed battery height.
        static let startLength = Battery.height - lineWidth
        /// Leaves a gap at the bottom of the ring for the four dots.
        static let finalLength = 464.0
    }

    // MARK: - Timing

    enum Timing {
        static let terminalFade = 0.70...0.85
        static let batteryCollapse = 0.84...1.38
        /// The battery body is swapped for a bending stroke at this instant.
        static let bendStart = batteryCollapse.upperBound
        static let wifiCentering = 1.40...1.90
        static let curvature = bendStart...1.53
        static let strokeDetach = bendStart...1.48
        static let strokeGrowth = 1.90...2.62

        /// The tallest bar collapses first; each shorter one starts a bit later.
        static func barCollapse(_ index: Int) -> ClosedRange<Double> {
            let rank = Double(Bars.count - 1 - index)
            return (0.90 + rank * 0.065)...(1.27 + rank * 0.035)
        }

        /// Dots take off right to left, 55 ms apart.
        static func dotFlight(_ index: Int) -> ClosedRange<Double> {
            let start = 1.84 + Double(Bars.count - 1 - index) * 0.055
            return start...(start + 0.73)
        }
    }
}

/// A snapshot of every element at a single moment.
///
/// `StatusBarPose(time:)` is a pure function: the same time always yields the same pose.
/// That makes scrubbing, reversing, speed changes and frame export trivial.
struct StatusBarPose {

    struct Bar {
        var center: CGPoint
        var height: Double
    }

    struct WiFi {
        var center: CGPoint
        var scale: Double
    }

    enum Battery {
        /// A rounded rectangle shrinking towards a line.
        case body(center: CGPoint, width: Double)
        /// A round-capped arc orbiting the ring center. `bend` is curvature (1 / radius).
        case stroke(center: CGPoint, rotation: Double, bend: Double, length: Double)
    }

    var bars: [Bar]
    var wifi: WiFi
    var battery: Battery
    var terminalScale: Double

    init(time: TimeInterval) {
        bars = (0..<Choreography.Bars.count).map { Self.bar($0, at: time) }
        wifi = Self.wifi(at: time)
        battery = Self.battery(at: time)
        terminalScale = 1 - Easing.smoothstep(time, in: Choreography.Timing.terminalFade)
    }
}

// MARK: - Elements

private extension StatusBarPose {

    typealias C = Choreography

    static func wifi(at time: Double) -> WiFi {
        let progress = Easing.smoothstep(time, in: C.Timing.wifiCentering)
        let center = CGPoint(x: Easing.mix(C.WiFi.startCenter.x, C.ringCenter.x, progress), y: C.WiFi.startCenter.y)
        return WiFi(center: center, scale: Easing.mix(1, C.WiFi.finalScale, progress))
    }

    static func battery(at time: Double) -> Battery {
        if time < C.Timing.bendStart {
            let progress = Easing.easeOut(time, in: C.Timing.batteryCollapse)
            return .body(
                center: CGPoint(x: Easing.mix(C.Battery.startX, C.Battery.collapsedX, progress), y: C.Battery.centerY),
                width: Easing.mix(C.Battery.startWidth, C.Battery.collapsedWidth, progress)
            )
        }

        // Right after the swap the stroke kicks outwards and twists like a hook,
        // then both effects fade while it orbits into place.
        let detach = Easing.smoothstep(time, in: C.Timing.strokeDetach)
        let hook = Easing.pulse(time, peak: 1.5, width: 0.045) * detach
        let excursion = 65 * Easing.pulse(time, peak: 1.56, width: 0.115) * detach
        let radius = C.ringRadius + excursion
        let angle = orbitAngle(at: time)

        let radians = angle * .pi / 180
        return .stroke(
            center: CGPoint(x: C.ringCenter.x + radius * cos(radians), y: C.ringCenter.y + radius * sin(radians)),
            rotation: angle - 60 * hook,
            bend: Easing.smoothstep(time, in: C.Timing.curvature) / radius + 0.015 * hook,
            length: Easing.mix(C.Stroke.startLength, C.Stroke.finalLength, Easing.easeOut(time, in: C.Timing.strokeGrowth))
        )
    }

    /// Position of the stroke around the ring, in degrees (0° = right, positive = clockwise on screen).
    ///
    /// A short clockwise dip, an accelerating counterclockwise turn,
    /// and a decelerating last half-turn that ends at the top (-450° ≡ -90°).
    static func orbitAngle(at time: Double) -> Double {
        switch time {
        case ..<1.5:
            Easing.mix(0, 40, Easing.smoothstep(time, in: C.Timing.bendStart...1.5))
        case ..<2.0:
            Easing.mix(40, -245, pow(Easing.progress(time, in: 1.5...2.0), 1.18))
        default:
            Easing.mix(-245, -450, Easing.easeOut(time, in: 2.0...2.69))
        }
    }

    static func bar(_ index: Int, at time: Double) -> Bar {
        // 1. Collapse: the capsule shrinks to a dot, bottoms stay on the baseline.
        let collapse = Easing.smoothstep(time, in: C.Timing.barCollapse(index))
        let height = Easing.mix(C.Bars.heights[index], C.Bars.width, collapse)
        let start = CGPoint(x: C.Bars.firstX + Double(index) * C.Bars.spacing, y: C.Bars.baselineY - height / 2)

        // 2. Flight: the dot swoops below the ring along a cubic Bézier curve.
        let angle = C.Bars.finalAngle(index) * .pi / 180
        let end = CGPoint(x: C.ringCenter.x + C.ringRadius * cos(angle), y: C.ringCenter.y + C.ringRadius * sin(angle))
        let flight = C.Timing.dotFlight(index)
        let position = Easing.cubicBezier(
            start,
            CGPoint(x: start.x, y: 556),
            CGPoint(x: end.x + 12, y: 566),
            end,
            Easing.smoothstep(time, in: flight)
        )

        // 3. Settle: a small springy bounce before the flight is over.
        let bounce = Easing.dampedOscillation(
            time,
            start: flight.lowerBound + 0.55,
            amplitude: -7,
            decay: 10,
            frequency: 19
        )
        return Bar(center: CGPoint(x: position.x, y: position.y + bounce), height: height)
    }
}
