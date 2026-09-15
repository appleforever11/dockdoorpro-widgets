import Foundation

enum CodexUsagePercent {
    /// `usage.json` stores percentages as whole numbers, so `1` means 1% and
    /// `100` means 100%. Keep accepting values below 1 as normalized fractions
    /// for callers that provide the alternate 0...1 representation.
    static func fraction(fromPercent value: Double) -> Double {
        let fraction = value >= 1 ? value / 100 : value
        return min(max(fraction, 0), 1)
    }
}
