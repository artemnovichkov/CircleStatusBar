import SwiftUI

/// Demo player with play/pause, scrubbing, speed and loop controls.
struct PlayerView: View {
    /// Background color of the reference video.
    static let background = Color(red: 229 / 255, green: 229 / 255, blue: 231 / 255)

    /// The source video ends at `duration`; when looping, the final pose is held a little longer.
    @State private var playback = Playback(duration: Choreography.duration, loopPeriod: 3.8)

    var body: some View {
        TimelineView(.animation(paused: !playback.isRunning(at: .now))) { context in
            let time = playback.time(at: context.date)
            VStack(spacing: 0) {
                CircleStatusBar(time: time)
                    .foregroundStyle(.black)
                controls(time: time, isRunning: playback.isRunning(at: context.date))
            }
        }
        .background(Self.background)
        .preferredColorScheme(.light)
        // A non-looping animation stops at its last frame, so the timeline can pause and stop redrawing.
        .task(id: playback) {
            guard let remaining = playback.remainingTime(at: .now) else { return }
            try? await Task.sleep(for: .seconds(remaining))
            guard !Task.isCancelled else { return }
            playback.pause(at: .now)
        }
    }

    private func controls(time: TimeInterval, isRunning: Bool) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    playback.togglePlayback(at: .now)
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .frame(width: 28, height: 28)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.space, modifiers: [])
                .accessibilityLabel(isRunning ? "Pause" : "Play")

                Slider(
                    value: Binding(get: { time }, set: { playback.seek(to: $0, at: .now) }),
                    in: 0...Choreography.duration
                )
                .accessibilityLabel("Animation position")

                Text("\(time, format: .number.precision(.fractionLength(2))) s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button("Replay", systemImage: "arrow.counterclockwise") {
                    playback.restart(at: .now)
                }
                .buttonStyle(.bordered)

                Spacer(minLength: 0)

                Picker("Speed", selection: Binding(get: { playback.rate }, set: { playback.setRate($0, at: .now) })) {
                    Text("0.25×").tag(0.25)
                    Text("0.5×").tag(0.5)
                    Text("1×").tag(1.0)
                }
                .pickerStyle(.menu)

                Toggle("Loop", systemImage: "repeat",
                       isOn: Binding(get: { playback.isLooping }, set: { playback.setLooping($0, at: .now) }))
                    .toggleStyle(.button)
            }
        }
        .padding(16)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }
}

#Preview {
    PlayerView()
}
