#if canImport(ValidationMacros)
import MacroTesting
import Testing

@testable import ValidationMacros

@Suite(
	.macros(
		[ValidationContextMacro.self, ValidationContextInitMacro.self],
		indentationWidth: .tab,
		record: .missing
	)
)
struct ValidationMacrosTests {
	@Test func appendsToExistingInit() {
		assertMacro {
			"""
			@ValidationContext
			final class Inputs {
				@Validation
				var inputA: String?

				@OtherWrapper
				var otherWrapper: String?

				var plainValue: Int = 0

				@ValidationWrapper
				var wrappedValue: String?

				@Validation
				var inputB: String?

				@Validation
				static var staticInput: String?

				init() {
					print("ready")
				}
			}
			"""
		} expansion: {
			"""
			final class Inputs {
				@Validation
				var inputA: String?

				@OtherWrapper
				var otherWrapper: String?

				var plainValue: Int = 0

				@ValidationWrapper
				var wrappedValue: String?

				@Validation
				var inputB: String?

				@Validation
				static var staticInput: String?

				init() {
					print("ready")
					$inputA.setContext(self)
					$inputB.setContext(self)
				}
			}

			extension Inputs: ValidationContext {
			}
			"""
		}
	}
}
#endif
