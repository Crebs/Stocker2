@testable import App
import XCTest

final class FinancialTests: XCTestCase {
    func testFinancialInitialization() {
        let financial = Financial(date: "2021-01-01", freeCashFlowPerShare: 5.0, roic: 0.1)
        XCTAssertEqual(financial.date, "2021-01-01")
        XCTAssertEqual(financial.freeCashFlowPerShare, 5.0)
        XCTAssertEqual(financial.roic, 0.1)
    }
}
