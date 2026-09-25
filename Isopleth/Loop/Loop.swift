import Foundation

/// Role: Loop. A ridge whose four-neighbor graph contains a cycle.
struct Loop: Hashable, Sendable, Identifiable, Equatable {
    var dayKeys: [Int]
    var toneIndex: Int

    var id: Int { dayKeys.min() ?? 0 }
}
