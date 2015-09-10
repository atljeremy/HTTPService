//
//  HTTPRequest.swift
//
//  Created by Jeremy Fox on 2/24/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import UIKit

public struct ImageUpload {
    
    public let image: UIImage
    public let field: String
    
    public init(image: UIImage, field: String) {
        self.image = image
        self.field = field
    }
}

public struct HTTPRequest {
    
    public typealias Params = [String: AnyObject]
    public typealias Headers = [String: String]
    
    public enum Method: String {
        case GET = "GET"
        case PUT = "PUT"
        case POST = "POST"
        case PATCH = "PATCH"
        case DELETE = "DELTE"
    }
    
    public let path: String
    public let method: Method
    public var headers: Headers?
    public let body: Params?
    public let imageUpload: ImageUpload?
    public let timeout: NSTimeInterval = 30
    public let acceptibleStatusCodeRange = 200..<300
    
    public init(path: String, method: Method, headers: Headers? = nil, body: Params? = nil) {
        self.path        = path
        self.method      = method
        self.headers     = headers
        self.body        = body
        self.imageUpload = nil
    }
    
    public init(path: String, method: Method, headers: Headers? = nil, body: Params? = nil, imageUpload: ImageUpload) {
        self.path        = path
        self.method      = method
        self.headers     = headers
        self.body        = body
        self.imageUpload = imageUpload
    }
    
    public mutating func addHeaders(_headers: Headers) -> HTTPRequest {
        if headers == nil {
            headers = HTTPRequest.Headers()
        }
        
        for (key, value) in _headers {
            headers?.updateValue(value, forKey: key)
        }
        
        return self
    }
    
    public mutating func removeHeaders(_headers: Headers) -> HTTPRequest {
        for (key, value) in _headers {
            if let containsHeader = headers?.contains({ $0.1 == value }) {
                if containsHeader {
                    headers?.removeValueForKey(key)
                }
            }
        }
        
        return self
    }
    
    public func executeMappingResponseToObject<T where T: JSONSerializable, T == T.DecodedType>(object: T.Type, completion: ((HTTPRequest, HTTPResult<T>, NSHTTPURLResponse?) -> Void)?) -> HTTPRequestOperation? {
        return HTTPService.defaultService().enqueue(self, mapResponseToObject: object, completion: completion)
    }
    
    public func execute(completion: ((HTTPRequest, HTTPResult<AnyObject>, NSHTTPURLResponse?) -> Void)?) -> HTTPRequestOperation? {
        return HTTPService.defaultService().enqueue(self, completion: completion)
    }
    
}
