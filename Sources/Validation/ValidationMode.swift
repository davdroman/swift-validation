import Foundation

public enum ValidationMode: Sendable {
	case automatic(delay: Duration?)
	case manual

	public static var automatic: Self { .automatic(delay: .none) }

	var delay: Duration? {
		if case let .automatic(delay) = self {
			return delay
		}
		return nil
	}

	var isAutomatic: Bool {
		if case .automatic = self {
			return true
		}
		return false
	}

	var isManual: Bool {
		if case .manual = self {
			return true
		}
		return false
	}
}
