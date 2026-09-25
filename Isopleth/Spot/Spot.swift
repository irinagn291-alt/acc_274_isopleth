import Foundation

/// Role: Spot. A lone marked cell. No same-tone grid-edge neighbor.
struct Spot: Hashable, Sendable, Identifiable, Equatable {
    var dayKey: Int
    var toneIndex: Int

    var id: Int { dayKey }
}
