#if canImport(SwiftUI)
import SwiftUI

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

#Preview {
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
