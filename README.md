# HTTPService
A super simple networking library which utilizes a service builder to construct and cache services.

## Usage
NOTE: These instructions are for v3.0+ only. Prior versions are no longer supported.

### Creating a Service

Start by creating a class that will represent a service and have it conform to the HTTPService protocol.
```swift
public class GitHubService: HTTPService {
    typealias Builder = GitHubService
    typealias Authorization = HTTPTokenAuthorization
    
    var urlSession = URLSession.shared
    var tasks = [URLSessionTask]()
    var baseUrl = BaseURL(string: "https://api.github.com")!
    var headers: HTTPHeaders? {
        return ["Accept": "application/vnd.github.v3+json"]
    }
    var authorization: HTTPTokenAuthorization?
    required init(authorization: HTTPTokenAuthorization?) {
        self.authorization = authorization
    }
}
```

Now, in order for `ServiceBuilder` to be able to build this service, we'll conform to the `HTTPServiceBuildable` protocol.
```swift
extension GitHubService: HTTPServiceBuildable {
    typealias Service = GitHubService

    static func build<T>() -> GitHubService? {
        guard let token = <Wherever you store user details>?.gitHubToken else {
            print("Cannot build GitHubService without an auth token.")
            return nil
        }
        let auth = HTTPTokenAuthorization(token: token)
        return GitHubService(authorization: auth)
    }
}
```

Your service is now ready to be created. If the service has already been created previously, you'll get back the cached version. If it hasn't been created previously, it'll be created, cached, and returned.
```swift
let gitHubService = ServiceBuilder<GitHubService>.build()
```

### Clearing ServiceBuilder's cache

If you ever need to clear the cache, simply call `ServiceBuilder<GitHubService>.purgeCache()`. If there is a cached version of this service, it'll be removed.

### Creating Requests

Create request classes that conform to the `HTTPRequest` protocol.

Example GET request:
```swift
class GitHubGetPRsRequest: HTTPRequest {
    
    typealias ResultType = [GitHubPR]
    typealias BodyType = HTTPRequestNoBody // Only needed for HTTPMethod.post, HTTPMethod.put, or HTTPMethod.patch requests
    
    // HTTPService required attributes
    var endpoint: String {
        return "repos/\(owner)/\(repo)/pulls"
    }
    var method: HTTPMethod = .get
    var params: [String : Any]?
    var body: HTTPRequestNoBody?
    var headers: [String : String]?
    var includeServiceLevelHeaders: Bool = true // See HTTPRequest for details on usage
    var includeServiceLevelAuthorization: Bool = true // See HTTPRequest for details on usage
    
    // Custom attributes
    let owner: String
    let repo: String
    
    // HTTPService required init
    required init(id: String?) {
        fatalError("Use init(owner:repo) instead)")
    }
    
    // Custom required init
    required init(owner: String, repo: String) {
        self.owner = owner
        self.repo = repo
    }
}
```

Example POST request:
```swift
struct GitHubPRBody: Encodable {
    let title: String
    let head: String
    let base: String
    let body: String = ""
    let maintainerCanModify: Bool = false
    let draft: Bool = false
}

class GitHubCreatePRRequest: HTTPRequest {
    
    typealias ResultType = GitHubPR
    typealias BodyType = GitHubPRBody
    
    var endpoint: String {
        return "/repos/\(pr.owner)/\(pr.repo)/pulls"
    }
    var method: HTTPMethod = .post
    var params: [String : Any]?
    var body: GitHubPRBody? {
        return GitHubPRBody(
            title: pr.title,
            head: "headbranch",
            base: "basebranch"
        )
    }
    var headers: [String : String]?
    var includeServiceLevelHeaders: Bool = true
    var includeServiceLevelAuthorization: Bool = true
    
    let pr: GitHubPR
    let head: String
    let base: String
    
    required init(for pr: GitHubPR, head: String, base: String) {
        self.pr = pr
    }
    
    required init(id: String?) {
        fatalError("Use init(for pr:) instead")
    }
}
```

### Executing Requests

You're now ready to send a request!
```swift
let getPRsRequest = GitHubGetPRsRequest(owner: "atljeremy", repo: 'httpservice')
gitHubService?.execute(request: getPRsRequest) { (result) in
    switch result {
    case let .success(prs):
        // Do something with prs
    case let .failure(error):
        // Handle failure
    }
}
```
