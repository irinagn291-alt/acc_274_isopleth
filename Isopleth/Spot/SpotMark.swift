import SwiftUI

/// Role: Spot. Drawn mark for a lone cell. No same-tone grid-edge neighbor.
struct SpotMark: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(PlateRadius.chip, min(rect.width, rect.height) / 2)
        return Path(roundedRect: rect, cornerRadius: radius, style: .continuous)
    }
}
