public typealias ObservableValidation<Value, Error> = Validation<Value, Error>

#if canImport(SwiftUI)
import SwiftUI

#Preview {
	ValidationPreview()
}

@MainActor
struct ValidationPreview: View {
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

#endif
