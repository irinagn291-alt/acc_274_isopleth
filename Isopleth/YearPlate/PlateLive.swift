import Foundation

/// Role: YearPlate. Process bootstrap for the single live plate. Not a second store.
enum PlateLive {
    @MainActor
    static func make() -> YearPlate {
        YearPlate(store: PlateStore(directory: directory()))
    }

    static func directory() -> URL {
        let files = FileManager.default
        if let root = try? files.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            return root.appendingPathComponent("Isopleth", isDirectory: true)
        }
        return files.temporaryDirectory.appendingPathComponent("Isopleth", isDirectory: true)
    }
}
