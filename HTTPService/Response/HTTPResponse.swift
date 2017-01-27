//
//  HTTPResponse.swift
//
//  Created by Jeremy Fox on 2/26/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Foundation

public struct HTTPResponse {
    
    public let data: Data
    public let statusCode: Int
    
    public init(data: Data, urlResponse: URLResponse) {
        self.data = data
        if let _urlResponse = urlResponse as? HTTPURLResponse {
            statusCode = _urlResponse.statusCode
        } else {
            statusCode = -1
        }
    }

}
