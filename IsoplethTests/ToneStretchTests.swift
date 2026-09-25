import XCTest
@testable import Isopleth

final class ToneStretchTests: XCTestCase {
    private let calendar = PlateTestDates.calendar
    private let year = PlateTestDates.year

    func test_gridLoopSplitsIntoTwoCalendarStretches() {
        let entries = mark([
            (PlateTestDates.day(year, 6, 10), 7),
            (PlateTestDates.day(year, 6, 11), 7),
            (PlateTestDates.day(year, 6, 17), 7),
            (PlateTestDates.day(year, 6, 18), 7),
        ])
        let census = ContourUnion.census(entries: entries, year: year, calendar: calendar)
        XCTAssertEqual(census.loops.count, 1)
        XCTAssertEqual(census.loops.first?.dayKeys.count, 4)

        let stretches = ToneStretchUnion.stretches(entries: entries, calendar: calendar)
        XCTAssertEqual(stretches.runs.count, 2)
        XCTAssertTrue(stretches.singles.isEmpty)
        XCTAssertEqual(stretches.runs[0].dayKeys, [20_260_610, 20_260_611])
        XCTAssertEqual(stretches.runs[1].dayKeys, [20_260_617, 20_260_618])
        XCTAssertEqual(stretches.runs[0].dayKeys.count, 2)
        XCTAssertEqual(stretches.runs[1].dayKeys.count, 2)
    }

    func test_weekApartPairsAreTwoRuns() {
        let entries = mark([
            (PlateTestDates.day(year, 8, 29), 7),
            (PlateTestDates.day(year, 8, 30), 7),
            (PlateTestDates.day(year, 9, 5), 7),
            (PlateTestDates.day(year, 9, 6), 7),
        ])
        let stretches = ToneStretchUnion.stretches(entries: entries, calendar: calendar)
        XCTAssertEqual(stretches.runs.count, 2)
        XCTAssertEqual(stretches.runs[0].dayKeys, [20_260_829, 20_260_830])
        XCTAssertEqual(stretches.runs[1].dayKeys, [20_260_905, 20_260_906])
        XCTAssertEqual(stretches.runs[0].toneIndex, 7)
    }

    func test_monthBoundaryStaysOneStretch() {
        let entries = mark([
            (PlateTestDates.day(year, 8, 31), 2),
            (PlateTestDates.day(year, 9, 1), 2),
        ])
        let stretches = ToneStretchUnion.stretches(entries: entries, calendar: calendar)
        XCTAssertEqual(stretches.runs.count, 1)
        XCTAssertEqual(stretches.runs.first?.dayKeys.count, 2)
        XCTAssertTrue(stretches.singles.isEmpty)
    }

    func test_toneChangeSplitsEvenOnNeighborDays() {
        let entries = mark([
            (PlateTestDates.day(year, 6, 10), 2),
            (PlateTestDates.day(year, 6, 11), 4),
        ])
        let stretches = ToneStretchUnion.stretches(entries: entries, calendar: calendar)
        XCTAssertTrue(stretches.runs.isEmpty)
        XCTAssertEqual(stretches.singles.count, 2)
    }

    private func mark(_ pairs: [(Date, Int)]) -> [Int: MoodEntry] {
        var entries: [Int: MoodEntry] = [:]
        for (date, tone) in pairs {
            let key = PlateCalendar.dayKey(date, calendar: calendar)
            entries[key] = MoodEntry(dayKey: key, toneIndex: tone)
        }
        return entries
    }
}
