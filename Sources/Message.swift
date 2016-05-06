public protocol Message: CustomDataStore {
    var version: Version { get set }
    var headers: [CaseInsensitiveString: String] { get set }
    var body: Body { get set }
}
