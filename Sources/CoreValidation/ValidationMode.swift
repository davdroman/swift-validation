import CasePaths
import Foundation

@CasePathable
@dynamicMemberLookup
public enum ValidationMode {
	case automatic(delay: TimeInterval?)
	case manual

	public static var automatic: Self { .automatic(delay: .none) }
}
