# HTTPService
A super simple networking library which utilizes a service builder to construct and cache services.

## Usage
NOTE: These instructions are for v4.2.0+ only. Prior versions are no longer supported.

### Creating a Service

Start by creating a class that will represent a service and have it conform to the `NetworkService` protocol.
```swift
public class GitHubService: NetworkService {
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

Now, in order for `ServiceBuilder` to be able to build this service, we'll conform to the `NetworkServiceBuildable` protocol.
```swift
extension GitHubService: NetworkServiceBuildable {
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
let gitHubService = await ServiceBuilder<GitHubService>.build()
```

### Clearing ServiceBuilder's cache

If you ever need to clear the cache, simply call:
```swift
await ServiceBuilder<GitHubService>.purgeCache()
```
If there is a cached version of this service, it'll be removed.

### Creating Requests

Create request classes that conform to the `HTTPRequest` protocol.

Example GET request:
```swift
class GitHubGetPRsRequest: HTTPRequest {
    
    typealias ResultType = [GitHubPR]
    typealias BodyType = HTTPRequestNoBody // Only needed for HTTPMethod.post, HTTPMethod.put, or HTTPMethod.patch requests
    
    // NetworkService required attributes
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
    
    // NetworkService required init
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

To send a request, use the execute method on your service:
```swift
let getPRsRequest = GitHubGetPRsRequest(owner: "atljeremy", repo: "httpservice")
let result = await gitHubService?.execute(request: getPRsRequest)

switch result {
case let .success(prs):
    // Do something with prs
case let .failure(error):
    // Handle failure
}

```

### Handling Pagination

If your service involves paginated responses, you can use HTTPPagedRequest and HTTPPagedResult protocols for easier handling of paginated data:
```swift
public struct GitHubPagedPRs: HTTPPagedResult {
    typealias ObjectsCollectionType = [GitHubPR]
    var links: PagedLinks?
    var perPage: Int?
    var total: Int?
    var objects: [GitHubPR]?
}

class GitHubGetPagedPRsRequest: HTTPPagedRequest {
    typealias ResultType = GitHubPagedPRs
    typealias BodyType = HTTPRequestNoBody
    
    var endpoint: String {
        return "repos/\(owner)/\(repo)/pulls"
    }
    var method: HTTPMethod = .get
    var params: [String: Any]?
    var body: HTTPRequestNoBody?
    var headers: [String: String]?
    var includeServiceLevelHeaders: Bool = true
    var includeServiceLevelAuthorization: Bool = true
    
    let owner: String
    let repo: String
    
    required init(owner: String, repo: String) {
        self.owner = owner
        self.repo = repo
    }
    
    required init(id: String?) {
        fatalError("Use init(owner:repo:) instead")
    }
}
```

This allows you to easily retrieve and navigate through paginated results from your API.

### Request Batching

If you need to send mutliple requests at once, use `HTTPBatchRequest` to send them in an efficient mannor and get back the result of each request.

Start by creating your `HTTPBatchRequest`:
```swift
struct GetPullRequests: HTTPBatchRequest {
    typealias Request = GitHubGetPullRequest

    var requests: [GitHubGetPullRequest]
    
    init(requests: [GitHubGetPullRequest]) {
        self.requests = requests
    }
}
```

Then create an instance of your batch request, passing it the necessary requests, and call `execute(batch:)` on your `NetworkService`:
```swift
let batchRequest = GetPullRequests(requests: [
    GitHubGetPullRequest(id: "123"),
    GitHubGetPullRequest(id: "456")
])

let service = await ServiceBuilder<GitHubService>.build()!
let results: [HTTPResult] = await service.execute(batch: batchRequest)

// Do something with the `results`
results.forEach { result in
    switch result {
    case let .success(pr):
        print(pr)
    case .failure(error):
        print(error)
    }
}
```
