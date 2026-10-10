import AppKit
import SwiftUI

struct VoiceOrbDemo: View {
    @State private var theme = DotTheme.orchid
    @State private var state = VoiceOrbState.speaking
    @State private var simulate = true
    @State private var level = 0.45
    @State private var sensitivity: Float = 1.5
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let speech = max(0, sin(t * 0.8)) * (0.2 + 0.55 * abs(sin(t * 4.2)))
            VStack(spacing: 20) {
                Text("Dot voice orb").font(.title2.bold())
                DotVoiceOrb(state: state, audioLevel: simulate ? speech : level,
                            configuration: VoiceOrbConfiguration(colors: theme.colors, sensitivity: sensitivity))
                    .frame(width: 260, height: 260)
                Picker("Theme", selection: $theme) {
                    ForEach(DotTheme.allCases, id: \.rawValue) { Text($0.rawValue).tag($0) }
                }
                Picker("State", selection: $state) {
                    Text("Idle").tag(VoiceOrbState.idle)
                    Text("Listening").tag(VoiceOrbState.listening)
                    Text("Speaking").tag(VoiceOrbState.speaking)
                }.pickerStyle(.segmented)
                Toggle("Simulate audio with pauses", isOn: $simulate)
                Slider(value: $level, in: 0...1) { Text("Audio level") }.disabled(simulate)
                Slider(value: $sensitivity, in: 0.5...4) { Text("Sensitivity") }
                Text("The renderer has no account, microphone or voice-service dependency.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(26).frame(width: 420).background(.regularMaterial)
        }
    }
}
@main struct OrbDemoApp {
    @MainActor static func main() {
        let app = NSApplication.shared; app.setActivationPolicy(.regular)
        let hosting = NSHostingView(rootView: VoiceOrbDemo())
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 420, height: 560),
                              styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Dot Glass · voice orb demo"; window.contentView = hosting
        window.center(); window.makeKeyAndOrderFront(nil); app.activate(ignoringOtherApps: true)
        app.run()
    }
}
