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

    func testServiceExecutesBatchRequestsAndReturnsParsedResults() {
        let expectation = expectation(description: "Batch requests complete")
        let batchRequest = GetPullRequests(requests: [
            GitHubGetPullRequest(id: "123"),
            GitHubGetPullRequest(id: "456")
        ])
        
        Task {
            let service = await ServiceBuilder<GitHubService>.build()!
            let results: [HTTPResult] = await service.execute(batch: batchRequest)
            
            XCTAssert(results.count == batchRequest.requests.count)
            results.forEach { result in
                switch result {
                case let .success(pr):
                    XCTAssertTrue(batchRequest.requests.contains(where: { $0.prId == "\(pr!.id)" }))
                case .failure(_):
                    XCTFail()
                }
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }

}
