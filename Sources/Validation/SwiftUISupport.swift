#if canImport(SwiftUI)
public import SwiftUI

//public typealias LocalizedValidation<Value> = Validation<Value, LocalizedStringKey?>

@MainActor
extension Binding {
	public init<Wrapped>(
		_ validation: Validation<Wrapped, some Any, some Any>
	) where Value == Wrapped? {
		self.init(
			get: { validation.rawValue },
			set: { validation.wrappedValue = $0 }
		)
	}

	public init(
		_ validation: Validation<Value, some Any, some Any>,
		default defaultValue: Value
	) {
		self.init(
			get: { validation.rawValue ?? defaultValue },
			set: { validation.wrappedValue = $0 }
		)
	}

	public init(
		_ validation: Validation<Value, some Any, some Any>,
		default defaultValue: Value,
		nilOnDefault: Bool = false
	) where Value: Equatable {
		self.init(
			get: { validation.rawValue ?? defaultValue },
			set: {
				if nilOnDefault && $0 == defaultValue {
					validation.wrappedValue = nil
				} else {
					validation.wrappedValue = $0
				}
			}
		)
	}
}

@MainActor
extension Binding {
	subscript<V>(
		dynamicMember keyPath: KeyPath<Value, Validation<V, some Any, some Any>>
	) -> Binding<V?> {
		Binding<V?>(
			get: { self.wrappedValue[keyPath: keyPath].rawValue },
			set: { newValue, transaction in
				self.transaction(transaction).wrappedValue[keyPath: keyPath].wrappedValue = newValue
			}
		)
	}

	func `default`<Wrapped>(
		_ defaultValue: Wrapped
	) -> Binding<Wrapped> where Value == Wrapped? {
		Binding<Wrapped>(
			get: { self.wrappedValue ?? defaultValue },
			set: { newValue, transaction in
				self.transaction(transaction).wrappedValue = newValue
			}
		)
	}

	func `default`<Wrapped: Equatable>(
		_ defaultValue: Wrapped,
		nilOnDefault: Bool = false
	) -> Binding<Wrapped> where Value == Wrapped? {
		Binding<Wrapped>(
			get: { self.wrappedValue ?? defaultValue },
			set: { newValue, transaction in
				if nilOnDefault && newValue == defaultValue {
					self.transaction(transaction).wrappedValue = nil
				} else {
					self.transaction(transaction).wrappedValue = newValue
				}
			}
		)
	}
}

#if DEBUG
//struct BarePreview: View {
//	lazy var name = Validation<String, String, Void>(context: ()) { name, context in
//		let _ = await {
//			do { try await Task.sleep(nanoseconds: NSEC_PER_SEC/2) }
//			catch { print(error) }
//		}()
//		switch name {
//		case nil:
//			"Cannot be unset"
//		case let name?:
//			if name.isEmpty { "Cannot be empty" }
//			if name.isBlank { "Cannot be blank" }
//		}
//	}
//
//	var body: some View {
////		VStack(alignment: .leading) {
////			TextField(
////				"Name",
////				//			text: Binding($name, default: "")
////				text: Binding(name).default("")
////			)
////			.textFieldStyle(.roundedBorder)
////
////			Group {
////				switch name.phase {
////				case .idle:
////					EmptyView()
////				case .validating:
////					Text("Validating...").foregroundColor(.gray)
////				case .invalid(let errors):
////					if let error = errors.first {
////						Text(error).foregroundColor(.red)
////					}
////				case .valid:
////					Text("All good!").foregroundColor(.green)
////				}
////			}
////			.font(.footnote)
////		}
////		.padding()
//	}
//}

//#Preview("Bare") {
//	@Previewable
//	lazy var name = Validation<String, String, Inputs>(context: self) { input, inputs in
//		let _ = await {
//			do { try await Task.sleep(nanoseconds: NSEC_PER_SEC/2) }
//			catch { print(error) }
//		}()
//		switch name {
//		case nil:
//			"Cannot be unset"
//		case let name?:
//			if name.isEmpty { "Cannot be empty" }
//			if name.isBlank { "Cannot be blank" }
//		}
//	}
//
//	VStack(alignment: .leading) {
//		TextField(
//			"Name",
////			text: Binding($name, default: "")
//			text: Binding($name).default("")
//		)
//		.textFieldStyle(.roundedBorder)
//
//		Group {
//			switch $name.phase {
//			case .idle:
//				EmptyView()
//			case .validating:
//				Text("Validating...").foregroundColor(.gray)
//			case .invalid(let errors):
//				if let error = errors.first {
//					Text(error).foregroundColor(.red)
//				}
//			case .valid:
//				Text("All good!").foregroundColor(.green)
//			}
//		}
//		.font(.footnote)
//	}
//	.padding()
//}

@MainActor
@Observable
final class Inputs {
//	@ObservationIgnored
//	@Validation({ input in
//		switch input {
//		case nil: "Cannot be nil"
//		case let input?:
//			if input.isEmpty { "Cannot be empty" }
//			if input.isBlank { "Cannot be blank" }
//		}
//	})
	@Validation({ input, inputs in
		switch input {
		case nil: "Cannot be nil"
		case let input?:
			if input.isEmpty { "Cannot be empty" }
			if input.isBlank { "Cannot be blank" }
		}
	})
	var inputA: String?

	// synthesizes:
	lazy var $inputA = Validation<String, _, _>(context: self) { input, inputs in
		switch input {
		case nil: "Cannot be nil"
		case let input?:
			if input.isEmpty { "Cannot be empty" }
			if input.isBlank { "Cannot be blank" }
		}
	}
	var inputA: String? {
		get { $inputA.wrappedValue }
		set { $inputA.wrappedValue = newValue }
	}

//	@ObservationIgnored
//	@Validation({ input in
//		switch input {
//		case nil: "Cannot be nil"
//		case let input?:
//			if input.isEmpty { "Cannot be empty" }
//			if input.isBlank { "Cannot be blank" }
//		}
//	})
//	var inputB: String?

	@ObservationIgnored
	lazy var inputB = Validation<String, String, Inputs>(context: self) { input, inputs in
		switch input {
		case nil: "Cannot be nil"
		case let input?:
			if input.isEmpty { "Cannot be empty" }
			if input.isBlank { "Cannot be blank" }
		}
	}

	@ObservationIgnored
	lazy var inputC = Validation<String, String, Void>(context: ()) { input, inputs in
		switch input {
		case nil: "Cannot be nil"
		case let input?:
			if input.isEmpty { "Cannot be empty" }
			if input.isBlank { "Cannot be blank" }
		}
	}
}

#Preview("@State") {
	@Previewable @State var inputs = Inputs()

	VStack(alignment: .leading) {
		TextField(
			"Name",
			text: Binding(inputs.$inputA, default: "")
//			text: $inputs.$inputA.default("")
		)
		.textFieldStyle(.roundedBorder)

		if let error = inputs.$inputA.errors?.first {
			Text(error)
				.foregroundColor(.red)
				.font(.footnote)
		}

		// this shows the thread hop
		//		Group {
		//			switch inputs.$inputA.phase {
		//			case .idle:
		//				EmptyView()
		//			case .validating:
		//				Text("Validating...").foregroundColor(.gray)
		//			case .invalid(let errors):
		//				if let error = errors.first {
		//					Text(error).foregroundColor(.red)
		//				}
		//			case .valid:
		//				Text("All good!").foregroundColor(.green)
		//			}
		//		}
	}
	//	.animation(.smooth(duration: 0.1), value: inputs.$inputA.phase)
	.padding()
}
#endif
#endif
