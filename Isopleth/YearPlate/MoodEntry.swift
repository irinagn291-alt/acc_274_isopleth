import Foundation

/// Role: YearPlate. One MoodEntry per local startOfDay, keyed as Int YYYYMMDD.
struct MoodEntry: Hashable, Sendable, Codable, Identifiable, Equatable {
    var dayKey: Int
    var toneIndex: Int

    var id: Int { dayKey }
}

/// Role: YearPlate. Failures of setTone and well rewrite. Not a 1-5 score.
enum PlateError: Error, Equatable, Sendable {
    case invalidTone
    case invalidWell
    case dayOutsideYear
    case dayInFuture
}

/// Role: YearPlate. Recoverable load. Never crash on a corrupt store.
enum PlateWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}
