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
        let ghService1 = ServiceBuilder<GitHubService>.build()
        let ghService2 = ServiceBuilder<GitHubService>.build()
        XCTAssertEqual(ghService1, ghService2)
    }
    
    func testPurgeRemovesCachedService() {
        let ghService1 = ServiceBuilder<GitHubService>.build()
        XCTAssertNotNil(ghService1)
        
        ServiceBuilder<GitHubService>.purgeCache()
        
        let ghService2 = ServiceBuilder<GitHubService>.build()
        XCTAssertNotEqual(ghService1, ghService2)
    }

}
