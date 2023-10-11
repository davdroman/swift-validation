#if canImport(SwiftUI)
import SwiftUI

extension Binding {
	public init<Error>(
		validating validation: ObservedObject<Validation<Value, Error>>.Wrapper,
		default: Value
	) {
		self.init(
			get: { validation.rawValue.wrappedValue ?? `default` },
			set: { validation.wrappedValue.wrappedValue = $0 }
		)
	}

	public init<Wrapped, Error>(
		validating validation: Binding<Validation<Wrapped, Error>>
	) where Value == Wrapped? {
		self.init(
			get: { validation.wrappedValue.rawValue },
			set: { validation.wrappedValue.wrappedValue = $0 }
		)
	}
}

extension Binding {
	public subscript<V, Error, T>(
		dynamicMember keyPath: KeyPath<Validated<V, Error>, T?>
	) -> T? where Value == Validation<V, Error> {
		wrappedValue.validated?[keyPath: keyPath]
	}
}

#if DEBUG
// TODO: use #BetterPreview macro
@available(iOS 14.0, *)
struct ValidationPreview: PreviewProvider {
	static var previews: some View {
		ValidationView()
	}

	struct ValidationView: View {
		@StateObject
		@Validation({ input in
			switch input {
			case nil: "Cannot be nil"
			case let input?:
				if input.isEmpty { "Cannot be empty" }
				if input.isBlank { "Cannot be blank" }
			}
		})
		var name: String? = nil

		var body: some View {
			VStack(alignment: .leading) {
				TextField(
					"Name",
					text: Binding(validating: $name, default: "")
				)
				.textFieldStyle(.roundedBorder)

				if let error = $name.readOnlyProjectedValue.errors?.first {
					Text(error)
						.foregroundColor(.red)
						.font(.footnote)
				}
			}
			.padding()
		}
	}
}
#endif
#endif
