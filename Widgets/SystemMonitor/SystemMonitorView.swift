import DockDoorWidgetSDK
import SwiftUI

struct SystemMonitorView: View {
    let size: CGSize
    let isVertical: Bool
    let widgetId: String
    var monitor: SystemMetricsMonitor

    private var dim: CGFloat { min(size.width, size.height) }
    private var compactRingSize: CGFloat { dim * WidgetMetrics.contentScale }

    private var showCPU: Bool {
        WidgetDefaults.bool(key: "showCPU", widgetId: widgetId, default: true)
    }

    private var showMemory: Bool {
        WidgetDefaults.bool(key: "showMemory", widgetId: widgetId, default: true)
    }

    private var slotSpan: WidgetSlotSpan {
        WidgetSlotSpan.detect(size: size, isVertical: isVertical)
    }

    private var refreshInterval: TimeInterval {
        switch WidgetDefaults.string(key: "refreshInterval", widgetId: widgetId, default: "1s") {
        case "5s": return 5
        case "2s": return 2
        default: return 1
        }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: refreshInterval)) { context in
            Group {
                switch slotSpan {
                case .compact:
                    compactLayout
                case .extended:
                    extendedLayout
                case .triple:
                    tripleLayout
                }
            }
            .onChange(of: context.date) { _, _ in
                monitor.tick(minimumInterval: refreshInterval * 0.8)
            }
        }
        .onAppear {
            monitor.tick(minimumInterval: 0)
        }
    }

    private var compactLayout: some View {
        Group {
            if showCPU && showMemory {
                ZStack {
                    SegmentedUsageRing(
                        segments: cpuSegments,
                        lineWidth: max(dim * 0.10, 3)
                    )
                    .frame(width: compactRingSize, height: compactRingSize)

                    SegmentedUsageRing(
                        segments: memorySegments,
                        lineWidth: max(dim * 0.075, 2.5)
                    )
                    .frame(
                        width: compactRingSize * 0.52,
                        height: compactRingSize * 0.52
                    )
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("CPU and Memory")
                .accessibilityValue(
                    "CPU \(SystemValueFormatter.percent(monitor.cpu.used)), "
                        + "Memory \(SystemValueFormatter.percent(monitor.memory.usedFraction))"
                )
            } else if showCPU {
                compactSingleRing(
                    title: "CPU",
                    symbolName: "cpu.fill",
                    value: SystemValueFormatter.percent(monitor.cpu.used),
                    segments: cpuSegments
                )
            } else if showMemory {
                compactSingleRing(
                    title: "Memory",
                    symbolName: "memorychip.fill",
                    value: SystemValueFormatter.percent(monitor.memory.usedFraction),
                    segments: memorySegments
                )
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(dim * 0.08)
    }

    private var extendedLayout: some View {
        Group {
            if showCPU && showMemory && isVertical {
                VStack(spacing: dim * 0.10) {
                    cpuRing
                    memoryRing
                }
            } else if showCPU && showMemory {
                HStack(spacing: dim * 0.24) {
                    cpuRing
                    memoryRing
                }
            } else if showCPU {
                cpuRing
            } else if showMemory {
                memoryRing
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, dim * 0.08)
        .padding(
            .horizontal,
            showCPU && showMemory && !isVertical ? dim * 0.04 : dim * 0.08
        )
    }

    private var tripleLayout: some View {
        Group {
            if showCPU && showMemory && isVertical {
                VStack(spacing: dim * 0.12) {
                    tripleCPUMetric()
                    tripleMemoryMetric()
                }
            } else if showCPU && showMemory {
                ViewThatFits(in: .horizontal) {
                    tripleMetricsRow(
                        groupSpacingScale: 0.14,
                        ringScale: 0.82,
                        metricSpacingScale: 0.12,
                        detailFontScale: 0.12,
                        labelFontScale: 0.07
                    )
                    tripleMetricsRow(
                        groupSpacingScale: 0.10,
                        ringScale: 0.80,
                        metricSpacingScale: 0.10,
                        detailFontScale: 0.105,
                        labelFontScale: 0.06
                    )
                    tripleMetricsRow(
                        groupSpacingScale: 0.06,
                        ringScale: 0.76,
                        metricSpacingScale: 0.08,
                        detailFontScale: 0.095,
                        labelFontScale: 0.055
                    )
                }
            } else if showCPU {
                tripleCPUMetric()
            } else if showMemory {
                tripleMemoryMetric()
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(dim * 0.04)
    }

    private func tripleMetricsRow(
        groupSpacingScale: CGFloat,
        ringScale: CGFloat,
        metricSpacingScale: CGFloat,
        detailFontScale: CGFloat,
        labelFontScale: CGFloat
    ) -> some View {
        HStack(spacing: dim * groupSpacingScale) {
            tripleCPUMetric(
                ringScale: ringScale,
                metricSpacingScale: metricSpacingScale,
                detailFontScale: detailFontScale,
                labelFontScale: labelFontScale
            )
            tripleMemoryMetric(
                ringScale: ringScale,
                metricSpacingScale: metricSpacingScale,
                detailFontScale: detailFontScale,
                labelFontScale: labelFontScale
            )
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func tripleCPUMetric(
        ringScale: CGFloat = 0.82,
        metricSpacingScale: CGFloat = 0.12,
        detailFontScale: CGFloat = 0.12,
        labelFontScale: CGFloat = 0.07
    ) -> some View {
        tripleMetric(
            title: "CPU",
            symbolName: "cpu.fill",
            value: SystemValueFormatter.percent(monitor.cpu.used),
            segments: cpuSegments,
            detail: SystemValueFormatter.temperature(monitor.cpuTemperature),
            detailLabel: "Temperature",
            detailColor: cpuTemperatureColor,
            ringScale: ringScale,
            metricSpacingScale: metricSpacingScale,
            detailFontScale: detailFontScale,
            labelFontScale: labelFontScale
        )
    }

    private func tripleMemoryMetric(
        ringScale: CGFloat = 0.82,
        metricSpacingScale: CGFloat = 0.12,
        detailFontScale: CGFloat = 0.12,
        labelFontScale: CGFloat = 0.07
    ) -> some View {
        tripleMetric(
            title: "Memory",
            symbolName: "memorychip.fill",
            value: SystemValueFormatter.percent(monitor.memory.usedFraction),
            segments: memorySegments,
            detail: monitor.memory.pressure.rawValue,
            detailLabel: "Pressure",
            detailColor: memoryPressureColor,
            ringScale: ringScale,
            metricSpacingScale: metricSpacingScale,
            detailFontScale: detailFontScale,
            labelFontScale: labelFontScale
        )
    }

    private func tripleMetric(
        title: String,
        symbolName: String,
        value: String,
        segments: [UsageSegment],
        detail: String,
        detailLabel: String,
        detailColor: Color,
        ringScale: CGFloat,
        metricSpacingScale: CGFloat,
        detailFontScale: CGFloat,
        labelFontScale: CGFloat
    ) -> some View {
        Group {
            if isVertical {
                // A vertical slot is only one column wide, so the detail text
                // sits under the ring instead of beside it.
                VStack(spacing: max(dim * 0.03, 2)) {
                    MetricRingView(
                        title: title,
                        value: value,
                        segments: segments,
                        size: dim * ringScale,
                        symbolName: symbolName,
                        showsTitle: false
                    )
                    Text(detail)
                        .font(.system(
                            size: max(dim * 0.105, 8),
                            weight: .semibold,
                            design: .rounded
                        ))
                        .foregroundStyle(detailColor)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            } else {
                HStack(spacing: dim * metricSpacingScale) {
                    MetricRingView(
                        title: title,
                        value: value,
                        segments: segments,
                        size: dim * ringScale,
                        symbolName: symbolName,
                        showsTitle: false
                    )

                    VStack(alignment: .leading, spacing: max(dim * 0.018, 1)) {
                        Text(detail)
                            .font(.system(
                                size: max(dim * detailFontScale, 8),
                                weight: .semibold,
                                design: .rounded
                            ))
                            .foregroundStyle(detailColor)
                            .monospacedDigit()
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        Text(compactDetailLabel(detailLabel))
                            .font(.system(
                                size: max(dim * labelFontScale, 6),
                                weight: .medium,
                                design: .rounded
                            ))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .layoutPriority(1)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(value), \(detailLabel) \(detail)")
    }

    private func compactDetailLabel(_ label: String) -> String {
        label == "Temperature" ? "TEMP" : label.uppercased()
    }

    private func compactSingleRing(
        title: String,
        symbolName: String,
        value: String,
        segments: [UsageSegment]
    ) -> some View {
        ZStack {
            SegmentedUsageRing(
                segments: segments,
                lineWidth: max(dim * 0.10, 3)
            )
            .frame(width: compactRingSize, height: compactRingSize)

            VStack(spacing: 0) {
                Text(value)
                    .font(.system(size: dim * 0.18, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.primary)
                Image(systemName: symbolName)
                    .font(.system(size: max(dim * 0.15, 8), weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.65)
        }
        .frame(width: compactRingSize, height: compactRingSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private var cpuRing: some View {
        MetricRingView(
            title: "CPU",
            value: SystemValueFormatter.percent(monitor.cpu.used),
            segments: cpuSegments,
            size: dim * 0.82,
            symbolName: "cpu.fill",
            showsTitle: false
        )
    }

    private var memoryRing: some View {
        MetricRingView(
            title: "Memory",
            value: SystemValueFormatter.percent(monitor.memory.usedFraction),
            segments: memorySegments,
            size: dim * 0.82,
            symbolName: "memorychip.fill",
            showsTitle: false
        )
    }

    private var cpuTemperatureColor: Color {
        guard let temperature = monitor.cpuTemperature else { return .secondary }
        if temperature >= 90 { return SystemMonitorPalette.widgetStatusCritical }
        if temperature >= 70 { return SystemMonitorPalette.widgetStatusWarning }
        return SystemMonitorPalette.widgetStatusNormal
    }

    private var memoryPressureColor: Color {
        switch monitor.memory.pressure {
        case .normal: return SystemMonitorPalette.widgetStatusNormal
        case .warning: return SystemMonitorPalette.widgetStatusWarning
        case .critical: return SystemMonitorPalette.widgetStatusCritical
        }
    }

    private var cpuSegments: [UsageSegment] {
        [
            UsageSegment(id: "user", fraction: monitor.cpu.user, color: SystemMonitorPalette.cpuUser),
            UsageSegment(id: "system", fraction: monitor.cpu.system, color: SystemMonitorPalette.widgetCPUSystem),
            UsageSegment(id: "idle", fraction: monitor.cpu.idle, color: SystemMonitorPalette.available),
        ]
    }

    private var memorySegments: [UsageSegment] {
        let total = max(monitor.memory.total, 1)
        return [
            UsageSegment(id: "app", fraction: monitor.memory.app / total, color: SystemMonitorPalette.memoryApp),
            UsageSegment(id: "wired", fraction: monitor.memory.wired / total, color: SystemMonitorPalette.widgetMemoryWired),
            UsageSegment(id: "compressed", fraction: monitor.memory.compressed / total, color: SystemMonitorPalette.widgetMemoryCompressed),
            UsageSegment(id: "available", fraction: monitor.memory.available / total, color: SystemMonitorPalette.available),
        ]
    }
}
