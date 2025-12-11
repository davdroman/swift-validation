#if canImport(ValidationMacro)
import MacroTesting
import Testing
@testable import ValidationMacro

@Suite(
	.macros(
		["Validation": ValidationMacro.self],
		indentationWidth: .tab,
		record: .missing
	)
)
struct ValidationMacroTests {
	@Test
	func synthesizesStorageAndAccessors() {
		assertMacro {
			"""
			struct Inputs {
				@Validation({ input, inputs in
					if input == nil { "Cannot be nil" }
					if inputs.description.isEmpty { "Missing context" }
				})
				var name: String?
			}
			"""
		} expansion: {
			"""
			struct Inputs {
				var name: String? {
					get {
						return $name.wrappedValue
					}
					set {
						$name.wrappedValue = newValue
					}
				}

				lazy var $name = Validation<String, _, _>(context: self) { input, inputs in
						if input == nil {
							"Cannot be nil"
						}
						if inputs.description.isEmpty {
							"Missing context"
						}
					}
			}
			"""
		}
	}

	@Test
	func something() {
		assertMacro {
			"""
			@Validation<String, String, Inputs>({ input, inputs in
				switch input {
				case nil: "Cannot be nil"
				case let input?:
					if input.isEmpty { "Cannot be empty" }
					if input.isBlank { "Cannot be blank" }
				}
			})
			var inputA: String?
			"""
		} expansion: {
			"""
			var inputA: String? {
				get {
					return $inputA.wrappedValue
				}
				set {
					$inputA.wrappedValue = newValue
				}
			}

			lazy var $inputA = Validation<String, String, Inputs>(context: self) { input, inputs in
				switch input {
				case nil:
					"Cannot be nil"
				case let input?:
					if input.isEmpty {
						"Cannot be empty"
					}
					if input.isBlank {
						"Cannot be blank"
					}
				}
			}
			"""
		}
	}

	@Test
	func respectsInitialValueAndContextArgument() {
		assertMacro {
			"""
			struct Inputs {
				@Validation(context: self.dependency, mode: .manual, { input, _ in
					input ?? "Default"
				})
				var name: String? = ""
			}
			"""
		} expansion: {
			"""
			struct Inputs {
				var name: String? {
					get {
						return $name.wrappedValue
					}
					set {
						$name.wrappedValue = newValue
					}
				}

				lazy var $name = Validation<String, _, _>(wrappedValue: "", context: self.dependency, mode: .manual) { input, _ in
						input ?? "Default"
					}
			}
			"""
		}
	}
}
#endif
