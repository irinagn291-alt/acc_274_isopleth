import Foundation

/// Role: YearPlate. Contour kind a cell shows. Projection of census, not a stored year.
enum PlateKind: Equatable, Sendable {
    case vacant
    case spot
    case ridge
    case loop
}

/// Role: YearPlate. One cell on the week-column plate, ready to draw. Views do not fork the year.
struct PlatePlot: Equatable, Sendable, Identifiable {
    var dayKey: Int
    var cell: PlateCell
    var toneIndex: Int?
    var kind: PlateKind
    var spokenName: String
    var isToday: Bool
    var isFuture: Bool
    var red: Double
    var green: Double
    var blue: Double

    var id: Int { dayKey }
}

/// Role: YearPlate. Layout of the week-column field. Column is weekday 0...6.
struct PlateLatticeLayout: Equatable, Sendable {
    var origin: CGPoint
    var cellWidth: CGFloat
    var cellHeight: CGFloat
    var columns: Int
    var rows: Int

    func rect(for cell: PlateCell) -> CGRect {
        CGRect(
            x: origin.x + CGFloat(cell.column) * cellWidth,
            y: origin.y + CGFloat(cell.row) * cellHeight,
            width: cellWidth,
            height: cellHeight
        )
    }

    static func make(in size: CGSize, rows: Int) -> PlateLatticeLayout {
        let columns = PlateLattice.weekdayColumns
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        let safeRows = max(rows, 1)
        return PlateLatticeLayout(
            origin: .zero,
            cellWidth: width / CGFloat(columns),
            cellHeight: height / CGFloat(safeRows),
            columns: columns,
            rows: safeRows
        )
    }
}

/// Role: YearPlate. Builds plots from the plate map. Never keeps a second year.
enum PlateGrid {
    static func kinds(from census: ContourCensus) -> [Int: PlateKind] {
        var map: [Int: PlateKind] = [:]
        for spot in census.spots {
            map[spot.dayKey] = .spot
        }
        for ridge in census.ridges {
            for key in ridge.dayKeys {
                map[key] = .ridge
            }
        }
        for loop in census.loops {
            for key in loop.dayKeys {
                map[key] = .loop
            }
        }
        return map
    }

    static func plots(
        year: Int,
        entries: [Int: MoodEntry],
        tones: [Tone],
        census: ContourCensus,
        now: Date,
        calendar: Calendar
    ) -> [PlatePlot] {
        let today = PlateCalendar.startOfDay(now, calendar: calendar)
        let todayKey = PlateCalendar.dayKey(today, calendar: calendar)
        let kindByKey = kinds(from: census)
        let days = PlateCalendar.daysInYear(year, calendar: calendar)
        guard let origin = PlateCalendar.date(year: year, month: 1, day: 1, calendar: calendar) else {
            return []
        }
        let start = calendar.startOfDay(for: origin)
        var plots: [PlatePlot] = []
        plots.reserveCapacity(days)
        for offset in 0 ..< days {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let day = calendar.startOfDay(for: date)
            guard let cell = PlateLattice.cell(for: day, year: year, calendar: calendar) else { continue }
            let key = PlateCalendar.dayKey(day, calendar: calendar)
            let entry = entries[key]
            let toneIndex = entry?.toneIndex
            let tone = toneIndex.flatMap { tones.indices.contains($0) ? tones[$0] : nil }
            plots.append(
                PlatePlot(
                    dayKey: key,
                    cell: cell,
                    toneIndex: toneIndex,
                    kind: kindByKey[key] ?? .vacant,
                    spokenName: tone?.spokenName ?? "Open",
                    isToday: key == todayKey,
                    isFuture: day > today,
                    red: tone?.red ?? 0,
                    green: tone?.green ?? 0,
                    blue: tone?.blue ?? 0
                )
            )
        }
        return plots
    }

    static func rowCount(in plots: [PlatePlot]) -> Int {
        (plots.map(\.cell.row).max() ?? 0) + 1
    }

    static func weekdayTitles(calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return (0 ..< PlateLattice.weekdayColumns).map { index in
            symbols[(start + index) % symbols.count]
        }
    }

    /// Weeks that hold marks plus today. Caps at six so the board stays sized to data.
    static let focusWeeks = 6

    static func focusedPlots(
        from plots: [PlatePlot],
        maxWeeks: Int = focusWeeks
    ) -> [PlatePlot] {
        guard let today = plots.first(where: \.isToday) else { return [] }
        let latestRow = today.cell.row
        let earliestAllowed = max(0, latestRow - (max(maxWeeks, 1) - 1))
        let markedRows = plots.filter { $0.kind != .vacant }.map(\.cell.row)
        let firstRow: Int
        if let earliestMark = markedRows.min() {
            firstRow = min(latestRow, max(earliestMark, earliestAllowed))
        } else {
            firstRow = latestRow
        }
        return plots.compactMap { plot in
            guard plot.cell.row >= firstRow, plot.cell.row <= latestRow else { return nil }
            var next = plot
            next.cell = PlateCell(row: plot.cell.row - firstRow, column: plot.cell.column)
            return next
        }
    }

    static func weekLanes(in plots: [PlatePlot], calendar: Calendar) -> [PlateWeekLane] {
        let grouped = Dictionary(grouping: plots, by: \.cell.row)
        return grouped.keys.sorted().compactMap { row in
            guard let sample = grouped[row]?.min(by: { $0.dayKey < $1.dayKey }),
                  let date = PlateCalendar.date(fromDayKey: sample.dayKey, calendar: calendar)
            else {
                return nil
            }
            return PlateWeekLane(row: row, start: PlateCalendar.startOfWeek(date, calendar: calendar))
        }
    }

    static func joins(in plots: [PlatePlot]) -> [PlateJoin] {
        var byCell: [PlateCell: PlatePlot] = [:]
        byCell.reserveCapacity(plots.count)
        for plot in plots {
            byCell[plot.cell] = plot
        }
        var links: [PlateJoin] = []
        for plot in plots {
            guard plot.kind == .ridge || plot.kind == .loop else { continue }
            let east = PlateCell(row: plot.cell.row, column: plot.cell.column + 1)
            let south = PlateCell(row: plot.cell.row + 1, column: plot.cell.column)
            for other in [east, south] {
                guard let neighbor = byCell[other] else { continue }
                guard neighbor.toneIndex == plot.toneIndex, neighbor.kind == plot.kind else { continue }
                links.append(
                    PlateJoin(
                        from: plot.cell,
                        to: other,
                        red: plot.red,
                        green: plot.green,
                        blue: plot.blue
                    )
                )
            }
        }
        return links
    }
}

/// Role: YearPlate. One week row on the focused board. Label is the week start date.
struct PlateWeekLane: Equatable, Sendable, Identifiable {
    var row: Int
    var start: Date

    var id: Int { row }
}

/// Role: YearPlate. Shared-edge join drawn on the plate. Identity is the two cells.
struct PlateJoin: Equatable, Hashable, Sendable, Identifiable {
    var from: PlateCell
    var to: PlateCell
    var red: Double
    var green: Double
    var blue: Double

    var id: String { "\(from.row).\(from.column)-\(to.row).\(to.column)" }
}
