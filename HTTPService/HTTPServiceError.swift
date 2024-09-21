//
//  HTTPServiceError.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/3/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation

public enum NetworkServiceError: Error {
    /// Used as a catchall for any error codes not defined below
    case requestFailed(String)
    /// Used when response data is expected but not received
    case emptyResponseData(String)
    /// Used when JSON serialization/decoding error(s) occur
    case jsonDecodingError(String)
    /// Used for download requests that result in a failed download
    case downloadFailed(String)
    
    // HTTP Error Codes
    case badRequest(String) // 400
    case unauthorized(String) // 401
    case forbidden(String) // 403
    case conflict(String) // 409
    case unprocessableEntity(String) // 422
    case serverError(String) // 500
    
    public var message: String {
        switch self {
        case .requestFailed(let s): return s
        case .emptyResponseData(let s): return s
        case .jsonDecodingError(let s): return s
        case .downloadFailed(let s): return s
        case .badRequest(let s): return s
        case .unauthorized(let s): return s
        case .forbidden(let s): return s
        case .conflict(let s): return s
        case .unprocessableEntity(let s): return s
        case .serverError(let s): return s
        }
    }
}
