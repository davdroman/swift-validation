#if canImport(SwiftUI)
import SwiftUI

// Binding Extras

fileprivate func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
	.init(
		get: { lhs.wrappedValue ?? rhs },
		set: { lhs.wrappedValue = $0 }
	)
}

// MARK: Vanilla SwiftUI Validation

extension Binding {
	@_disfavoredOverload
	public static func validation<Value, Error>(
		_ validation: Binding<Validation<Value, Error>>
	) -> Binding<Value?> {
		.init(
			get: { validation.wrappedValue.rawValue },
			set: { validation.wrappedValue.wrappedValue = $0 }
		)
	}

	public static func validation<S: StringProtocol, Error>(
		_ validation: Binding<Validation<S, Error>>
	) -> Binding<S> {
		.validation(validation) ?? ""
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
struct VanillaValidationPreview: PreviewProvider {
	static var previews: some View {
		VanillaValidationView()
	}
}

struct VanillaValidationView: View {
	@State
	@Validation<String, String>(
		onNil: "Cannot be nil",
		rules: [
			.if(\.isEmpty, error: "Cannot be empty"),
			.if(\.isBlank, error: "Cannot be blank"),
		]
	)
	var name: String? = nil

	var body: some View {
		VStack(alignment: .leading) {
			TextField(
				"Name",
				text: .validation($name)
			)
			.textFieldStyle(.roundedBorder)

			if let error = $name.errors?.first {
				Text(error)
					.foregroundColor(.red)
					.font(.footnote)
			}
		}
		.padding()
	}
}

extension String {
	var isBlank: Bool {
		self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
}
#endif
#endif
