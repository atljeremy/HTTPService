//
//  HTTPService.swift
//  HTTPService
//
//  Created by Jeremy Fox on 5/14/19.
//  Copyright © 2019. All rights reserved.
//

import Foundation
import Combine

/// A simple typealias that represents HTTP Headers
public typealias HTTPHeaders = [String: String]

/// A simple typealias that is meant to help express the purpose/intent of the URL
public typealias BaseURL = URL

public typealias HTTPResult<T> = Result<T?, HTTPServiceError>

public protocol HTTPService: AnyObject {
    
    associatedtype Builder: HTTPServiceBuildable
    associatedtype Authorization: HTTPAuthorization
    
    var urlSession: URLSession { get }
    var baseUrl: BaseURL { get }
    var headers: HTTPHeaders? { get }
    var authorization: Authorization? { get }
    
    init(authorization: Authorization?)
    
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPRequest
    
    @discardableResult
    func executeWithCancelation<T>(request: T) -> Task<Result<T.ResultType?, HTTPServiceError>, Never> where T : HTTPRequest
    
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPPagedRequest
    
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPDataRequest
    
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPRequestChainable
    
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPDownloadRequestChainable
    
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPRequest & HTTPRequestLifecycleAware
    
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPDownloadRequest
    
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T : HTTPDownloadRequest & HTTPRequestLifecycleAware
    
    @discardableResult
    func execute<T>(request: T) async -> HTTPResult<T.ResultType> where T: HTTPUploadRequest
}

extension HTTPURLResponse {
    var isFailure: Bool {
        return statusCode >= 400
    }
    
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
}
