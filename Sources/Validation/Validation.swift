@_spi(package) import CoreValidation
#if canImport(Observation)
import Observation
#endif

@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
public typealias SwiftValidation<Value, Error> = Validation<Value, Error>

@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
@propertyWrapper
#if canImport(Observation)
@Observable
#endif
public final class Validation<Value, Error>: ValidationBase<Value, Error> {
	@_spi(package) public override var state: ValidationState<Value, Error> {
		get {
			access(keyPath: \.state)
			return super.state
		}
		set {
			withMutation(keyPath: \.state) {
				super.state = newValue
			}
		}
	}

	public override var wrappedValue: Value? {
		get { super.wrappedValue }
		set { super.wrappedValue = newValue }
	}
}

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
#Preview {
	ValidationPreview()
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
@MainActor
struct ValidationPreview: View {
	@State
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
