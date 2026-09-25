import Foundation

/// Role: Ridge. One unbroken stretch of consecutive calendar days on the same tone.
struct ToneStretch: Hashable, Sendable, Identifiable, Equatable {
    var dayKeys: [Int]
    var toneIndex: Int

    var id: String {
        "\(toneIndex)-\(dayKeys.first ?? 0)-\(dayKeys.last ?? 0)"
    }
}

/// Role: Ridge. Split marks into calendar stretches. A gap or a tone change starts a new card.
enum ToneStretchUnion {
    static func stretches(
        entries: [Int: MoodEntry],
        calendar: Calendar
    ) -> (runs: [ToneStretch], singles: [ToneStretch]) {
        let ordered = entries.values.sorted { $0.dayKey < $1.dayKey }
        var buckets: [ToneStretch] = []
        for entry in ordered {
            if var last = buckets.last,
               last.toneIndex == entry.toneIndex,
               follows(last.dayKeys.last, entry.dayKey, calendar: calendar)
            {
                last.dayKeys.append(entry.dayKey)
                buckets[buckets.count - 1] = last
            } else {
                buckets.append(ToneStretch(dayKeys: [entry.dayKey], toneIndex: entry.toneIndex))
            }
        }
        return (
            buckets.filter { $0.dayKeys.count >= 2 },
            buckets.filter { $0.dayKeys.count == 1 }
        )
    }

    private static func follows(_ previous: Int?, _ next: Int, calendar: Calendar) -> Bool {
        guard let previous,
              let date = PlateCalendar.date(fromDayKey: previous, calendar: calendar),
              let following = PlateCalendar.shifting(date, byDays: 1, calendar: calendar)
        else {
            return false
        }
        return PlateCalendar.dayKey(following, calendar: calendar) == next
    }
}
