import Foundation

public enum ValidationMode {
	case automatic(delay: TimeInterval?)
	case manual

	public static var automatic: Self { .automatic(delay: .none) }

	var delay: TimeInterval? {
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
