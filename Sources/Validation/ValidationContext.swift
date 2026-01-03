public protocol ValidationContext: AnyObject {
	typealias Focus = _Focus<Self>

	var validationTraits: [any ValidationTrait] { get }
}

public extension ValidationContext {
	var validationTraits: [any ValidationTrait] { [] }
}

// ExpressibleByKeyPathLiteral would be really sweet here
public struct _Focus<Context>: Hashable {
	let keyPath: PartialKeyPath<Context>

	public init(_ keyPath: KeyPath<Context, Validation<some Any, some Any, some Any>>) {
		self.keyPath = keyPath
	}
}
