//
//  File.swift
//  HTTPServiceTests
//
//  Created by Jeremy Fox on 8/7/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation
import HTTPService

final class GitHubService: HTTPService {
    typealias Builder = GitHubService
    typealias Authorization = HTTPTokenAuthorization
    
    var urlSession = URLSession.shared
    var tasks = [URLSessionTask]()
    var baseUrl = BaseURL(string: "https://api.github.com")!
    var headers: HTTPHeaders? {
        return ["Accept": "application/vnd.github.v3+json"]
    }
    var authorization: HTTPTokenAuthorization?
    
    init(authorization: HTTPTokenAuthorization?) {
        self.authorization = authorization
    }
}

extension GitHubService: HTTPServiceBuilder {
    static func build<T>() -> T? {
        let auth = HTTPTokenAuthorization(token: UUID().uuidString)
        return GitHubService(authorization: auth) as? T
    }
}

extension GitHubService {
    @discardableResult
    func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPRequest {
        do {
            let data = try JSONSerialization.data(withJSONObject: ["id": 123, "name": "PR Name"], options: .init(rawValue: 0))
            let pr = try JSONDecoder().decode(T.ResultType.self, from: data)
            handler(.success(pr))
        } catch _ {
            handler(.failure(.emptyResponseData("")))
        }
        
        return URLSessionDataTask()
    }
}

extension GitHubService: Equatable {}

func ==(left: GitHubService, right: GitHubService) -> Bool {
    return left.urlSession == right.urlSession && left.tasks == right.tasks && left.baseUrl == right.baseUrl && left.headers == right.headers && left.authorization?.value == right.authorization?.value
}
