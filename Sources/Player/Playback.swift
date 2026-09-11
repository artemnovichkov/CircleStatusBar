import Foundation

/// A tiny playback clock: maps wall-clock dates to animation time.
///
/// Instead of accumulating deltas every frame, it stores an anchor — "at `anchorDate`
/// the animation was at `anchorTime`" — and derives everything else from it.
/// Every mutation re-anchors at the current date, so play, pause, seek, speed and loop
/// changes never cause a jump.
struct Playback: Equatable {
    /// Length of the animation.
    var duration: TimeInterval
    /// Length of one loop cycle; the final pose is held for `loopPeriod - duration`.
    var loopPeriod: TimeInterval

    private var isPlaying = true
    private(set) var rate = 1.0
    private(set) var isLooping = true
    private var anchorTime: TimeInterval = 0
    private var anchorDate = Date.now

    init(duration: TimeInterval, loopPeriod: TimeInterval) {
        precondition(loopPeriod >= duration, "The loop period must include the whole animation")
        self.duration = duration
        self.loopPeriod = loopPeriod
    }

    /// Animation time at `date`, in `0...duration`.
    func time(at date: Date) -> TimeInterval {
        let elapsed = anchorTime + (isPlaying ? date.timeIntervalSince(anchorDate) * rate : 0)
        let cycleTime = isLooping ? elapsed.truncatingRemainder(dividingBy: loopPeriod) : elapsed
        return min(max(cycleTime, 0), duration)
    }

    /// `true` while time is actually advancing (a non-looping animation stops at its end).
    func isRunning(at date: Date) -> Bool {
        isPlaying && (isLooping || time(at: date) < duration)
    }

    /// How long until a non-looping animation reaches its end, or `nil` if it never will.
    func remainingTime(at date: Date) -> TimeInterval? {
        guard isPlaying, !isLooping else { return nil }
        return max(0, (duration - time(at: date)) / rate)
    }

    mutating func play(at date: Date) {
        let current = time(at: date)
        reanchor(time: current >= duration ? 0 : current, date: date)
        isPlaying = true
    }

    mutating func pause(at date: Date) {
        reanchor(time: time(at: date), date: date)
        isPlaying = false
    }

    mutating func togglePlayback(at date: Date) {
        if isRunning(at: date) { pause(at: date) } else { play(at: date) }
    }

    mutating func restart(at date: Date) {
        reanchor(time: 0, date: date)
        isPlaying = true
    }

    /// Jumps to `time` and pauses, like dragging a scrubber.
    mutating func seek(to time: TimeInterval, at date: Date) {
        reanchor(time: min(max(time, 0), duration), date: date)
        isPlaying = false
    }

    mutating func setRate(_ rate: Double, at date: Date) {
        precondition(rate > 0, "Rate must be positive")
        reanchor(time: time(at: date), date: date)
        self.rate = rate
    }

    mutating func setLooping(_ isLooping: Bool, at date: Date) {
        reanchor(time: time(at: date), date: date)
        self.isLooping = isLooping
    }

    private mutating func reanchor(time: TimeInterval, date: Date) {
        anchorTime = time
        anchorDate = date
    }
}
