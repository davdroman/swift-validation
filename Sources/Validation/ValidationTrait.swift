protocol ValidationTrait {
	func beforeValidation() async
	func mutatePhase(mutate: () -> Void)
	func afterValidation() async
}

extension ValidationTrait {
	func beforeValidation() async {}
	func mutatePhase(mutate: () -> Void) {}
	func afterValidation() async {}
}

#if canImport(SwiftUI)
import SwiftUI

struct AnimationValidationTrait: ValidationTrait {
	let animation: Animation

	func mutatePhase(mutate: () -> Void) {
		withAnimation(animation) {
			mutate()
		}
	}
}

extension ValidationTrait where Self == AnimationValidationTrait {
	static func animation(_ animation: Animation = .default) -> Self {
		AnimationValidationTrait(animation: animation)
	}
}
#endif
