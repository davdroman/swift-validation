public import Builders
import IssueReporting
public import Observation

@MainActor
@Observable
@propertyWrapper
@dynamicMemberLookup
public final class Validation<Value: Sendable, Error: Sendable, Context: Sendable>: Sendable {
	@ObservationIgnored
	private let rules: ValidationRules<Value, Error, Context>
	@ObservationIgnored
	private let defaultValue: Value?
	@ObservationIgnored
	private let traits: [any ValidationTrait]
	@ObservationIgnored
	private weak var context: (any ValidationContext)?

	internal private(set) var rawValue: Value?
	public private(set) var phase: ValidationPhase<Value, Error>

	public subscript<T>(dynamicMember keyPath: KeyPath<ValidationPhase<Value, Error>, T>) -> T {
		phase[keyPath: keyPath]
	}

	private enum ContextResolutionError: Swift.Error {
		case unset
		case typeMismatch(expected: Any.Type, actual: Any.Type)
	}

	private var resolvedContext: Context {
		get throws(ContextResolutionError) {
			if Context.self == Void.self {
				return () as! Context
			}

			guard let context else {
				throw .unset
			}

			if let context = context as? Context {
				return context
			} else {
				throw .typeMismatch(expected: Context.self, actual: type(of: context))
			}
		}
	}

	@ObservationIgnored
	private var task: Task<Void, Never>?

	private init(
		wrappedValue rawValue: Value? = nil,
		of rules: ValidationRules<Value, Error, Context>,
		defaultValue: Value?,
		traits: [any ValidationTrait]
	) {
		self.rawValue = rawValue
		self.phase = .idle
		self.rules = rules
		self.defaultValue = defaultValue
		self.traits = traits

		self.validateIfPossible(isInitial: true, reportIssue: false)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		of rules: ValidationRules<Value, Error, Context>,
		traits: any ValidationTrait...
	) {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: nil, traits: traits)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		traits: any ValidationTrait...,
		@ArrayBuilder<Error> rules handler: @escaping ValidationRulesHandler<Value, Error>
	) where Context == Void {
		self.init(wrappedValue: rawValue, of: ValidationRules(handler: handler), defaultValue: nil, traits: traits)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		traits: any ValidationTrait...,
		@ArrayBuilder<Error> rules handler: @escaping ValidationRulesHandlerWithContext<Value, Error, Context>
	) where Context: ValidationContext {
		self.init(wrappedValue: rawValue, of: ValidationRules(handler: handler), defaultValue: nil, traits: traits)
	}

	// MARK: support for double optionals

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		of rules: ValidationRules<Value, Error, Context>,
		traits: any ValidationTrait...
	) where Value == Wrapped? {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: .some(nil), traits: traits)
	}

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		traits: any ValidationTrait...,
		@ArrayBuilder<Error> rules handler: @escaping ValidationRulesHandler<Value, Error>
	) where Value == Wrapped?, Context == Void {
		self.init(wrappedValue: rawValue, of: ValidationRules(handler: handler), defaultValue: .some(nil), traits: traits)
	}

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		traits: any ValidationTrait...,
		@ArrayBuilder<Error> rules handler: @escaping ValidationRulesHandlerWithContext<Value, Error, Context>
	) where Value == Wrapped?, Context: ValidationContext {
		self.init(wrappedValue: rawValue, of: ValidationRules(handler: handler), defaultValue: .some(nil), traits: traits)
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

	public func setContext(_ context: some ValidationContext) {
		self.context = context
		validateIfPossible(isInitial: true)
	}

	private func validateIfPossible(isInitial: Bool, reportIssue report: Bool = true) {
		do throws(ContextResolutionError) {
			validate(in: try resolvedContext, isInitial: isInitial)
		} catch {
			switch error {
			case .unset:
				reportIssue(
					"""
					Context-dependent validation cannot be performed without a context.

					Make sure to mark the enclosing class as `@ValidationContext`.
					"""
				)
			case .typeMismatch(let expected, let actual):
				reportIssue(
					"""
					Expected context of type \(expected), but got \(actual).

					Make sure to mark the enclosing context type matches your rules' context type.
					"""
				)
			}
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
