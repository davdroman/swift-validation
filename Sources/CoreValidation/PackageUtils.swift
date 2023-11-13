import Foundation

package extension StringProtocol {
	var isBlank: Bool {
		self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
}
