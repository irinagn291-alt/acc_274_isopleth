import SwiftUI

/// Role: Ridge. Drawn mark for an open contour. Same-tone cells that share an edge.
struct RidgeMark: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(PlateRadius.chip, min(rect.width, rect.height) / 2)
        return Path(roundedRect: rect, cornerRadius: radius, style: .continuous)
    }
}

/// Role: Ridge. Shared-edge bar between two unioned cells on the week-column plate.
struct RidgeJoin: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(PlateRadius.chip, min(rect.width, rect.height) / 2)
        return Path(roundedRect: rect, cornerRadius: radius, style: .continuous)
    }
}
