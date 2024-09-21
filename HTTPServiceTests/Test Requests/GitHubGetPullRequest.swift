//
//  GitHubGetPullRequest.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/7/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation
import HTTPService

struct GitHubGetPullRequest: HTTPRequest {
    
    typealias ResultType = PullRequest
    typealias BodyType = HTTPRequestNoBody
    
    var endpoint: String {
        "/something/\(prId!)"
    }
    var method: HTTPMethod = .get
    var params: [String : Any]?
    var body: HTTPRequestNoBody?
    var headers: [String : String]?
    var includeServiceLevelHeaders: Bool = true
    var includeServiceLevelAuthorization: Bool = true
    
    let prId: String?
    
    init(id: String?) {
        prId = id
    }
}

struct GetPullRequests: HTTPBatchRequest {
    var requests: [GitHubGetPullRequest]
    
    init(requests: [GitHubGetPullRequest]) {
        self.requests = requests
    }
    
    typealias Request = GitHubGetPullRequest
}
