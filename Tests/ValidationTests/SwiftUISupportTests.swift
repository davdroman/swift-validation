#if canImport(SwiftUI)
import SwiftUI
@testable import Validation
import ViewInspector
import XCTest

final class SwiftUISupportTests: XCTestCase {
	func testViewBinding() throws {
		struct SUT: View {
			@ObservedObject
			@Validation({ input in
				switch input {
				case nil: "Cannot be nil"
				case let input?:
					if input.isEmpty { "Cannot be empty" }
					if input.isBlank { "Cannot be blank" }
				}
			})
			var name: String? = nil

			var didAppear: ((Self) -> Void)?

			var body: some View {
				VStack(alignment: .leading) {
					TextField(
						"Name",
						text: Binding(validating: $name, default: "")
					)
					.textFieldStyle(.roundedBorder)

					if let error = $name.readOnlyProjectedValue.errors?.first {
						Text(error)
							.foregroundColor(.red)
							.font(.footnote)
					} else {
						Text("All good!")
							.foregroundColor(.green)
							.font(.footnote)
					}
				}
				.padding()
				.onAppear { didAppear?(self) }
			}
		}

		var sut = SUT()
		let exp = sut.on(\.didAppear) { sut in
			XCTAssertNoThrow(try sut.find(text: "Cannot be nil"))
			XCTAssertEqual(try sut.actualView().$name.readOnlyProjectedValue.errors?.rawValue, ["Cannot be nil"])

			try sut.find(ViewType.TextField.self).setInput("")

			XCTAssertNoThrow(try sut.find(text: "Cannot be empty"))
			XCTAssertEqual(try sut.actualView().$name.readOnlyProjectedValue.errors?.rawValue, ["Cannot be empty", "Cannot be blank"])

			try sut.find(ViewType.TextField.self).setInput(" ")

			XCTAssertNoThrow(try sut.find(text: "Cannot be blank"))
			XCTAssertEqual(try sut.actualView().$name.readOnlyProjectedValue.errors?.rawValue, ["Cannot be blank"])

			try sut.find(ViewType.TextField.self).setInput(" D")

			XCTAssertNoThrow(try sut.find(text: "All good!"))
			XCTAssertEqual(try sut.actualView().$name.readOnlyProjectedValue.errors, nil)
		}
		ViewHosting.host(view: sut)
		wait(for: [exp])
	}

	func testIsolatedBinding() {
		let validation = Validation { (input: String?) in
			switch input {
			case nil: "Cannot be nil"
			case let input?:
				if input.isEmpty { "Cannot be empty" }
				if input.isBlank { "Cannot be blank" }
			}
		}

		let sut = Binding(
			validating: ObservedObject(wrappedValue: validation).projectedValue,
			default: ""
		)
		XCTAssertEqual(sut.wrappedValue, "")
		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be nil"))

		sut.wrappedValue = ""
		XCTAssertEqual(sut.wrappedValue, "")
		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be empty", "Cannot be blank"))

		sut.wrappedValue = " "
		XCTAssertEqual(sut.wrappedValue, " ")
		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be blank"))

		sut.wrappedValue = "  "
		XCTAssertEqual(sut.wrappedValue, "  ")
		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be blank"))
	}
}
#endif
