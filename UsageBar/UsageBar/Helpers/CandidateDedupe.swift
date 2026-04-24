import Foundation

/// Shared helper for deduplicating multi-account provider candidates.
enum CandidateDedupe {
    static func merge<T>(
        _ candidates: [T],
        accountId: (T) -> String?,
        isSameUsage: (T, T) -> Bool,
        priority: (T) -> Int,
        mergeCandidates: ((T, T) -> T)? = nil
    ) -> [T] {
        var results: [T] = []

        for candidate in candidates {
            if let candidateId = accountId(candidate),
               let index = results.firstIndex(where: { accountId($0) == candidateId }) {
                let existing = results[index]
                results[index] = preferredCandidate(
                    incoming: candidate,
                    existing: existing,
                    priority: priority,
                    mergeCandidates: mergeCandidates
                )
                continue
            }

            if let index = results.firstIndex(where: { isSameUsage($0, candidate) }) {
                let existing = results[index]
                results[index] = preferredCandidate(
                    incoming: candidate,
                    existing: existing,
                    priority: priority,
                    mergeCandidates: mergeCandidates
                )
                continue
            }

            results.append(candidate)
        }

        return results
    }

    private static func preferredCandidate<T>(
        incoming: T,
        existing: T,
        priority: (T) -> Int,
        mergeCandidates: ((T, T) -> T)?
    ) -> T {
        let incomingPriority = priority(incoming)
        let existingPriority = priority(existing)

        let preferred: T
        let secondary: T
        if incomingPriority > existingPriority {
            preferred = incoming
            secondary = existing
        } else {
            preferred = existing
            secondary = incoming
        }

        guard let mergeCandidates else {
            return preferred
        }
        return mergeCandidates(preferred, secondary)
    }
}
