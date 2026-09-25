import Foundation

/// Role: YearPlate. Quiet streak is consecutive marked days ending today or yesterday.
enum QuietMark {
    static func length(markedKeys: Set<Int>, now: Date, calendar: Calendar) -> Int {
        let today = PlateCalendar.startOfDay(now, calendar: calendar)
        let todayKey = PlateCalendar.dayKey(today, calendar: calendar)
        guard let yesterday = PlateCalendar.shifting(today, byDays: -1, calendar: calendar) else {
            return markedKeys.contains(todayKey) ? 1 : 0
        }
        let yesterdayKey = PlateCalendar.dayKey(yesterday, calendar: calendar)
        let anchor: Date
        if markedKeys.contains(todayKey) {
            anchor = today
        } else if markedKeys.contains(yesterdayKey) {
            anchor = yesterday
        } else {
            return 0
        }
        var count = 0
        var cursor = anchor
        while markedKeys.contains(PlateCalendar.dayKey(cursor, calendar: calendar)) {
            count += 1
            guard let previous = PlateCalendar.shifting(cursor, byDays: -1, calendar: calendar) else {
                break
            }
            cursor = previous
        }
        return count
    }
}
