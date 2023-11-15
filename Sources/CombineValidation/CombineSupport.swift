import CoreValidation
import SwiftUI

extension Binding {
	@MainActor
	public init<Error>(
		validating validation: ObservedObject<Validation<Value, Error>>.Wrapper
	) {
		self.init(
			get: { validation.proxySelf.rawValue },
			set: { validation.wrappedValue.wrappedValue = $0 }
		)
	}
}

extension ObservedObject.Wrapper {
	public subscript<Value, Error, Subject>(
		dynamicMember keyPath: KeyPath<ObjectType, Subject>
	) -> Subject where ObjectType == Validation<Value, Error> {
		let baseBinding = self.proxySelf as Binding<ValidationBase<Value, Error>>
		let validation = baseBinding.wrappedValue as! Validation<Value, Error>
		return validation[keyPath: keyPath]
	}
}
