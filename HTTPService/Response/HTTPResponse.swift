//
//  HTTPResponse.swift
//
//  Created by Jeremy Fox on 2/26/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

public struct HTTPResponse {
    
    public typealias HTTPStatusCode = Int
    
    public let data: NSData
    public let statusCode: HTTPStatusCode
    
    public init(data: NSData, urlResponse: NSURLResponse) {
        self.data = data
        if let _urlResponse = urlResponse as? NSHTTPURLResponse {
            statusCode = _urlResponse.statusCode
        } else {
            statusCode = -1
        }
    }
}
