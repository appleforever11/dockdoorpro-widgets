import DockDoorWidgetSDK
import SwiftUI

final class PomodoroTimerPlugin: WidgetPlugin, DockDoorWidgetProvider {
    var id: String { "pomodoro-timer" }
    var name: String { "Pomodoro Timer" }
    var iconSymbol: String { "timer" }
    var widgetDescription: String {
        "A polished focus timer with break cycles, daily goals, and persistent progress."
    }
    var supportedOrientations: [WidgetOrientation] { [.horizontal, .vertical] }

    private lazy var timerModel = PomodoroTimerModel(widgetId: id)

    func settingsSchema() -> [WidgetSetting] {
        return [
            .slider(
                key: "focusMinutes",
                label: "Focus Duration (minutes)",
                range: 15...60,
                step: 5,
                defaultValue: 25
            ),
            .slider(
                key: "shortBreakMinutes",
                label: "Short Break (minutes)",
                range: 3...15,
                step: 1,
                defaultValue: 5
            ),
            .slider(
                key: "longBreakMinutes",
                label: "Long Break (minutes)",
                range: 10...30,
                step: 5,
                defaultValue: 15
            ),
            .picker(
                key: "sessionsPerRound",
                label: "Focus Sessions Before Long Break",
                options: ["2", "3", "4", "5"],
                defaultValue: "4"
            ),
            .slider(
                key: "dailyGoal",
                label: "Daily Focus Goal",
                range: 1...12,
                step: 1,
                defaultValue: 8
            ),
            .toggle(
                key: "autoStartBreaks",
                label: "Auto-start Breaks",
                defaultValue: false
            ),
            .toggle(
                key: "autoStartFocus",
                label: "Auto-start Focus Sessions",
                defaultValue: false
            ),
            .picker(
                key: "alertStrength",
                label: "Completion Alert Strength",
                options: PomodoroAlertStrength.allCases.map(\.rawValue),
                defaultValue: PomodoroAlertStrength.noticeable.rawValue
            ),
            .picker(
                key: "glowDuration",
                label: "Completion Glow Duration",
                options: PomodoroGlowDuration.allCases.map(\.rawValue),
                defaultValue: PomodoroGlowDuration.thirtySeconds.rawValue
            ),
            .picker(
                key: "theme",
                label: "Color Theme",
                options: PomodoroTheme.allCases.map(\.rawValue),
                defaultValue: PomodoroTheme.tomato.rawValue
            ),
        ]
    }

    @MainActor
    func makeBody(size: CGSize, isVertical: Bool) -> AnyView {
        AnyView(
            PomodoroDockView(
                size: size,
                isVertical: isVertical,
                widgetId: id,
                model: timerModel
            )
        )
    }

    @MainActor
    func makePanelBody(dismiss: @escaping () -> Void) -> AnyView? {
        AnyView(
            PomodoroPanelView(
                widgetId: id,
                model: timerModel,
                dismiss: dismiss
            )
        )
    }

    func performTapAction() {
        DispatchQueue.main.async { [weak self] in
            self?.timerModel.toggleTimer(at: Date())
        }
    }
}
