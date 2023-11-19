import Builders
import CoreValidation
import NonEmpty
import SwiftUI

@MainActor
@propertyWrapper
public struct ValidationState<Value, Error>: DynamicProperty {
	@ObservedObject
	@Validation<Value, Error>
	var value: Value?

	public init(
		wrappedValue rawValue: Value,
		of rules: ValidationRules<Value, Error>,
		mode: ValidationMode = .automatic
	) {
		self._value = ObservedObject(
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
		self._value = ObservedObject(
			initialValue: Validation(
				wrappedValue: rawValue,
				mode: mode,
				handler
			)
		)
	}

	public var wrappedValue: Value? {
		get { value }
		set { value = newValue }
	}

	public var projectedValue: Validation<Value, Error> {
		_value.wrappedValue
	}
}
