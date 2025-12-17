public import Builders
import Dependencies
public import Observation

@MainActor
@Observable
@propertyWrapper
@dynamicMemberLookup
public final class Validation<Value: Sendable, Error: Sendable, Context: Sendable>: Sendable {
	public typealias Rules = ValidationRules<Value, Error, Context>
	public typealias Phase = ValidationPhase<Value, Error>

	@ObservationIgnored
	private let rules: Rules
	@ObservationIgnored
	private let defaultValue: Value?
	@ObservationIgnored
	private let mode: ValidationMode
	@ObservationIgnored
	private weak var _context: AnyObject?
	private var context: Context? {
		if Context.self == Void.self {
			return (() as! Context)
		} else {
			return _context as? Context
		}
	}

	private(set) var rawValue: Value?
	public internal(set) var phase: Phase

	public subscript<T>(dynamicMember keyPath: KeyPath<Phase, T>) -> T {
		phase[keyPath: keyPath]
	}

	@ObservationIgnored
	private var task: Task<Void, Never>?

	private init(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		defaultValue: Value?,
		context: Context?,
		mode: ValidationMode = .automatic
	) {
		self.rawValue = rawValue
		self.phase = .idle
		self.rules = rules
		self.defaultValue = defaultValue
		self._context = context as? AnyObject
		self.mode = mode

//		withoutAnimations {
			self.validateIfPossible(reportIssue: false)
//		}
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		mode: ValidationMode = .automatic
	) where Context == Void {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: nil, context: nil, mode: mode)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		context: Context? = nil,
		mode: ValidationMode = .automatic
	) where Context: AnyObject {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: nil, context: context, mode: mode)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		mode: ValidationMode = .automatic,
		@ArrayBuilder<Error> _ handler: @escaping ValidationRulesHandler<Value, Error>
	) where Context == Void {
		self.init(wrappedValue: rawValue, of: Rules(handler: handler), defaultValue: nil, context: nil, mode: mode)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		context: Context? = nil,
		mode: ValidationMode = .automatic,
		@ArrayBuilder<Error> _ handler: @escaping ValidationRulesHandlerWithContext<Value, Error, Context>
	) where Context: AnyObject {
		self.init(wrappedValue: rawValue, of: Rules(handler: handler), defaultValue: nil, context: context, mode: mode)
	}

	// MARK: support for double optionals

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		mode: ValidationMode = .automatic
	) where Value == Wrapped?, Context == Void {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: .some(nil), context: nil, mode: mode)
	}

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		context: Context? = nil,
		mode: ValidationMode = .automatic
	) where Value == Wrapped? {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: .some(nil), context: context, mode: mode)
	}

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		mode: ValidationMode = .automatic,
		@ArrayBuilder<Error> _ handler: @escaping ValidationRulesHandlerWithContext<Value, Error, Context>
	) where Value == Wrapped?, Context == Void {
		self.init(wrappedValue: rawValue, of: Rules(handler: handler), defaultValue: .some(nil), context: nil, mode: mode)
	}

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		context: Context? = nil,
		mode: ValidationMode = .automatic,
		@ArrayBuilder<Error> _ handler: @escaping ValidationRulesHandlerWithContext<Value, Error, Context>
	) where Value == Wrapped? {
		self.init(wrappedValue: rawValue, of: Rules(handler: handler), defaultValue: .some(nil), context: context, mode: mode)
	}

	public var wrappedValue: Value? {
		get {
			phase.value
		}
		set {
			let oldValue = rawValue
			let hasValueChanged = !equals(oldValue as Any, newValue as Any)
			guard hasValueChanged else { return }

			rawValue = newValue
			validateIfPossible()
		}
	}

	public var projectedValue: Validation {
		self
	}

	public func setContext(_ context: Context) where Context: AnyObject {
		self._context = context
		withoutAnimations {
			validateIfPossible()
		}
	}

	private func validateIfPossible(reportIssue report: Bool = true) {
		if let context {
			validate(in: context)
		} else if report {
			reportIssue(
				"""
				Validation value mutated without context.

				Validation cannot be performed without a context.

				Please set the context using the `$<property>.setContext(_:)` method before mutating the value — ideally in the initializer of the enclosing type.
				"""
			)
		}
	}

	private func validate(in context: Context) {
		task?.cancel()
		task = Task {
			if let delay = mode.delay {
				@Dependency(\.continuousClock) var clock
				do {
					try await clock.sleep(for: delay)
				} catch {
					return // cancelled
				}
			}

			phase = .validating(phase.errors)

			let errors = await rules.evaluate(rawValue, in: context)

			do {
				try Task.checkCancellation()
			} catch {
				return // cancelled
			}

			if !errors.isEmpty {
				phase = .invalid(errors)
			} else if let rawValue = rawValue ?? defaultValue {
				phase = .valid(rawValue)
			} else {
				phase = .invalid([])
			}
		}
	}

	deinit {
		task?.cancel()
	}
}

// https://forums.swift.org/t/why-cant-existential-types-be-compared/59118/3
fileprivate func equals(_ lhs: Any, _ rhs: Any) -> Bool {
	func open<A: Equatable>(_ lhs: A, _ rhs: Any) -> Bool {
		lhs == (rhs as? A)
	}

	guard let lhs = lhs as? any Equatable
	else { return false }

	return open(lhs, rhs)
}
