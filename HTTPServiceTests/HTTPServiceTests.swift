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
        let expectation = expectation(description: "Async function completes")
    
        Task {
            let service = await ServiceBuilder<GitHubService>.build()!
            let result = await service.execute(request: GitHubGetPullRequest(id: "123"))
            switch result {
            case let .success(pr):
                XCTAssertTrue(pr?.name == "PR Name")
            case .failure(_):
                XCTFail()
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }

}
