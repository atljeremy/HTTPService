//
//  HTTPResult.swift
//
//  Created by Jeremy Fox on 3/3/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

public final class Box<T> {
    public let value: T
    public init(_ value: T) {
        self.value = value
    }
}

public enum HTTPResult<T> {
    
    case Failure(NSError, HTTPResponse.HTTPStatusCode)
    case Success(Box<T>, HTTPResponse.HTTPStatusCode)
    
    init(_ value: T, _ statusCode: HTTPResponse.HTTPStatusCode, _ error: NSError?) {
        if let err = error {
            self = .Failure(err, statusCode)
        }
        self = .Success(Box(value), statusCode)
    }
    
    public static func fromOptional(optional: T?, _ statusCode: HTTPResponse.HTTPStatusCode, _ error: NSError?) -> HTTPResult<T> {
        if let _optional = optional {
            return .Success(Box(_optional), statusCode)
        }
        if let _error = error {
            return .Failure(_error, statusCode)
        }
        return .Failure(NSError(domain: "HTTPObjectMappingErrorDomain", code: 7878, userInfo: [NSLocalizedDescriptionKey: "Unexpected error"]), 000)
    }
}