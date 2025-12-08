#if canImport(SwiftUI)
public import SwiftUI

//public typealias LocalizedValidation<Value> = Validation<Value, LocalizedStringKey?>

@MainActor
extension Binding {
	public init<Error>(
		_ validation: Validation<Value, Error>
	) {
		self.init(
			get: { validation.rawValue },
			set: { validation.wrappedValue = $0 }
		)
	}

	public init<Error>(
		_ validation: Validation<Value?, Error>,
		default defaultValue: Value
	) {
		self.init(
			get: { validation.rawValue ?? defaultValue },
			set: { validation.wrappedValue = $0 }
		)
	}
}

#if DEBUG
#Preview("Bare") {
	@Previewable @Validation({ $name in
		let _ = await {
			do { try await Task.sleep(nanoseconds: NSEC_PER_SEC/2) }
			catch { print(error) }
		}()
		if $name.isUnset { "Cannot be unset" }
		if name.isEmpty { "Cannot be empty" }
		if name.isBlank { "Cannot be blank" }
	})
	var name = ""

	VStack(alignment: .leading) {
		TextField(
			"Name",
			text: Binding($name)
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

@MainActor
@Observable
final class Inputs {
	@ObservationIgnored
	@Validation<String?, String>({ $input in
		switch input {
		case nil: "Cannot be nil"
		case let input?:
			if input.isEmpty { "Cannot be empty" }
			if input.isBlank { "Cannot be blank" }
		}
	})
	var inputA = nil

	@ObservationIgnored
	@Validation<String?, String>({ $input in
		switch input {
		case nil: "Cannot be nil"
		case let input?:
			if input.isEmpty { "Cannot be empty" }
			if input.isBlank { "Cannot be blank" }
		}
	})
	var inputB = nil
}

#Preview("@State") {
	@Previewable @State var inputs = Inputs()

	VStack(alignment: .leading) {
		TextField(
			"Name",
			text: Binding(inputs.$inputA, default: "")
		)
		.textFieldStyle(.roundedBorder)

		if let error = inputs.$inputA.errors?.first {
			Text(error)
				.foregroundColor(.red)
				.font(.footnote)
		}
	}
	.padding()
}
#endif
#endif
