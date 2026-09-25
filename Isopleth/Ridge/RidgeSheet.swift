import SwiftUI
import UIKit

/// Role: Ridge. Tone-run sheet. Consecutive same-tone days and isolated days. Observes YearPlate.
struct RidgeSheet: View {
    @ObservedObject var plate: YearPlate
    var onSetToday: () -> Void
    var onOpenDay: (Bool) -> Void
    var onRetry: () async -> Void
    var onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var displayPoint: CGFloat = 34

    var body: some View {
        ZStack {
            PlateColor.background.ignoresSafeArea()
            PlateSafeStage(edges: [.bottom, .leading, .trailing]) { _ in
                VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
                    sheetChrome
                    Text("This view counts each unbroken stretch of consecutive days on the same tone, and single isolated days. One card is one stretch. Open a run to go back to those days.")
                        .font(PlateFont.body)
                        .foregroundStyle(PlateColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if let warning = plate.warning, isEmpty {
                        errorState(warning)
                    } else if isEmpty {
                        emptyState
                    } else if usesBoard {
                        censusBoard
                    } else {
                        ScrollView {
                            stackedCensus
                                .padding(.bottom, PlateSpace.n(2))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(.horizontal, PlateSpace.n(2))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PlateColor.background.ignoresSafeArea())
    }

    private var isEmpty: Bool {
        plate.entries.isEmpty
    }

    private var calendarStretches: (runs: [ToneStretch], singles: [ToneStretch]) {
        ToneStretchUnion.stretches(entries: plate.entries, calendar: .current)
    }

    private var usesBoard: Bool {
        (sizeClass == .regular || UIDevice.current.userInterfaceIdiom == .pad)
            && !typeSize.isAccessibilitySize
    }

    private var todayKey: Int {
        PlateCalendar.dayKey(Date(), calendar: .current)
    }

    private var sheetChrome: some View {
        HStack(spacing: PlateSpace.n(1)) {
            Text("Tone runs")
                .font(PlateFont.title)
                .foregroundStyle(PlateColor.ink)
                .lineLimit(1)
            Spacer(minLength: PlateSpace.n(1))
            Button("Done") { onDismiss() }
                .buttonStyle(PlateGhostStyle())
                .accessibilityLabel("Close tone runs")
        }
    }

    private var emptyState: some View {
        PlateVoid(
            image: "ipl_EmptyList",
            headline: "No runs yet.",
            line: "Mark today so a neighbor day can join it.",
            actionTitle: "Set the tone"
        ) {
            onDismiss()
            onSetToday()
        }
    }

    private func errorState(_ warning: PlateWarning) -> some View {
        PlateVoid(
            image: "ipl_EmptyList",
            headline: warningHeadline(warning),
            line: "Reload the year, then count again.",
            actionTitle: "Reload"
        ) {
            Task { await onRetry() }
        }
    }

    private var censusBoard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
                if let hero = heroLine {
                    runCard(hero, hero: true)
                }
                remainingRunsGrid
                markedDaysLane
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.bottom, PlateSpace.n(3))
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(PlateMotion.travel(reduceMotion: reduceMotion), value: plate.census.loops.count)
    }

    private var allLines: [ContourLine] {
        censusGroups.flatMap(\.rows)
    }

    private var heroLine: ContourLine? {
        let groups = censusGroups
        return groups.first(where: { $0.id == "runs" && !$0.rows.isEmpty })?.rows.first
            ?? groups.first(where: { $0.id == "single" && !$0.rows.isEmpty })?.rows.first
    }

    private var remainingLines: [ContourLine] {
        guard let hero = heroLine else { return allLines }
        return allLines.filter { $0.id != hero.id }
    }

    private var remainingRunsGrid: some View {
        let columns = [
            GridItem(.flexible(minimum: PlateStroke.hit), spacing: PlateSpace.n(2), alignment: .top),
            GridItem(.flexible(minimum: PlateStroke.hit), spacing: PlateSpace.n(2), alignment: .top),
        ]
        return Group {
            if remainingLines.isEmpty {
                EmptyView()
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: PlateSpace.n(2)) {
                    ForEach(remainingLines) { row in
                        runCard(row, hero: false)
                    }
                }
            }
        }
    }

    private var markedDaysLane: some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            Text("Marked days")
                .font(PlateFont.caption)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(PlateColor.muted)
                .lineLimit(1)
            Text("Date and tone only. Run lengths live in the cards above.")
                .font(PlateFont.body)
                .foregroundStyle(PlateColor.muted)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(markedDayLines) { row in
                markedDayRow(row)
            }
        }
        .padding(PlateSpace.n(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(PlateColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
        .clipped()
    }

    private func markedDayRow(_ row: ContourLine) -> some View {
        Button {
            onOpenDay(row.includesToday)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: PlateSpace.n(1)) {
                Text(row.detail)
                    .font(PlateFont.body)
                    .foregroundStyle(PlateColor.ink)
                    .lineLimit(1)
                    .layoutPriority(1)
                Spacer(minLength: PlateSpace.n(1))
                Text(row.name)
                    .font(PlateFont.headline)
                    .foregroundStyle(PlateColor.ink)
                    .lineLimit(1)
            }
            .padding(.horizontal, PlateSpace.n(2))
            .frame(maxWidth: .infinity, minHeight: PlateStroke.hit, alignment: .leading)
            .background(PlateColor.background)
            .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
        }
        .buttonStyle(PlatePressStyle())
        .accessibilityLabel("\(row.detail), \(row.name)")
        .accessibilityHint(row.includesToday ? "Closes and opens today's tone well" : "Returns to the day-by-day log")
        .accessibilityAddTraits(.isButton)
    }

    private var markedDayLines: [ContourLine] {
        plate.entries.values.sorted { $0.dayKey < $1.dayKey }.map { entry in
            spotRow(Spot(dayKey: entry.dayKey, toneIndex: entry.toneIndex))
        }
    }

    private func runCard(_ row: ContourLine, hero _: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            Text(row.kind)
                .font(PlateFont.caption)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(PlateColor.muted)
                .lineLimit(1)
            contourFigure(row)
        }
        .padding(PlateSpace.n(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(PlateColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
    }

    private var stackedCensus: some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
            ForEach(censusGroups) { group in
                ledgerLane(group)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(PlateMotion.travel(reduceMotion: reduceMotion), value: plate.census.loops.count)
    }

    private var censusGroups: [CensusGroup] {
        let stretches = calendarStretches
        return [
            CensusGroup(
                id: "runs",
                title: "Same-tone runs",
                count: stretches.runs.count,
                caption: "Each card is one unbroken stretch of consecutive days on the same tone.",
                rows: stretches.runs.map {
                    contourRow(keys: $0.dayKeys, toneIndex: $0.toneIndex, kind: "Same-tone run")
                }
            ),
            CensusGroup(
                id: "single",
                title: "Single days",
                count: stretches.singles.count,
                caption: "A marked day with no same-tone day on either side.",
                rows: stretches.singles.map { stretch in
                    spotRow(Spot(dayKey: stretch.dayKeys[0], toneIndex: stretch.toneIndex))
                }
            ),
        ]
    }

    private func ledgerLane(_ group: CensusGroup) -> some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            laneChrome(title: group.title, count: group.count)
            Text(group.caption)
                .font(PlateFont.body)
                .foregroundStyle(PlateColor.muted)
                .fixedSize(horizontal: false, vertical: true)
            if group.rows.isEmpty {
                Text("None yet.")
                    .font(PlateFont.body)
                    .foregroundStyle(PlateColor.muted)
            } else {
                figureStack(group.rows)
            }
        }
        .padding(PlateSpace.n(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(PlateColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func laneChrome(title: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            Text(title)
                .font(PlateFont.caption)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(PlateColor.muted)
                .lineLimit(1)
            Text(PlateReadout.count(count))
                .font(typeSize.isAccessibilitySize ? PlateFont.headline : PlateFont.display(displayPoint))
                .foregroundStyle(PlateColor.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func figureStack(_ rows: [ContourLine]) -> some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Rectangle()
                        .fill(PlateColor.muted.opacity(0.35))
                        .frame(height: PlateStroke.hairline)
                }
                contourFigure(row)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func contourFigure(_ row: ContourLine) -> some View {
        Button {
            onOpenDay(row.includesToday)
        } label: {
            VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
                Text(row.name)
                    .font(PlateFont.headline)
                    .foregroundStyle(PlateColor.ink)
                    .lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: PlateSpace.n(1)) {
                    Text(row.figure)
                        .font(PlateFont.title)
                        .foregroundStyle(PlateColor.accent)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(row.unit)
                        .font(PlateFont.caption)
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundStyle(PlateColor.muted)
                        .lineLimit(1)
                }
                VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
                    ForEach(row.days, id: \.self) { day in
                        Text(day)
                            .font(PlateFont.body)
                            .foregroundStyle(PlateColor.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                Text(row.includesToday ? "Mark today" : "Show these days")
                    .font(PlateFont.headline)
                    .foregroundStyle(PlateColor.accent)
                    .frame(maxWidth: .infinity, minHeight: PlateStroke.hit, alignment: .leading)
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlatePressStyle())
        .accessibilityLabel("\(row.kind), \(row.name), \(row.figure) \(row.unit), \(row.detail)")
        .accessibilityHint(row.includesToday ? "Closes and opens today's tone well" : "Returns to the day-by-day log")
        .accessibilityAddTraits(.isButton)
    }

    private func contourRow(keys: [Int], toneIndex: Int, kind: String) -> ContourLine {
        let tone = plate.tones.indices.contains(toneIndex) ? plate.tones[toneIndex] : nil
        let days = keys.compactMap { PlateCalendar.date(fromDayKey: $0) }
            .map { PlateReadout.day($0) }
        let detail: String
        if days.isEmpty {
            detail = kind
        } else {
            detail = days.joined(separator: ", ")
        }
        return ContourLine(
            id: "\(kind)-\(keys.first ?? 0)-\(keys.last ?? 0)",
            kind: kind,
            name: tone?.spokenName ?? kind,
            detail: detail,
            days: days,
            figure: PlateReadout.count(keys.count),
            unit: keys.count == 1 ? "day" : "days",
            includesToday: keys.contains(todayKey)
        )
    }

    private func spotRow(_ spot: Spot) -> ContourLine {
        let tone = plate.tones.indices.contains(spot.toneIndex) ? plate.tones[spot.toneIndex] : nil
        let date = PlateCalendar.date(fromDayKey: spot.dayKey)
        let day = date.map { PlateReadout.day($0) } ?? "Single day"
        return ContourLine(
            id: "spot-\(spot.dayKey)",
            kind: "Single day",
            name: tone?.spokenName ?? "Single day",
            detail: day,
            days: [day],
            figure: PlateReadout.count(1),
            unit: "day",
            includesToday: spot.dayKey == todayKey
        )
    }

    private func warningHeadline(_ warning: PlateWarning) -> String {
        switch warning {
        case .recoveredFromBackup:
            return "Recovered from a spare copy."
        case .startedEmpty:
            return "Started from a blank year."
        }
    }
}

struct ContourLine: Identifiable {
    var id: String
    var kind: String
    var name: String
    var detail: String
    var days: [String]
    var figure: String
    var unit: String
    var includesToday: Bool
}

private struct CensusGroup: Identifiable {
    var id: String
    var title: String
    var count: Int
    var caption: String
    var rows: [ContourLine]
}
