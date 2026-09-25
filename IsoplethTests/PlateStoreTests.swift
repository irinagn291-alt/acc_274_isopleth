import XCTest
@testable import Isopleth

final class PlateStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var directory: URL!
    private let calendar = PlateTestDates.calendar
    private let year = PlateTestDates.year

    override func setUpWithError() throws {
        suiteName = "ipl.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        defaults = nil
        suiteName = nil
        directory = nil
    }

    func test_roundTrip_reloadPreservesMoodEntry() async throws {
        let store = makeStore()
        let today = PlateTestDates.day(year, 6, 10)
        let key = PlateCalendar.dayKey(today, calendar: calendar)
        var document = PlateDocument.empty(year: year)
        document.entries = [MoodEntry(dayKey: key, toneIndex: 3)]
        try await store.save(document)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        let restored = try XCTUnwrap(loaded.document)
        XCTAssertEqual(restored.year, year)
        XCTAssertEqual(restored.entries.count, 1)
        XCTAssertEqual(restored.entries.first?.toneIndex, 3)
        XCTAssertEqual(restored.entries.first?.dayKey, key)
        XCTAssertEqual(restored.schemaVersion, 1)
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        var document = PlateDocument.empty(year: year)
        document.onboardingComplete = true
        try await store.save(document)
        if let good = defaults.data(forKey: PlateKey.store) {
            defaults.set(good, forKey: PlateKey.backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: PlateKey.store)
        try Data("{not-json".utf8).write(to: directory.appendingPathComponent("plate.json"), options: .atomic)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.document?.onboardingComplete, true)
        XCTAssertEqual(loaded.document?.year, year)
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        defaults.set(Data("nope".utf8), forKey: PlateKey.store)
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertNil(loaded.document)
    }

    func test_resetAllData_clearsSnapshot() async throws {
        let store = makeStore()
        try await store.save(PlateDocument.empty(year: year))
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertNil(loaded.document)
        XCTAssertNil(defaults.data(forKey: PlateKey.store))
        XCTAssertNil(defaults.data(forKey: PlateKey.backup))
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let data = try PlateCodec.encode(PlateDocument.empty(year: year))
        let decoded = try PlateCodec.decode(data)
        XCTAssertEqual(decoded.year, year)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.tones.count, 12)

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try PlateCodec.decode(future)) { error in
            XCTAssertEqual(error as? PlateCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try PlateCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? PlateCodec.Failure, .corrupt)
        }
    }

    func test_codecCollapsesDuplicateDays() throws {
        let key = PlateCalendar.dayKey(PlateTestDates.day(year, 6, 10), calendar: calendar)
        var document = PlateDocument.empty(year: year)
        document.entries = [
            MoodEntry(dayKey: key, toneIndex: 1),
            MoodEntry(dayKey: key, toneIndex: 8),
        ]
        let normalized = PlateCodec.normalized(document)
        XCTAssertEqual(normalized.entries.count, 1)
        XCTAssertEqual(normalized.entries.first?.toneIndex, 8)
    }

    func test_formatterUsesNumberFormatter() {
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(PlateFigures.integer(12, locale: locale), "12")
        XCTAssertEqual(PlateFigures.integer(1_200, locale: locale), "1,200")
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedMarksPriorDayOnce() async {
        let store = makeStore()
        let now = PlateTestDates.day(year, 6, 10)
        let first = await store.seedDemoIfNeeded(year: year, now: now, calendar: calendar)
        let second = await store.seedDemoIfNeeded(year: year, now: now, calendar: calendar)
        XCTAssertNil(second)
        let seeded = first
        XCTAssertNotNil(seeded)
        XCTAssertGreaterThanOrEqual(seeded?.entries.count ?? 0, 4)
        XCTAssertEqual(seeded?.onboardingComplete, true)
        XCTAssertTrue(defaults.bool(forKey: PlateKey.demo))
        let todayKey = PlateCalendar.dayKey(now, calendar: calendar)
        XCTAssertNil(seeded?.entryMap[todayKey])
        XCTAssertTrue(PlateCommit.canSet(on: now, year: year, calendar: calendar, now: now))
    }
    #endif

    private func makeStore() -> PlateStore {
        PlateStore(
            directory: directory,
            suiteName: suiteName,
            writeDelayNanoseconds: 0
        )
    }
}
