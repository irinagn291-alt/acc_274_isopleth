import SwiftUI
import UIKit

/// Role: YearPlate. Focused week board. Each row is a dated week. Today is a Button.
struct PlateDayBoard: View {
    var plots: [PlatePlot]
    var lanes: [PlateWeekLane]
    var weekdayTitles: [String]
    var canSetToday: Bool
    var committing: Bool
    var bloomGeneration: Int
    var bloomHue: UIColor
    var reduceMotion: Bool
    var onToday: () -> Void
    var onMarkedDay: (PlatePlot) -> Void
    var expandsToFill: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            headerRow
            VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
                ForEach(lanes) { lane in
                    weekLane(lane)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(maxHeight: expandsToFill ? .infinity : nil)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Day by day tone log. Each row is one week. Tap today to mark it.")
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdayTitles.enumerated()), id: \.offset) { _, title in
                Text(title)
                    .font(PlateFont.caption)
                    .foregroundStyle(PlateColor.muted)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
            }
        }
        .frame(minHeight: PlateSpace.n(3))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(weekdayTitles.joined(separator: ", "))
    }

    private func weekLane(_ lane: PlateWeekLane) -> some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            Text(PlateReadout.weekOf(lane.start))
                .font(PlateFont.caption)
                .foregroundStyle(PlateColor.ink)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .top, spacing: 0) {
                ForEach(0 ..< PlateLattice.weekdayColumns, id: \.self) { column in
                    dayCell(plot(row: lane.row, column: column))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .frame(minHeight: cellMinHeight, maxHeight: expandsToFill ? .infinity : cellMinHeight)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(maxHeight: expandsToFill ? .infinity : nil)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(maxHeight: expandsToFill ? .infinity : nil)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Week of \(PlateReadout.weekOf(lane.start))")
    }

    @ViewBuilder
    private func dayCell(_ plot: PlatePlot?) -> some View {
        if let plot {
            if plot.isToday {
                todayCell(plot)
            } else if plot.kind != .vacant {
                markedCell(plot)
            } else {
                openCell(plot)
            }
        } else {
            Color.clear
        }
    }

    private func todayCell(_ plot: PlatePlot) -> some View {
        Button(action: onToday) {
            ZStack {
                cellFace(plot, today: true)
                PlateBloomHost(
                    generation: bloomGeneration,
                    hue: bloomHue,
                    point: CGPoint(x: PlateStroke.hit / 2, y: PlateStroke.hit / 2),
                    reduceMotion: reduceMotion
                )
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, minHeight: cellMinHeight, alignment: .topLeading)
            .frame(maxHeight: expandsToFill ? .infinity : cellMinHeight)
            .contentShape(RoundedRectangle(cornerRadius: PlateRadius.chip, style: .continuous))
        }
        .buttonStyle(PlatePressStyle())
        .disabled(!canSetToday || committing)
        .accessibilityLabel(todayLabel(plot))
        .accessibilityHint("Opens the tone well")
        .accessibilityAddTraits(.isButton)
    }

    private func markedCell(_ plot: PlatePlot) -> some View {
        Button {
            onMarkedDay(plot)
        } label: {
            cellFace(plot, today: false)
                .frame(maxWidth: .infinity, minHeight: cellMinHeight, alignment: .topLeading)
                .frame(maxHeight: expandsToFill ? .infinity : cellMinHeight)
                .contentShape(RoundedRectangle(cornerRadius: PlateRadius.chip, style: .continuous))
        }
        .buttonStyle(PlatePressStyle())
        .accessibilityLabel("\(plot.spokenName), \(dayLabel(plot))")
        .accessibilityHint("Opens the tone runs for this day")
        .accessibilityAddTraits(.isButton)
    }

    private func openCell(_ plot: PlatePlot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dayLabel(plot))
                .font(PlateFont.caption)
                .foregroundStyle(plot.isFuture ? PlateColor.muted.opacity(0.55) : PlateColor.muted)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .padding(PlateSpace.n(1))
        .frame(maxWidth: .infinity, minHeight: cellMinHeight, alignment: .topLeading)
        .frame(maxHeight: expandsToFill ? .infinity : cellMinHeight)
        .accessibilityLabel(plot.isFuture ? "\(dayLabel(plot)), closed" : "\(dayLabel(plot)), open")
        .accessibilityAddTraits(.isStaticText)
    }

    private func cellFace(_ plot: PlatePlot, today: Bool) -> some View {
        let ink = Color(red: plot.red, green: plot.green, blue: plot.blue)
        let marked = plot.kind != .vacant
        return VStack(alignment: .leading, spacing: 0) {
            Text(dayLabel(plot))
                .font(PlateFont.caption)
                .foregroundStyle(PlateColor.ink)
                .monospacedDigit()
                .lineLimit(1)
                .layoutPriority(1)
            if today {
                Text("Today")
                    .font(PlateFont.micro)
                    .foregroundStyle(PlateColor.accent)
                    .lineLimit(1)
            }
            if marked {
                Text(plot.spokenName)
                    .font(PlateFont.micro)
                    .foregroundStyle(PlateColor.ink)
                    .lineLimit(1)
                    .layoutPriority(1)
            } else if today {
                Text("Open")
                    .font(PlateFont.micro)
                    .foregroundStyle(PlateColor.muted)
                    .lineLimit(1)
            }
        }
        .padding(PlateSpace.n(1))
        .frame(maxWidth: .infinity, minHeight: cellMinHeight, alignment: .topLeading)
        .frame(maxHeight: expandsToFill ? .infinity : cellMinHeight)
        .background(today ? PlateColor.surface : PlateColor.surface.opacity(marked ? 1 : 0.45))
        .overlay {
            RoundedRectangle(cornerRadius: PlateRadius.chip, style: .continuous)
                .stroke(today ? PlateColor.accent : ink.opacity(0.7), lineWidth: today ? 2 : PlateStroke.hairline)
        }
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.chip, style: .continuous))
        .clipped()
    }

    private var cellMinHeight: CGFloat {
        PlateStroke.hit + PlateSpace.n(3)
    }

    private func plot(row: Int, column: Int) -> PlatePlot? {
        plots.first { $0.cell.row == row && $0.cell.column == column }
    }

    private func dayLabel(_ plot: PlatePlot) -> String {
        guard let date = PlateCalendar.date(fromDayKey: plot.dayKey) else {
            return PlateReadout.count(plot.dayKey % 100)
        }
        return PlateReadout.monthDay(date)
    }

    private func todayLabel(_ plot: PlatePlot) -> String {
        if plot.kind == .vacant {
            return "Today, \(dayLabel(plot)), open. Set the tone."
        }
        return "Today, \(dayLabel(plot)), \(plot.spokenName)."
    }
}

/// Role: YearPlate. Names every tone currently on the focused board.
struct PlateToneLegend: View {
    var plots: [PlatePlot]

    var body: some View {
        let marks = uniqueMarks
        VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            Text("On this log")
                .font(PlateFont.caption)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(PlateColor.muted)
                .lineLimit(1)
            if marks.isEmpty {
                Text("No tones yet. Today is the outlined cell.")
                    .font(PlateFont.body)
                    .foregroundStyle(PlateColor.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(Self.legendCopy(names: marks.map(\.spokenName)))
                    .font(PlateFont.body)
                    .foregroundStyle(PlateColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var uniqueMarks: [PlatePlot] {
        var seen = Set<String>()
        return plots.filter { $0.kind != .vacant }.filter { plot in
            seen.insert(plot.spokenName).inserted
        }
        .sorted { $0.spokenName < $1.spokenName }
    }

    static func legendCopy(names: [String]) -> String {
        let listed = names.joined(separator: ". ")
        if listed.isEmpty {
            return "Today is outlined. Each marked day names its tone."
        }
        return "Today is outlined. Each marked day names its tone. \(listed)."
    }
}
