import SwiftUI
import UIKit

/// Role: YearPlate. Presentation stroke and hit sizes. Views never pick raw points.
enum PlateStroke {
    static let hairline: CGFloat = 1
    static let hit: CGFloat = 44
}

/// Role: YearPlate. Locale readout for year, counts, and day labels.
enum PlateReadout {
    static func year(_ value: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func count(_ value: Int, locale: Locale = .current) -> String {
        PlateFigures.integer(value, locale: locale)
    }

    static func day(_ date: Date, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func weekOf(_ date: Date, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar.current
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }

    static func monthDay(_ date: Date, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar.current
        formatter.setLocalizedDateFormatFromTemplate("d")
        return formatter.string(from: date)
    }
}

/// Role: YearPlate. One spring on commit. Everything else eases out. Reduce Motion fades.
enum PlateMotion {
    static func commit(reduceMotion: Bool) -> Animation {
        if reduceMotion {
            return .easeOut(duration: 0.25)
        }
        return .spring(response: 0.4, dampingFraction: 0.8)
    }

    static func travel(reduceMotion: Bool) -> Animation {
        .easeOut(duration: 0.28)
    }
}

/// Role: YearPlate. One haptic on a successful set. None on navigation.
enum PlateHaptic {
    @MainActor
    static func commit() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

/// Role: YearPlate. Primary set-the-tone control. Soft card. Accent only on the live verb.
struct PlateSoftStyle: ButtonStyle {
    var isLoading: Bool = false

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
                .opacity(isLoading ? 0 : 1)
            if isLoading {
                ProgressView()
                    .tint(PlateColor.accent)
                    .accessibilityLabel("Saving")
            }
        }
        .font(PlateFont.headline)
        .foregroundStyle(isEnabled ? PlateColor.accent : PlateColor.muted)
        .frame(maxWidth: .infinity, minHeight: PlateStroke.hit)
        .padding(.horizontal, PlateSpace.n(2))
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
        .scaleEffect(scale(configuration.isPressed))
        .opacity(opacity(configuration.isPressed))
        .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        .contentShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
    }

    private func scale(_ pressed: Bool) -> CGFloat {
        if reduceMotion || isLoading { return 1 }
        return pressed ? 0.98 : 1
    }

    private func opacity(_ pressed: Bool) -> CGFloat {
        if !isEnabled { return 0.55 }
        if pressed { return 0.88 }
        return 1
    }
}

/// Role: YearPlate. Destructive reset. Does not wear accent.
struct PlateEraseStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PlateFont.headline)
            .foregroundStyle(isEnabled ? PlateColor.ink : PlateColor.muted)
            .frame(maxWidth: .infinity, minHeight: PlateStroke.hit)
            .padding(.horizontal, PlateSpace.n(2))
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous)
                    .stroke(PlateColor.muted.opacity(isEnabled ? 0.45 : 0.2), lineWidth: PlateStroke.hairline)
            }
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: PlateRadius.card, style: .continuous))
    }
}

/// Role: YearPlate. Sparse chrome labels. Pressed opacity. Min 44pt.
struct PlateGhostStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PlateFont.caption)
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(isEnabled ? PlateColor.ink : PlateColor.muted)
            .padding(.horizontal, PlateSpace.n(2))
            .frame(minWidth: PlateStroke.hit, minHeight: PlateStroke.hit)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: PlateRadius.chip, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: PlateRadius.chip, style: .continuous))
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
            .opacity(configuration.isPressed ? 0.7 : (isEnabled ? 1 : 0.55))
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// Role: YearPlate. Well tone press. Scale, not a second radius.
struct PlatePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.96 : 1))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

