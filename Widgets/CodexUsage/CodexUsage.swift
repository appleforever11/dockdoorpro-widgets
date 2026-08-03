import DockDoorWidgetSDK
import Foundation
import SwiftUI

final class CodexUsagePlugin: WidgetPlugin, DockDoorWidgetProvider {
    var id: String { "codex-usage" }
    var name: String { "Codex Usage" }
    var iconSymbol: String { "gauge.with.dots.needle.67percent" }
    var widgetDescription: String { "Read-only Codex usage limits, credits, and reset countdowns" }
    var supportedOrientations: [WidgetOrientation] { [.horizontal, .vertical] }

    @MainActor
    func makeBody(size: CGSize, isVertical: Bool) -> AnyView {
        AnyView(CodexUsageCompactView(size: size, isVertical: isVertical))
    }

    @MainActor
    func makePanelBody(dismiss: @escaping () -> Void) -> AnyView? {
        AnyView(CodexUsagePanelView(dismiss: dismiss))
    }

    func settingsSchema() -> [WidgetSetting] {
        [
            .toggle(
                key: "rainbowUsageRing",
                label: "Rainbow Usage Ring",
                defaultValue: true
            ),
        ]
    }
}

private enum CodexUsagePreferences {
    static let widgetID = "codex-usage"

    static var rainbowUsageRing: Bool {
        WidgetDefaults.bool(key: "rainbowUsageRing", widgetId: widgetID, default: true)
    }

    static func setRainbowUsageRing(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "widget.\(widgetID).rainbowUsageRing")
    }
}

private struct CodexUsageCompactView: View {
    let size: CGSize
    let isVertical: Bool
    @State private var snapshot = CodexUsageSnapshot.empty
    @State private var now = Date()
    @State private var rainbow = CodexUsagePreferences.rainbowUsageRing

    private var dim: CGFloat { min(size.width, size.height) }
    private var isExtended: Bool {
        isVertical ? size.height > size.width * 1.5 : size.width > size.height * 1.5
    }
    private var card: CodexUsageCard { snapshot.card(at: now) }
    private var ringSize: CGFloat { min(max(dim * 0.70, 24), 38) }

    var body: some View {
        Group {
            if isExtended {
                extendedLayout
            } else {
                compactLayout
            }
        }
        .task {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { break }
                await refresh()
            }
        }
        .task {
            while !Task.isCancelled {
                now = Date()
                rainbow = CodexUsagePreferences.rainbowUsageRing
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    private var compactLayout: some View {
        VStack(spacing: 1) {
            UsageRing(
                percentRemaining: card.percentRemaining ?? snapshot.primaryPercent,
                size: ringSize,
                lineWidth: max(3, dim * 0.055),
                rainbow: rainbow
            )
            Text(card.shortLabel)
                .font(.system(size: max(9, min(dim * 0.21, 12)), weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(.primary)
    }

    private var extendedLayout: some View {
        Group {
            if isVertical {
                VStack(spacing: max(3, dim * 0.08)) {
                    UsageRing(
                        percentRemaining: card.percentRemaining ?? snapshot.primaryPercent,
                        size: ringSize,
                        lineWidth: max(3, dim * 0.052),
                        rainbow: rainbow
                    )
                    usageLabels(alignment: .center)
                }
            } else {
                HStack(spacing: max(4, dim * 0.05)) {
                    UsageRing(
                        percentRemaining: card.percentRemaining ?? snapshot.primaryPercent,
                        size: ringSize,
                        lineWidth: max(3, dim * 0.052),
                        rainbow: rainbow
                    )
                    usageLabels(alignment: .leading)
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
        .foregroundStyle(.primary)
    }

    private func usageLabels(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 1) {
            Text(card.title)
                .font(.system(size: isVertical ? 11 : 13, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.70)
            Text(card.subtitle)
                .font(.system(size: isVertical ? 8.5 : 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(.primary.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .layoutPriority(1)
    }

    private func refresh() async {
        snapshot = await CodexUsageStore.read()
        rainbow = CodexUsagePreferences.rainbowUsageRing
    }
}

private struct CodexUsagePanelView: View {
    let dismiss: () -> Void
    @State private var snapshot = CodexUsageSnapshot.empty
    @State private var rainbow = CodexUsagePreferences.rainbowUsageRing
    @State private var now = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Label("Codex Usage", systemImage: "gauge.with.dots.needle.67percent")
                    .font(.headline)
                Spacer()
                Button {
                    rainbow.toggle()
                    CodexUsagePreferences.setRainbowUsageRing(rainbow)
                } label: {
                    Image(systemName: rainbow ? "paintpalette.fill" : "paintpalette")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(rainbow ? .pink : .secondary)
                        .frame(width: 22, height: 22)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .help(rainbow ? "Rainbow usage ring is on" : "Turn on rainbow usage ring")
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                UsageRing(
                    percentRemaining: snapshot.primaryPercent,
                    size: 72,
                    lineWidth: 7,
                    rainbow: rainbow
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.primaryTitle)
                        .font(.title3.weight(.bold))
                    Text(snapshot.primarySubtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text(snapshot.resetSummary(now: now))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 10) {
                UsageStat(title: "Limits", value: "\(snapshot.limits.count)")
                UsageStat(title: "Credits", value: snapshot.creditsBalance ?? "-")
                UsageStat(title: "Source", value: "Local")
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Usage Limits")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(snapshot.limits) { limit in
                    HStack(spacing: 8) {
                        Image(systemName: limit.systemImage)
                            .frame(width: 16)
                            .foregroundStyle(limit.tint)
                        Text(limit.name)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(limit.percentLabel)
                                .font(.caption.monospacedDigit().weight(.bold))
                            Text(limit.resetLabel)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .lineLimit(1)
                }
            }

            Text("Read-only local snapshot")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(width: 350)
        .task {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { break }
                await refresh()
            }
        }
        .task {
            while !Task.isCancelled {
                now = Date()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    private func refresh() async {
        snapshot = await CodexUsageStore.read()
        rainbow = CodexUsagePreferences.rainbowUsageRing
    }
}

private struct UsageRing: View {
    let percentRemaining: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let rainbow: Bool

    private var clamped: Double { min(max(percentRemaining, 0), 1) }
    private var fallbackColor: Color {
        switch clamped {
        case 0.45...: return Color(red: 0.13, green: 0.72, blue: 1.00)
        case 0.20..<0.45: return .orange
        default: return .red
        }
    }
    private var colors: [Color] {
        rainbow
            ? [
                Color(red: 1.00, green: 0.18, blue: 0.34),
                Color(red: 1.00, green: 0.55, blue: 0.16),
                Color(red: 1.00, green: 0.90, blue: 0.18),
                Color(red: 0.18, green: 0.86, blue: 0.36),
                Color(red: 0.12, green: 0.70, blue: 1.00),
                Color(red: 0.48, green: 0.34, blue: 1.00),
                Color(red: 0.95, green: 0.28, blue: 0.86),
                Color(red: 1.00, green: 0.18, blue: 0.34),
            ]
            : [fallbackColor.opacity(0.72), fallbackColor, .cyan.opacity(0.85)]
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(rainbow ? 0.10 : 0.14), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(colors: colors, center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            if rainbow {
                Circle()
                    .trim(from: 0, to: clamped)
                    .stroke(
                        AngularGradient(colors: colors, center: .center),
                        style: StrokeStyle(lineWidth: lineWidth * 1.55, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: max(2, lineWidth * 0.55))
                    .opacity(0.55)
            }
            VStack(spacing: -1) {
                Text("\(Int((clamped * 100).rounded()))")
                    .font(.system(size: size * 0.34, weight: .black, design: .rounded))
                    .monospacedDigit()
                Text("%")
                    .font(.system(size: size * 0.15, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .minimumScaleFactor(0.65)
        }
        .frame(width: size, height: size)
        .background(.black.opacity(0.16), in: Circle())
        .shadow(color: (rainbow ? Color.pink : fallbackColor).opacity(rainbow ? 0.48 : 0.30), radius: rainbow ? 8 : 5, y: 1)
        .accessibilityLabel("Codex usage remaining")
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent")
    }
}

private struct UsageStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.callout.weight(.bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CodexUsageSnapshot {
    let limits: [CodexUsageLimit]
    let creditsBalance: String?

    static let empty = CodexUsageSnapshot(
        limits: [CodexUsageLimit(name: "General", percentRemaining: 1, resetLabel: "Waiting for data", systemImage: "gauge.with.dots.needle.67percent")],
        creditsBalance: nil
    )

    var primaryLimit: CodexUsageLimit {
        limits.first ?? CodexUsageLimit(name: "General", percentRemaining: 1, resetLabel: "Waiting for data", systemImage: "gauge.with.dots.needle.67percent")
    }

    var primaryPercent: Double { primaryLimit.percentRemaining }
    var primaryTitle: String { primaryLimit.percentLabel }
    var primarySubtitle: String { "\(primaryLimit.name) - \(primaryLimit.resetLabel)" }

    func resetSummary(now: Date) -> String {
        if let resetDate = primaryLimit.resetDate {
            let interval = max(0, resetDate.timeIntervalSince(now))
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            return hours > 0 ? "Resets in \(hours)h \(minutes)m" : "Resets in \(minutes)m"
        }
        return primaryLimit.resetLabel == "No reset date" ? "No reset date in local snapshot" : "Resets \(primaryLimit.resetLabel)"
    }

    func card(at date: Date) -> CodexUsageCard {
        var cards = limits.map { limit in
            CodexUsageCard(
                title: limit.percentLabel,
                subtitle: "\(limit.shortName) - \(limit.resetLabel)",
                shortLabel: limit.shortName,
                percentRemaining: limit.percentRemaining
            )
        }
        if let creditsBalance {
            cards.append(CodexUsageCard(
                title: creditsBalance,
                subtitle: "Current credits",
                shortLabel: "Credits",
                percentRemaining: nil
            ))
        }
        guard !cards.isEmpty else {
            return CodexUsageCard(title: "Usage", subtitle: "Waiting for data", shortLabel: "Usage", percentRemaining: 1)
        }
        let index = Int(date.timeIntervalSinceReferenceDate / 4) % cards.count
        return cards[index]
    }
}

private struct CodexUsageCard {
    let title: String
    let subtitle: String
    let shortLabel: String
    let percentRemaining: Double?
}

private struct CodexUsageLimit: Identifiable {
    let id: String
    let name: String
    let percentRemaining: Double
    let resetDate: Date?
    let resetLabel: String
    let systemImage: String

    init(name: String, percentRemaining: Double, resetDate: Date? = nil, resetLabel: String, systemImage: String) {
        self.id = name
        self.name = name
        self.percentRemaining = min(max(percentRemaining, 0), 1)
        self.resetDate = resetDate
        self.resetLabel = resetLabel
        self.systemImage = systemImage
    }

    var percentLabel: String { "\(Int((percentRemaining * 100).rounded()))% left" }
    var shortName: String {
        if name.localizedCaseInsensitiveContains("spark") { return "Spark" }
        if name.localizedCaseInsensitiveContains("general") { return "General" }
        return name.count > 10 ? String(name.prefix(10)) : name
    }
    var tint: Color {
        switch percentRemaining {
        case 0.45...: return Color(red: 0.13, green: 0.72, blue: 1.00)
        case 0.20..<0.45: return .orange
        default: return .red
        }
    }
}

private enum CodexUsageStore {
    private static let usageURL = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent(".codex/usage.json")

    static func read() async -> CodexUsageSnapshot {
        guard let data = try? Data(contentsOf: usageURL),
              let file = try? JSONDecoder().decode(CodexUsageFile.self, from: data)
        else {
            return .empty
        }

        let decodedLimits = (file.limits ?? []).map { record in
            CodexUsageLimit(
                name: record.name,
                percentRemaining: record.normalizedRemainingPercent,
                resetDate: parseDate(record.resetAt),
                resetLabel: record.resetLabel ?? "No reset date",
                systemImage: record.systemImage ?? defaultSymbol(for: record.name)
            )
        }

        let limits: [CodexUsageLimit]
        if decodedLimits.isEmpty {
            let remaining = normalizedRemaining(
                remaining: file.percentRemaining ?? file.remainingPercent,
                used: file.percentUsed ?? file.usedPercent,
                amountRemaining: file.remaining,
                amountLimit: file.limit
            ) ?? 1
            limits = [CodexUsageLimit(
                name: file.title ?? "General",
                percentRemaining: remaining,
                resetDate: parseDate(file.resetAt),
                resetLabel: file.resetLabel ?? "No reset date",
                systemImage: "gauge.with.dots.needle.67percent"
            )]
        } else {
            limits = decodedLimits
        }

        return CodexUsageSnapshot(limits: limits, creditsBalance: file.creditsBalance)
    }

    private static func normalizedRemaining(
        remaining: Double?,
        used: Double?,
        amountRemaining: Int64?,
        amountLimit: Int64?
    ) -> Double? {
        if let remaining {
            return min(max(remaining > 1 ? remaining / 100 : remaining, 0), 1)
        }
        if let used {
            return min(max(1 - (used > 1 ? used / 100 : used), 0), 1)
        }
        if let amountRemaining, let amountLimit, amountLimit > 0 {
            return min(max(Double(amountRemaining) / Double(amountLimit), 0), 1)
        }
        return nil
    }

    private static func defaultSymbol(for name: String) -> String {
        name.localizedCaseInsensitiveContains("spark") ? "sparkles" : "gauge.with.dots.needle.67percent"
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}

private struct CodexUsageFile: Decodable {
    let title: String?
    let creditsBalance: String?
    let remaining: Int64?
    let limit: Int64?
    let resetAt: String?
    let resetLabel: String?
    let percentRemaining: Double?
    let remainingPercent: Double?
    let percentUsed: Double?
    let usedPercent: Double?
    let limits: [CodexUsageLimitRecord]?
}

private struct CodexUsageLimitRecord: Decodable {
    let name: String
    let resetAt: String?
    let resetLabel: String?
    let percentRemaining: Double?
    let remainingPercentValue: Double?
    let percentUsed: Double?
    let usedPercent: Double?
    let remaining: Int64?
    let limit: Int64?
    let systemImage: String?

    var normalizedRemainingPercent: Double {
        if let value = percentRemaining ?? remainingPercentValue {
            return min(max(value > 1 ? value / 100 : value, 0), 1)
        }
        if let value = percentUsed ?? usedPercent {
            return min(max(1 - (value > 1 ? value / 100 : value), 0), 1)
        }
        if let remaining, let limit, limit > 0 {
            return min(max(Double(remaining) / Double(limit), 0), 1)
        }
        return 1
    }

    enum CodingKeys: String, CodingKey {
        case name
        case resetAt
        case resetLabel
        case percentRemaining
        case remainingPercentValue = "remainingPercent"
        case percentUsed
        case usedPercent
        case remaining
        case limit
        case systemImage
    }
}
