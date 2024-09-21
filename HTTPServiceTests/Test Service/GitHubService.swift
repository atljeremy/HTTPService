//
//  File.swift
//  HTTPServiceTests
//
//  Created by Jeremy Fox on 8/7/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation
import HTTPService

final class GitHubService: NetworkService {

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

extension GitHubService: NetworkServiceBuildable {
    typealias Service = GitHubService
    
    static func build() -> GitHubService? {
        let auth = HTTPTokenAuthorization(token: UUID().uuidString)
        return self.init(authorization: auth)
    }
}

extension GitHubService {
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPRequest {
        do {
            var prJson: [String: Any] = [:]
            switch request.endpoint {
            case let endpoint where endpoint.contains("123"):
                prJson = ["id": 123, "name": "PR Name"]
            case let endpoint where endpoint.contains("456"):
                prJson = ["id": 456, "name": "PR Name"]
            default:
                break
            }
            let data = try JSONSerialization.data(withJSONObject: prJson, options: .init(rawValue: 0))
            let pr = try JSONDecoder().decode(T.ResultType.self, from: data)
            return .success(pr)
        } catch _ {
            return .failure(.emptyResponseData(""))
        }
    }
}

extension GitHubService: Equatable {}

func ==(left: GitHubService, right: GitHubService) -> Bool {
    return left.urlSession == right.urlSession && left.tasks == right.tasks && left.baseUrl == right.baseUrl && left.headers == right.headers && left.authorization?.value == right.authorization?.value
}
