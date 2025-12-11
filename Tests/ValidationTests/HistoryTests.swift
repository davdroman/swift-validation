//import Validation
//import XCTest
//
//final class HistoryTests: XCTestCase {
//	func test() {
//		@ValidationInput var name = "Jim"
//
//		XCTAssertEqual(name, "Jim")
//		XCTAssertEqual($name.oldValues, [])
//
//		name = "James"
//
//		XCTAssertEqual(name, "James")
//		XCTAssertEqual($name.oldValues, ["Jim"])
//
//		name = "Jimothy"
//
//		XCTAssertEqual(name, "Jimothy")
//		XCTAssertEqual($name.oldValues, ["Jim", "James"])
//
//		name = "Jim"
//
//		XCTAssertEqual(name, "Jim")
//		XCTAssertEqual($name.oldValues, ["Jim", "James", "Jimothy"])
//	}
//}
