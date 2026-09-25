import Foundation

/// Role: YearPlate. Day edges are Calendar.startOfDay. Storage key is Int YYYYMMDD.
enum PlateCalendar {
    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func year(of date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.year, from: calendar.startOfDay(for: date))
    }

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return year * 10_000 + month * 100 + day
    }

    static func date(fromDayKey key: Int, calendar: Calendar = .current) -> Date? {
        var parts = DateComponents()
        parts.year = key / 10_000
        parts.month = (key / 100) % 100
        parts.day = key % 100
        guard let date = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: date)
    }

    static func daysInYear(_ year: Int, calendar: Calendar = .current) -> Int {
        var parts = DateComponents()
        parts.year = year
        parts.month = 1
        parts.day = 1
        guard let january = calendar.date(from: parts),
              let range = calendar.range(of: .day, in: .year, for: january)
        else {
            return 365
        }
        return range.count
    }

    static func date(year: Int, month: Int, day: Int, calendar: Calendar = .current) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func shifting(_ date: Date, byDays days: Int, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: date))
    }

    static func startOfWeek(_ date: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: start)
        let delta = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -delta, to: start) ?? start
    }
}
