#if canImport(SwiftUI)
import SwiftUI

extension Binding {
	public init<Error>(
		validating validation: Binding<ValidationBase<Value, Error>>,
		default: Value
	) {
		self.init(
			get: { validation.wrappedValue.rawValue ?? `default` },
			set: { validation.wrappedValue.wrappedValue = $0 }
		)
	}

	public init<Wrapped, Error>(
		validating validation: Binding<ValidationBase<Wrapped, Error>>
	) where Value == Wrapped? {
		self.init(
			get: { validation.wrappedValue.rawValue },
			set: { validation.wrappedValue.wrappedValue = $0 }
		)
	}
}

extension Binding {
	public subscript<V, Error, T>(
		dynamicMember keyPath: KeyPath<ValidationState<V, Error>, T?>
	) -> T? where Value == ValidationBase<V, Error> {
		wrappedValue.state[keyPath: keyPath]
	}
}

//#if DEBUG
//// TODO: use #BetterPreview macro
//@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
//struct ValidationPreview: PreviewProvider {
//	static var previews: some View {
//		ValidationView()
//	}
//
//	struct ValidationView: View {
//		@Observable
//		final class Inputs {
//			@ObservationIgnored
//			@Validation({ input in
//				switch input {
//				case nil: "Cannot be nil"
//				case let input?:
//					if input.isEmpty { "Cannot be empty" }
//					if input.isBlank { "Cannot be blank" }
//				}
//			})
//			var inputA: String? = nil
//
//			@ObservationIgnored
//			@Validation({ input in
//				switch input {
//				case nil: "Cannot be nil"
//				case let input?:
//					if input.isEmpty { "Cannot be empty" }
//					if input.isBlank { "Cannot be blank" }
//				}
//			})
//			var inputB: String? = nil
//		}
//
//		@State
//		var inputs = Inputs()
//
//		var body: some View {
//			VStack(alignment: .leading) {
//				TextField(
//					"Name",
//					text: Binding(validating: $inputs.$inputA, default: "")
//				)
//				.textFieldStyle(.roundedBorder)
//
//				if let error = $inputs.$inputA.errors?.first {
//					Text(error)
//						.foregroundColor(.red)
//						.font(.footnote)
//				}
//			}
//			.padding()
//		}
//	}
//}
//#endif
#endif
