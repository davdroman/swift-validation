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
			@MainActor
			@ValidationContext(traits: .debounce(for: .seconds(1)), .debounce(for: .seconds(2)))
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
			@MainActor
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
				nonisolated var validationTraits: [any ValidationTrait] {
					[.debounce(for: .seconds(1)), .debounce(for: .seconds(2))]
				}
			}
			"""
		}
	}
}
#endif
