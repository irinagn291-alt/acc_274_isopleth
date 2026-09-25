import SwiftUI

extension Tone {
    var ink: Color {
        Color(red: red, green: green, blue: blue)
    }
}

/// Role: Well. In-place radial overlay on today. Twelve native Buttons. Binds to the same YearPlate.
struct ToneWellOverlay: View {
    var tones: [Tone]
    var onPick: (Int) -> Void
    var onDismiss: () -> Void
    var isBusy: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var swatch: CGFloat = 24

    var body: some View {
        ZStack {
            Button(action: onDismiss) {
                PlateColor.background.opacity(0.78)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close the well")
            .disabled(isBusy)

            VStack(spacing: 0) {
                chrome
                if typeSize.isAccessibilitySize {
                    accessibleWell
                } else {
                    radialWell
                }
            }
        }
        .transition(.opacity)
        .animation(PlateMotion.travel(reduceMotion: reduceMotion), value: isBusy)
    }

    private var chrome: some View {
        HStack(alignment: .top, spacing: PlateSpace.n(1)) {
            VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
                Text("Set the tone")
                    .font(PlateFont.title)
                    .foregroundStyle(PlateColor.ink)
                    .tracking(-0.4)
                    .lineLimit(2)
                Text("Twelve named tones. Not a score.")
                    .font(PlateFont.body)
                    .foregroundStyle(PlateColor.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(PlateFont.headline)
                    .foregroundStyle(PlateColor.ink)
                    .frame(width: PlateStroke.hit, height: PlateStroke.hit)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: PlateRadius.chip, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: PlateRadius.chip, style: .continuous))
            }
            .buttonStyle(PlatePressStyle())
            .disabled(isBusy)
            .accessibilityLabel("Close the well")
        }
        .padding(.horizontal, PlateSpace.n(2))
        .padding(.top, PlateSpace.n(2))
    }

    private var radialWell: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) * 0.36
            ZStack {
                Image("ipl_ControlFace")
                    .resizable()
                    .scaledToFit()
                    .frame(width: PlateSpace.n(8), height: PlateSpace.n(8))
                    .padding(PlateSpace.n(2))
                    .background(PlateColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
                    .position(center)
                    .accessibilityHidden(true)
                ForEach(Array(tones.enumerated()), id: \.element.id) { index, tone in
                    let angle = (Double(index) / Double(ToneWell.toneCount)) * 2 * Double.pi - Double.pi / 2
                    Button {
                        onPick(index)
                    } label: {
                        VStack(spacing: PlateSpace.n(1)) {
                            Circle()
                                .fill(tone.ink)
                                .frame(width: swatch, height: swatch)
                                .overlay {
                                    Circle()
                                        .stroke(PlateColor.ink.opacity(0.35), lineWidth: PlateStroke.hairline)
                                }
                            Text(tone.spokenName)
                                .font(PlateFont.caption)
                                .foregroundStyle(PlateColor.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(width: PlateStroke.hit + PlateSpace.n(2), height: PlateStroke.hit + PlateSpace.n(2))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlatePressStyle())
                    .disabled(isBusy)
                    .accessibilityLabel(tone.spokenName)
                    .position(
                        x: center.x + CGFloat(cos(angle)) * radius,
                        y: center.y + CGFloat(sin(angle)) * radius
                    )
                }
            }
        }
    }

    private var accessibleWell: some View {
        ScrollView {
            VStack(spacing: PlateSpace.n(1)) {
                Image("ipl_ControlFace")
                    .resizable()
                    .scaledToFit()
                    .frame(width: PlateSpace.n(8), height: PlateSpace.n(8))
                    .padding(PlateSpace.n(2))
                    .frame(maxWidth: .infinity)
                    .background(PlateColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
                    .accessibilityHidden(true)
                ForEach(Array(tones.enumerated()), id: \.element.id) { index, tone in
                    Button(tone.spokenName) {
                        onPick(index)
                    }
                    .buttonStyle(PlatePressStyle())
                    .font(PlateFont.caption)
                    .foregroundStyle(PlateColor.ink)
                    .padding(.leading, PlateSpace.n(4))
                    .frame(maxWidth: .infinity, minHeight: PlateStroke.hit, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
                    .overlay(alignment: .leading) {
                        Circle()
                            .fill(tone.ink)
                            .frame(width: swatch, height: swatch)
                            .padding(.leading, PlateSpace.n(1))
                            .accessibilityHidden(true)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
                    .disabled(isBusy)
                    .accessibilityLabel(tone.spokenName)
                }
            }
            .padding(.horizontal, PlateSpace.n(2))
            .padding(.vertical, PlateSpace.n(2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Role: Well. iPad rail. Twelve named Buttons mark today. Each row also shows how many cells already wear that tone.
struct PlateTodayRail: View {
    var tones: [Tone]
    var counts: [Int]
    var canSetToday: Bool
    var isBusy: Bool
    var onPick: (Int) -> Void

    @ScaledMetric(relativeTo: .body) private var swatch: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(1)) {
            Text("Today's tone")
                .font(PlateFont.caption)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(PlateColor.muted)
                .lineLimit(1)
            Text("Tap a name to mark today. The figure is how many cells already wear that tone.")
                .font(PlateFont.body)
                .foregroundStyle(PlateColor.muted)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(tones.enumerated()), id: \.element.id) { index, tone in
                Button {
                    onPick(index)
                } label: {
                    HStack(spacing: PlateSpace.n(1)) {
                        Circle()
                            .fill(tone.ink)
                            .frame(width: swatch, height: swatch)
                            .overlay {
                                Circle()
                                    .stroke(PlateColor.ink.opacity(0.35), lineWidth: PlateStroke.hairline)
                            }
                            .accessibilityHidden(true)
                        Text(tone.spokenName)
                            .font(PlateFont.body)
                            .foregroundStyle(PlateColor.ink)
                            .lineLimit(1)
                        Spacer(minLength: PlateSpace.n(1))
                        Text(PlateReadout.count(count(at: index)))
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
                .disabled(!canSetToday || isBusy)
                .accessibilityLabel("\(tone.spokenName), \(PlateReadout.count(count(at: index))) cells")
                .accessibilityHint("Marks today with this tone")
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding(PlateSpace.n(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(PlateColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
        .clipped()
    }

    private func count(at index: Int) -> Int {
        counts.indices.contains(index) ? counts[index] : 0
    }
}
