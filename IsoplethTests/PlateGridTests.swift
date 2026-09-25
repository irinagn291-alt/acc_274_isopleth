import XCTest
@testable import Isopleth

final class PlateGridTests: XCTestCase {
    private let calendar = PlateTestDates.calendar
    private let year = PlateTestDates.year

    func test_projectionMapsSpotRidgeLoopWithoutStoringAYear() {
        let today = PlateTestDates.day(year, 6, 10)
        let neighbor = PlateTestDates.day(year, 6, 9)
        var entries: [Int: MoodEntry] = [:]
        let todayKey = PlateCalendar.dayKey(today, calendar: calendar)
        let neighborKey = PlateCalendar.dayKey(neighbor, calendar: calendar)
        entries[todayKey] = MoodEntry(dayKey: todayKey, toneIndex: 4)
        entries[neighborKey] = MoodEntry(dayKey: neighborKey, toneIndex: 4)
        let lone = PlateTestDates.day(year, 6, 1)
        let loneKey = PlateCalendar.dayKey(lone, calendar: calendar)
        entries[loneKey] = MoodEntry(dayKey: loneKey, toneIndex: 1)

        let census = ContourUnion.census(entries: entries, year: year, calendar: calendar)
        let plots = PlateGrid.plots(
            year: year,
            entries: entries,
            tones: ToneWell.factory,
            census: census,
            now: today,
            calendar: calendar
        )

        XCTAssertEqual(plots.count, PlateCalendar.daysInYear(year, calendar: calendar))
        XCTAssertEqual(plots.first(where: { $0.dayKey == loneKey })?.kind, .spot)
        XCTAssertEqual(plots.first(where: { $0.dayKey == todayKey })?.kind, .ridge)
        XCTAssertEqual(plots.first(where: { $0.dayKey == neighborKey })?.kind, .ridge)
        XCTAssertEqual(PlateGrid.joins(in: plots).count, 1)
        XCTAssertTrue(plots.contains(where: \.isToday))

        let focused = PlateGrid.focusedPlots(from: plots)
        XCTAssertTrue(focused.contains(where: \.isToday))
        XCTAssertLessThan(focused.count, plots.count)
        XCTAssertTrue(focused.contains(where: { $0.dayKey == loneKey }))
        XCTAssertTrue(focused.contains(where: { $0.dayKey == todayKey }))
        let lanes = PlateGrid.weekLanes(in: focused, calendar: calendar)
        XCTAssertFalse(lanes.isEmpty)
        XCTAssertEqual(lanes.count, PlateGrid.rowCount(in: focused))
    }

    func test_focusedPlotsKeepsTodayWeekWhenEmpty() {
        let today = PlateTestDates.day(year, 9, 20)
        let plots = PlateGrid.plots(
            year: year,
            entries: [:],
            tones: ToneWell.factory,
            census: ContourUnion.census(entries: [:], year: year, calendar: calendar),
            now: today,
            calendar: calendar
        )
        let focused = PlateGrid.focusedPlots(from: plots)
        XCTAssertEqual(PlateGrid.rowCount(in: focused), 1)
        XCTAssertEqual(focused.filter(\.isToday).count, 1)
        let lanes = PlateGrid.weekLanes(in: focused, calendar: calendar)
        XCTAssertEqual(lanes.count, 1)
    }

    func test_kindsComeFromCensusNotAForkedMap() {
        let a = PlateTestDates.day(year, 6, 10)
        let b = PlateTestDates.day(year, 6, 11)
        let c = PlateTestDates.day(year, 6, 17)
        let d = PlateTestDates.day(year, 6, 18)
        var entries: [Int: MoodEntry] = [:]
        for date in [a, b, c, d] {
            let key = PlateCalendar.dayKey(date, calendar: calendar)
            entries[key] = MoodEntry(dayKey: key, toneIndex: 7)
        }
        let census = ContourUnion.census(entries: entries, year: year, calendar: calendar)
        XCTAssertEqual(census.loops.count, 1)
        let kinds = PlateGrid.kinds(from: census)
        XCTAssertEqual(kinds.count, 4)
        XCTAssertTrue(kinds.values.allSatisfy { $0 == .loop })
    }

    func test_legendNamesTheToneInsteadOfALetter() {
        let copy = PlateToneLegend.legendCopy(names: ["Bench", "Fold", "Lift", "Notch"])
        XCTAssertTrue(copy.contains("Each marked day names its tone"))
        XCTAssertTrue(copy.contains("Bench"))
        XCTAssertFalse(copy.contains("A letter names"))
        XCTAssertFalse(copy.contains("B is Bench"))
    }
}
