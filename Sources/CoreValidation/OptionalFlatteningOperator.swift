/// Optional flattening operator
postfix operator |?

postfix func |? <T>(optional: T??) -> T? {
	optional?.flatMap({ $0 })
}

postfix func |? <T>(optional: T???) -> T? {
	optional?.flatMap({ $0 })?.flatMap({ $0 })
}

postfix func |? <T>(optional: T????) -> T? {
	optional?.flatMap({ $0 })?.flatMap({ $0 })?.flatMap({ $0 })
}

postfix func |? <T>(optional: T?????) -> T? {
	optional?.flatMap({ $0 })?.flatMap({ $0 })?.flatMap({ $0 })?.flatMap({ $0 })
}
