import Foundation

extension StringProtocol {
	var isBlank: Bool {
		self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
}
