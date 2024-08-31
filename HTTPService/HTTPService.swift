//
//  HTTPService.swift
//  HTTPService
//
//  Created by Jeremy Fox on 5/14/19.
//  Copyright © 2019. All rights reserved.
//

import Foundation
import Combine

/// A typealias representing HTTP headers as a dictionary where the key is a `String` representing the header field
/// and the value is a `String` representing the header value.
///
/// Example:
/// ```swift
/// let headers: HTTPHeaders = ["Content-Type": "application/json"]
/// ```
public typealias HTTPHeaders = [String: String]

/// A typealias representing a base URL for HTTP requests.
///
/// This typealias is used to express the purpose or intent of a `URL`, making it clear that the `URL` represents a base URL.
///
/// Example:
/// ```swift
/// let baseUrl: BaseURL = URL(string: "https://api.example.com")!
/// ```
public typealias BaseURL = URL

/// A typealias representing the result of an HTTP operation, which can either be a success with an optional result of type `T?`,
/// or a failure with an `HTTPServiceError`.
///
/// This typealias simplifies handling the outcome of HTTP requests.
///
/// Example:
/// ```swift
/// func handleResult(result: HTTPResult<Data>) {
///     switch result {
///     case .success(let data):
///         // Handle successful response
///     case .failure(let error):
///         // Handle error
///     }
/// }
/// ```
public typealias HTTPResult<T> = Result<T?, HTTPServiceError>

/// An extension to `HTTPURLResponse` that provides additional functionality for checking failure status
/// and converting HTTP status codes to `HTTPServiceError`.
extension HTTPURLResponse {
    
    /// A Boolean value indicating whether the response status code represents a failure.
    ///
    /// This property returns `true` if the status code is greater than or equal to 400, indicating a client or server error.
    var isFailure: Bool {
        return statusCode >= 400
    }
    
    /// Converts the response status code to a corresponding `HTTPServiceError`.
    ///
    /// This method checks the response status code and returns an appropriate `HTTPServiceError` if the status code indicates a failure.
    /// If the status code does not represent a failure, this method returns `nil`.
    ///
    /// - Parameter message: An optional message to include with the error.
    /// - Returns: An `HTTPServiceError` corresponding to the response status code, or `nil` if the status code is not a failure.
    func httpServiceError(with message: String? = nil) -> HTTPServiceError? {
        guard isFailure else { return nil }
        
        switch statusCode {
        case 400: return .badRequest(message ?? "")
        case 401: return .unauthorized(message ?? "")
        case 403: return .forbidden(message ?? "")
        case 409: return .conflict(message ?? "")
        case 422: return .unprocessableEntity(message ?? "")
        case 500: return .serverError(message ?? "")
        default: return .requestFailed(message ?? "")
        }
    }
}

/// A protocol that defines the requirements for an HTTP-based service.
///
/// Types that conform to `HTTPService` must implement various methods to execute different types of HTTP requests,
/// such as `HTTPRequest`, `HTTPPagedRequest`, and `HTTPDownloadRequest`. This protocol provides a flexible foundation
/// for building services that interact with HTTP APIs.
///
/// ### Associated Types:
/// - `Builder`: A type conforming to `HTTPServiceBuildable`, responsible for building instances of the service.
/// - `Authorization`: A type conforming to `HTTPAuthorization`, which handles the authorization logic for the service.
///
/// - SeeAlso: `HTTPServiceBuildable`, `HTTPAuthorization`
public protocol HTTPService: AnyObject {
    
    /// The associated builder type, which must conform to `HTTPServiceBuildable`.
    associatedtype Builder: HTTPServiceBuildable
    
    /// The associated authorization type, which must conform to `HTTPAuthorization`.
    associatedtype Authorization: HTTPAuthorization
    
    /// The `URLSession` used to execute HTTP requests.
    var urlSession: URLSession { get }
    
    /// The base URL for the service, used as the starting point for constructing requests.
    var baseUrl: BaseURL { get }
    
    /// Optional headers to be included in all requests made by the service.
    var headers: HTTPHeaders? { get }
    
    /// Optional authorization handler used to manage authorization logic for the service.
    var authorization: Authorization? { get }
    
    /// Initializes a new instance of the service with the specified authorization handler.
    ///
    /// - Parameter authorization: The authorization handler used by the service.
    init(authorization: Authorization?)
    
    /// Executes a given HTTP request asynchronously and returns the result.
    ///
    /// - Parameter request: The HTTP request to execute.
    /// - Returns: A `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPRequest
    
    /// Executes a given HTTP request asynchronously and returns a `Task` that can be used to cancel the request.
    ///
    /// - Parameter request: The HTTP request to execute.
    /// - Returns: A `Task` that returns a `Result` containing the result of the request or an error if the request fails.
    @discardableResult
    func executeWithCancelation<T>(request: T) -> Task<Result<T.ResultType?, HTTPServiceError>, Never> where T : HTTPRequest
    
    /// Executes a given paged HTTP request asynchronously and returns the result.
    ///
    /// - Parameter request: The paged HTTP request to execute.
    /// - Returns: A `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPPagedRequest

    /// Executes a given paged HTTP request asynchronously and returns a `Task` that can be used to cancel the request.
    ///
    /// - Parameter request: The paged HTTP request to execute.
    /// - Returns: A `Task` that returns a `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPPagedRequest
    
    /// Executes a given data request asynchronously and returns the result.
    ///
    /// - Parameter request: The data request to execute.
    /// - Returns: A `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPDataRequest

    /// Executes a given data request asynchronously and returns a `Task` that can be used to cancel the request.
    ///
    /// - Parameter request: The data request to execute.
    /// - Returns: A `Task` that returns a `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPDataRequest
    
    /// Executes a given chainable HTTP request asynchronously and returns the result.
    ///
    /// - Parameter request: The chainable HTTP request to execute.
    /// - Returns: A `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPRequestChainable

    /// Executes a given chainable HTTP request asynchronously and returns a `Task` that can be used to cancel the request.
    ///
    /// - Parameter request: The chainable HTTP request to execute.
    /// - Returns: A `Task` that returns a `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPRequestChainable
    
    /// Executes a given chainable HTTP download request asynchronously and returns the result.
    ///
    /// - Parameter request: The chainable HTTP download request to execute.
    /// - Returns: A `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPDownloadRequestChainable

    /// Executes a given chainable HTTP download request asynchronously and returns a `Task` that can be used to cancel the request.
    ///
    /// - Parameter request: The chainable HTTP download request to execute.
    /// - Returns: A `Task` that returns a `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPDownloadRequestChainable 
    
    /// Executes a given HTTP request that is also lifecycle aware asynchronously and returns the result.
    ///
    /// - Parameter request: The HTTP request to execute.
    /// - Returns: A `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPRequest & HTTPRequestLifecycleAware

    /// Executes a given HTTP request that is also lifecycle aware asynchronously and returns a `Task` that can be used to cancel the request.
    ///
    /// - Parameter request: The HTTP request to execute.
    /// - Returns: A `Task` that returns a `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPRequest & HTTPRequestLifecycleAware
    
    /// Executes a given HTTP download request asynchronously and returns the result.
    ///
    /// - Parameter request: The HTTP download request to execute.
    /// - Returns: A `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPDownloadRequest

    /// Executes a given HTTP download request asynchronously and returns a `Task` that can be used to cancel the request.
    ///
    /// - Parameter request: The HTTP download request to execute.
    /// - Returns: A `Task` that returns a `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPDownloadRequest

    /// Executes a given HTTP download request that is also lifecycle aware asynchronously and returns the result.
    ///
    /// - Parameter request: The HTTP download request to execute.
    /// - Returns: A `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPDownloadRequest & HTTPRequestLifecycleAware

    /// Executes a given HTTP download request that is also lifecycle aware asynchronously and returns a `Task` that can be used to cancel the request.
    ///
    /// - Parameter request: The HTTP download request to execute.
    /// - Returns: A `Task` that returns a `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPDownloadRequest & HTTPRequestLifecycleAware

    /// Executes a given HTTP upload request asynchronously and returns the result.
    ///
    /// - Parameter request: The HTTP upload request to execute.
    /// - Returns: A `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T: HTTPUploadRequest

    /// Executes a given HTTP upload request and returns a `Task` that can be used to cancel the request.
    ///
    /// - Parameter request: The HTTP download request to execute.
    /// - Returns: A `Task` that returns a `HTTPResult` containing the result of the request or an error if the request fails.
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPUploadRequest
}

extension HTTPService {
    private func logRequestInfo(for request: URLRequest) {
        var info = """
        
        --------- HTTPService Executing HTTP Request ---------
        URL: \(request.url?.absoluteString ?? "No URL, wtf?!")
        Headers: \(request.allHTTPHeaderFields ?? [:])
        """
        do {
            if let data = request.httpBody {
                info += "\nBody: \(try JSONSerialization.jsonObject(with: data, options: []))"
            }
        } catch {}
        info += "\n---------------------------------------------------"
        print(info)
    }
    
    @discardableResult
    public func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPRequest {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        do {
            let (data, urlResponse) = try await urlSession.data(for: urlRequest)
            
            guard let response = urlResponse as? HTTPURLResponse else {
                return .failure(.serverError(""))
            }
            
            guard !response.isFailure else {
                return .failure(response.httpServiceError(with: "") ?? .requestFailed(""))
            }
            
            guard !(T.ResultType.self is HTTPResponseNoContent.Type) else {
                return .success(nil)
            }
            
            guard data.count > 0 else {
                return .failure(.emptyResponseData(response.url?.absoluteString ?? ""))
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(.iso8601Full)
            let obj = try decoder.decode(T.ResultType.self, from: data)
            return .success(obj)
        } catch let decodingError as DecodingError {
            return .failure(.jsonDecodingError(decodingError.localizedDescription))
        } catch {
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
    
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPRequest {
        return Task {
            await execute(request: request)
        }
    }
    
    @discardableResult
    public func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPPagedRequest {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        do {
            let (data, urlResponse) = try await urlSession.data(for: urlRequest)
            
            guard let response = urlResponse as? HTTPURLResponse else {
                return .failure(.serverError(""))
            }
            
            guard !response.isFailure else {
                return .failure(response.httpServiceError(with: "") ?? .requestFailed(""))
            }
            
            guard !(T.ResultType.self is HTTPResponseNoContent.Type) else {
                return .success(nil)
            }
            
            guard data.count > 0 else {
                return .failure(.emptyResponseData(response.url?.absoluteString ?? ""))
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(.iso8601Full)
            var obj = try decoder.decode(T.ResultType.self, from: data)
            let headers = response.allHeaderFields
            let links = (headers["Link"] as? String)?.httpLinks
            obj.links = PagedLinks(first: links?[.first], previous: links?[.previous], next: links?[.next], last: links?[.last])
            if let perPage = headers["per-page"] as? String {
                obj.perPage = Int(perPage)
            }
            if let total = headers["total"] as? String {
                obj.total = Int(total)
            }
            return .success(obj)
        } catch let decodingError as DecodingError  {
            return .failure(.jsonDecodingError(decodingError.localizedDescription))
        } catch {
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
    
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPPagedRequest {
        return Task {
            await execute(request: request)
        }
    }
    
    @discardableResult
    public func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPDataRequest {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        do {
            let (data, urlResponse) = try await urlSession.data(for: urlRequest)
            
            guard let response = urlResponse as? HTTPURLResponse else {
                return .failure(.serverError(""))
            }
            
            guard !response.isFailure else {
                return .failure(response.httpServiceError(with: "") ?? .requestFailed(""))
            }
            
            guard data.count > 0 else {
                return .failure(.emptyResponseData(response.url?.absoluteString ?? ""))
            }

            return .success(data)
        } catch {
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
    
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPDataRequest {
        return Task {
            await execute(request: request)
        }
    }
    
    @discardableResult
    public func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPRequestChainable {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        request.willExecute(request: urlRequest)
        do {
            let (data, urlResponse) = try await urlSession.data(for: urlRequest)
            
            guard let response = urlResponse as? HTTPURLResponse else {
                let error = HTTPServiceError.serverError("")
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
            
            guard !response.isFailure else {
                let error = response.httpServiceError(with: "") ?? .requestFailed("")
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
            
            guard data.count > 0 else {
                let error = HTTPServiceError.emptyResponseData(response.url?.absoluteString ?? "")
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(.iso8601Full)
            var obj = try decoder.decode(T.ResultType.self, from: data)
            obj = request.didComplete(request: urlRequest, receiving: obj) ?? obj
            let result = await execute(request: request.chainedRequest)
            switch result {
            case let .success(chainedObj):
                guard let chainedObj = chainedObj else {
                    request.didComplete(request: urlRequest, with: nil)
                    return .failure(.emptyResponseData(response.url?.absoluteString ?? ""))
                }
                obj = (request.didComplete(chained: urlRequest, receiving: chainedObj) as? T.ResultType) ?? obj
                return .success(obj)
            case let .failure(error):
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
        } catch let decodingError as DecodingError  {
            request.didComplete(request: urlRequest, with: decodingError)
            return .failure(.jsonDecodingError(decodingError.localizedDescription))
        } catch {
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
    
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPRequestChainable {
        return Task {
            await execute(request: request)
        }
    }
    
    @discardableResult
    public func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPDownloadRequestChainable {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        request.willExecute(request: urlRequest)
        do {
            let (data, urlResponse) = try await urlSession.data(for: urlRequest)
            
            guard let response = urlResponse as? HTTPURLResponse else {
                let error = HTTPServiceError.serverError("")
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
            
            guard !response.isFailure else {
                let error = response.httpServiceError(with: "") ?? .requestFailed("")
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
            
            guard data.count > 0 else {
                let error = HTTPServiceError.emptyResponseData(response.url?.absoluteString ?? "")
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(.iso8601Full)
            var obj = try decoder.decode(T.ResultType.self, from: data)
            obj = request.didComplete(request: urlRequest, receiving: obj) ?? obj
            let result = await execute(request: request.chainedRequest)
            switch result {
            case let .success(chainedObj):
                guard let chainedObj = chainedObj else {
                    request.didComplete(request: urlRequest, with: nil)
                    return .failure(.emptyResponseData(response.url?.absoluteString ?? ""))
                }
                obj = (request.didComplete(chained: urlRequest, receiving: chainedObj) as? T.ResultType) ?? obj
                return .success(obj)
            case let .failure(error):
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
        } catch let decodingError as DecodingError  {
            request.didComplete(request: urlRequest, with: decodingError)
            return .failure(.jsonDecodingError(decodingError.localizedDescription))
        } catch {
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
    
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPDownloadRequestChainable {
        return Task {
            await execute(request: request)
        }
    }
    
    @discardableResult
    public func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPRequest & HTTPRequestLifecycleAware {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        request.willExecute(request: urlRequest)
        do {
            let (data, urlResponse) = try await urlSession.data(for: urlRequest)
            
            guard let response = urlResponse as? HTTPURLResponse else {
                let error = HTTPServiceError.serverError("")
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
            
            guard !response.isFailure else {
                let error = response.httpServiceError(with: "") ?? .requestFailed("")
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
            
            guard data.count > 0 else {
                let error = HTTPServiceError.emptyResponseData(response.url?.absoluteString ?? "")
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(.iso8601Full)
            let obj = try decoder.decode(T.ResultType.self, from: data)
            return .success(request.didComplete(request: urlRequest, receiving: obj) ?? obj)
        } catch let decodingError as DecodingError  {
            request.didComplete(request: urlRequest, with: decodingError)
            return .failure(.jsonDecodingError(decodingError.localizedDescription))
        } catch {
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
    
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPRequest & HTTPRequestLifecycleAware {
        return Task {
            await execute(request: request)
        }
    }
    
    @discardableResult
    public func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPDownloadRequest {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers)
        logRequestInfo(for: urlRequest)
        do {
            let (url, urlResponse) = try await urlSession.download(for: urlRequest)
            
            guard let response = urlResponse as? HTTPURLResponse else {
                return .failure(.serverError(""))
            }
            
            guard !response.isFailure else {
                return .failure(response.httpServiceError(with: "") ?? .requestFailed(""))
            }
            
            guard !url.absoluteString.isEmpty else {
                return .failure(.downloadFailed("Failing URL: \(response.url?.absoluteString ?? "")"))
            }
            
            return .success(url)
        } catch {
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
    
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPDownloadRequest {
        return Task {
            await execute(request: request)
        }
    }
    
    @discardableResult
    public func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T: HTTPDownloadRequest & HTTPRequestLifecycleAware {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        request.willExecute(request: urlRequest)
        do {
            let (url, urlResponse) = try await urlSession.download(for: urlRequest)
            
            guard let response = urlResponse as? HTTPURLResponse else {
                let error = HTTPServiceError.serverError("")
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
            
            guard !response.isFailure else {
                let error = response.httpServiceError(with: "") ?? .requestFailed("")
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
            
            guard !url.absoluteString.isEmpty else {
                let error = HTTPServiceError.downloadFailed("Failing URL: \(response.url?.absoluteString ?? "")")
                request.didComplete(request: urlRequest, with: error)
                return .failure(error)
            }
            
            return .success(request.didComplete(request: urlRequest, receiving: url) ?? url)
        } catch {
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
    
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPDownloadRequest & HTTPRequestLifecycleAware {
        return Task {
            await execute(request: request)
        }
    }
    
    @discardableResult
    public func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T: HTTPUploadRequest {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        do {
            guard let body = urlRequest.httpBody else {
                return .failure(.badRequest("Missing body data"))
            }
            
            let (data, urlResponse) = try await urlSession.upload(for: urlRequest, from: body)
            
            guard let response = urlResponse as? HTTPURLResponse else {
                return .failure(.serverError(""))
            }
            
            guard !response.isFailure else {
                return .failure(response.httpServiceError(with: "") ?? .requestFailed(""))
            }
            
            guard data.count > 0 else {
                return .failure(.emptyResponseData(response.url?.absoluteString ?? ""))
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(.iso8601Full)
            let obj = try decoder.decode(T.ResultType.self, from: data)
            return .success(obj)
        } catch let decodingError as DecodingError  {
            return .failure(.jsonDecodingError(decodingError.localizedDescription))
        } catch {
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
    
    @discardableResult
    public func executeWithCancelation<T>(request: T) -> Task<HTTPResult<T.ResultType>, Never> where T : HTTPUploadRequest {
        return Task {
            await execute(request: request)
        }
    }
}
