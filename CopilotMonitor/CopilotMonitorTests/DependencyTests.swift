import XCTest
@testable import UsageBar

final class DependencyTests: XCTestCase {
    
    func testMenuResultBuilderExists() {
        let menu = NSMenu {
            MenuItem("Test")
        }
        XCTAssertEqual(menu.items.count, 1)
    }
    
    func testMenuDesignTokenExists() {
        XCTAssertEqual(MenuDesignToken.Dimension.menuWidth, 300)
    }

    func testModelUsageGrouperMergesEquivalentWindows() {
        let resetDate = Date(timeIntervalSince1970: 1_700_000_000)
        let grouped = ModelUsageGrouper.groupedUsageWindows(
            modelBreakdown: [
                "gemini-2.5-pro": 80,
                "gemini-2.5-flash": 80,
                "gemini-2.5-pro-exp": 55
            ],
            modelResetTimes: [
                "gemini-2.5-pro": resetDate,
                "gemini-2.5-flash": resetDate,
                "gemini-2.5-pro-exp": Date(timeIntervalSince1970: 1_700_003_600)
            ]
        )

        XCTAssertTrue(grouped.contains { $0.models == ["gemini-2.5-flash", "gemini-2.5-pro"] })
        XCTAssertTrue(grouped.contains { $0.models == ["gemini-2.5-pro-exp"] })
    }
}
