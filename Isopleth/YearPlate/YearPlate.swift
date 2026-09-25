import Combine
import Foundation

/// Role: YearPlate. The year document and the single ObservableObject every view observes and never copies.
@MainActor
final class YearPlate: ObservableObject {
    @Published private(set) var year: Int
    @Published private(set) var entries: [Int: MoodEntry]
    @Published private(set) var tones: [Tone]
    @Published private(set) var onboardingComplete: Bool
    @Published private(set) var warning: PlateWarning?

    private let store: any PlatePersisting
    private let calendar: Calendar
    private let now: () -> Date
    private var noteTask: Task<Void, Never>?

    init(
        store: any PlatePersisting,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() },
        year: Int? = nil
    ) {
        self.store = store
        self.calendar = calendar
        self.now = now
        let resolvedYear = year ?? PlateCalendar.year(of: now(), calendar: calendar)
        self.year = resolvedYear
        self.entries = [:]
        self.tones = ToneWell.factory
        self.onboardingComplete = false
        self.warning = nil
    }

    var census: ContourCensus {
        ContourUnion.census(entries: entries, year: year, calendar: calendar)
    }

    var daysInYear: Int {
        PlateCalendar.daysInYear(year, calendar: calendar)
    }

    var canSetToday: Bool {
        PlateCommit.canSet(on: now(), year: year, calendar: calendar, now: now())
    }

    func entry(on date: Date) -> MoodEntry? {
        entries[PlateCalendar.dayKey(date, calendar: calendar)]
    }

    func quietStreak(at date: Date? = nil) -> Int {
        QuietMark.length(markedKeys: Set(entries.keys), now: date ?? now(), calendar: calendar)
    }

    func load() async {
        let loaded = await store.load()
        if let document = loaded.document {
            apply(document, warning: loaded.warning)
        } else {
            apply(PlateDocument.empty(year: year), warning: loaded.warning)
        }
        if let seeded = await store.seedDemoIfNeeded(year: year, now: now(), calendar: calendar) {
            apply(seeded, warning: warning)
        }
    }

    func setTone(_ toneIndex: Int, on date: Date) throws {
        entries = try PlateCommit.applying(
            toneIndex: toneIndex,
            on: date,
            year: year,
            existing: entries,
            well: tones,
            calendar: calendar,
            now: now()
        )
        persistSoon()
    }

    func rewriteTones(_ tones: [Tone]) throws {
        self.tones = try ToneWell.validated(tones)
        persistSoon()
    }

    func renameTone(at index: Int, spokenName: String) throws {
        try rewriteTones(ToneWell.renaming(tones, at: index, spokenName: spokenName))
    }

    func shiftToneInk(at index: Int) throws {
        try rewriteTones(ToneWell.advancingInk(tones, at: index))
    }

    func markOnboardingComplete() {
        onboardingComplete = true
        persistSoon()
    }

    func persistNow() async throws {
        noteTask?.cancel()
        noteTask = nil
        try await store.save(makeDocument())
    }

    func flushForScene() async throws {
        try await persistNow()
        try await store.flush()
    }

    func resetAllData() async throws {
        noteTask?.cancel()
        noteTask = nil
        try await store.resetAllData()
        apply(PlateDocument.empty(year: year), warning: nil)
        try await store.save(makeDocument())
    }

    private func persistSoon() {
        noteTask?.cancel()
        noteTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.store.note(self.makeDocument())
        }
    }

    private func apply(_ document: PlateDocument, warning: PlateWarning?) {
        year = document.year
        entries = document.entryMap
        tones = document.tones
        onboardingComplete = document.onboardingComplete
        self.warning = warning
    }

    private func makeDocument() -> PlateDocument {
        PlateDocument(
            schemaVersion: PlateCodec.currentSchema,
            year: year,
            entries: entries.values.sorted { $0.dayKey < $1.dayKey },
            tones: tones,
            onboardingComplete: onboardingComplete
        )
    }
}
