//
//  HTTPServiceTests.swift
//  HTTPServiceTests
//
//  Created by Jeremy Fox on 8/7/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import XCTest
import HTTPService

class HTTPServiceTests: XCTestCase {

    func testServiceExecutesRequestAndReturnsParsedResultType() {
        let service = ServiceBuilder<GitHubService>.build()
        service?.execute(request: GitHubGetPullRequest(id: "123")) { (result) in
            switch result {
            case let .success(pr):
                XCTAssertTrue(pr?.name == "PR Name")
            case .failure(_):
                XCTFail()
            }
        }
    }

}
