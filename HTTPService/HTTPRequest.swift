//
//  HTTPRequest.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/3/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation

/// Represents the HTTP methods used in network requests.
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// A protocol defining the requirements for an HTTP request.
///
/// Types conforming to `HTTPRequest` must define an endpoint, HTTP method, and optional parameters,
/// body, and headers. This protocol also allows control over whether service-level headers and
/// authorization should be included in the request.
public protocol HTTPRequest {
    associatedtype ResultType: Decodable
    associatedtype BodyType: Encodable
    
    /// The endpoint for the request, relative to the service's base URL.
    var endpoint: String { get }
    
    /// The HTTP method for the request (GET, POST, etc.).
    var method: HTTPMethod { get }
    
    /// Optional parameters to be included in the request's query string.
    var params: [String: Any]? { get }
    
    /// The optional body of the request, encoded according to the `BodyType`.
    var body: BodyType? { get }
    
    /// Headers specific to this request, overriding any service-level headers.
    var headers: [String: String]? { get }
    
    /// Indicates whether the service's headers should be included in the request.
    var includeServiceLevelHeaders: Bool { get }
    
    /// Indicates whether the service's authorization should be included in the request.
    var includeServiceLevelAuthorization: Bool { get }
    
    /// Initializes a new request with an optional identifier.
    init(id: String?)
}

/// Represents a response with no content, typically used for HTTP 204 (No Content) responses.
public struct HTTPResponseNoContent: Decodable {}

/// Represents a request with no body, typically used for HTTP GET requests.
public struct HTTPRequestNoBody: Encodable {}

/// A protocol defining lifecycle awareness for HTTP requests.
///
/// Types conforming to `HTTPRequestLifecycleAware` can execute custom logic before and after
/// the request is executed, and after it completes with either a result or an error.
public protocol HTTPRequestLifecycleAware {
    associatedtype ResultType: Decodable
    
    /// Called before the request is executed.
    func willExecute(request: URLRequest)
    
    /// Called after the request completes with a result.
    ///
    /// - Returns: The processed result, or `nil` if there is no result.
    @discardableResult
    func didComplete(request: URLRequest, receiving object: ResultType?) -> ResultType?
    
    /// Called after the request completes with an error.
    func didComplete(request: URLRequest, with error: Error?)
}

/// A protocol representing a request that returns raw `Data` as its result.
public protocol HTTPDataRequest: HTTPRequest where ResultType == Data {}

/// A protocol representing a request that downloads a file, returning a `URL` as its result.
public protocol HTTPDownloadRequest: HTTPRequest where ResultType == URL {}

/// A protocol representing a request that uploads a file, with the request body being `Data`.
public protocol HTTPUploadRequest: HTTPRequest where BodyType == Data {
    
    /// The URL of the file to be uploaded.
    var fileUrl: URL? { get set }
    
    /// The type of the file to be uploaded.
    var fileType: String? { get set }
    
    /// Initializes a new upload request with an identifier, file URL, and file type.
    init(id: String?, attachment fileUrl: URL, as fileType: String)
}

/// A protocol defining lifecycle awareness for chainable HTTP requests.
///
/// Types conforming to `HTTPRequestChainableLifecycleAware` can execute custom logic before and after
/// the chained request is executed, and after it completes with either a result or an error.
public protocol HTTPRequestChainableLifecycleAware: HTTPRequestLifecycleAware {
    associatedtype ChainedRequest: HTTPRequest
    associatedtype ParentRequestResultType
    
    /// Called after the chained request completes with a result.
    ///
    /// - Returns: The processed result of the parent request, or `nil` if there is no result.
    @discardableResult
    func didComplete(chained request: URLRequest, receiving object: ChainedRequest.ResultType?) -> ParentRequestResultType?
}

/// A protocol defining lifecycle awareness for chainable HTTP download requests.
public protocol HTTPDownloadRequestChainableLifecycleAware: HTTPRequestLifecycleAware {
    associatedtype ChainedRequest: HTTPDownloadRequest
    associatedtype ParentRequestResultType
    
    /// Called after the chained download request completes with a result.
    ///
    /// - Returns: The processed result of the parent request, or `nil` if there is no result.
    @discardableResult
    func didComplete(chained request: URLRequest, receiving object: ChainedRequest.ResultType?) -> ParentRequestResultType?
}

/// A protocol for chaining HTTP requests.
///
/// Types conforming to `HTTPRequestChainable` can chain another request to be executed after the
/// current request completes.
public protocol HTTPRequestChainable: HTTPRequest, HTTPRequestChainableLifecycleAware {
    /// The request to be executed after the current request completes.
    var chainedRequest: ChainedRequest { get }
}

/// A protocol for chaining HTTP download requests.
public protocol HTTPDownloadRequestChainable: HTTPRequest, HTTPDownloadRequestChainableLifecycleAware {
    /// The download request to be executed after the current request completes.
    var chainedRequest: ChainedRequest { get }
}

/// Extension to `HTTPRequest` providing a method to build a `URLRequest` from the request details.
extension HTTPRequest {
    
    /// Builds a `URLRequest` based on the properties of the conforming `HTTPRequest`.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL used to resolve the endpoint.
    ///   - additionalHeaders: Optional additional headers to be included in the request.
    ///   - authorization: Optional authorization to be added to the request.
    /// - Returns: A `URLRequest` ready to be executed.
    func buildURLRequest(resolvingAgainst baseURL: BaseURL, with additionalHeaders: HTTPHeaders? = nil, and authorization: HTTPAuthorization? = nil) -> URLRequest {
        
        // Build URL
        let url: URL
        if endpoint.contains("http") {
            url = URL(string: endpoint)!
        } else {
            url = baseURL.appendingPathComponent(endpoint)
        }
        
        // Create the Request with the URL
        var request = URLRequest(url: url)
        
        // Set the HTTP Method
        request.httpMethod = method.rawValue
        
        // Add the HTTP Headers from this instance of HTTPRequest
        headers?.forEach { (key, value) in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add the authorization
        if includeServiceLevelAuthorization, let auth = authorization, !(auth is HTTPNoAuthorization) {
            request.addValue(auth.value, forHTTPHeaderField: "Authorization")
        }
        
        // Add the additional HTTP Headers passed in (most likely from the HTTPService)
        if includeServiceLevelHeaders {
            // Add the service level headers
            additionalHeaders?.forEach { (key, value) in
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // If there's a request body, encode it and add it to the request
        if let body = body {
            if body is Data {
                request.httpBody = body as? Data
            } else {
                do {
                    request.httpBody = try JSONEncoder().encode(body)
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                } catch {
                    // Handle encoding error
                }
            }
        }
        
        // If there's no request body and there are params, add the params to the request
        earlyExitPoint: if request.httpBody == nil, let params = params {
            let newItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            guard var urlComponents = URLComponents(string: request.url!.absoluteString) else { break earlyExitPoint }
            var queryItems = urlComponents.queryItems ?? []
            queryItems.append(contentsOf: newItems)
            urlComponents.queryItems = queryItems
            request.url = urlComponents.url!
        }
        
        return request
    }
}

