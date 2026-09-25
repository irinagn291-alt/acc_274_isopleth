import SwiftUI
import UIKit

/// Role: YearPlate. Root plate. Observes one YearPlate. The year never leaves. Well overlays today.
struct PlateCanvas: View {
    @ObservedObject var plate: YearPlate

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var showWell = false
    @State private var showRidges = false
    @State private var showSettings = false
    @State private var showOnboarding = false
    @State private var reviewConsumed = false
    @State private var showSpinner = false
    @State private var committing = false
    @State private var commitError: PlateError?
    @State private var bloomGeneration = 0
    @State private var bloomHue = UIColor.white
    @State private var hostHeight: CGFloat = 0
    @State private var hostSafeTop: CGFloat = 0
    @State private var chromeHeight: CGFloat = 0

    @ScaledMetric(relativeTo: .title2) private var yearPoint: CGFloat = 28
    @ScaledMetric(relativeTo: .title2) private var verbPoint: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var bodyLead: CGFloat = 8

    var body: some View {
        ZStack {
            PlateColor.background.ignoresSafeArea()
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                plateBody(now: timeline.date)
            }
        }
        .overlay {
            if showWell {
                ToneWellOverlay(
                    tones: plate.tones,
                    onPick: commitTone,
                    onDismiss: { showWell = false },
                    isBusy: committing
                )
            }
        }
        .overlay {
            if showSpinner {
                ProgressView()
                    .tint(PlateColor.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(PlateColor.background.opacity(0.55))
                    .accessibilityLabel("Loading the plate")
            }
        }
        .sheet(isPresented: showRidgesSheet) {
            ridgesPane
                .presentationDetents([.height(hostSheetHeight)])
                .presentationDragIndicator(.visible)
                .presentationBackground(PlateColor.background)
                .presentationBackgroundInteraction(.disabled)
        }
        .fullScreenCover(isPresented: showRidgesCover) {
            ZStack {
                PlateColor.background.ignoresSafeArea()
                ridgesPane
            }
            .presentationBackground(PlateColor.background)
        }
        .sheet(isPresented: showSettingsSheet) {
            settingsPane
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(PlateColor.background)
                .presentationBackgroundInteraction(.disabled)
        }
        .fullScreenCover(isPresented: showSettingsCover) {
            settingsPane
                .presentationBackground(PlateColor.background)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            PlateOnboarding {
                plate.markOnboardingComplete()
                showOnboarding = false
                applyReview()
            }
        }
        .task { await bootstrap() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive || phase == .background {
                Task { try? await plate.flushForScene() }
            }
        }
        .animation(PlateMotion.travel(reduceMotion: reduceMotion), value: showWell)
        .animation(PlateMotion.commit(reduceMotion: reduceMotion), value: bloomGeneration)
    }

    @ViewBuilder
    private func plateBody(now: Date) -> some View {
        let yearPlots = PlateGrid.plots(
            year: plate.year,
            entries: plate.entries,
            tones: plate.tones,
            census: plate.census,
            now: now,
            calendar: .current
        )
        let plots = PlateGrid.focusedPlots(from: yearPlots)
        let lanes = PlateGrid.weekLanes(in: plots, calendar: .current)
        let wide = sizeClass == .regular || UIDevice.current.userInterfaceIdiom == .pad
        PlateSafeStage { insets in
            Group {
                if wide && !typeSize.isAccessibilitySize {
                    wideHome(now: now, plots: plots, lanes: lanes)
                } else {
                    compactHome(now: now, plots: plots, lanes: lanes)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { recordHost(geo, insets: insets) }
                        .onChange(of: geo.size) { _, _ in recordHost(geo, insets: insets) }
                }
            }
        }
    }

    private func compactHome(now: Date, plots: [PlatePlot], lanes: [PlateWeekLane]) -> some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
            plateMasthead(now: now, showsJewel: true)
            board(plots: plots, lanes: lanes)
            PlateToneLegend(plots: plots)
            footer
        }
        .padding(.horizontal, PlateSpace.n(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func wideHome(now: Date, plots: [PlatePlot], lanes: [PlateWeekLane]) -> some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
            plateMasthead(now: now, showsJewel: false)
            HStack(alignment: .top, spacing: PlateSpace.n(2)) {
                VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
                    board(plots: plots, lanes: lanes, expandsToFill: true)
                    PlateToneLegend(plots: plots)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                wideRail(now: now, plots: plots)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, PlateSpace.n(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func wideRail(now: Date, plots: [PlatePlot]) -> some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
            quietJewel(now: now)
                .frame(maxWidth: .infinity, alignment: .trailing)
            footer
            ScrollView {
                VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
                    PlateTodayRail(
                        tones: plate.tones,
                        counts: toneCounts,
                        canSetToday: plate.canSetToday,
                        isBusy: committing,
                        onPick: commitTone
                    )
                    railMarks(plots: plots)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.bottom, PlateSpace.n(2))
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: PlateSpace.n(40), alignment: .topLeading)
    }

    private func railMarks(plots: [PlatePlot]) -> some View {
        let marked = plots.filter { $0.kind != .vacant }.sorted { $0.dayKey < $1.dayKey }
        return VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            Text("Days already marked")
                .font(PlateFont.caption)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(PlateColor.muted)
                .lineLimit(1)
            if marked.isEmpty {
                Text("No marks yet. Today is the outlined cell.")
                    .font(PlateFont.body)
                    .foregroundStyle(PlateColor.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(marked) { plot in
                    Button {
                        showRidges = true
                    } label: {
                        HStack(spacing: PlateSpace.n(1)) {
                            Text(markedDayLabel(plot))
                                .font(PlateFont.body)
                                .foregroundStyle(PlateColor.ink)
                                .lineLimit(1)
                            Spacer(minLength: PlateSpace.n(1))
                            Text(plot.spokenName)
                                .font(PlateFont.headline)
                                .foregroundStyle(PlateColor.ink)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: PlateStroke.hit, alignment: .leading)
                        .padding(.horizontal, PlateSpace.n(2))
                        .background(PlateColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
                    }
                    .buttonStyle(PlatePressStyle())
                    .accessibilityLabel("\(plot.spokenName), \(markedDayLabel(plot))")
                    .accessibilityHint("Opens the tone runs for this day")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        .padding(PlateSpace.n(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(PlateColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
        .clipped()
    }

    private var toneCounts: [Int] {
        plate.tones.indices.map { index in
            plate.entries.values.reduce(0) { $0 + ($1.toneIndex == index ? 1 : 0) }
        }
    }

    private func markedDayLabel(_ plot: PlatePlot) -> String {
        guard let date = PlateCalendar.date(fromDayKey: plot.dayKey) else {
            return PlateReadout.count(plot.dayKey)
        }
        return PlateReadout.day(date)
    }

    private func board(plots: [PlatePlot], lanes: [PlateWeekLane], expandsToFill: Bool = true) -> some View {
        PlateDayBoard(
            plots: plots,
            lanes: lanes,
            weekdayTitles: PlateGrid.weekdayTitles(calendar: .current),
            canSetToday: plate.canSetToday,
            committing: committing,
            bloomGeneration: bloomGeneration,
            bloomHue: bloomHue,
            reduceMotion: reduceMotion,
            onToday: { showWell = true },
            onMarkedDay: { _ in showRidges = true },
            expandsToFill: expandsToFill
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(maxHeight: expandsToFill ? .infinity : nil)
    }

    /// Year, streak, job, and next tap. First child of the safe stage so it starts under the status bar.
    private func plateMasthead(now: Date, showsJewel: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
            VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
                HStack(alignment: .firstTextBaseline, spacing: PlateSpace.n(2)) {
                    Text(PlateReadout.year(plate.year))
                        .font(yearFont)
                        .tracking(typeSize.isAccessibilitySize ? 0 : -0.6)
                        .foregroundStyle(PlateColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .layoutPriority(1)
                    Spacer(minLength: PlateSpace.n(2))
                    if showsJewel {
                        quietJewel(now: now)
                    }
                }
                Text("Mark today")
                    .font(verbFont)
                    .tracking(typeSize.isAccessibilitySize ? 0 : -0.4)
                    .foregroundStyle(PlateColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Tap today's cell, then Set the tone.")
                    .font(PlateFont.body)
                    .foregroundStyle(PlateColor.muted)
                    .lineSpacing(bodyLead)
                    .fixedSize(horizontal: false, vertical: true)
            }
            liveBanner
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlateColor.background)
        .background {
            GeometryReader { geo in
                Color.clear.preference(key: PlateChromeHeightKey.self, value: geo.size.height)
            }
        }
        .onPreferenceChange(PlateChromeHeightKey.self) { chromeHeight = $0 }
    }

    @ViewBuilder
    private var liveBanner: some View {
        if let commitError {
            banner(text: commitCopy(commitError), action: "Try again") {
                self.commitError = nil
                showWell = true
            }
        } else if let warning = plate.warning {
            banner(text: warningCopy(warning), action: "Reload") {
                Task { await plate.load() }
            }
        }
    }

    private func quietJewel(now: Date) -> some View {
        let streak = plate.quietStreak(at: now)
        return VStack(alignment: .trailing, spacing: 0) {
            Text(PlateReadout.count(streak))
                .font(PlateFont.title)
                .foregroundStyle(PlateColor.accent)
                .monospacedDigit()
                .lineLimit(1)
                .layoutPriority(1)
            Text("Quiet days")
                .font(PlateFont.caption)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(PlateColor.muted)
        }
        .padding(PlateSpace.n(1))
        .frame(minWidth: PlateStroke.hit, minHeight: PlateStroke.hit)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quiet days, \(PlateReadout.count(streak))")
    }

    private var footer: some View {
        VStack(spacing: PlateSpace.n(1)) {
            Button("Set the tone") {
                showWell = true
            }
            .buttonStyle(PlateSoftStyle(isLoading: committing))
            .disabled(!plate.canSetToday || committing)
            .accessibilityHint("Opens the twelve tone well")
            HStack {
                Button("Tone runs") { showRidges = true }
                    .buttonStyle(PlateGhostStyle())
                    .accessibilityLabel("Tone runs")
                Spacer(minLength: PlateSpace.n(1))
                Button("Settings") { showSettings = true }
                    .buttonStyle(PlateGhostStyle())
                    .accessibilityLabel("Settings")
            }
        }
    }

    private func banner(text: String, action: String, run: @escaping () -> Void) -> some View {
        HStack(alignment: .center, spacing: PlateSpace.n(1)) {
            Text(text)
                .font(PlateFont.body)
                .foregroundStyle(PlateColor.ink)
                .lineLimit(3)
            Spacer(minLength: PlateSpace.n(1))
            Button(action, action: run)
                .buttonStyle(PlateGhostStyle())
        }
        .padding(PlateSpace.n(2))
        .frame(maxWidth: .infinity, minHeight: PlateStroke.hit)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
    }

    /// iPad covers the plate. A form sheet would let year marks share the census cards.
    private var ridgesFillFrame: Bool {
        sizeClass == .regular || UIDevice.current.userInterfaceIdiom == .pad
    }

    private var settingsFillFrame: Bool {
        sizeClass == .regular || UIDevice.current.userInterfaceIdiom == .pad
    }

    private var showRidgesSheet: Binding<Bool> {
        Binding(
            get: { showRidges && !ridgesFillFrame },
            set: { value in
                if !ridgesFillFrame {
                    showRidges = value
                }
            }
        )
    }

    private var showRidgesCover: Binding<Bool> {
        Binding(
            get: { showRidges && ridgesFillFrame },
            set: { value in
                if ridgesFillFrame {
                    showRidges = value
                }
            }
        )
    }

    private var showSettingsSheet: Binding<Bool> {
        Binding(
            get: { showSettings && !settingsFillFrame },
            set: { value in
                if !settingsFillFrame {
                    showSettings = value
                }
            }
        )
    }

    private var showSettingsCover: Binding<Bool> {
        Binding(
            get: { showSettings && settingsFillFrame },
            set: { value in
                if settingsFillFrame {
                    showSettings = value
                }
            }
        )
    }

    private var ridgesPane: some View {
        RidgeSheet(
            plate: plate,
            onSetToday: { showWell = true },
            onOpenDay: { includesToday in
                showRidges = false
                if includesToday {
                    showWell = true
                }
            },
            onRetry: { await plate.load() },
            onDismiss: { showRidges = false }
        )
    }

    private var settingsPane: some View {
        PlateSettings(
            plate: plate,
            onRerunOnboarding: {
                showSettings = false
                showOnboarding = true
            },
            onDismiss: { showSettings = false }
        )
    }

    private var yearFont: Font {
        typeSize.isAccessibilitySize ? PlateFont.headline : PlateFont.display(yearPoint)
    }

    private var verbFont: Font {
        typeSize.isAccessibilitySize ? PlateFont.title : PlateFont.display(verbPoint)
    }

    /// Sheet starts below the host chrome so the year, streak, and Mark today line stay whole.
    private var hostSheetHeight: CGFloat {
        let reserved = hostSafeTop + max(chromeHeight, PlateSpace.n(14)) + PlateSpace.n(2)
        let fallback = max(hostHeight, 720)
        return max(PlateSpace.n(48), fallback - reserved)
    }

    private func recordHost(_ geo: GeometryProxy, insets: EdgeInsets) {
        hostHeight = geo.size.height + max(insets.top, PlateSpace.safeTopFloor) + max(insets.bottom, PlateSpace.safeBottomFloor)
        hostSafeTop = max(insets.top, PlateSpace.safeTopFloor)
    }

    private func commitCopy(_ error: PlateError) -> String {
        switch error {
        case .invalidTone:
            return "That tone is not in the well."
        case .invalidWell:
            return "The well is not twelve tones."
        case .dayOutsideYear:
            return "Today is outside this plate."
        case .dayInFuture:
            return "Tomorrow is still closed."
        }
    }

    private func warningCopy(_ warning: PlateWarning) -> String {
        switch warning {
        case .recoveredFromBackup:
            return "Recovered from a spare copy."
        case .startedEmpty:
            return "Could not read the plate. Started empty."
        }
    }

    private func commitTone(_ index: Int) {
        guard !committing else { return }
        committing = true
        defer { committing = false }
        do {
            try plate.setTone(index, on: Date())
            commitError = nil
            if plate.tones.indices.contains(index) {
                let tone = plate.tones[index]
                bloomHue = UIColor(red: tone.red, green: tone.green, blue: tone.blue, alpha: 1)
            }
            bloomGeneration += 1
            PlateHaptic.commit()
            showWell = false
        } catch let error as PlateError {
            commitError = error
        } catch {
            commitError = .invalidTone
        }
    }

    private func bootstrap() async {
        let spinner = Task {
            try await Task.sleep(nanoseconds: 150_000_000)
            if !Task.isCancelled {
                showSpinner = true
            }
        }
        await plate.load()
        spinner.cancel()
        showSpinner = false
        if plate.onboardingComplete {
            applyReview()
        } else {
            showOnboarding = true
        }
    }

    private func applyReview() {
        var consumed = reviewConsumed
        let launch = CoverLaunch.consume(
            arguments: ProcessInfo.processInfo.arguments,
            onboardingComplete: plate.onboardingComplete,
            consumed: &consumed
        )
        reviewConsumed = consumed
        guard let launch else { return }
        switch launch {
        case .today:
            break
        case .log:
            showRidges = true
        case .goals:
            showSettings = true
        case .extra(let token):
            switch token.lowercased() {
            case "well":
                showWell = true
            case "ridges", "ridge", "loops", "spots":
                showRidges = true
            case "settings", "tones":
                showSettings = true
            default:
                break
            }
        }
    }
}

private struct PlateChromeHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
