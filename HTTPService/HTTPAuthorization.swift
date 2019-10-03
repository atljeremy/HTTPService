//
//  HTTPAuthorization.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/3/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation

/// Used to authorize HTTP Requests using the "Authorization" header.
///
/// See `HTTPBasicAuthorization`, `HTTPBearerAuthorization`, `HTTPTokenAuthorization`, `HTTPCustomTokenAuthorization` and `HTTPNoAuthorization`
public protocol HTTPAuthorization {
    
    /// Used as the value of the "Authorization" header
    var value: String { get }
}

/// Use for services that do not require authorization
public struct HTTPNoAuthorization: HTTPAuthorization {
    public var value: String = ""
}

/// Use for standard "Basic" authorization
///
/// http://www.iana.org/go/rfc7617
public struct HTTPBasicAuthorization: HTTPAuthorization {
    let username: String
    let password: String
    public var value: String
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
        value = "Basic \(Data("\(username):\(password)".utf8).base64EncodedString())"
    }
}

/// Use for standard "Bearer" authorization
///
/// http://www.iana.org/go/rfc6750
public struct HTTPBearerAuthorization: HTTPAuthorization {
    let token: String
    public var value: String
    
    public init(token: String) {
        self.token = token
        value = "Bearer \(token)"
    }
}

/// Use for authorization similar to Bearer, but require `token` in place of `bearer`
public struct HTTPTokenAuthorization: HTTPAuthorization {
    let token: String
    public var value: String
    
    public init(token: String) {
        self.token = token
        value = "token \(token)"
    }
}

/// Use for authorized HTTP requests that only accept a token and aren't Basic or Bearer.
///
/// A custom authorization mechanism where the value of the "Authorization"
/// header should only contain a `token` and aren't "Basic" or "Bearer" auth.
public struct HTTPCustomTokenAuthorization: HTTPAuthorization {
    public var value: String
    
    public init(token: String) {
        value = token
    }
}
