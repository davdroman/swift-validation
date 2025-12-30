#if canImport(SwiftUI)
public import SwiftUI

public struct AnimationValidationTrait: ValidationTrait {
	private let animation: Animation

	init(animation: Animation) {
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
