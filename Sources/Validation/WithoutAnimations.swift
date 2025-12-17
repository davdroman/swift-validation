#if canImport(SwiftUI)
import SwiftUI
#endif

func withoutAnimations<T>(_ execute: () throws -> T) rethrows -> T {
	#if canImport(SwiftUI)
	var transaction = Transaction()
	transaction.disablesAnimations = true
	return try withTransaction(transaction, execute)
	#else
	return try execute()
	#endif
}
