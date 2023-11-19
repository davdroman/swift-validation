import Builders
import CoreValidation
import NonEmpty
import SwiftUI

@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
public typealias ObservableValidationState<Value, Error> = ValidationState<Value, Error>

@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
@MainActor
@propertyWrapper
public struct ValidationState<Value, Error>: DynamicProperty {
	@State
	@Validation<Value, Error>
	var state: Value?

	public init(
		wrappedValue rawValue: Value,
		of rules: ValidationRules<Value, Error>,
		mode: ValidationMode = .automatic
	) {
		self._state = State(
			initialValue: Validation(
				wrappedValue: rawValue,
				of: rules,
				mode: mode
			)
		)
	}

	public init(
		wrappedValue rawValue: Value,
		mode: ValidationMode = .automatic,
		@ArrayBuilder<Error> _ handler: @escaping ValidationRulesHandler<Value, Error>
	) {
		self._state = State(
			initialValue: Validation(
				wrappedValue: rawValue,
				mode: mode,
				handler
			)
		)
	}

	public var wrappedValue: Value? {
		get { state }
		set { state = newValue }
	}

	public var projectedValue: Validation<Value, Error> {
		_state.wrappedValue
	}
}
