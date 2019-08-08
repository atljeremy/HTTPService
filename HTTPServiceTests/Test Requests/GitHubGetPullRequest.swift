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
    
    var endpoint = "/something"
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
