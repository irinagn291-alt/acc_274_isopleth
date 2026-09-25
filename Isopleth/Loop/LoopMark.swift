import SwiftUI

/// Role: Loop. Ring mark for a ridge whose four-neighbor graph contains a cycle.
struct LoopMark: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(PlateRadius.chip, min(rect.width, rect.height) / 2)
        let inset = max(min(rect.width, rect.height) * 0.22, 1)
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: radius, height: radius), style: .continuous)
        let inner = rect.insetBy(dx: inset, dy: inset)
        let innerRadius = max(radius - inset, 1)
        path.addRoundedRect(
            in: inner,
            cornerSize: CGSize(width: innerRadius, height: innerRadius),
            style: .continuous
        )
        return path
    }
}
