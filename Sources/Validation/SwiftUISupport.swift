#if canImport(SwiftUI)
import CoreValidation
import SwiftUI

@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
extension Binding {
	@MainActor
	public init<Error>(
		validating validation: Validation<Value, Error>
	) {
		self.init(
			get: { validation.rawValue },
			set: { validation.wrappedValue = $0 }
		)
	}
}
#endif
