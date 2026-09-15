import Foundation

@main
struct CodexUsagePercentTests {
    static func main() {
        let remainingCases: [(input: Double, expected: Double)] = [
            (0, 0),
            (1, 0.01),
            (92, 0.92),
            (100, 1),
            (0.5, 0.5),
        ]

        for testCase in remainingCases {
            let actual = CodexUsagePercent.fraction(fromPercent: testCase.input)
            precondition(
                abs(actual - testCase.expected) < 0.000001,
                "Expected \(testCase.input) to normalize to \(testCase.expected), got \(actual)"
            )
        }

        let usedOnePercentRemaining = 1 - CodexUsagePercent.fraction(fromPercent: 1)
        precondition(abs(usedOnePercentRemaining - 0.99) < 0.000001)

        print("Codex usage percentage regression tests passed")
    }
}
