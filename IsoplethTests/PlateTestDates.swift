import Foundation

enum PlateTestDates {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 1
        return calendar
    }()

    static let year = 2026

    static func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 15) -> Date {
        let parts = DateComponents(year: year, month: month, day: day, hour: hour)
        guard let date = calendar.date(from: parts) else {
            preconditionFailure("test date components must be valid")
        }
        return date
    }
}
