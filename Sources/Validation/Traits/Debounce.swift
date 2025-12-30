public struct DebounceValidationTrait: ValidationTrait {
	private let duration: Duration
	private let clock: any Clock<Duration>

	init(duration: Duration, clock: some Clock<Duration>) {
		self.duration = duration
		self.clock = clock
	}

	public func beforeValidation() async throws(CancellationError) {
		do {
			try await clock.sleep(for: duration)
		} catch {
			throw CancellationError()
		}
	}
}

#if Dependencies
import Dependencies
#endif

extension ValidationTrait where Self == DebounceValidationTrait {
	public static func debounce(for duration: Duration, clock: some Clock<Duration>) -> Self {
		DebounceValidationTrait(duration: duration, clock: clock)
	}

	public static func debounce(for duration: Duration) -> Self {
		#if Dependencies
		@Dependency(\.continuousClock) var clock
		return DebounceValidationTrait(duration: duration, clock: clock)
		#else
		return DebounceValidationTrait(duration: duration, clock: ContinuousClock())
		#endif
	}
}
