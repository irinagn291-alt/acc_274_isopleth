import Foundation

/// Role: YearPlate. Persistence seam. The UI never touches UserDefaults or files.
protocol PlatePersisting: Sendable {
    func load() async -> (document: PlateDocument?, warning: PlateWarning?)
    func note(_ document: PlateDocument) async
    func save(_ document: PlateDocument) async throws
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded(year: Int, now: Date, calendar: Calendar) async -> PlateDocument?
}

/// Role: YearPlate. One Codable YearPlate in UserDefaults under ipl.store.v1, plus an atomic file projection.
actor PlateStore: PlatePersisting {
    private struct Disk {
        var root: URL
        var file: URL { root.appendingPathComponent("plate.json", isDirectory: false) }
        var spare: URL { root.appendingPathComponent("plate.json.backup", isDirectory: false) }
    }

    private let disk: Disk
    private let suiteName: String?
    private let files: FileManager
    private let writeDelayNanoseconds: UInt64
    private var latest: PlateDocument?
    private var writeTask: Task<Void, Never>?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        suiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.disk = Disk(root: directory)
        self.suiteName = suiteName
        self.files = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Isopleth", isDirectory: true)
    }

    func load() async -> (document: PlateDocument?, warning: PlateWarning?) {
        switch recover() {
        case .clean(let document):
            latest = document
            return (document, nil)
        case .spare(let document):
            latest = document
            return (document, .recoveredFromBackup)
        case .blank(let hadPayload):
            latest = nil
            return (nil, hadPayload ? .startedEmpty : nil)
        }
    }

    func note(_ document: PlateDocument) async {
        latest = document
        scheduleFlush()
    }

    func save(_ document: PlateDocument) async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = document
        try persist(document)
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if let latest {
            try persist(latest)
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = nil
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: PlateKey.store)
        defaults.removeObject(forKey: PlateKey.backup)
        if files.fileExists(atPath: disk.root.path) {
            try files.removeItem(at: disk.root)
        }
        try files.createDirectory(at: disk.root, withIntermediateDirectories: true)
    }

    func seedDemoIfNeeded(year: Int, now: Date, calendar: Calendar) async -> PlateDocument? {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        guard defaults.object(forKey: PlateKey.demo) == nil else { return nil }
        if let latest, !latest.entries.isEmpty {
            defaults.set(true, forKey: PlateKey.demo)
            return nil
        }
        let snapshot = PlateSeed.document(year: year, now: now, calendar: calendar)
        latest = snapshot
        do {
            try persist(snapshot)
        } catch {
            lastWriteError = String(describing: error)
        }
        defaults.set(true, forKey: PlateKey.demo)
        return snapshot
        #else
        _ = (year, now, calendar)
        return nil
        #endif
    }

    private enum Recovered {
        case clean(PlateDocument)
        case spare(PlateDocument)
        case blank(Bool)
    }

    private func recover() -> Recovered {
        let defaults = preferenceDefaults()
        if let data = defaults.data(forKey: PlateKey.store), let document = decode(data) {
            return .clean(document)
        }
        if let document = decodeFile(disk.file) {
            return .clean(document)
        }
        if let data = defaults.data(forKey: PlateKey.backup), let document = decode(data) {
            return .spare(document)
        }
        if let document = decodeFile(disk.spare) {
            return .spare(document)
        }
        let hadPayload = defaults.data(forKey: PlateKey.store) != nil
            || files.fileExists(atPath: disk.file.path)
        return .blank(hadPayload)
    }

    private func persist(_ document: PlateDocument) throws {
        let data = try PlateCodec.encode(document)
        let defaults = preferenceDefaults()
        if let previous = defaults.data(forKey: PlateKey.store) {
            defaults.set(previous, forKey: PlateKey.backup)
        }
        defaults.set(data, forKey: PlateKey.store)
        try files.createDirectory(at: disk.root, withIntermediateDirectories: true)
        if files.fileExists(atPath: disk.file.path) {
            if files.fileExists(atPath: disk.spare.path) {
                try files.removeItem(at: disk.spare)
            }
            try files.copyItem(at: disk.file, to: disk.spare)
        }
        try data.write(to: disk.file, options: .atomic)
        lastWriteError = nil
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if let latest {
                try persist(latest)
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func decode(_ data: Data) -> PlateDocument? {
        try? PlateCodec.decode(data)
    }

    private func decodeFile(_ url: URL) -> PlateDocument? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data)
    }

    private func preferenceDefaults() -> UserDefaults {
        if let suiteName {
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }
}
