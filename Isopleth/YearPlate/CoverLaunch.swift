import Foundation

/// Role: YearPlate. `-ReviewScreen` launch keys. Read once after onboarding. Not tabs.
enum CoverLaunch: Equatable, Sendable {
    case today
    case log
    case goals
    case extra(String)

    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> CoverLaunch? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        let token = arguments[next]
        switch token {
        case "today":
            return .today
        case "log":
            return .log
        case "goals":
            return .goals
        default:
            guard !token.isEmpty, !token.hasPrefix("-") else { return nil }
            return .extra(token)
        }
    }
}
