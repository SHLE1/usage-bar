import Foundation

// MARK: - HTTP Response Validation

extension HTTPURLResponse {
    /// Whether the status code indicates success (2xx).
    var isSuccess: Bool { (200...299).contains(statusCode) }

    /// Whether the status code indicates an authentication error (401 or 403).
    var isAuthError: Bool { statusCode == 401 || statusCode == 403 }

    /// Whether the status code indicates rate limiting (429).
    var isRateLimited: Bool { statusCode == 429 }
}

// MARK: - Shared DateFormatters

/// Thread-safe cached DateFormatter instances to avoid repeated allocation.
enum SharedDateFormatters {
    /// "MMM d, yyyy" with UTC timezone and en_US_POSIX locale.
    static let monthDayYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    /// "MMM d" with UTC timezone and en_US_POSIX locale.
    static let monthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    /// "yyyy-MM-dd HH:mm:ss" with UTC timezone (used by Z.AI API).
    static let utcDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
}
