import SwiftUI

/// Marketplace edition: source-backed pages, with appearance owned by the host.
@MainActor
struct CodexUsagePanelView: View {
    let model: CodexUsageModel
    let dismiss: () -> Void
    @State private var page: Page = .overview
    private var snapshot: CodexUsageSnapshot { model.snapshot }
    private var theme: CodexTheme { CodexTheme.current(widgetId: codexUsageWidgetId) }

    private enum Page: String, CaseIterable {
        case overview = "Overview", model = "Model", health = "Health"
        var symbol: String {
            switch self {
            case .overview: return "gauge.with.dots.needle.67percent"
            case .model: return "square.stack.3d.up"
            case .health: return "heart.text.square"
            }
        }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 5)) { timeline in
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Codex Usage").font(.headline)
                    Spacer()
                    Button(action: dismiss) { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Close Codex Usage")
                }
                HStack(spacing: 6) {
                    ForEach(Page.allCases, id: \.self) { option in
                        Button { page = option } label: {
                            Label(option.rawValue, systemImage: option.symbol)
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(theme.accent.opacity(page == option ? 0.22 : 0.06),
                                            in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(page == option ? .isSelected : [])
                    }
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        switch page {
                        case .overview: overview(now: timeline.date)
                        case .model: modelDetails
                        case .health: health
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(2)
                }
                Text("Read-only local snapshot")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(CodexThemeBackground(theme: theme))
            .tint(theme.accent)
            .task(id: timeline.date) { await model.tick() }
        }
    }

    private func overview(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                UsageRing(percentRemaining: snapshot.primaryPercent, size: 76, lineWidth: 7, theme: theme)
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.primaryTitle).font(.title2.weight(.bold))
                    Text(snapshot.primaryLimit?.name ?? "No usage recorded").font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(snapshot.resetSummary(now: now)).font(.caption).foregroundStyle(theme.accent)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(theme.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.accent.opacity(0.22)))
            HStack(spacing: 8) {
                UsageStat(title: "Limits", value: "\(snapshot.limits.count)")
                UsageStat(title: "Credits", value: snapshot.creditsBalance ?? "—")
                UsageStat(title: "Source", value: "Local")
            }
            Text("Usage limits").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            if snapshot.limits.isEmpty {
                Text("Run a Codex session to record usage limits.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            ForEach(snapshot.limits) { limit in
                HStack(spacing: 8) {
                    Image(systemName: limit.systemImage).foregroundStyle(theme.accent).frame(width: 18)
                    Text(limit.name).font(.caption.weight(.semibold))
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(limit.percentLabel).font(.caption.monospacedDigit().weight(.bold))
                        Text(limit.resetLabel).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            Divider()
            Label(snapshot.modelSummary, systemImage: "sparkles")
                .font(.caption.weight(.semibold)).foregroundStyle(theme.accent)
        }
    }

    private var modelDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest recorded model").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            if let context = snapshot.modelContext {
                let identity = CodexTheme.allCases.first { $0.rawValue == context.modelLabel } ?? theme
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.modelLabel).font(.title2.weight(.bold))
                    Text(context.reasoningLabel).font(.callout.weight(.semibold))
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.8), radius: 3)
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 100, alignment: .bottomLeading)
                .background {
                    GeometryReader { geometry in
                        CodexIdentityArtwork(identity: identity, isEmphasized: true)
                            .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                if let identifier = context.model {
                    Text(identifier).font(.caption.monospaced()).textSelection(.enabled)
                }
            } else {
                Text("No model context recorded yet.").font(.callout)
            }
            Text("Model and effort come from the latest local session record. Change new-chat defaults in Codex.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var health: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Local source status", systemImage: "heart.text.square").font(.headline)
            statusRow("Limits available", value: snapshot.limits.isEmpty ? "No" : "Yes")
            statusRow("Model recorded", value: snapshot.modelContext == nil ? "No" : "Yes")
            if let lastRead = model.lastRead {
                HStack {
                    Text("Last checked").font(.caption)
                    Spacer()
                    Text(lastRead, style: .time).font(.caption.monospacedDigit())
                }
            }
            Divider()
            Text("Reads Codex session logs and an optional local usage.json snapshot. Last checked is the read time, not the age of the recorded account limits.")
                .font(.caption).foregroundStyle(.secondary)
            Text("Choose the widget theme in DockDoor’s widget settings.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func statusRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title).font(.caption)
            Spacer()
            Text(value).font(.caption.weight(.semibold)).foregroundStyle(theme.accent)
        }
    }
}
