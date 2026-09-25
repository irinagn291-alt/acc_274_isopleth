import Foundation

/// Role: Ridge. Same-tone cells that share a grid edge, with no cycle in the four-neighbor graph.
struct Ridge: Hashable, Sendable, Identifiable, Equatable {
    var dayKeys: [Int]
    var toneIndex: Int

    var id: Int { dayKeys.min() ?? 0 }
}
