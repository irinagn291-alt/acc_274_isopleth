import Foundation

/// Role: Ridge. One cell on the week-column year plate. Column is weekday 0...6.
struct PlateCell: Hashable, Sendable, Equatable {
    var row: Int
    var column: Int
}

/// Role: Ridge. Maps a startOfDay onto the week-column plate, including weekday columns.
enum PlateLattice {
    static let weekdayColumns = 7

    static func cell(for date: Date, year: Int, calendar: Calendar) -> PlateCell? {
        let start = calendar.startOfDay(for: date)
        guard PlateCalendar.year(of: start, calendar: calendar) == year else { return nil }
        guard let january = PlateCalendar.date(year: year, month: 1, day: 1, calendar: calendar) else {
            return nil
        }
        let origin = calendar.startOfDay(for: january)
        let days = calendar.dateComponents([.day], from: origin, to: start).day ?? 0
        let weekday = calendar.component(.weekday, from: origin)
        let originColumn = (weekday - calendar.firstWeekday + weekdayColumns) % weekdayColumns
        let index = originColumn + days
        return PlateCell(row: index / weekdayColumns, column: index % weekdayColumns)
    }

    static func cell(forDayKey key: Int, year: Int, calendar: Calendar) -> PlateCell? {
        guard let date = PlateCalendar.date(fromDayKey: key, calendar: calendar) else { return nil }
        return cell(for: date, year: year, calendar: calendar)
    }

    static func neighbors(of cell: PlateCell) -> [PlateCell] {
        var next: [PlateCell] = [
            PlateCell(row: cell.row - 1, column: cell.column),
            PlateCell(row: cell.row + 1, column: cell.column),
        ]
        if cell.column > 0 {
            next.append(PlateCell(row: cell.row, column: cell.column - 1))
        }
        if cell.column < weekdayColumns - 1 {
            next.append(PlateCell(row: cell.row, column: cell.column + 1))
        }
        return next
    }

    static func shareEdge(_ a: PlateCell, _ b: PlateCell) -> Bool {
        neighbors(of: a).contains(b)
    }
}
