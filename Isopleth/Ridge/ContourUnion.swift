import Foundation

/// Role: Ridge. Census of spots, open ridges, and closed loops on one YearPlate.
struct ContourCensus: Equatable, Sendable {
    var spots: [Spot]
    var ridges: [Ridge]
    var loops: [Loop]

    static let empty = ContourCensus(spots: [], ridges: [], loops: [])
}

/// Role: Ridge. Set-then-ridge. Same-tone four-neighbors union. A cycle writes a Loop.
enum ContourUnion {
    static func census(
        entries: [Int: MoodEntry],
        year: Int,
        calendar: Calendar
    ) -> ContourCensus {
        var located: [PlateCell: MoodEntry] = [:]
        located.reserveCapacity(entries.count)
        for (key, entry) in entries {
            guard let cell = PlateLattice.cell(forDayKey: key, year: year, calendar: calendar) else {
                continue
            }
            located[cell] = entry
        }

        var visited: Set<PlateCell> = []
        var spots: [Spot] = []
        var ridges: [Ridge] = []
        var loops: [Loop] = []

        let starts = located.keys.sorted { lhs, rhs in
            if lhs.row != rhs.row { return lhs.row < rhs.row }
            return lhs.column < rhs.column
        }

        for start in starts {
            if visited.contains(start) { continue }
            guard let seed = located[start] else { continue }
            let tone = seed.toneIndex
            var component: [PlateCell] = []
            var queue: [PlateCell] = [start]
            visited.insert(start)
            var head = 0
            while head < queue.count {
                let current = queue[head]
                head += 1
                component.append(current)
                for neighbor in PlateLattice.neighbors(of: current) {
                    guard !visited.contains(neighbor) else { continue }
                    guard let other = located[neighbor], other.toneIndex == tone else { continue }
                    visited.insert(neighbor)
                    queue.append(neighbor)
                }
            }

            let keys = component.compactMap { cell -> Int? in
                located[cell]?.dayKey
            }.sorted()
            guard let first = keys.first else { continue }

            if component.count == 1 {
                spots.append(Spot(dayKey: first, toneIndex: tone))
                continue
            }

            if hasCycle(component: Set(component)) {
                loops.append(Loop(dayKeys: keys, toneIndex: tone))
            } else {
                ridges.append(Ridge(dayKeys: keys, toneIndex: tone))
            }
        }

        spots.sort { $0.dayKey < $1.dayKey }
        ridges.sort { $0.id < $1.id }
        loops.sort { $0.id < $1.id }
        return ContourCensus(spots: spots, ridges: ridges, loops: loops)
    }

    /// Connected undirected grid graph has a cycle when edge count is at least vertex count.
    private static func hasCycle(component: Set<PlateCell>) -> Bool {
        var edges = 0
        for cell in component {
            let right = PlateCell(row: cell.row, column: cell.column + 1)
            let down = PlateCell(row: cell.row + 1, column: cell.column)
            if component.contains(right) { edges += 1 }
            if component.contains(down) { edges += 1 }
        }
        return edges >= component.count
    }
}
