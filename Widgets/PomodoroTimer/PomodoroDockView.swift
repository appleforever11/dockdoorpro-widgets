import DockDoorWidgetSDK
import SwiftUI

struct PomodoroDockView: View {
    let size: CGSize
    let isVertical: Bool
    let widgetId: String

    var model: PomodoroTimerModel
    @Environment(\.colorScheme) private var colorScheme

    private var dim: CGFloat { min(size.width, size.height) }

    private var slotSpan: WidgetSlotSpan {
        WidgetSlotSpan.detect(size: size, isVertical: isVertical)
    }

    private var palette: PomodoroPalette {
        PomodoroTheme.current(widgetId: widgetId).palette(for: colorScheme)
    }

    private var phaseColor: Color {
        palette.phaseColor(model.phase)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            dockContent(at: context.date)
                .onChange(of: context.date) { _, date in
                    model.synchronize(at: date)
                }
        }
        .onAppear {
            model.synchronize(at: Date())
        }
    }

    @ViewBuilder
    private func dockContent(at date: Date) -> some View {
        Group {
            switch slotSpan {
            case .compact:
                compactLayout(at: date)
            case .extended:
                extendedLayout(at: date)
            case .triple:
                tripleLayout(at: date)
            }
        }
        .padding(dim * WidgetMetrics.spacingScale)
        .animation(
            .easeInOut(duration: 0.28),
            value: model.remainingFraction(at: date)
        )
        .animation(.spring(response: 0.34, dampingFraction: 0.76), value: model.phase)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text(verbatim:
                "\(model.phase.title), \(model.displayTime(at: date)), \(model.statusText)"
            )
        )
    }

    private func compactLayout(at date: Date) -> some View {
        countdownRing(
            size: dim * WidgetMetrics.contentScale,
            compact: true,
            at: date
        )
            .scaleEffect(model.completionPulse.isMultiple(of: 2) ? 1 : 1.035)
            .animation(
                .spring(response: 0.32, dampingFraction: 0.62),
                value: model.completionPulse
            )
    }

    private func extendedLayout(at date: Date) -> some View {
        Group {
            if isVertical {
                VStack(spacing: dim * WidgetMetrics.spacingScale) {
                    countdownRing(
                        size: dim * 0.82,
                        compact: false,
                        at: date
                    )
                    statusSummary(alignment: .center, compact: true, at: date)
                }
            } else {
                HStack(spacing: dim * WidgetMetrics.spacingScale) {
                    countdownRing(
                        size: dim * 0.82,
                        compact: false,
                        at: date
                    )
                    statusSummary(alignment: .leading, compact: false, at: date)
                        .layoutPriority(1)
                }
            }
        }
    }

    private func tripleLayout(at date: Date) -> some View {
        Group {
            if isVertical {
                VStack(spacing: dim * WidgetMetrics.spacingScale) {
                    countdownRing(
                        size: dim * 0.82,
                        compact: false,
                        at: date
                    )
                    statusSummary(alignment: .center, compact: false, at: date)
                    dailyGoalView(horizontal: false)
                }
            } else {
                HStack(spacing: dim * WidgetMetrics.spacingScale) {
                    countdownRing(
                        size: dim * 0.82,
                        compact: false,
                        at: date
                    )
                    statusSummary(alignment: .leading, compact: false, at: date)
                        .frame(minWidth: dim * 0.70, alignment: .leading)
                        .layoutPriority(1)
                    dailyGoalView(horizontal: true)
                        .frame(width: dim * 1.16)
                }
            }
        }
    }

    private func countdownRing(
        size ringSize: CGFloat,
        compact: Bool,
        at date: Date
    ) -> some View {
        let lineWidth = compact
            ? ringSize * 0.105
            : max(ringSize * 0.10, 3)

        return ZStack {
            Circle()
                .stroke(phaseColor.opacity(0.14), lineWidth: lineWidth)

            Circle()
                .trim(
                    from: 0,
                    to: max(0.001, model.remainingFraction(at: date))
                )
                .stroke(
                    AngularGradient(
                        colors: [phaseColor, palette.secondary, phaseColor],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: phaseColor.opacity(0.22), radius: ringSize * 0.045)

            if compact {
                VStack(spacing: -1) {
                    Text(verbatim: model.compactValue(at: date))
                        .font(.system(
                            size: ringSize * 0.30,
                            weight: .bold,
                            design: .rounded
                        ).monospacedDigit())
                        .minimumScaleFactor(0.62)
                    Text(verbatim: model.compactUnit(at: date))
                        .font(.system(
                            size: max(7.5, ringSize * 0.13),
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundStyle(.secondary)
                        .kerning(0.2)
                }
            } else {
                Image(systemName: model.phase.symbol)
                    .font(.system(
                        size: ringSize * WidgetMetrics.sfSymbolScale * 0.45,
                        weight: .semibold
                    ))
                    .foregroundStyle(phaseColor)
            }
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(statusColor)
                .frame(width: ringSize * 0.13, height: ringSize * 0.13)
                .overlay {
                    Circle()
                        .stroke(Color.primary.opacity(0.16), lineWidth: 0.6)
                }
                .shadow(color: statusColor.opacity(0.28), radius: 2)
                .offset(x: ringSize * 0.015, y: -ringSize * 0.015)
        }
        .frame(width: ringSize, height: ringSize)
    }

    private func statusSummary(
        alignment: HorizontalAlignment,
        compact: Bool,
        at date: Date
    ) -> some View {
        VStack(alignment: alignment, spacing: compact ? 0 : 1) {
            Text(verbatim: model.phase.compactTitle)
                .font(.system(
                    size: dim * (compact ? 0.105 : 0.12),
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(phaseColor)
                .lineLimit(1)

            Text(verbatim: model.displayTime(at: date))
                .font(.system(
                    size: dim * (compact ? 0.16 : 0.20),
                    weight: .bold,
                    design: .rounded
                ).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.62)

            if !compact {
                HStack(spacing: 3) {
                    Image(systemName: model.isRunning ? "play.fill" : (model.isPaused ? "pause.fill" : "circle"))
                        .font(.system(
                            size: max(
                                7,
                                dim * WidgetMetrics.sfSymbolScale * 0.16
                            ),
                            weight: .bold
                        ))
                    Text(verbatim: dockStatusText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(.system(
                    size: max(8, dim * 0.11),
                    weight: .semibold,
                    design: .rounded
                ))
                .foregroundStyle(.secondary)
            }
        }
    }

    private func dailyGoalView(horizontal: Bool) -> some View {
        VStack(
            alignment: horizontal ? .leading : .center,
            spacing: dim * WidgetMetrics.spacingScale * 0.45
        ) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(
                        size: dim * WidgetMetrics.sfSymbolScale * (horizontal ? 0.27 : 0.18),
                        weight: .semibold
                    ))
                    .foregroundStyle(palette.secondary)
                Text(verbatim: "\(model.completedToday)/\(model.dailyGoal)")
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            .font(.system(
                size: dim * (horizontal ? 0.16 : 0.105),
                weight: .semibold
            ))

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(phaseColor.opacity(0.13))
                    Capsule()
                        .fill(palette.gradient)
                        .frame(width: proxy.size.width * model.dailyProgress)
                }
            }
            .frame(height: max(3, dim * (horizontal ? 0.07 : 0.045)))
        }
    }

    private var dockStatusText: String {
        model.isRunning ? "Running" : model.statusText
    }

    private var statusColor: Color {
        switch model.runState {
        case .running:
            return colorScheme == .dark
                ? Color(red: 0.30, green: 0.66, blue: 0.42)
                : .green
        case .paused:
            return colorScheme == .dark
                ? Color(red: 0.78, green: 0.50, blue: 0.28)
                : .orange
        case .idle: return Color.secondary.opacity(0.7)
        }
    }
}
