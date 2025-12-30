#if canImport(SwiftUI)
public import SwiftUI

//public typealias LocalizedValidation<Value> = Validation<Value, LocalizedStringKey?>

// TODO: flatten double optionals
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
}

@MainActor
extension Binding {
	public subscript<V>(
		dynamicMember keyPath: KeyPath<Value, Validation<V, some Any, some Any>>
	) -> Binding<V?> {
		Binding<V?>(
			get: { self.wrappedValue[keyPath: keyPath].rawValue },
			set: { newValue, transaction in
				self.transaction(transaction).wrappedValue[keyPath: keyPath].wrappedValue = newValue
			}
		)
	}
}

@MainActor
extension Bindable {
	public subscript<V>(
		dynamicMember keyPath: KeyPath<Value, Validation<V, some Any, some Any>>
	) -> Binding<V?> {
		Binding<V?>(
			get: { self.wrappedValue[keyPath: keyPath].rawValue },
			set: { newValue in
				self.wrappedValue[keyPath: keyPath].wrappedValue = newValue
			}
		)
	}
}

@MainActor
extension Binding {
	public func `default`<Wrapped>(
		_ defaultValue: Wrapped
	) -> Binding<Wrapped> where Value == Wrapped? {
		Binding<Wrapped>(
			get: { self.wrappedValue ?? defaultValue },
			set: { newValue, transaction in
				self.transaction(transaction).wrappedValue = newValue
			}
		)
	}

	public func `default`<Wrapped: Equatable>(
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
	init() {
		$inputA.setContext(self)
	}

	@ObservationIgnored
	@Validation(traits: .animation(.smooth(duration: 0.1)), rules: { (input, inputs: Inputs) in
		switch input {
		case nil: "Cannot be nil"
		case let input?:
			if input.isEmpty { "Cannot be empty" }
			if input.allSatisfy(\.isWhitespace) { "Cannot be blank" }
		}
	})
	var inputA: String?

	@ObservationIgnored
	@Validation(traits: .animation(.smooth(duration: 0.1)), rules: { input in
		switch input {
		case nil: "Cannot be nil"
		case let input?:
			if input.isEmpty { "Cannot be empty" }
			if input.allSatisfy(\.isWhitespace) { "Cannot be blank" }
		}
	})
	var inputB: String?
}

struct PreviewView: View {
	@Bindable var inputs: Inputs

	var body: some View {
		VStack(alignment: .leading) {
			TextField("A", text: $inputs.$inputA.default(""))
				.textFieldStyle(.roundedBorder)

			if let error = inputs.$inputA.errors?.first {
				Text(error)
					.foregroundColor(.red)
					.font(.footnote)
			}

			TextField("B", text: $inputs.$inputB.default(""))
				.textFieldStyle(.roundedBorder)

			if let error = inputs.$inputB.errors?.first {
				Text(error)
					.foregroundColor(.red)
					.font(.footnote)
			}
		}
		.padding()
	}
}

#Preview("@State") {
	@Previewable @State var inputs = Inputs()

	PreviewView(inputs: inputs)
}
#endif
#endif
