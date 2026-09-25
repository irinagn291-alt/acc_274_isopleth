import Foundation

/// Role: YearPlate. Spot, ridge, loop, and streak counts go through NumberFormatter.
enum PlateFigures {
    static func integer(_ value: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
