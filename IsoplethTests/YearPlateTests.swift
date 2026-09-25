import XCTest
@testable import Isopleth

final class YearPlateTests: XCTestCase {
    private var suiteName: String!
    private var directory: URL!
    private let calendar = PlateTestDates.calendar
    private let year = PlateTestDates.year
    private let now = PlateTestDates.day(PlateTestDates.year, 6, 10)

    override func setUpWithError() throws {
        suiteName = "ipl.plate.\(UUID().uuidString)"
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let suiteName {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        suiteName = nil
        directory = nil
    }

    @MainActor
    func test_oneYearPlate_setToneIsTheOnlyWrite() async throws {
        let plate = makePlate()
        XCTAssertTrue(plate.entries.isEmpty)
        XCTAssertEqual(plate.census, .empty)
        XCTAssertTrue(plate.canSetToday)

        try plate.setTone(4, on: now)
        XCTAssertEqual(plate.entries.count, 1)
        XCTAssertEqual(plate.census.spots.count, 1)

        try plate.setTone(7, on: now)
        XCTAssertEqual(plate.entries.count, 1)
        XCTAssertEqual(plate.entry(on: now)?.toneIndex, 7)

        let neighbor = PlateTestDates.day(year, 6, 9)
        try plate.setTone(7, on: neighbor)
        XCTAssertEqual(plate.entries.count, 2)
        XCTAssertEqual(plate.census.ridges.count, 1)
        XCTAssertTrue(plate.census.spots.isEmpty)
    }

    @MainActor
    func test_persistNowRoundTripThroughStore() async throws {
        let plate = makePlate()
        try plate.setTone(3, on: now)
        plate.markOnboardingComplete()
        try await plate.persistNow()

        let relaunched = makePlate()
        await relaunched.load()
        XCTAssertEqual(relaunched.entries.count, 1)
        XCTAssertEqual(relaunched.entry(on: now)?.toneIndex, 3)
        XCTAssertTrue(relaunched.onboardingComplete)
    }

    @MainActor
    func test_resetAllDataClearsMarks() async throws {
        let plate = makePlate()
        try plate.setTone(1, on: now)
        try await plate.persistNow()
        try await plate.resetAllData()
        XCTAssertTrue(plate.entries.isEmpty)
        XCTAssertFalse(plate.onboardingComplete)
        XCTAssertEqual(plate.tones.count, 12)
    }

    @MainActor
    func test_renameAndShiftInkGoThroughRewriteTones() throws {
        let plate = makePlate()
        try plate.renameTone(at: 2, spokenName: "Ledger")
        XCTAssertEqual(plate.tones[2].spokenName, "Ledger")
        XCTAssertEqual(plate.tones.count, 12)

        let before = plate.tones[2]
        try plate.shiftToneInk(at: 2)
        XCTAssertEqual(plate.tones[2].spokenName, "Ledger")
        XCTAssertNotEqual(plate.tones[2].red, before.red)
        XCTAssertEqual(plate.tones.count, 12)

        for index in plate.tones.indices {
            let ink = plate.tones[index]
            try plate.shiftToneInk(at: index)
            let shifted = plate.tones[index]
            XCTAssertEqual(shifted.spokenName, ink.spokenName)
            XCTAssertFalse(shifted.red == ink.red && shifted.green == ink.green && shifted.blue == ink.blue)
        }
    }

    @MainActor
    private func makePlate() -> YearPlate {
        let store = PlateStore(
            directory: directory,
            suiteName: suiteName,
            writeDelayNanoseconds: 0
        )
        return YearPlate(store: store, calendar: calendar, now: { self.now }, year: year)
    }
}
