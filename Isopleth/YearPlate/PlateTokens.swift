import SwiftUI

/// Role: YearPlate. Identity constants for the store key, contact, and User-Agent.
enum PlateIdentity {
    static let domainHost = "isopleth-ridge.pro"
    static let contactURL = URL(string: "https://\(domainHost)/contact-us")!
    static let userAgent = "Isopleth/1.0 (iOS; +https://\(domainHost))"
}

/// Role: YearPlate. Preference keys. Views never touch UserDefaults.
enum PlateKey {
    static let store = "ipl.store.v1"
    static let backup = "ipl.store.v1.backup"
    static let demo = "ipl.demo.v1"
}

/// Role: YearPlate. Palette tokens from SPEC 7.1. Never a raw hex in a view.
enum PlateColor {
    /// Screen background `#1B282C`
    static let background = Color("background")
    /// Cards, rows, sheets `#292F3D`
    static let surface = Color("surface")
    /// Primary text and icons `#F1F3F4`
    static let ink = Color("ink")
    /// Primary action `#5E85E8`
    static let accent = Color("accent")
    /// Secondary text `#B0BBBF`
    static let muted = Color("muted")
}

/// Role: YearPlate. SF Pro via Font.system. At most six named steps. Never below 12pt, display never above 34pt.
enum PlateFont {
    static let displayLimit: CGFloat = 34
    static let floor: CGFloat = 12

    static func display(_ size: CGFloat? = nil) -> Font {
        let point = min(max(size ?? displayLimit, floor), displayLimit)
        return Font.system(size: point, weight: .regular, design: .default)
    }

    static var title: Font { Font.system(.title2, design: .default).weight(.regular) }
    static var headline: Font { Font.system(.headline, design: .default) }
    static var body: Font { Font.system(.body, design: .default) }
    static var caption: Font { Font.system(.caption, design: .default) }
    static var micro: Font { Font.system(size: floor, weight: .regular, design: .default) }

    static func micro(_ size: CGFloat) -> Font {
        Font.system(size: max(size, floor), weight: .regular, design: .default)
    }
}

/// Role: YearPlate. One base spacing unit. Only multiples of it.
enum PlateSpace {
    static let unit: CGFloat = 8

    static func n(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }

    /// Floor when a host reports no inset. Keeps chrome out of the status bar and home indicator.
    static var safeTopFloor: CGFloat { n(8) }
    static var safeBottomFloor: CGFloat { n(5) }
}

/// Role: YearPlate. Full-bleed void with measured gutters. Chrome never enters the status bar or home indicator.
struct PlateSafeStage<Content: View>: View {
    var edges: Edge.Set = [.top, .bottom, .leading, .trailing]
    @ViewBuilder var content: (EdgeInsets) -> Content

    var body: some View {
        GeometryReader { geo in
            let insets = geo.safeAreaInsets
            content(insets)
                .padding(.top, edges.contains(.top) ? max(insets.top, PlateSpace.safeTopFloor) : 0)
                .padding(.bottom, edges.contains(.bottom) ? max(insets.bottom, PlateSpace.safeBottomFloor) : 0)
                .padding(.leading, edges.contains(.leading) ? insets.leading : 0)
                .padding(.trailing, edges.contains(.trailing) ? insets.trailing : 0)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .ignoresSafeArea(edges: edges)
    }
}

/// Role: YearPlate. Two radii only. Cards 16, chips 10. Never a bare literal in a view.
enum PlateRadius {
    static let card: CGFloat = 16
    static let chip: CGFloat = 10
}
