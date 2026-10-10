import AppKit
import SwiftUI
@main struct DebutPreview: App {
    @State private var connection = DotConnection(defaults: UserDefaults(suiteName: "dot-glass.offline-debut-preview")!)
    @State private var mode = CommandLine.arguments.dropFirst().first ?? "Conversation"
    @State private var theme = DotTheme.current
    var body: some Scene {
        WindowGroup("Dot Glass · Offline review examples") {
            VStack(spacing: 8) {
                Text("OFFLINE EXAMPLE · NO ACCOUNT OR LIVE CALL").font(.caption2).tracking(1)
                HStack {
                    Picker("Screen", selection: $mode) {
                        ForEach(["Conversation", "Onboarding", "Tour", "Recovery", "Muted call"], id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Theme", selection: $theme) { ForEach(DotTheme.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                }
                DotPanel(connection: connection).frame(width: 440, height: 640)
            }.padding(12).background(.regularMaterial)
            .onChange(of: mode) { _, _ in configure() }
            .onChange(of: theme) { _, _ in UserDefaults.standard.set(theme.rawValue, forKey: "widget.dot-glass.theme") }
            .task {
                connection.webView.loadHTMLString("<html><body>Offline fixture</body></html>", baseURL: URL(string: "about:blank"))
                try? await Task.sleep(for: .milliseconds(500)); configure()
            }
        }.windowResizability(.contentSize)
    }
    private func configure() {
        connection.name = "Your Dot"; connection.ready = true; connection.loading = false
        connection.showConnection = false; connection.showTour = mode == "Tour"; connection.needsSetup = mode == "Onboarding"
        connection.voiceConnected = mode == "Muted call"; connection.microphoneMuted = mode == "Muted call"
        connection.notice = mode == "Recovery" ? "Your ChatGPT session expired. Sign in again to reconnect; your draft is safe." : nil
        if mode == "Recovery" { connection.ready = false }
        connection.messages = [
            DotMessage(id: "one", text: "Hey Dot, let’s talk through an idea.", isMine: true, hasAttachment: false, readReceipt: "Read"),
            DotMessage(id: "two", text: "Of course. What are you thinking?", isMine: false, hasAttachment: false),
            DotMessage(id: "three", text: "I’ll call you from my dock.", isMine: true, hasAttachment: false),
            DotMessage(id: "four", text: "I’m here whenever you’re ready.", isMine: false, hasAttachment: false)
        ]
    }
}
