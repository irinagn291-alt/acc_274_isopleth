import SwiftUI

/// Role: YearPlate. Full-page empty or error surface. Generated art, headline, line, one CTA.
struct PlateVoid: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var action: () -> Void

    @ScaledMetric(relativeTo: .title2) private var artBand: CGFloat = 144

    var body: some View {
        VStack(alignment: .leading, spacing: PlateSpace.n(2)) {
            Spacer(minLength: 0)
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
            Text(headline)
                .font(PlateFont.title)
                .foregroundStyle(PlateColor.ink)
                .lineLimit(2)
            Text(line)
                .font(PlateFont.body)
                .foregroundStyle(PlateColor.muted)
                .lineSpacing(PlateSpace.n(1))
            Spacer(minLength: 0)
            Button(actionTitle, action: action)
                .buttonStyle(PlateSoftStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
