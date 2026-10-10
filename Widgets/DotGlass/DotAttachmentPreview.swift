import AppKit
import SwiftUI

/// Small previews made from images already rendered in the owned web session.
/// Authenticated downloads and unsupported media remain explicit browser actions.
struct DotAttachmentPreview: View {
    let encoded: String
    @State private var enlarged = false
    private var image: NSImage? {
        guard encoded.utf8.count <= 180000, encoded.hasPrefix("data:image/png;base64,"),
              let data = Data(base64Encoded: String(encoded.dropFirst(22))),
              let image = NSImage(data: data), image.size.width <= 320, image.size.height <= 220 else { return nil }
        return image
    }
    var body: some View {
        if let image {
            Button { enlarged = true } label: {
                Image(nsImage: image).resizable().scaledToFit().frame(maxWidth: 240, maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }.buttonStyle(.plain).accessibilityLabel("View image preview")
                .sheet(isPresented: $enlarged) {
                    VStack(spacing: 16) {
                        Image(nsImage: image).resizable().scaledToFit().frame(maxWidth: 480, maxHeight: 360)
                        Text("Image preview · open the attachment in your browser for the original").font(.caption).foregroundStyle(.secondary)
                        Button("Done") { enlarged = false }.keyboardShortcut(.cancelAction)
                    }.padding(24)
                }
        }
    }
}
