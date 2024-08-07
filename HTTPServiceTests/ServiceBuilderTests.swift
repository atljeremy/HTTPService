//
//  HTTPServiceTests.swift
//  HTTPServiceTests
//
//  Created by Jeremy Fox on 8/7/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import XCTest
import HTTPService

class ServiceBuilderTests: XCTestCase {

    func testReturnsCachedService() {
        let expectation = expectation(description: "Async")
        
        Task {
            let ghService1 = await ServiceBuilder<GitHubService>.build()
            let ghService2 = await ServiceBuilder<GitHubService>.build()
            XCTAssertEqual(ghService1, ghService2)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }
    
    func testIgnoreingCacheDoesntReturnCachedService() {
        let expectation = expectation(description: "Async")
        
        Task {
            let ghService1 = await ServiceBuilder<GitHubService>.build()
            let ghService2 = await ServiceBuilder<GitHubService>.build(ignoringCache: true)
            XCTAssertNotEqual(ghService1, ghService2)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }
    
    func testPurgeRemovesCachedService() {
        let expectation = expectation(description: "Async")
        
        Task {
            let ghService1 = await ServiceBuilder<GitHubService>.build()
            XCTAssertNotNil(ghService1)
            
            await ServiceBuilder<GitHubService>.purgeCache()
            
            let ghService2 = await ServiceBuilder<GitHubService>.build()
            XCTAssertNotEqual(ghService1, ghService2)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }

}
