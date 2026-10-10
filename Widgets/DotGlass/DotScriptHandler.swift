import Foundation
import WebKit

final class DotScriptHandler: NSObject, WKScriptMessageHandler {
    weak var owner: DotConnection?
    init(owner: DotConnection) { self.owner = owner }
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, message.frameInfo.securityOrigin.protocol == "https",
              message.frameInfo.securityOrigin.host == "chatgpt.com",
              [0, 443].contains(message.frameInfo.securityOrigin.port),
              JSONSerialization.isValidJSONObject(message.body),
              let data = try? JSONSerialization.data(withJSONObject: message.body), data.count <= 4_000_000 else { return }
        // Reject queued transcript events from a previous route after navigation.
        if let payload = message.body as? [String: Any], let room = payload["conversation"] as? String,
           let current = owner?.webView.url, let expected = DotURLPolicy.conversation(current.absoluteString),
           let incoming = DotURLPolicy.conversation(room), incoming != expected { return }
        if let voice = try? JSONDecoder().decode(DotVoiceSnapshot.self, from: data) {
            Task { @MainActor [weak self] in self?.owner?.receiveVoice(voice) }
        } else if let snapshot = try? JSONDecoder().decode(DotSnapshot.self, from: data) {
            Task { @MainActor [weak self] in self?.owner?.receive(snapshot) }
        }
    }
}
