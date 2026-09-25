import XCTest
@testable import Isopleth

final class IsoplethTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: IsoplethApp.self), "IsoplethApp")
        XCTAssertEqual(ToneWell.toneCount, 12)
        XCTAssertEqual(PlateClient.userAgent, "Isopleth/1.0 (iOS; +https://isopleth-ridge.pro)")
    }
}
