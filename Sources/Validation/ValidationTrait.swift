import Dependencies

public protocol ValidationTrait: Sendable {
	func beforeValidation() async
	func mutatePhase(isInitial: Bool, mutate: () -> Void)
	func afterValidation() async
}

public extension ValidationTrait {
	func beforeValidation() async {}
	func mutatePhase(isInitial: Bool, mutate: () -> Void) { mutate() }
	func afterValidation() async {}
}

extension [any ValidationTrait] {
	func beforeValidation() async {
		for trait in self {
			await trait.beforeValidation()
		}
	}

	func mutatePhase(isInitial: Bool, mutate: () -> Void) {
		withoutActuallyEscaping(mutate) { mutate in
			let operation = reversed().reduce(mutate) { next, trait in
				{ trait.mutatePhase(isInitial: isInitial, mutate: next) }
			}
			operation()
		}
	}

	func afterValidation() async {
		for trait in self {
			await trait.afterValidation()
		}
	}
}

public struct DebounceValidationTrait: ValidationTrait {
	@Dependency(\.continuousClock) private var clock

	private let duration: Duration

	public init(duration: Duration) {
		self.duration = duration
	}

	public func beforeValidation() async {
		do {
			try await clock.sleep(for: duration)
		} catch {}
	}
}

extension ValidationTrait where Self == DebounceValidationTrait {
	public static func debounce(for duration: Duration) -> Self {
		DebounceValidationTrait(duration: duration)
	}
}

#if canImport(SwiftUI)
public import SwiftUI

public struct AnimationValidationTrait: ValidationTrait {
	private let animation: Animation

	public init(animation: Animation) {
		self.animation = animation
	}

	public func mutatePhase(isInitial: Bool, mutate: () -> Void) {
		if isInitial {
			mutate()
		} else {
			withAnimation(animation) {
				mutate()
			}
		}
	}
}

extension ValidationTrait where Self == AnimationValidationTrait {
	public static func animation(_ animation: Animation = .default) -> Self {
		AnimationValidationTrait(animation: animation)
	}
}
#endif
