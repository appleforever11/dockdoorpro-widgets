import SwiftUI

/// Artwork and controls belong to Dot Glass; no Tracker assets or runtime dependency.
struct DotAppearancePicker: View {
    @State var theme: DotTheme
    @State var opacity: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Appearance").font(.system(.title2, design: .rounded).weight(.bold))
                    Text("Live theme previews").font(.callout).foregroundStyle(.secondary)
                }
                Spacer(minLength: 6)
                Text(theme.rawValue).font(.caption.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(theme.colors[0].opacity(0.16), in: Capsule())
            }
            Text("ORB GLOW").font(.caption.weight(.semibold)).tracking(1.7).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(DotTheme.allCases, id: \.rawValue) { choice in
                    DotThemeCard(theme: choice, selected: theme == choice) {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                            theme = choice
                        }
                    }
                }
            }
            HStack(spacing: 12) {
                DotRing(phase: .speaking, diameter: 68)
                    .environment(\.dotTheme, theme)
                    .accessibilityLabel("Animated \(theme.rawValue) orb preview")
                VStack(alignment: .leading, spacing: 6) {
                    Text("Here with you.").font(.caption.weight(.medium))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .modifier(DotBubbleSurface(isMine: false))
                    Text("Hello, Dot.").font(.caption)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .modifier(DotBubbleSurface(isMine: true)).frame(maxWidth: .infinity, alignment: .trailing)
                }
            }.padding(12).background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 18))
                .environment(\.dotTheme, theme).environment(\.dotGlassOpacity, opacity)
            Divider().opacity(0.5)
            HStack {
                Text("GLASS").font(.caption.weight(.semibold)).tracking(1.7).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int((opacity * 100).rounded()))%").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            Slider(value: $opacity, in: 0.2...1, step: 0.05) { Text("Glass opacity") }
                .tint(theme.colors[0]).accessibilityLabel("Glass opacity")
            Text("Preview only. Save your theme and glass opacity in DockDoor Settings → Stacks → Dot Glass.")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(20).frame(width: 360)
            .environment(\.colorScheme, .dark)
            .modifier(DotGlassSurface(opacity: max(0.65, opacity)))
    }
}

private struct DotThemeCard: View {
    let theme: DotTheme
    let selected: Bool
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16).fill(
                    LinearGradient(colors: [theme.colors[1].opacity(0.55), theme.colors[0].opacity(0.3), .black.opacity(0.72)],
                                   startPoint: .topTrailing, endPoint: .bottomLeading))
                DotThemeArtwork(theme: theme).clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                HStack(spacing: 6) {
                    Image(systemName: theme.artSymbol).font(.caption.weight(.semibold))
                    Text(theme.rawValue).font(.system(.callout, design: .rounded).weight(.bold))
                }.foregroundStyle(.white).padding(12)
                if selected {
                    Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white).frame(width: 20, height: 20)
                        .background(theme.colors[0].opacity(0.85), in: Circle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(9)
                }
            }.frame(height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(
                    selected ? theme.colors[2] : .white.opacity(hovered ? 0.4 : 0.16), lineWidth: selected ? 2 : 0.7))
                .shadow(color: theme.colors[0].opacity(selected ? 0.24 : 0), radius: 9)
                .contentShape(RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain).onHover { hovered = $0 }
            .accessibilityLabel("\(theme.rawValue) theme").accessibilityValue(selected ? "Selected" : "")
            .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

private struct DotThemeArtwork: View {
    let theme: DotTheme
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                Canvas { context, _ in
                    for index in 0..<4 {
                        let offset = CGFloat(index) * 13
                        var path = Path()
                        path.move(to: CGPoint(x: -15, y: size.height * 0.5 + offset))
                        path.addCurve(to: CGPoint(x: size.width + 10, y: 8 + offset),
                                      control1: CGPoint(x: size.width * 0.4, y: -35 + offset),
                                      control2: CGPoint(x: size.width * 0.58, y: size.height + offset))
                        context.stroke(path, with: .color(theme.colors[index % 3].opacity(theme == .aurora ? 0.5 : 0.17)),
                                       lineWidth: theme == .aurora ? 6 : 0.8)
                    }
                    for point in [CGPoint(x: 25, y: 17), CGPoint(x: 75, y: 32), CGPoint(x: 133, y: 62)] {
                        context.fill(Path(ellipseIn: CGRect(x: point.x, y: point.y, width: 1.5, height: 1.5)), with: .color(.white.opacity(0.5)))
                    }
                }
                Circle().fill(RadialGradient(colors: [theme.colors[0].opacity(0.52), .clear], center: .center, startRadius: 0, endRadius: 50))
                    .frame(width: 110, height: 110).position(x: size.width * 0.73, y: 34)
                DotRing(phase: .ready, diameter: 70).environment(\.dotTheme, theme)
                    .position(x: size.width * 0.73, y: 34)
                Image(systemName: theme.artSymbol).font(.system(size: 19, weight: .light))
                    .foregroundStyle(theme.colors[2].opacity(0.85)).position(x: size.width * 0.73, y: 34)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

private extension DotTheme {
    var artSymbol: String {
        switch self {
        case .arctic: return "snowflake"
        case .aurora: return "sparkles"
        case .orchid: return "moon.stars.fill"
        case .ember: return "flame.fill"
        case .rose: return "heart.fill"
        case .solar: return "sun.max.fill"
        }
    }
}
