import AppKit
import DockDoorWidgetSDK
import SwiftUI

struct SystemMonitorPanel: View {
    let dismiss: () -> Void
    let widgetId: String
    var monitor: SystemMetricsMonitor

    private let panelWidth: CGFloat = 340
    private let panelHorizontalPadding: CGFloat = 14
    private let panelScreenMargin: CGFloat = 48
    private let headerHeightAllowance: CGFloat = 42
    private let maximumScrollViewportHeight: CGFloat = 760

    private var refreshInterval: TimeInterval {
        switch WidgetDefaults.string(key: "refreshInterval", widgetId: widgetId, default: "1s") {
        case "5s": return 5
        case "2s": return 2
        default: return 1
        }
    }

    private var processLimit: Int {
        Int(WidgetDefaults.string(key: "processCount", widgetId: widgetId, default: "8")) ?? 8
    }

    private var scrollViewportHeight: CGFloat {
        let mouseLocation = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
        let visibleHeight = activeScreen?.visibleFrame.height ?? 800
        let screenConstrainedHeight = max(
            320,
            visibleHeight - (panelScreenMargin * 2) - headerHeightAllowance
        )
        return min(maximumScrollViewportHeight, screenConstrainedHeight)
    }

    private var panelCardWidth: CGFloat {
        panelWidth - (panelHorizontalPadding * 2)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: refreshInterval)) { context in
            panelContent
                .onChange(of: context.date) { _, _ in
                    monitor.tick(minimumInterval: refreshInterval * 0.8)
                }
        }
        .onAppear {
            monitor.tick(minimumInterval: 0)
        }
    }

    private var panelContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(width: panelWidth, height: 0)
                .accessibilityHidden(true)

            header
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                .zIndex(1)
            SystemGlassDivider()
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    overview
                    history
                    cpuDetails
                    memoryDetails
                    processSection(
                        title: "Top CPU Processes",
                        symbol: "cpu",
                        processes: Array(monitor.topCPUProcesses.prefix(processLimit)),
                        value: { SystemValueFormatter.processPercent($0.value) },
                        color: SystemMonitorPalette.cpuUser,
                        reflectionFromTrailing: false
                    )
                    processSection(
                        title: "Top Memory Processes",
                        symbol: "memorychip",
                        processes: Array(monitor.topMemoryProcesses.prefix(processLimit)),
                        value: { SystemValueFormatter.bytes($0.value) },
                        color: SystemMonitorPalette.memoryCompressed,
                        reflectionFromTrailing: true
                    )
                }
                .frame(width: panelCardWidth, alignment: .leading)
                .padding(.horizontal, panelHorizontalPadding)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .frame(width: panelWidth, height: scrollViewportHeight)
            .layoutPriority(0)
            .clipped()
        }
        .background(panelBackground)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.headline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [SystemMonitorPalette.cpuUser, SystemMonitorPalette.memoryCompressed],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("CPU & Memory")
                .font(.headline)

            Spacer()
            SystemLivePulseDot(color: SystemMonitorPalette.cpuUser)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color.primary.opacity(0.06), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var overview: some View {
        HStack(spacing: 0) {
            panelMetricRing(
                title: "CPU",
                value: SystemValueFormatter.percent(monitor.cpu.used),
                segments: cpuSegments
            )

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 0.5, height: 98)

            panelMetricRing(
                title: "Memory",
                value: SystemValueFormatter.percent(monitor.memory.usedFraction),
                segments: memorySegments
            )
        }
        .background(
            SystemGlassCard(
                leadingTint: SystemMonitorPalette.cpuUser,
                trailingTint: SystemMonitorPalette.memoryCompressed
            )
        )
    }

    private func panelMetricRing(title: String, value: String, segments: [UsageSegment]) -> some View {
        MetricRingView(
            title: title,
            value: value,
            segments: segments,
            size: 88,
            typography: .semantic
        )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionLabel("60-second History")

            HStack(spacing: 8) {
                historyCard(
                    title: "CPU",
                    value: SystemValueFormatter.percent(monitor.cpu.used),
                    data: monitor.cpuHistory,
                    color: SystemMonitorPalette.cpuUser,
                    reflectionFromTrailing: false
                )
                historyCard(
                    title: "Memory",
                    value: SystemValueFormatter.percent(monitor.memory.usedFraction),
                    data: monitor.memoryHistory,
                    color: SystemMonitorPalette.memoryCompressed,
                    reflectionFromTrailing: true
                )
            }
        }
    }

    private func historyCard(
        title: String,
        value: String,
        data: [Double],
        color: Color,
        reflectionFromTrailing: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.caption2.weight(.semibold).monospaced())
            }
            SystemHistoryChart(data: data, color: color)
                .frame(height: 48)
        }
        .padding(11)
        .background(
            SystemGlassCard(
                leadingTint: reflectionFromTrailing ? nil : color,
                trailingTint: reflectionFromTrailing ? color : nil
            )
        )
    }

    private var cpuDetails: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionLabel("CPU Details")

            VStack(spacing: 0) {
                detailRow("User", value: SystemValueFormatter.percent(monitor.cpu.user), color: SystemMonitorPalette.cpuUser)
                divider
                detailRow("System", value: SystemValueFormatter.percent(monitor.cpu.system), color: SystemMonitorPalette.cpuSystem)
                divider
                detailRow("Idle", value: SystemValueFormatter.percent(monitor.cpu.idle), color: SystemMonitorPalette.available)
                divider
                detailRow(
                    "Load Average",
                    value: monitor.loadAverages.map { String(format: "%.2f", $0) }.joined(separator: "  ")
                )
                divider
                detailRow("Uptime", value: SystemValueFormatter.uptime(monitor.uptime))
                divider
                statusDetailRow(
                    "Temperature",
                    value: SystemValueFormatter.temperature(monitor.cpuTemperature),
                    valueColor: temperatureColor
                )
            }
            .background(
                SystemGlassCard(leadingTint: SystemMonitorPalette.cpuUser)
            )
        }
    }

    private var memoryDetails: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionLabel("Memory Details")

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text("Used")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(SystemValueFormatter.bytes(monitor.memory.used)) / \(SystemValueFormatter.bytes(monitor.memory.total))")
                        .font(.callout.weight(.semibold).monospaced())
                }
                .font(.callout)

                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        memoryBarPart(
                            color: SystemMonitorPalette.memoryApp,
                            width: geometry.size.width * fraction(monitor.memory.app)
                        )
                        memoryBarPart(
                            color: SystemMonitorPalette.memoryWired,
                            width: geometry.size.width * fraction(monitor.memory.wired)
                        )
                        memoryBarPart(
                            color: SystemMonitorPalette.memoryCompressed,
                            width: geometry.size.width * fraction(monitor.memory.compressed)
                        )
                        memoryBarPart(
                            color: SystemMonitorPalette.available,
                            width: geometry.size.width * fraction(monitor.memory.available)
                        )
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 8)

                memoryLegendRow("App Memory", value: monitor.memory.app, color: SystemMonitorPalette.memoryApp)
                memoryLegendRow("Wired", value: monitor.memory.wired, color: SystemMonitorPalette.memoryWired)
                memoryLegendRow("Compressed", value: monitor.memory.compressed, color: SystemMonitorPalette.memoryCompressed)
                memoryLegendRow("Available", value: monitor.memory.available, color: SystemMonitorPalette.available)
                memoryLegendRow(
                    "Swap Used",
                    value: monitor.memory.swapUsed,
                    color: SystemMonitorPalette.memorySwap
                )

                HStack {
                    Text("Pressure")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(monitor.memory.pressure.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(pressureColor)
                }
            }
            .padding(11)
            .background(
                SystemGlassCard(trailingTint: SystemMonitorPalette.memoryCompressed)
            )
        }
    }

    private func processSection(
        title: String,
        symbol: String,
        processes: [ProcessMetric],
        value: @escaping (ProcessMetric) -> String,
        color: Color,
        reflectionFromTrailing: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionLabel(title)

            if processes.isEmpty {
                Text("Collecting process samples…")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(11)
                    .background(
                        SystemGlassCard(
                            leadingTint: reflectionFromTrailing ? nil : color,
                            trailingTint: reflectionFromTrailing ? color : nil
                        )
                    )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(processes.enumerated()), id: \.element.id) { index, process in
                        ProcessUsageRow(
                            process: process,
                            symbol: symbol,
                            formattedValue: value(process),
                            color: color
                        )
                        if index != processes.count - 1 {
                            divider.padding(.leading, 30)
                        }
                    }
                }
                .background(
                    SystemGlassCard(
                        leadingTint: reflectionFromTrailing ? nil : color,
                        trailingTint: reflectionFromTrailing ? color : nil
                    )
                )
            }
        }
    }

    private func detailRow(_ label: String, value: String, color: Color? = nil) -> some View {
        HStack(spacing: 7) {
            if let color {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold).monospaced())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
    }

    private func statusDetailRow(_ label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold).monospaced())
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
    }

    private func memoryLegendRow(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(SystemValueFormatter.bytes(value))
                .font(.caption.weight(.semibold).monospaced())
        }
    }

    private func memoryBarPart(color: Color, width: CGFloat) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: max(width, 0))
    }

    private func fraction(_ value: Double) -> CGFloat {
        guard monitor.memory.total > 0 else { return 0 }
        return CGFloat(min(max(value / monitor.memory.total, 0), 1))
    }

    private var pressureColor: Color {
        switch monitor.memory.pressure {
        case .normal: return SystemMonitorPalette.statusNormal
        case .warning: return SystemMonitorPalette.statusWarning
        case .critical: return SystemMonitorPalette.destructive
        }
    }

    private var temperatureColor: Color {
        guard let temperature = monitor.cpuTemperature else { return .secondary }
        if temperature >= 90 { return SystemMonitorPalette.destructive }
        if temperature >= 70 { return SystemMonitorPalette.statusWarning }
        return SystemMonitorPalette.statusNormal
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(height: 0.5)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .kerning(0.4)
    }

    private var cpuSegments: [UsageSegment] {
        [
            UsageSegment(id: "user", fraction: monitor.cpu.user, color: SystemMonitorPalette.cpuUser),
            UsageSegment(id: "system", fraction: monitor.cpu.system, color: SystemMonitorPalette.cpuSystem),
            UsageSegment(id: "idle", fraction: monitor.cpu.idle, color: SystemMonitorPalette.available),
        ]
    }

    private var memorySegments: [UsageSegment] {
        let total = max(monitor.memory.total, 1)
        return [
            UsageSegment(id: "app", fraction: monitor.memory.app / total, color: SystemMonitorPalette.memoryApp),
            UsageSegment(id: "wired", fraction: monitor.memory.wired / total, color: SystemMonitorPalette.memoryWired),
            UsageSegment(id: "compressed", fraction: monitor.memory.compressed / total, color: SystemMonitorPalette.memoryCompressed),
            UsageSegment(id: "available", fraction: monitor.memory.available / total, color: SystemMonitorPalette.available),
        ]
    }

    private var panelBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
            LinearGradient(
                colors: [
                    SystemMonitorPalette.cpuUser.opacity(0.07),
                    Color.clear,
                    SystemMonitorPalette.memoryCompressed.opacity(0.05),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct ProcessUsageRow: View {
    let process: ProcessMetric
    let symbol: String
    let formattedValue: String
    let color: Color

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 14)

            Text(process.name)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)

            if hovering {
                Text(verbatim: "PID \(process.pid)")
                    .font(.caption.weight(.semibold).monospaced())
                    .foregroundStyle(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.12))
                    )
            } else {
                Text(formattedValue)
                    .font(.caption.weight(.semibold).monospaced())
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .help("PID: \(process.pid)")
    }
}
