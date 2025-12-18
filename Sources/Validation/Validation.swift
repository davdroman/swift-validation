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
	private let traits: [any ValidationTrait]
	@ObservationIgnored
	private weak var _context: AnyObject?
	private var context: Context? {
		if Context.self == Void.self {
			return (() as! Context)
		} else {
			return _context as? Context
		}
	}

	internal private(set) var rawValue: Value?
	public private(set) var phase: Phase

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
		traits: [any ValidationTrait]
	) {
		self.rawValue = rawValue
		self.phase = .idle
		self.rules = rules
		self.defaultValue = defaultValue
		self._context = context as? AnyObject
		self.traits = traits

		self.validateIfPossible(isInitial: true, reportIssue: false)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		traits: any ValidationTrait...
	) where Context == Void {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: nil, context: nil, traits: traits)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		context: Context? = nil,
		traits: any ValidationTrait...
	) where Context: AnyObject {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: nil, context: context, traits: traits)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		traits: any ValidationTrait...,
		@ArrayBuilder<Error> rules handler: @escaping ValidationRulesHandler<Value, Error>
	) where Context == Void {
		self.init(wrappedValue: rawValue, of: Rules(handler: handler), defaultValue: nil, context: nil, traits: traits)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		context: Context? = nil,
		traits: any ValidationTrait...,
		@ArrayBuilder<Error> rules handler: @escaping ValidationRulesHandlerWithContext<Value, Error, Context>
	) where Context: AnyObject {
		self.init(wrappedValue: rawValue, of: Rules(handler: handler), defaultValue: nil, context: context, traits: traits)
	}

	// MARK: support for double optionals

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		traits: any ValidationTrait...
	) where Value == Wrapped?, Context == Void {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: .some(nil), context: nil, traits: traits)
	}

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		context: Context? = nil,
		traits: any ValidationTrait...,
	) where Value == Wrapped?, Context: AnyObject {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: .some(nil), context: context, traits: traits)
	}

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		traits: any ValidationTrait...,
		@ArrayBuilder<Error> rules handler: @escaping ValidationRulesHandlerWithContext<Value, Error, Context>
	) where Value == Wrapped?, Context == Void {
		self.init(wrappedValue: rawValue, of: Rules(handler: handler), defaultValue: .some(nil), context: nil, traits: traits)
	}

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		context: Context? = nil,
		traits: any ValidationTrait...,
		@ArrayBuilder<Error> rules handler: @escaping ValidationRulesHandlerWithContext<Value, Error, Context>
	) where Value == Wrapped?, Context: AnyObject {
		self.init(wrappedValue: rawValue, of: Rules(handler: handler), defaultValue: .some(nil), context: context, traits: traits)
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
			validateIfPossible(isInitial: false)
		}
	}

	public var projectedValue: Validation {
		self
	}

	public func setContext(_ context: Context) where Context: AnyObject {
		self._context = context
		withoutAnimations {
			validateIfPossible(isInitial: true)
		}
	}

	private func validateIfPossible(isInitial: Bool, reportIssue report: Bool = true) {
		if let context {
			validate(in: context, isInitial: isInitial)
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

	private func validate(in context: Context, isInitial: Bool) {
		task?.cancel()
		task = Task {
			do {
				try await traits.beforeValidation()
			} catch {
				return // cancelled
			}

			traits.mutatePhase(isInitial: isInitial) {
				phase = .validating(phase.errors)
			}

			let errors = await rules.evaluate(rawValue, in: context)

			do {
				try Task.checkCancellation()
			} catch {
				return // cancelled
			}

			traits.mutatePhase(isInitial: isInitial) {
				if !errors.isEmpty {
					phase = .invalid(errors)
				} else if let rawValue = rawValue ?? defaultValue {
					phase = .valid(rawValue)
				} else {
					phase = .invalid([])
				}
			}

			do {
				try await traits.afterValidation()
			} catch {
				return // cancelled
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
