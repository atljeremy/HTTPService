//
//  HTTPResult.swift
//
//  Created by Jeremy Fox on 3/3/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Foundation

public final class Box<T> {
    public let value: T
    public init(_ value: T) {
        self.value = value
    }
}

public enum HTTPResult<T> {
    
    case failure(Error)
    case success(Box<T>)
    
    public init(value: T?, with error: Error? = nil) {
        if let _value = value {
            self = .success(Box(_value))
            return
        }
        if let _error = error {
            self = .failure(_error)
            return
        }
        self = .failure(NSError(domain: "HTTPObjectMappingErrorDomain", code: 7878, userInfo: [NSLocalizedDescriptionKey: "Unexpected error"]))
    }
    
    public static func from(value: T?, with error: Error? = nil) -> HTTPResult<T> {
        return self.init(value: value, with: error)
    }
}
