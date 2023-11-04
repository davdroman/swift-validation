import CasePaths
import Foundation

@CasePathable
public enum ValidationMode {
	case automatic(delay: TimeInterval?)
	case manual

	public static var automatic: Self { .automatic(delay: .none) }
}

extension ValidationMode {
	var delay: TimeInterval? {
		self[case: \.automatic]?[case: \.some]
	}
}
