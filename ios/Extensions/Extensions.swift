import Foundation

extension String {
    /// Parses "12.50" and "12,50": the decimal pad types a comma in many locales.
    var decimalValue: Double? {
        Double(trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }
}

extension Date {
    /// The calendar day in the user's time zone, as YYYY-MM-DD.
    var apiDay: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = .current
        return formatter.string(from: self)
    }
}
