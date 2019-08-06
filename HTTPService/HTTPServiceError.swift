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
    
    public var message: String {
        switch self {
        case let .requestFailed(s):
            return s
        case let .emptyResponseData(s):
            return s
        case let .jsonDecodingError(s):
            return s
        case let .downloadFailed(s):
            return s
        }
    }
}
