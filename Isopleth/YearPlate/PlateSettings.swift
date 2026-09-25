import SwiftUI
import UIKit

/// Role: YearPlate. Settings sheet. Observes the same YearPlate. Tones, contact, cover, reset.
struct PlateSettings: View {
    @ObservedObject var plate: YearPlate
    var onRerunOnboarding: () -> Void
    var onDismiss: () -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var confirmReset = false
    @State private var resetBusy = false
    @State private var persistFailed = false
    @State private var toneFailed = false
    @State private var editingIndex = 0
    @State private var draftName = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            PlateSafeStage(edges: [.bottom, .leading, .trailing]) { _ in
                Group {
                    if persistFailed {
                        errorState
                    } else if usesBoard {
                        settingsBoard
                    } else {
                        settingsForm
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(PlateColor.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                        .buttonStyle(PlateGhostStyle())
                        .accessibilityLabel("Close settings")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { nameFocused = false }
                        .accessibilityLabel("Dismiss keyboard")
                }
            }
        }
        .confirmationDialog("Erase every mark on this plate?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset all data", role: .destructive) {
                Task { await resetAll() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    /// iPad fills the frame. A form sheet would leave the year plate around a stub card.
    private var usesBoard: Bool {
        (sizeClass == .regular || UIDevice.current.userInterfaceIdiom == .pad)
            && !typeSize.isAccessibilitySize
    }

    private var emptyBlock: some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            Image("ipl_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: PlateSpace.n(12))
                .clipped()
                .padding(PlateSpace.n(2))
                .frame(maxWidth: .infinity)
                .background(PlateColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
                .accessibilityHidden(true)
            Text("No marks yet.")
                .font(PlateFont.headline)
                .foregroundStyle(PlateColor.ink)
            Text("Tones are ready before the first stroke.")
                .font(PlateFont.body)
                .foregroundStyle(PlateColor.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var settingsBoard: some View {
        GeometryReader { geo in
            ScrollView {
                HStack(alignment: .top, spacing: PlateSpace.n(2)) {
                    toneRoster
                    editorColumn
                }
                .padding(PlateSpace.n(2))
                .padding(.bottom, PlateSpace.n(2))
                .frame(minHeight: geo.size.height, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollIndicators(.hidden)
        }
        .background(PlateColor.background)
        .onAppear(perform: syncDraft)
    }

    private var toneRoster: some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            Text("Twelve tones")
                .font(PlateFont.headline)
                .foregroundStyle(PlateColor.ink)
                .lineLimit(1)
            Text("Pick a tone, then rewrite its name or ink. Colour is never the only signal.")
                .font(PlateFont.caption)
                .foregroundStyle(PlateColor.muted)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            toneRows
        }
        .padding(PlateSpace.n(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(PlateColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
    }

    private var toneRows: some View {
        VStack(spacing: PlateSpace.n(1)) {
            ForEach(Array(plate.tones.enumerated()), id: \.offset) { index, tone in
                let marks = toneMarkCount(index)
                Button {
                    editingIndex = index
                    syncDraft()
                    nameFocused = true
                } label: {
                    HStack(spacing: PlateSpace.n(1)) {
                        Text(tone.spokenName)
                            .font(PlateFont.body)
                            .foregroundStyle(index == editingIndex ? PlateColor.accent : PlateColor.ink)
                            .lineLimit(1)
                        Spacer(minLength: PlateSpace.n(1))
                        Text(PlateReadout.count(marks))
                            .font(PlateFont.headline)
                            .foregroundStyle(PlateColor.ink)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: PlateStroke.hit, alignment: .leading)
                    .padding(.horizontal, PlateSpace.n(2))
                    .background(PlateColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
                }
                .buttonStyle(PlatePressStyle())
                .accessibilityLabel("\(tone.spokenName), \(PlateReadout.count(marks)) cells")
                .accessibilityAddTraits(index == editingIndex ? .isSelected : AccessibilityTraits())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var editorColumn: some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
            VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
                Text("Spoken name")
                    .font(PlateFont.caption)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(PlateColor.muted)
                    .lineLimit(1)
                TextField("Spoken name", text: $draftName)
                    .font(PlateFont.body)
                    .foregroundStyle(PlateColor.ink)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit { commitDraft(); nameFocused = false }
                    .onChange(of: draftName) { _, _ in commitDraft() }
                    .padding(.horizontal, PlateSpace.n(2))
                    .frame(maxWidth: .infinity, minHeight: PlateStroke.hit, alignment: .leading)
                    .background(PlateColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
                Button {
                    shiftSelectedInk()
                } label: {
                    PlateActionRow(title: "Shift ink", trailing: .ink(selectedTone))
                }
                .buttonStyle(PlatePressStyle())
                .disabled(!plate.tones.indices.contains(editingIndex))
                .accessibilityLabel(shiftInkLabel)
                .accessibilityHint("Rewrites the selected tone ink")
                .accessibilityAddTraits(.isButton)
                if toneFailed {
                    Text("Could not rewrite the well. Names must stay unique.")
                        .font(PlateFont.body)
                        .foregroundStyle(PlateColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(PlateSpace.n(2))
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(PlateColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
            .clipped()

            VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
                Button {
                    restoreFactoryTones()
                } label: {
                    PlateActionRow(title: "Restore factory tones", trailing: .chevron)
                }
                .buttonStyle(PlatePressStyle())
                .accessibilityLabel("Restore factory tones")
                .accessibilityAddTraits(.isButton)

                Button {
                    openURL(PlateIdentity.contactURL)
                } label: {
                    PlateActionRow(title: "Contact", trailing: .external)
                }
                .buttonStyle(PlatePressStyle())
                .accessibilityLabel("Contact")
                .accessibilityHint("Opens the contact page")
                .accessibilityAddTraits(.isButton)

                Button {
                    onRerunOnboarding()
                } label: {
                    PlateActionRow(title: "Replay the cover", trailing: .chevron)
                }
                .buttonStyle(PlatePressStyle())
                .accessibilityLabel("Replay the cover")
                .accessibilityAddTraits(.isButton)

                Button("Reset all data") {
                    confirmReset = true
                }
                .buttonStyle(PlateEraseStyle())
                .disabled(resetBusy)
                .accessibilityLabel("Reset all data")

                selectedToneFigure
            }
            .padding(PlateSpace.n(2))
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(PlateColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
            .clipped()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var settingsForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
                    if plate.entries.isEmpty {
                        emptyBlock
                    }
                    toneRoster
                }
                .padding(PlateSpace.n(2))
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.visible)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
                compactEditor
                actionsStack
            }
            .padding(.horizontal, PlateSpace.n(2))
            .padding(.bottom, PlateSpace.n(2))
            .padding(.top, PlateSpace.n(1))
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(PlateColor.background)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(PlateColor.background)
        .tint(PlateColor.accent)
        .onAppear(perform: syncDraft)
    }

    private var compactEditor: some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            Text("Spoken name")
                .font(PlateFont.caption)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(PlateColor.muted)
                .lineLimit(1)
            TextField("Spoken name", text: $draftName)
                .font(PlateFont.body)
                .foregroundStyle(PlateColor.ink)
                .focused($nameFocused)
                .submitLabel(.done)
                .onSubmit { commitDraft(); nameFocused = false }
                .onChange(of: draftName) { _, _ in commitDraft() }
                .padding(.horizontal, PlateSpace.n(2))
                .frame(maxWidth: .infinity, minHeight: PlateStroke.hit, alignment: .leading)
                .background(PlateColor.background)
                .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
            Button {
                shiftSelectedInk()
            } label: {
                PlateActionRow(title: "Shift ink", trailing: .ink(selectedTone))
            }
            .buttonStyle(PlatePressStyle())
            .disabled(!plate.tones.indices.contains(editingIndex))
            .accessibilityLabel(shiftInkLabel)
            .accessibilityHint("Rewrites the selected tone ink")
            .accessibilityAddTraits(.isButton)
            if toneFailed {
                Text("Could not rewrite the well. Names must stay unique.")
                    .font(PlateFont.body)
                    .foregroundStyle(PlateColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(PlateSpace.n(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(PlateColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
        .clipped()
    }

    private var actionsStack: some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            Button {
                restoreFactoryTones()
            } label: {
                PlateActionRow(title: "Restore factory tones", trailing: .chevron)
            }
            .buttonStyle(PlatePressStyle())
            .accessibilityLabel("Restore factory tones")
            .accessibilityAddTraits(.isButton)

            Button {
                openURL(PlateIdentity.contactURL)
            } label: {
                PlateActionRow(title: "Contact", trailing: .external)
            }
            .buttonStyle(PlatePressStyle())
            .accessibilityLabel("Contact")
            .accessibilityHint("Opens the contact page")
            .accessibilityAddTraits(.isButton)

            Button {
                onRerunOnboarding()
            } label: {
                PlateActionRow(title: "Replay the cover", trailing: .chevron)
            }
            .buttonStyle(PlatePressStyle())
            .accessibilityLabel("Replay the cover")
            .accessibilityAddTraits(.isButton)

            Button("Reset all data") {
                confirmReset = true
            }
            .buttonStyle(PlateEraseStyle())
            .disabled(resetBusy)
            .accessibilityLabel("Reset all data")
        }
        .padding(PlateSpace.n(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(PlateColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
        .clipped()
    }

    private var selectedTone: Tone? {
        plate.tones.indices.contains(editingIndex) ? plate.tones[editingIndex] : nil
    }

    private var shiftInkLabel: String {
        guard let tone = selectedTone else { return "Shift ink" }
        return "Shift ink, \(ToneWell.inkSpokenName(tone))"
    }

    private func restoreFactoryTones() {
        do {
            try plate.rewriteTones(ToneWell.factory)
            toneFailed = false
            editingIndex = 0
            syncDraft()
            nameFocused = false
        } catch {
            toneFailed = true
        }
    }

    private func toneMarkCount(_ index: Int) -> Int {
        plate.entries.values.reduce(0) { $0 + ($1.toneIndex == index ? 1 : 0) }
    }

    private var selectedToneFigure: some View {
        let name = plate.tones.indices.contains(editingIndex)
            ? plate.tones[editingIndex].spokenName
            : "Tone"
        let marks = plate.entries.values.filter { $0.toneIndex == editingIndex }.count
        return VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            Text("On this plate")
                .font(PlateFont.caption)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(PlateColor.muted)
                .lineLimit(1)
            Text(name)
                .font(PlateFont.title)
                .foregroundStyle(PlateColor.ink)
                .lineLimit(1)
            Text(PlateReadout.count(marks))
                .font(PlateFont.display())
                .foregroundStyle(PlateColor.accent)
                .monospacedDigit()
                .lineLimit(1)
            Text(marks == 1 ? "cell marked." : "cells marked.")
                .font(PlateFont.body)
                .foregroundStyle(PlateColor.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, PlateSpace.n(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(PlateReadout.count(marks)) \(marks == 1 ? "cell" : "cells") marked on this plate")
        .accessibilityAddTraits(.isStaticText)
    }

    private func shiftSelectedInk() {
        guard plate.tones.indices.contains(editingIndex) else { return }
        do {
            try plate.shiftToneInk(at: editingIndex)
            toneFailed = false
        } catch {
            toneFailed = true
        }
    }

    private func syncDraft() {
        if !plate.tones.indices.contains(editingIndex) {
            editingIndex = 0
        }
        guard plate.tones.indices.contains(editingIndex) else { return }
        draftName = plate.tones[editingIndex].spokenName
    }

    private func commitDraft() {
        guard plate.tones.indices.contains(editingIndex) else { return }
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try plate.renameTone(at: editingIndex, spokenName: trimmed)
            toneFailed = false
        } catch {
            toneFailed = true
        }
    }

    private var errorState: some View {
        PlateVoid(
            image: "ipl_EmptyList",
            headline: "Could not save.",
            line: "The plate stayed in memory. Try again.",
            actionTitle: "Try again"
        ) {
            persistFailed = false
        }
    }

    private func resetAll() async {
        resetBusy = true
        defer { resetBusy = false }
        do {
            try await plate.resetAllData()
            persistFailed = false
            onDismiss()
        } catch {
            persistFailed = true
        }
    }
}

/// Role: YearPlate. Settings row. Title plus a named trailing accessory, padded inside the card.
private struct PlateActionRow: View {
    enum Trailing {
        case ink(Tone?)
        case chevron
        case external
    }

    var title: String
    var trailing: Trailing

    @ScaledMetric(relativeTo: .body) private var swatch: CGFloat = 16

    var body: some View {
        HStack(spacing: PlateSpace.n(1)) {
            Text(title)
                .font(PlateFont.body)
                .foregroundStyle(PlateColor.ink)
                .lineLimit(1)
                .layoutPriority(1)
            Spacer(minLength: PlateSpace.n(1))
            trailingChrome
        }
        .padding(.horizontal, PlateSpace.n(2))
        .frame(maxWidth: .infinity, minHeight: PlateStroke.hit, alignment: .leading)
        .background(PlateColor.background)
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
    }

    @ViewBuilder
    private var trailingChrome: some View {
        switch trailing {
        case .ink(let tone):
            if let tone {
                Circle()
                    .fill(tone.ink)
                    .frame(width: swatch, height: swatch)
                    .overlay {
                        Circle()
                            .stroke(PlateColor.ink.opacity(0.45), lineWidth: PlateStroke.hairline)
                    }
                    .accessibilityHidden(true)
                Text(ToneWell.inkSpokenName(tone))
                    .font(PlateFont.headline)
                    .foregroundStyle(PlateColor.ink)
                    .lineLimit(1)
            }
        case .chevron:
            Image(systemName: "chevron.forward")
                .font(PlateFont.headline)
                .foregroundStyle(PlateColor.ink)
                .accessibilityHidden(true)
        case .external:
            Image(systemName: "arrow.up.right")
                .font(PlateFont.headline)
                .foregroundStyle(PlateColor.ink)
                .accessibilityHidden(true)
        }
    }
}
