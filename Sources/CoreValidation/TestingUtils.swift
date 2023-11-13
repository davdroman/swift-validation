import Foundation

extension StringProtocol {
	package var isBlank: Bool {
		self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
}
