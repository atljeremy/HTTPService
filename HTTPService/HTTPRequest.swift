//
//  HTTPRequest.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/3/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public protocol HTTPRequest {
    associatedtype ResultType: Decodable
    associatedtype BodyType: Encodable
    
    var endpoint: String { get }
    var method: HTTPMethod { get }
    var params: [String: Any]? { get }
    var body: BodyType? { get }
    
    /// Used to set request specific headers.
    ///
    /// These should be headers that aren't something that should be used for all
    /// requests the corresponding service will make. Those types of headers
    /// should be added to the service's headers.
    var headers: [String: String]? { get }
    
    /// Used to tell the service if it's headers should be added to the request.
    ///
    /// Setting this to `true` will result in any headers, added to the corresponding
    /// service, being used in the request.
    ///
    /// Setting this to `false` will ensure the only headers sent in the request
    /// are that of the headers owned by the request itself.
    var includeServiceLevelHeaders: Bool { get }
    
    /// Used to tell the service if it's authorization should be added to the request.
    ///
    /// Setting this to `true` will result in the service's authorization being
    /// added to the Authorization header for the request.
    ///
    /// Setting this to `false` will result in the service's authoriztaion not
    /// being added to the request.
    var includeServiceLevelAuthorization: Bool { get }
    
    init(id: String?)
}

public struct HTTPResponseNoContent: Decodable {}

public struct HTTPRequestNoBody: Encodable {}

public protocol HTTPRequestLifecycleAware {
    associatedtype ResultType: Decodable
    
    func willExecute(request: URLRequest)
    @discardableResult
    func didComplete(request: URLRequest, receiving object: ResultType?) -> ResultType?
    func didComplete(request: URLRequest, with error: Error?)
}

public protocol HTTPDownloadRequest: HTTPRequest where ResultType == URL {}
public protocol HTTPUploadRequest: HTTPRequest where BodyType == Data {
    var fileUrl: URL? { get set }
    var fileType: String? { get set }
    
    init(id: String?, attachment fileUrl: URL, as fileType: String)
}

public protocol HTTPRequestChainableLifecycleAware: HTTPRequestLifecycleAware {
    associatedtype ChainedRequest: HTTPRequest
    associatedtype ParentRequestResultType
    
    @discardableResult
    func didComplete(chained request: URLRequest, receiving object: ChainedRequest.ResultType?) -> ParentRequestResultType?
}

public protocol HTTPDownloadRequestChainableLifecycleAware: HTTPRequestLifecycleAware {
    associatedtype ChainedRequest: HTTPDownloadRequest
    associatedtype ParentRequestResultType
    
    @discardableResult
    func didComplete(chained request: URLRequest, receiving object: ChainedRequest.ResultType?) -> ParentRequestResultType?
}

// Use from an HTTRequest to add a chained request that will execute after it's parent HTTPRequest completes.
public protocol HTTPRequestChainable: HTTPRequest, HTTPRequestChainableLifecycleAware {
    var chainedRequest: ChainedRequest { get }
}

// Use from an HTTPRequest to add a chaing download request that will execute after it's parent HTTP request complets.
public protocol HTTPDownloadRequestChainable: HTTPRequest, HTTPDownloadRequestChainableLifecycleAware {
    var chainedRequest: ChainedRequest { get }
}

extension HTTPRequest {
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
        if includeServiceLevelAuthorization, let auth = authorization {
            request.addValue(auth.value, forHTTPHeaderField: "Authorization")
        }
        
        // Add the additional HTTP Headers passed in (most likely from the HTTPSerivce)
        if includeServiceLevelHeaders {
            // Add the service level headers
            additionalHeaders?.forEach { (key, value) in
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // If there's a request body, encode it an add it to the request
        if let body = body {
            if body is Data {
                request.httpBody = body as? Data
            } else {
                do {
                    request.httpBody = try JSONEncoder().encode(body)
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                } catch {}
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
