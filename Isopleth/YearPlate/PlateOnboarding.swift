import SwiftUI

/// Role: YearPlate. One-shot cover. Skip still writes factory tones and the completion flag.
struct PlateOnboarding: View {
    var onFinish: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .largeTitle) private var displayPoint: CGFloat = 34
    @ScaledMetric(relativeTo: .title2) private var artBand: CGFloat = 224

    private let lastPage = 3

    var body: some View {
        VStack(spacing: PlateSpace.n(2)) {
            Group {
                switch page {
                case 0:
                    pageView(
                        image: "ipl_Onboarding1",
                        title: "The year plate",
                        line: "One mark for each day. Terrain, not a journal."
                    )
                case 1:
                    pageView(
                        image: "ipl_Onboarding2",
                        title: "Set the tone",
                        line: "Tap today. Twelve named tones. Colour is never the only signal."
                    )
                case 2:
                    pageView(
                        image: "ipl_Onboarding3",
                        title: "Ridges join",
                        line: "Same-tone cells that share an edge become a ridge. A close is a loop. A lone cell is a spot."
                    )
                default:
                    pageView(
                        image: "ipl_TwistHero",
                        title: "Quiet days",
                        line: "Consecutive marks ending today or yesterday. A gap starts over."
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(PlateMotion.travel(reduceMotion: reduceMotion), value: page)

            VStack(spacing: PlateSpace.n(1)) {
                Button("Skip") { onFinish() }
                    .buttonStyle(PlateGhostStyle())
                    .frame(maxWidth: .infinity)

                if page < lastPage {
                    Button("Next") { page += 1 }
                        .buttonStyle(PlateSoftStyle())
                } else {
                    Button("Open the plate") { onFinish() }
                        .buttonStyle(PlateSoftStyle())
                }
            }
        }
        .padding(.horizontal, PlateSpace.n(2))
        .padding(.bottom, PlateSpace.n(2))
        .padding(.top, PlateSpace.n(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PlateColor.background.ignoresSafeArea())
    }

    private func pageView(image: String, title: String, line: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: artBand)
                    .clipped()
                    .padding(PlateSpace.n(2))
                    .frame(maxWidth: .infinity)
                    .background(PlateColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
                    .accessibilityHidden(true)
                Text(title)
                    .font(typeSize.isAccessibilitySize ? PlateFont.title : PlateFont.display(displayPoint))
                    .foregroundStyle(PlateColor.ink)
                    .tracking(typeSize.isAccessibilitySize ? 0 : -0.8)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(line)
                    .font(PlateFont.body)
                    .foregroundStyle(PlateColor.muted)
                    .lineSpacing(PlateSpace.n(1))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, PlateSpace.n(2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .scrollIndicators(.hidden)
    }
}
