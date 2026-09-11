import CoreGraphics
import Foundation

/// Small, dependency-free math toolbox used by the choreography.
///
/// Every function is pure, so any moment of the animation can be computed
/// directly from a timestamp — no state, no accumulated error.
enum Easing {

    /// Linear interpolation between `a` and `b`.
    static func mix(_ a: Double, _ b: Double, _ progress: Double) -> Double {
        a + (b - a) * progress
    }

    /// Normalized position of `time` inside `window`, clamped to `0...1`.
    static func progress(_ time: Double, in window: ClosedRange<Double>) -> Double {
        min(1, max(0, (time - window.lowerBound) / (window.upperBound - window.lowerBound)))
    }

    /// Hermite smoothstep: zero velocity at both ends of the window.
    static func smoothstep(_ time: Double, in window: ClosedRange<Double>) -> Double {
        let p = progress(time, in: window)
        return p * p * (3 - 2 * p)
    }

    /// Cubic ease-out: starts fast, decelerates into the end of the window.
    static func easeOut(_ time: Double, in window: ClosedRange<Double>) -> Double {
        let p = progress(time, in: window)
        return 1 - pow(1 - p, 3)
    }

    /// Gaussian bump that peaks at `1` when `time == peak`; `width` controls how quickly it fades.
    static func pulse(_ time: Double, peak: Double, width: Double) -> Double {
        exp(-pow((time - peak) / width, 2))
    }

    /// Exponentially decaying sine — a cheap spring overshoot. Zero before `start`.
    static func dampedOscillation(
        _ time: Double,
        start: Double,
        amplitude: Double,
        decay: Double,
        frequency: Double
    ) -> Double {
        guard time > start else { return 0 }
        let elapsed = time - start
        return amplitude * exp(-elapsed * decay) * sin(elapsed * frequency)
    }

    /// Point on a cubic Bézier curve at parameter `t`.
    static func cubicBezier(
        _ p0: CGPoint,
        _ p1: CGPoint,
        _ p2: CGPoint,
        _ p3: CGPoint,
        _ t: Double
    ) -> CGPoint {
        let u = 1 - t
        let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
        return CGPoint(
            x: a * p0.x + b * p1.x + c * p2.x + d * p3.x,
            y: a * p0.y + b * p1.y + c * p2.y + d * p3.y
        )
    }
}
