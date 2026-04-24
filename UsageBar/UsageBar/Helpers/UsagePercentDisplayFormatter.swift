import Foundation

enum UsagePercentDisplayFormatter {
    static func string(from percent: Double) -> String {
        let normalized = min(max(percent, 0.0), 999.0)
        if normalized > 0.0, normalized < 1.0 {
            return "1%"
        }
        return String(format: "%.0f%%", normalized)
    }

    static func wholePercent(from percent: Double) -> Int {
        let normalized = min(max(percent, 0.0), 100.0)
        if normalized > 0.0, normalized < 1.0 {
            return 1
        }
        return Int(normalized.rounded())
    }
}
