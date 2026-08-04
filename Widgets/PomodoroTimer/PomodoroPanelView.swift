import SwiftUI

struct PomodoroPanelView: View {
    let widgetId: String
    var model: PomodoroTimerModel
    let dismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: PomodoroPalette {
        PomodoroTheme.current(widgetId: widgetId).palette(for: colorScheme)
    }

    private var phaseColor: Color {
        palette.phaseColor(model.phase)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            panelContent(at: context.date)
                .onChange(of: context.date) { _, date in
                    model.synchronize(at: date)
                }
        }
        .onAppear {
            model.synchronize(at: Date())
        }
    }

    private func panelContent(at date: Date) -> some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 14) {
                phaseSelector
                timerCard(at: date)
                controls
                todayCard
                footerHint
            }
            .padding(16)
        }
        .frame(width: 340)
        .background(panelBackground)
        .animation(.spring(response: 0.34, dampingFraction: 0.78), value: model.phase)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(palette.gradient)
                Image(systemName: "timer")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 38, height: 38)
            .shadow(color: phaseColor.opacity(0.22), radius: 6, y: 2)

            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: "Pomodoro Timer")
                    .font(.headline.weight(.bold))
                Text(verbatim: model.statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(palette.secondary)
                Text(verbatim: "\(model.completedToday)/\(model.dailyGoal)")
                    .monospacedDigit()
            }
            .font(.caption.weight(.bold))
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(phaseColor.opacity(0.10), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(phaseColor.opacity(0.16), lineWidth: 0.6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            LinearGradient(
                colors: [Color.primary.opacity(0.055), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 0.5)
        }
    }

    private var phaseSelector: some View {
        HStack(spacing: 6) {
            ForEach(PomodoroPhase.allCases) { phase in
                Button {
                    model.selectPhase(phase)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: phase.symbol)
                            .font(.caption.weight(.semibold))
                        Text(verbatim: phase.title)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    PomodoroModeButtonStyle(
                        selected: model.phase == phase,
                        accent: palette.phaseColor(phase)
                    )
                )
                .accessibilityHint(
                    Text(verbatim: "Switch and reset to this phase")
                )
            }
        }
    }

    private func timerCard(at date: Date) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(phaseColor.opacity(0.12), lineWidth: 11)

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
                        style: StrokeStyle(lineWidth: 11, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: phaseColor.opacity(0.20), radius: 7)

                VStack(spacing: 3) {
                    Image(systemName: model.phase.symbol)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(phaseColor)
                    Text(verbatim: model.displayTime(at: date))
                        .font(.largeTitle.weight(.bold).monospacedDigit())
                        .contentTransition(.numericText())
                    Text(verbatim: model.phase.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.5)
                }
            }
            .frame(width: 154, height: 154)
            .scaleEffect(model.completionPulse.isMultiple(of: 2) ? 1 : 1.025)
            .animation(
                .spring(response: 0.30, dampingFraction: 0.60),
                value: model.completionPulse
            )

            roundProgress

            HStack(spacing: 5) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption2.weight(.bold))
                Text(verbatim: "Up next: \(model.nextPhase.title)")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 17)
        .background(
            LinearGradient(
                colors: [
                    phaseColor.opacity(colorScheme == .dark ? 0.12 : 0.08),
                    palette.secondary.opacity(colorScheme == .dark ? 0.07 : 0.045),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(phaseColor.opacity(0.16), lineWidth: 0.7)
        }
    }

    private var roundProgress: some View {
        HStack(spacing: 7) {
            ForEach(0..<model.sessionsPerRound, id: \.self) { index in
                let completed = model.phase == .longBreak
                    || index < model.cycleFocusCount
                let current = model.phase == .focus
                    && index == min(
                        model.cycleFocusCount,
                        model.sessionsPerRound - 1
                    )

                Circle()
                    .fill(completed ? phaseColor : Color.primary.opacity(0.10))
                    .frame(width: 8, height: 8)
                    .overlay {
                        if current {
                            Circle()
                                .strokeBorder(phaseColor, lineWidth: 1.5)
                                .padding(-3)
                        }
                    }
                    .shadow(
                        color: completed ? phaseColor.opacity(0.24) : .clear,
                        radius: 2
                    )
            }
        }
        .padding(.vertical, 2)
        .accessibilityLabel(
            Text(verbatim:
                "\(model.cycleFocusCount) focus sessions completed this round"
            )
        )
    }

    private var controls: some View {
        HStack(spacing: 9) {
            Button {
                model.reset()
            } label: {
                actionLabel("Reset", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PomodoroActionButtonStyle(accent: phaseColor))

            Button {
                model.toggleTimer(at: Date())
            } label: {
                actionLabel(
                    primaryActionTitle,
                    systemImage: primaryActionSymbol
                )
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(
                PomodoroActionButtonStyle(
                    accent: phaseColor,
                    prominent: true
                )
            )
            .keyboardShortcut(.space, modifiers: [])

            Button {
                model.skip()
            } label: {
                actionLabel("Skip", systemImage: "forward.end.fill")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PomodoroActionButtonStyle(accent: palette.secondary))
        }
    }

    private var todayCard: some View {
        VStack(spacing: 9) {
            HStack {
                Label {
                    Text(verbatim: "Today's Focus")
                } icon: {
                    Image(systemName: "chart.bar.fill")
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)

                Spacer()

                Text(verbatim: "\(model.completedToday) of \(model.dailyGoal) sessions")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(phaseColor.opacity(0.12))

                    Capsule()
                        .fill(palette.gradient)
                        .frame(width: proxy.size.width * model.dailyProgress)
                        .shadow(color: phaseColor.opacity(0.18), radius: 3)
                }
            }
            .frame(height: 7)

            HStack {
                Text(verbatim: todayMotivation)
                Spacer()
                Text(verbatim: "\(Int((model.dailyProgress * 100).rounded()))%")
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            Color.primary.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.6)
        }
    }

    private var footerHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "cursorarrow.click.2")
            Text(verbatim: "Click the Dock widget to start or pause")
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(.tertiary)
    }

    private var primaryActionTitle: String {
        switch model.runState {
        case .running:
            return "Pause"
        case .paused:
            return "Resume"
        case .idle:
            return "Start"
        }
    }

    private var primaryActionSymbol: String {
        model.isRunning ? "pause.fill" : "play.fill"
    }

    private func actionLabel(
        _ title: String,
        systemImage: String
    ) -> some View {
        Label {
            Text(verbatim: title)
        } icon: {
            Image(systemName: systemImage)
        }
    }

    private var todayMotivation: String {
        if model.completedToday >= model.dailyGoal {
            return "Goal complete — nicely done!"
        }
        if model.completedToday == 0 {
            return "Start with one focused session"
        }
        return "Keep the rhythm going"
    }

    private var panelBackground: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            LinearGradient(
                colors: [
                    phaseColor.opacity(colorScheme == .dark ? 0.07 : 0.045),
                    .clear,
                    palette.secondary.opacity(colorScheme == .dark ? 0.045 : 0.025),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct PomodoroModeButtonStyle: ButtonStyle {
    let selected: Bool
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        PomodoroModeButtonBody(
            configuration: configuration,
            selected: selected,
            accent: accent
        )
    }
}

private struct PomodoroModeButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let selected: Bool
    let accent: Color

    @State private var hovered = false

    var body: some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundStyle(selected || hovered ? accent : Color.secondary)
            .padding(.horizontal, 7)
            .frame(height: 30)
            .background(
                accent.opacity(selected ? 0.14 : (hovered ? 0.08 : 0)),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(
                        accent.opacity(selected ? 0.22 : (hovered ? 0.14 : 0)),
                        lineWidth: 0.7
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : (hovered ? 1.015 : 1))
            .animation(.easeOut(duration: 0.14), value: hovered)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
            .onHover { hovered = $0 }
    }
}

private struct PomodoroActionButtonStyle: ButtonStyle {
    let accent: Color
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        PomodoroActionButtonBody(
            configuration: configuration,
            accent: accent,
            prominent: prominent
        )
    }
}

private struct PomodoroActionButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let accent: Color
    let prominent: Bool

    @Environment(\.isEnabled) private var isEnabled
    @State private var hovered = false

    var body: some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(prominent ? Color.white : accent)
            .padding(.horizontal, 8)
            .frame(height: 36)
            .background(
                prominent
                    ? AnyShapeStyle(accent.opacity(configuration.isPressed ? 0.78 : 0.94))
                    : AnyShapeStyle(accent.opacity(hovered ? 0.13 : 0.07)),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        (prominent ? Color.white : accent)
                            .opacity(hovered ? 0.24 : 0.12),
                        lineWidth: 0.7
                    )
            }
            .shadow(
                color: accent.opacity(prominent && hovered ? 0.22 : 0),
                radius: 6,
                y: 2
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (hovered ? 1.025 : 1))
            .opacity(isEnabled ? 1 : 0.42)
            .animation(.easeOut(duration: 0.14), value: hovered)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
            .onHover { hovered = $0 }
    }
}
