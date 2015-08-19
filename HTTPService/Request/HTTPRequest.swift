//
//  HTTPRequest.swift
//
//  Created by Jeremy Fox on 2/24/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

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
    public let headers: Headers?
    public let body: Params?
    public let imageUpload: ImageUpload?
    public let timeout: NSTimeInterval = 30
    public let acceptibleStatusCodeRange = 200..<300
    
    public init(path: String, method: Method, headers: Headers?, body: Params?) {
        self.path        = path
        self.method      = method
        self.headers     = headers
        self.body        = body
        self.imageUpload = nil
    }
    
    public init(path: String, method: Method, headers: Headers?, body: Params?, imageUpload: ImageUpload) {
        self.path        = path
        self.method      = method
        self.headers     = headers
        self.body        = body
        self.imageUpload = imageUpload
    }
    
}
