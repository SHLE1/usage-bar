import Foundation

struct GroupedModelUsageWindow {
    let models: [String]
    let usedPercent: Double
    let resetDate: Date?

    var primaryModelForSort: String {
        models.first ?? ""
    }
}

enum ModelUsageGrouper {
    private struct GroupKey: Hashable {
        let remainingPercentBitPattern: UInt64
        let resetEpochMillisecond: Int64?
        // If reset time is missing, do not group models together (stricter and avoids false pooling).
        let modelWhenNoReset: String?
    }

    static func groupedUsageWindows(
        modelBreakdown: [String: Double],
        modelResetTimes: [String: Date]? = nil
    ) -> [GroupedModelUsageWindow] {
        var modelsByKey: [GroupKey: [String]] = [:]
        var groupDetailsByKey: [GroupKey: (remainingPercent: Double, resetDate: Date?)] = [:]

        for (model, remainingPercent) in modelBreakdown {
            let resetDate = modelResetTimes?[model]
            // Group only when quota usage and reset window are truly identical.
            let key = GroupKey(
                remainingPercentBitPattern: remainingPercent.bitPattern,
                resetEpochMillisecond: resetDate.map { Int64($0.timeIntervalSince1970 * 1000.0) },
                modelWhenNoReset: resetDate == nil ? model : nil
            )
            modelsByKey[key, default: []].append(model)
            groupDetailsByKey[key] = (remainingPercent: remainingPercent, resetDate: resetDate)
        }

        return modelsByKey
            .map { key, models in
                let sortedModels = models.sorted {
                    $0.localizedStandardCompare($1) == .orderedAscending
                }
                let detail = groupDetailsByKey[key]
                let remainingPercent = detail?.remainingPercent ?? 100.0
                return GroupedModelUsageWindow(
                    models: sortedModels,
                    usedPercent: max(0.0, 100.0 - remainingPercent),
                    resetDate: detail?.resetDate
                )
            }
            .sorted { lhs, rhs in
                if lhs.usedPercent != rhs.usedPercent {
                    return lhs.usedPercent > rhs.usedPercent
                }
                return lhs.primaryModelForSort.localizedStandardCompare(rhs.primaryModelForSort) == .orderedAscending
            }
    }
}
