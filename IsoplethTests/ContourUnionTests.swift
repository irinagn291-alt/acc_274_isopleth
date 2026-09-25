import XCTest
@testable import Isopleth

final class ContourUnionTests: XCTestCase {
    private let calendar = PlateTestDates.calendar
    private let year = PlateTestDates.year

    func test_loneCellIsSpot() {
        let today = PlateTestDates.day(year, 6, 10)
        let entries = mark([(today, 3)])
        let census = ContourUnion.census(entries: entries, year: year, calendar: calendar)
        XCTAssertEqual(census.spots.count, 1)
        XCTAssertTrue(census.ridges.isEmpty)
        XCTAssertTrue(census.loops.isEmpty)
        XCTAssertEqual(census.spots.first?.toneIndex, 3)
    }

    func test_sameToneGridEdgeUnionsIntoRidge() {
        let wednesday = PlateTestDates.day(year, 6, 10)
        let tuesday = PlateTestDates.day(year, 6, 9)
        let entries = mark([(tuesday, 4), (wednesday, 4)])
        let census = ContourUnion.census(entries: entries, year: year, calendar: calendar)
        XCTAssertTrue(census.spots.isEmpty)
        XCTAssertEqual(census.ridges.count, 1)
        XCTAssertTrue(census.loops.isEmpty)
        XCTAssertEqual(census.ridges.first?.dayKeys.count, 2)
    }

    func test_weekdayColumnUnionsIntoRidge() {
        let thisWeek = PlateTestDates.day(year, 6, 10)
        let lastWeek = PlateTestDates.day(year, 6, 17)
        let entries = mark([(thisWeek, 5), (lastWeek, 5)])
        let census = ContourUnion.census(entries: entries, year: year, calendar: calendar)
        XCTAssertEqual(census.ridges.count, 1)
        XCTAssertTrue(census.loops.isEmpty)
        XCTAssertTrue(census.spots.isEmpty)
    }

    func test_closedFourNeighborCycleWritesLoop() {
        let entries = mark([
            (PlateTestDates.day(year, 6, 10), 7),
            (PlateTestDates.day(year, 6, 11), 7),
            (PlateTestDates.day(year, 6, 17), 7),
            (PlateTestDates.day(year, 6, 18), 7),
        ])
        let census = ContourUnion.census(entries: entries, year: year, calendar: calendar)
        XCTAssertEqual(census.loops.count, 1)
        XCTAssertTrue(census.ridges.isEmpty)
        XCTAssertTrue(census.spots.isEmpty)
        XCTAssertEqual(census.loops.first?.dayKeys.count, 4)
    }

    func test_diagonalSameToneStaysTwoSpots() {
        let entries = mark([
            (PlateTestDates.day(year, 6, 10), 1),
            (PlateTestDates.day(year, 6, 18), 1),
        ])
        let census = ContourUnion.census(entries: entries, year: year, calendar: calendar)
        XCTAssertEqual(census.spots.count, 2)
        XCTAssertTrue(census.ridges.isEmpty)
        XCTAssertTrue(census.loops.isEmpty)
    }

    func test_differentTonesDoNotUnion() {
        let entries = mark([
            (PlateTestDates.day(year, 6, 9), 1),
            (PlateTestDates.day(year, 6, 10), 2),
        ])
        let census = ContourUnion.census(entries: entries, year: year, calendar: calendar)
        XCTAssertEqual(census.spots.count, 2)
        XCTAssertTrue(census.ridges.isEmpty)
    }

    func test_saturdaySundayDoNotShareAGridEdge() throws {
        let saturday = PlateTestDates.day(year, 6, 13)
        let sunday = PlateTestDates.day(year, 6, 14)
        let a = try XCTUnwrap(PlateLattice.cell(for: saturday, year: year, calendar: calendar))
        let b = try XCTUnwrap(PlateLattice.cell(for: sunday, year: year, calendar: calendar))
        XCTAssertFalse(PlateLattice.shareEdge(a, b))
        let census = ContourUnion.census(
            entries: mark([(saturday, 6), (sunday, 6)]),
            year: year,
            calendar: calendar
        )
        XCTAssertEqual(census.spots.count, 2)
    }

    func test_leapYearHasThreeHundredSixtySixCells() {
        XCTAssertEqual(PlateCalendar.daysInYear(2024, calendar: calendar), 366)
        XCTAssertEqual(PlateCalendar.daysInYear(2026, calendar: calendar), 365)
        let leap = PlateTestDates.day(2024, 2, 29)
        XCTAssertEqual(PlateCalendar.dayKey(leap, calendar: calendar), 20_240_229)
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
