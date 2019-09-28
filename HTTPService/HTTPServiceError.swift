//
//  HTTPServiceError.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/3/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation

public enum HTTPServiceError: Error {
    case requestFailed(String)
    case emptyResponseData(String)
    case jsonDecodingError(String)
    case downloadFailed(String)
    case unauthorized(String)
    
    public var message: String {
        switch self {
        case .requestFailed(let s):
            return s
        case .emptyResponseData(let s):
            return s
        case .jsonDecodingError(let s):
            return s
        case .downloadFailed(let s):
            return s
        case .unauthorized(let s):
            return s
        }
    }
}
