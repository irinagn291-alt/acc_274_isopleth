import Foundation

/// Role: YearPlate. Simulator-only marks. Device never seeds. Once, behind ipl.demo.v1.
enum PlateSeed {
    static func document(year: Int, now: Date, calendar: Calendar) -> PlateDocument {
        var snapshot = PlateDocument.empty(year: year)
        snapshot.entries = Array(marks(year: year, now: now, calendar: calendar).values)
            .sorted { $0.dayKey < $1.dayKey }
        snapshot.onboardingComplete = true
        return PlateCodec.normalized(snapshot)
    }

    static func marks(year: Int, now: Date, calendar: Calendar) -> [Int: MoodEntry] {
        var entries: [Int: MoodEntry] = [:]
        let today = PlateCalendar.startOfDay(now, calendar: calendar)

        func put(_ date: Date, tone: Int) {
            guard PlateCalendar.year(of: date, calendar: calendar) == year else { return }
            let start = PlateCalendar.startOfDay(date, calendar: calendar)
            guard start < today else { return }
            let key = PlateCalendar.dayKey(start, calendar: calendar)
            entries[key] = MoodEntry(dayKey: key, toneIndex: tone)
        }

        if let yesterday = PlateCalendar.shifting(today, byDays: -1, calendar: calendar),
           let todayCell = PlateLattice.cell(for: today, year: year, calendar: calendar),
           let priorCell = PlateLattice.cell(for: yesterday, year: year, calendar: calendar),
           PlateLattice.shareEdge(todayCell, priorCell)
        {
            put(yesterday, tone: 4)
        } else if let lastWeek = PlateCalendar.shifting(today, byDays: -7, calendar: calendar) {
            put(lastWeek, tone: 4)
        }

        if let a = PlateCalendar.shifting(today, byDays: -21, calendar: calendar),
           let b = PlateCalendar.shifting(today, byDays: -20, calendar: calendar),
           let c = PlateCalendar.shifting(today, byDays: -14, calendar: calendar),
           let d = PlateCalendar.shifting(today, byDays: -13, calendar: calendar)
        {
            put(a, tone: 7)
            put(b, tone: 7)
            put(c, tone: 7)
            put(d, tone: 7)
        }

        if let p = PlateCalendar.shifting(today, byDays: -10, calendar: calendar),
           let q = PlateCalendar.shifting(today, byDays: -9, calendar: calendar),
           let r = PlateCalendar.shifting(today, byDays: -8, calendar: calendar)
        {
            put(p, tone: 2)
            put(q, tone: 2)
            put(r, tone: 2)
        }

        if let lone = PlateCalendar.shifting(today, byDays: -30, calendar: calendar) {
            put(lone, tone: 9)
        }

        return entries
    }
}
