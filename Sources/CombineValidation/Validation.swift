@_spi(package) import CoreValidation
import SwiftUI

public typealias CombineValidation<Value, Error> = Validation<Value, Error>

@propertyWrapper
public final class Validation<Value, Error>: ValidationBase<Value, Error>, ObservableObject {
	@_spi(package) public override var state: _ValidationState<Value, Error> {
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
		let _ = await {
			do { try await Task.sleep(nanoseconds: NSEC_PER_SEC/2) }
			catch { print(error) }
		}()
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

			Group {
				switch $name.phase {
				case .idle:
					EmptyView()
				case .validating:
					Text("Validating...").foregroundColor(.gray)
				case .invalid(let errors):
					if let error = errors.first {
						Text(error).foregroundColor(.red)
					}
				case .valid:
					Text("All good!").foregroundColor(.green)
				}
			}
			.font(.footnote)
		}
		.padding()
	}
}
