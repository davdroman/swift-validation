#if canImport(SwiftUI)
import CoreValidation
import SwiftUI

@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
extension Binding {
	@MainActor
	public init<Error>(
		validating validation: Binding<Validation<Value, Error>>
	) {
		self.init(
			get: { validation.wrappedValue.rawValue },
			set: { validation.wrappedValue.wrappedValue = $0 }
		)
	}
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
extension Binding {
	@MainActor
	public subscript<_Value, Error, T>(
		dynamicMember keyPath: KeyPath<_ValidationState<_Value, Error>, T>
	) -> T where Value == Validation<_Value, Error> {
		wrappedValue.state[keyPath: keyPath]
	}
}
#endif
