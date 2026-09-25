import XCTest
@testable import Isopleth

/// Family year_mood_canvas: one MoodEntry per startOfDay, quiet streak, 12 tones.
final class FamilyInvariantTests: XCTestCase {
    private let calendar = PlateTestDates.calendar
    private let well = ToneWell.factory
    private let year = PlateTestDates.year

    func test_oneMoodEntryPerStartOfDay() throws {
        let morning = PlateTestDates.day(year, 6, 10, hour: 8)
        let evening = PlateTestDates.day(year, 6, 10, hour: 21)
        XCTAssertEqual(calendar.startOfDay(for: morning), calendar.startOfDay(for: evening))

        var existing: [Int: MoodEntry] = [:]
        existing = try PlateCommit.applying(
            toneIndex: 2,
            on: morning,
            year: year,
            existing: existing,
            well: well,
            calendar: calendar,
            now: evening
        )
        XCTAssertEqual(existing.count, 1)

        existing = try PlateCommit.applying(
            toneIndex: 7,
            on: evening,
            year: year,
            existing: existing,
            well: well,
            calendar: calendar,
            now: evening
        )
        XCTAssertEqual(existing.count, 1)
        let key = PlateCalendar.dayKey(morning, calendar: calendar)
        XCTAssertEqual(existing[key]?.toneIndex, 7)
        XCTAssertEqual(existing[key]?.dayKey, key)
    }

    func test_quietStreakEndsTodayOrYesterday_gapRestarts() {
        let today = PlateTestDates.day(year, 6, 10)
        func keys(_ offsets: Int...) -> Set<Int> {
            Set(offsets.compactMap { offset in
                guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                    return nil
                }
                return PlateCalendar.dayKey(date, calendar: calendar)
            })
        }

        XCTAssertEqual(QuietMark.length(markedKeys: keys(0, 1, 2), now: today, calendar: calendar), 3)
        XCTAssertEqual(QuietMark.length(markedKeys: keys(1, 2, 3), now: today, calendar: calendar), 3)
        XCTAssertEqual(QuietMark.length(markedKeys: keys(0, 2, 3), now: today, calendar: calendar), 1)
        XCTAssertEqual(QuietMark.length(markedKeys: keys(2, 3, 4), now: today, calendar: calendar), 0)
        XCTAssertEqual(QuietMark.length(markedKeys: [], now: today, calendar: calendar), 0)
    }

    func test_twelveTones_noScores() {
        XCTAssertEqual(ToneWell.toneCount, 12)
        XCTAssertEqual(ToneWell.factory.count, 12)
        XCTAssertEqual(Set(ToneWell.factory.map(\.spokenName)).count, 12)
        XCTAssertThrowsError(try ToneWell.validated(Array(ToneWell.factory.dropLast()))) { error in
            XCTAssertEqual(error as? PlateError, .invalidWell)
        }
        XCTAssertThrowsError(
            try PlateCommit.applying(
                toneIndex: 12,
                on: PlateTestDates.day(year, 6, 10),
                year: year,
                existing: [:],
                well: well,
                calendar: calendar,
                now: PlateTestDates.day(year, 6, 10)
            )
        ) { error in
            XCTAssertEqual(error as? PlateError, .invalidTone)
        }
        XCTAssertThrowsError(
            try PlateCommit.applying(
                toneIndex: -1,
                on: PlateTestDates.day(year, 6, 10),
                year: year,
                existing: [:],
                well: well,
                calendar: calendar,
                now: PlateTestDates.day(year, 6, 10)
            )
        ) { error in
            XCTAssertEqual(error as? PlateError, .invalidTone)
        }
    }

    func test_setToneEmptyPopulatedInvalid() throws {
        let today = PlateTestDates.day(year, 6, 10)
        var existing: [Int: MoodEntry] = [:]
        XCTAssertTrue(existing.isEmpty)
        XCTAssertTrue(PlateCommit.canSet(on: today, year: year, calendar: calendar, now: today))

        existing = try PlateCommit.applying(
            toneIndex: 4,
            on: today,
            year: year,
            existing: existing,
            well: well,
            calendar: calendar,
            now: today
        )
        XCTAssertEqual(existing.count, 1)
        XCTAssertEqual(existing.values.first?.toneIndex, 4)

        XCTAssertThrowsError(
            try PlateCommit.applying(
                toneIndex: 4,
                on: PlateTestDates.day(2025, 6, 10),
                year: year,
                existing: existing,
                well: well,
                calendar: calendar,
                now: today
            )
        ) { error in
            XCTAssertEqual(error as? PlateError, .dayOutsideYear)
        }

        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: today))
        XCTAssertThrowsError(
            try PlateCommit.applying(
                toneIndex: 4,
                on: tomorrow,
                year: year,
                existing: existing,
                well: well,
                calendar: calendar,
                now: today
            )
        ) { error in
            XCTAssertEqual(error as? PlateError, .dayInFuture)
        }
        XCTAssertFalse(PlateCommit.canSet(on: tomorrow, year: year, calendar: calendar, now: today))
    }

    func test_factoryTonesReadAgainstPlateBackground() {
        func linear(_ channel: Double) -> Double {
            if channel <= 0.04045 {
                return channel / 12.92
            }
            return pow((channel + 0.055) / 1.055, 2.4)
        }
        func luminance(_ red: Double, _ green: Double, _ blue: Double) -> Double {
            0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        }
        let background = luminance(27.0 / 255.0, 40.0 / 255.0, 44.0 / 255.0)
        for tone in ToneWell.factory {
            let mark = luminance(tone.red, tone.green, tone.blue)
            let lighter = max(mark, background)
            let darker = min(mark, background)
            let ratio = (lighter + 0.05) / (darker + 0.05)
            XCTAssertGreaterThanOrEqual(ratio, 4.3, tone.spokenName)
        }
    }

    func test_settingsRewritesNameAndInk_keepsTwelve() throws {
        let renamed = try ToneWell.renaming(well, at: 4, spokenName: "Ledger")
        XCTAssertEqual(renamed.count, 12)
        XCTAssertEqual(renamed[4].spokenName, "Ledger")
        XCTAssertEqual(renamed[4].red, well[4].red)

        XCTAssertThrowsError(try ToneWell.renaming(well, at: 4, spokenName: "Still")) { error in
            XCTAssertEqual(error as? PlateError, .invalidWell)
        }
        XCTAssertThrowsError(try ToneWell.renaming(well, at: 4, spokenName: "  ")) { error in
            XCTAssertEqual(error as? PlateError, .invalidWell)
        }
        XCTAssertThrowsError(try ToneWell.renaming(well, at: 12, spokenName: "Ledger")) { error in
            XCTAssertEqual(error as? PlateError, .invalidWell)
        }

        XCTAssertEqual(ToneWell.inkSpokenName(well[0]), "Cobalt")
        XCTAssertEqual(ToneWell.inkSpokenName(well[7]), "Silver")

        let shifted = try ToneWell.advancingInk(well, at: 4)
        XCTAssertEqual(shifted.count, 12)
        XCTAssertEqual(shifted[4].spokenName, well[4].spokenName)
        XCTAssertNotEqual(shifted[4].red, well[4].red)
        XCTAssertEqual(shifted[4].red, well[5].red)
        XCTAssertEqual(ToneWell.inkSpokenName(shifted[4]), ToneWell.inkSpokenName(well[5]))

        var cursor = well
        for _ in 0 ..< ToneWell.toneCount {
            cursor = try ToneWell.advancingInk(cursor, at: 4)
        }
        XCTAssertEqual(cursor[4], well[4])
    }
}
