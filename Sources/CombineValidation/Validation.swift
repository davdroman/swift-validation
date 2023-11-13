@_spi(package) import CoreValidation
import SwiftUI

public typealias CombineValidation<Value, Error> = Validation<Value, Error>

@propertyWrapper
public final class Validation<Value, Error>: ValidationBase<Value, Error>, ObservableObject {
	@_spi(package) public override var state: ValidationState<Value, Error> {
		willSet {
			objectWillChange.send()
		}
	}

	public override var wrappedValue: Value? {
		get { super.wrappedValue }
		set { super.wrappedValue = newValue }
	}
}

#Preview {
	ValidationPreview()
}

struct ValidationPreview: View {
	@ObservedObject
	@Validation({ $name in
		if $name.isUnset { "Cannot be unset" }
		if name.isEmpty { "Cannot be empty" }
		if name.isBlank { "Cannot be blank" }
	})
	var name = ""

	var body: some View {
		VStack(alignment: .leading) {
			TextField(
				"Name",
				text: Binding(validating: $name)
			)
			.textFieldStyle(.roundedBorder)

			if let error = $name.errors?.first {
				Text(error)
					.foregroundColor(.red)
					.font(.footnote)
			} else {
				Text("All good!")
					.foregroundColor(.green)
					.font(.footnote)
			}
		}
		.padding()
	}
}
