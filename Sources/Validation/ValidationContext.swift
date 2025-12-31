// TODO: use module selector when available https://github.com/swiftlang/swift-evolution/blob/main/proposals/0491-module-selectors.md
public typealias _Validation = Validation

public protocol ValidationContext: AnyObject {
	typealias Focus = _Focus<Self>
}

// ExpressibleByKeyPathLiteral would be really sweet here
public struct _Focus<Context>: Hashable {
	let keyPath: PartialKeyPath<Context>

	public init(_ keyPath: KeyPath<Context, Validation<some Any, some Any, some Any>>) {
		self.keyPath = keyPath
	}
}
