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
    case success(Box<T>?)
    
    public init(value: T?, with error: Error? = nil) {
        guard error == nil else {
            self = .failure(error!)
            return
        }
        
        guard let value = value else {
            self = .success(nil)
            return
        }
        
        self = .success(Box(value))
    }
    
    public static func from(value: T?, with error: Error? = nil) -> HTTPResult<T> {
        return self.init(value: value, with: error)
    }

}
