import CoreValidation
import SwiftUI

extension Binding {
	@MainActor
	public init<Error>(
		validating validation: ObservedObject<Validation<Value, Error>>.Wrapper
	) {
		self.init(validating: validation.projectedValue)
	}
}
