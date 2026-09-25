import Foundation

/// Role: YearPlate. Set is the only MoodEntry write. Upserts one startOfDay key.
enum PlateCommit {
    static func applying(
        toneIndex: Int,
        on date: Date,
        year: Int,
        existing: [Int: MoodEntry],
        well: [Tone],
        calendar: Calendar,
        now: Date
    ) throws -> [Int: MoodEntry] {
        guard well.count == ToneWell.toneCount else { throw PlateError.invalidWell }
        guard (0 ..< ToneWell.toneCount).contains(toneIndex) else { throw PlateError.invalidTone }
        let start = PlateCalendar.startOfDay(date, calendar: calendar)
        guard PlateCalendar.year(of: start, calendar: calendar) == year else {
            throw PlateError.dayOutsideYear
        }
        guard start <= PlateCalendar.startOfDay(now, calendar: calendar) else {
            throw PlateError.dayInFuture
        }
        let key = PlateCalendar.dayKey(start, calendar: calendar)
        var next = existing
        next[key] = MoodEntry(dayKey: key, toneIndex: toneIndex)
        return next
    }

    static func canSet(on date: Date, year: Int, calendar: Calendar, now: Date) -> Bool {
        let start = PlateCalendar.startOfDay(date, calendar: calendar)
        guard PlateCalendar.year(of: start, calendar: calendar) == year else { return false }
        return start <= PlateCalendar.startOfDay(now, calendar: calendar)
    }
}
