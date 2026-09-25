import XCTest
@testable import Isopleth

final class CoverLaunchTests: XCTestCase {
    func test_readsReviewScreenOnceAfterOnboarding() {
        var consumed = false
        let today = CoverLaunch.consume(
            arguments: ["-ReviewScreen", "today"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(today, .today)
        XCTAssertTrue(consumed)

        let again = CoverLaunch.consume(
            arguments: ["-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertNil(again)
    }

    func test_todayLogGoalsAreThreeDifferentKeys() {
        XCTAssertNotEqual(CoverLaunch.today, CoverLaunch.log)
        XCTAssertNotEqual(CoverLaunch.log, CoverLaunch.goals)
        XCTAssertNotEqual(CoverLaunch.today, CoverLaunch.goals)

        var consumed = false
        XCTAssertEqual(
            CoverLaunch.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .log
        )
        consumed = false
        XCTAssertEqual(
            CoverLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .goals
        )
        consumed = false
        XCTAssertEqual(
            CoverLaunch.consume(
                arguments: ["-ReviewScreen", "well"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .extra("well")
        )
    }

    func test_skipsUntilOnboardingCompletes() {
        var consumed = false
        let skipped = CoverLaunch.consume(
            arguments: ["-ReviewScreen", "log"],
            onboardingComplete: false,
            consumed: &consumed
        )
        XCTAssertNil(skipped)
        XCTAssertFalse(consumed)
        let later = CoverLaunch.consume(
            arguments: ["-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(later, .log)
    }

    func test_missingValueIsNil() {
        var consumed = false
        let empty = CoverLaunch.consume(
            arguments: ["-ReviewScreen"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertNil(empty)
        XCTAssertTrue(consumed)
    }
}
