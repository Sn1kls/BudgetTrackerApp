import XCTest
@testable import BudgetTracker

final class BudgetTrackerTests: XCTestCase {

    func testDecimalValueAcceptsDotAndComma() {
        XCTAssertEqual("12.50".decimalValue, 12.5)
        XCTAssertEqual("12,50".decimalValue, 12.5)
        XCTAssertEqual(" 7 ".decimalValue, 7)
        XCTAssertNil("abc".decimalValue)
        XCTAssertNil("".decimalValue)
    }

    func testApiDayUsesTheLocalCalendarDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let localMidnight = calendar.date(from: DateComponents(year: 2025, month: 6, day: 1))!
        let lateEvening = calendar.date(from: DateComponents(year: 2025, month: 6, day: 1, hour: 23))!

        XCTAssertEqual(localMidnight.apiDay, "2025-06-01")
        XCTAssertEqual(lateEvening.apiDay, "2025-06-01")
    }

    func testErrorMessageComesFromTheResponseBody() {
        let body = Data(#"{"password": ["This password is too short."], "username": ["Taken."]}"#.utf8)
        let error = NetworkError.statusCode(400, message: NetworkError.message(from: body))

        XCTAssertEqual(error.localizedDescription, "This password is too short.\nTaken.")
    }

    func testErrorMessageFallsBackToStatusCode() {
        let error = NetworkError.statusCode(500, message: NetworkError.message(from: Data("oops".utf8)))

        XCTAssertEqual(error.localizedDescription, "Request failed (HTTP 500).")
    }
}
