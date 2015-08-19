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
    
    case Failure(NSError)
    case Success(Box<T>)
    
    init(_ value: T, _ error: NSError?) {
        if let err = error {
            self = .Failure(err)
        }
        self = .Success(Box(value))
    }
    
    public static func fromOptional(optional: T?, _ error: NSError?) -> HTTPResult<T> {
        if let _optional = optional {
            return .Success(Box(_optional))
        }
        if let _error = error {
            return .Failure(_error)
        }
        return .Failure(NSError(domain: "HTTPObjectMappingErrorDomain", code: 7878, userInfo: [NSLocalizedDescriptionKey: "Unexpected error"]))
    }
}