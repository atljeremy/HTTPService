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

public protocol HTTPService: class {
    
    associatedtype Builder: HTTPServiceBuildable
    associatedtype Authorization: HTTPAuthorization
    
    var urlSession: URLSession { get }
    var tasks: [URLSessionTask] { get set }
    var baseUrl: BaseURL { get }
    var headers: HTTPHeaders? { get }
    var authorization: Authorization? { get }
    
    init(authorization: Authorization?)
    
    @discardableResult
    func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPRequest
    
    @discardableResult
    func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPPagedRequest
    
    @discardableResult
    func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPDataRequest
    
    @discardableResult
    func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPRequestChainable
    
    @discardableResult
    func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPDownloadRequestChainable
    
    @discardableResult
    func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPRequest & HTTPRequestLifecycleAware
    
    @discardableResult
    func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPDownloadRequest
    
    @discardableResult
    func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPDownloadRequest & HTTPRequestLifecycleAware
    
    @discardableResult
    func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T: HTTPUploadRequest
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
    public func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPRequest {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        var task: URLSessionTask?
        task = urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            if let response = response {
                print(response)
            }
            
            guard let response = response as? HTTPURLResponse else {
                handler(.failure(.serverError(error?.localizedDescription ?? "")))
                return
            }
            
            guard !response.isFailure else {
                handler(.failure(response.httpServiceError(with: error?.localizedDescription) ?? .serverError("")))
                return
            }
            
            guard !(T.ResultType.self is HTTPResponseNoContent.Type) else {
                handler(.success(nil))
                return
            }
            
            guard let data = data, data.count > 0 else {
                handler(.failure(.emptyResponseData(response.url?.absoluteString ?? "")))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(.iso8601Full)
                let obj = try decoder.decode(T.ResultType.self, from: data)
                handler(.success(obj))
            } catch let e {
                handler(.failure(.jsonDecodingError(e.localizedDescription)))
            }
        }
        tasks.append(task!)
        task!.resume()
        return task!
    }
    
    @available(iOS 13.0, *)
    public func execute<T>(request: T) -> AnyPublisher<T.ResultType, Error> where T : HTTPRequest {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.iso8601Full)
        var task: AnyPublisher<T.ResultType, Error>
        task = urlSession.dataTaskPublisher(for: urlRequest)
            .tryMap() {
                print($0.response)

                guard let response = $0.response as? HTTPURLResponse else { throw HTTPServiceError.serverError("") }

                guard !response.isFailure else { throw response.httpServiceError(with: "") ?? .serverError("") }

                guard $0.data.count > 0 else { throw HTTPServiceError.emptyResponseData(response.url?.absoluteString ?? "") }
                
                return $0.data
            }
            .decode(type: T.ResultType.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            
        return task
    }
    
    @discardableResult
    public func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPPagedRequest {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        var task: URLSessionTask?
        task = urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            if let response = response {
                print(response)
            }
            
            guard let response = response as? HTTPURLResponse else {
                handler(.failure(.serverError(error?.localizedDescription ?? "")))
                return
            }
            
            guard !response.isFailure else {
                handler(.failure(response.httpServiceError(with: error?.localizedDescription) ?? .serverError("")))
                return
            }
            
            guard !(T.ResultType.self is HTTPResponseNoContent.Type) else {
                handler(.success(nil))
                return
            }
            
            guard let data = data, data.count > 0 else {
                handler(.failure(.emptyResponseData(response.url?.absoluteString ?? "")))
                return
            }
            
            do {
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
                handler(.success(obj))
            } catch let e {
                handler(.failure(.jsonDecodingError(e.localizedDescription)))
            }
        }
        tasks.append(task!)
        task!.resume()
        return task!
    }
    
    @discardableResult
    public func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPDataRequest {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        var task: URLSessionTask?
        task = urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            if let response = response {
                print(response)
            }
            
            guard let response = response as? HTTPURLResponse else {
                handler(.failure(.serverError(error?.localizedDescription ?? "")))
                return
            }
            
            guard !response.isFailure else {
                handler(.failure(response.httpServiceError(with: error?.localizedDescription) ?? .serverError("")))
                return
            }
            
            guard let data = data, data.count > 0 else {
                handler(.failure(.emptyResponseData(response.url?.absoluteString ?? "")))
                return
            }
            
            handler(.success(data))
        }
        tasks.append(task!)
        task!.resume()
        return task!
    }
    
    @discardableResult
    public func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPRequestChainable {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        var task: URLSessionTask?
        request.willExecute(request: urlRequest)
        task = urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            if let response = response {
                print(response)
            }
            
            guard let response = response as? HTTPURLResponse else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.serverError(error?.localizedDescription ?? "")))
                return
            }
            
            guard !response.isFailure else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(response.httpServiceError(with: error?.localizedDescription) ?? .serverError("")))
                return
            }
            
            guard let data = data, data.count > 0 else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.emptyResponseData(response.url?.absoluteString ?? "")))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(.iso8601Full)
                var obj = try decoder.decode(T.ResultType.self, from: data)
                obj = request.didComplete(request: urlRequest, receiving: obj) ?? obj
                self?.execute(request: request.chainedRequest) { (result) in
                    switch result {
                    case let .success(chainedObj):
                        guard let chainedObj = chainedObj else {
                            request.didComplete(request: urlRequest, with: nil)
                            handler(.failure(.emptyResponseData(response.url?.absoluteString ?? "")))
                            return
                        }
                        obj = (request.didComplete(chained: urlRequest, receiving: chainedObj) as? T.ResultType) ?? obj
                        handler(.success(obj))
                    case let .failure(error):
                        request.didComplete(request: urlRequest, with: error)
                        handler(.failure(error))
                    }
                }
            } catch let e {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.jsonDecodingError(e.localizedDescription)))
            }
        }
        tasks.append(task!)
        task!.resume()
        return task!
    }
    
    @discardableResult
    public func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPDownloadRequestChainable {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        var task: URLSessionTask?
        request.willExecute(request: urlRequest)
        task = urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            if let response = response {
                print(response)
            }
            
            guard let response = response as? HTTPURLResponse else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.serverError(error?.localizedDescription ?? "")))
                return
            }
            
            guard !response.isFailure else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(response.httpServiceError(with: error?.localizedDescription) ?? .serverError("")))
                return
            }
            
            guard let data = data, data.count > 0 else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.emptyResponseData(response.url?.absoluteString ?? "")))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(.iso8601Full)
                var obj = try decoder.decode(T.ResultType.self, from: data)
                obj = request.didComplete(request: urlRequest, receiving: obj) ?? obj
                self?.execute(request: request.chainedRequest) { (result) in
                    switch result {
                    case let .success(chainedObj):
                        guard let chainedObj = chainedObj else {
                            request.didComplete(request: urlRequest, with: nil)
                            handler(.failure(.emptyResponseData(response.url?.absoluteString ?? "")))
                            return
                        }
                        obj = (request.didComplete(chained: urlRequest, receiving: chainedObj) as? T.ResultType) ?? obj
                        handler(.success(obj))
                    case let .failure(error):
                        request.didComplete(request: urlRequest, with: error)
                        handler(.failure(error))
                    }
                }
            } catch let e {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.jsonDecodingError(e.localizedDescription)))
            }
        }
        tasks.append(task!)
        task!.resume()
        return task!
    }
    
    @discardableResult
    public func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPRequest & HTTPRequestLifecycleAware {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        var task: URLSessionTask?
        request.willExecute(request: urlRequest)
        task = urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            if let response = response {
                print(response)
            }
            
            guard let response = response as? HTTPURLResponse else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.serverError(error?.localizedDescription ?? "")))
                return
            }
            
            guard !response.isFailure else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(response.httpServiceError(with: error?.localizedDescription) ?? .serverError("")))
                return
            }
            
            guard let data = data, data.count > 0 else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.emptyResponseData(response.url?.absoluteString ?? "")))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(.iso8601Full)
                let obj = try decoder.decode(T.ResultType.self, from: data)
                handler(.success(request.didComplete(request: urlRequest, receiving: obj) ?? obj))
            } catch let e {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.jsonDecodingError(e.localizedDescription)))
            }
        }
        tasks.append(task!)
        task!.resume()
        return task!
    }
    
    @discardableResult
    public func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPDownloadRequest {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers)
        logRequestInfo(for: urlRequest)
        var task: URLSessionTask?
        task = urlSession.downloadTask(with: urlRequest) { [weak self] (url, response, error) in
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            if let response = response {
                print(response)
            }
            
            guard let response = response as? HTTPURLResponse else {
                handler(.failure(.serverError(error?.localizedDescription ?? "")))
                return
            }
            
            guard !response.isFailure else {
                handler(.failure(response.httpServiceError(with: error?.localizedDescription) ?? .serverError("")))
                return
            }
            
            guard let url = url else {
                handler(.failure(.downloadFailed("Failing URL: \(response.url?.absoluteString ?? "")")))
                return
            }
            
            handler(.success(url))
        }
        tasks.append(task!)
        task!.resume()
        return task!
    }
    
    @discardableResult
    public func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T: HTTPDownloadRequest & HTTPRequestLifecycleAware {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        var task: URLSessionTask?
        request.willExecute(request: urlRequest)
        task = urlSession.downloadTask(with: urlRequest) { [weak self] (url, response, error) in
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            if let response = response {
                print(response)
            }
            
            guard let response = response as? HTTPURLResponse else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.serverError(error?.localizedDescription ?? "")))
                return
            }
            
            guard !response.isFailure else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(response.httpServiceError(with: error?.localizedDescription) ?? .serverError("")))
                return
            }
            
            guard let url = url else {
                let error = HTTPServiceError.downloadFailed("Failing URL: \(response.url?.absoluteString ?? "")")
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(error))
                return
            }
            
            handler(.success(request.didComplete(request: urlRequest, receiving: url) ?? url))
        }
        tasks.append(task!)
        task!.resume()
        return task!
    }
    
    @discardableResult
    public func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T: HTTPUploadRequest {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        var task: URLSessionTask?
        task = urlSession.uploadTask(with: urlRequest, from: urlRequest.httpBody) { [weak self] (data, response, error) in
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            if let response = response {
                print(response)
            }
            
            guard let response = response as? HTTPURLResponse else {
                handler(.failure(.serverError(error?.localizedDescription ?? "")))
                return
            }
            
            guard !response.isFailure else {
                handler(.failure(response.httpServiceError(with: error?.localizedDescription) ?? .serverError("")))
                return
            }
            
            guard let data = data, data.count > 0 else {
                handler(.failure(.emptyResponseData(response.url?.absoluteString ?? "")))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(.iso8601Full)
                let obj = try decoder.decode(T.ResultType.self, from: data)
                handler(.success(obj))
            } catch let e {
                handler(.failure(.jsonDecodingError(e.localizedDescription)))
            }
        }
        tasks.append(task!)
        task!.resume()
        return task!
    }
}
