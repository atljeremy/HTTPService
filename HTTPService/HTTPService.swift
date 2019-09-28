//
//  HTTPService.swift
//  HTTPService
//
//  Created by Jeremy Fox on 5/14/19.
//  Copyright © 2019. All rights reserved.
//

import Foundation

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
            
            if let response = response {
                print(response)
            }
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            guard error == nil else {
                handler(.failure(.requestFailed(error!.localizedDescription)))
                return
            }
            
            guard (response as? HTTPURLResponse)?.statusCode != 401 else {
                handler(.failure(.unauthorized("")))
                return
            }
            
            guard !(T.ResultType.self is HTTPResponseNoContent.Type) else {
                handler(.success(nil))
                return
            }
            
            guard let data = data, data.count > 0 else {
                handler(.failure(.emptyResponseData(response?.url?.absoluteString ?? "")))
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
    
    @discardableResult
    public func execute<T>(request: T, handler: @escaping (HTTPResult<T.ResultType>) -> Void) -> URLSessionTask where T : HTTPRequestChainable {
        let urlRequest = request.buildURLRequest(resolvingAgainst: baseUrl, with: headers, and: authorization)
        logRequestInfo(for: urlRequest)
        var task: URLSessionTask?
        request.willExecute(request: urlRequest)
        task = urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            
            if let response = response {
                print(response)
            }
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            guard error == nil else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.requestFailed(error!.localizedDescription)))
                return
            }
            
            guard (response as? HTTPURLResponse)?.statusCode != 401 else {
                handler(.failure(.unauthorized("")))
                return
            }
            
            guard let data = data, data.count > 0 else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.emptyResponseData(response?.url?.absoluteString ?? "")))
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
                            handler(.failure(.emptyResponseData(response?.url?.absoluteString ?? "")))
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
            
            if let response = response {
                print(response)
            }
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            guard error == nil else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.requestFailed(error!.localizedDescription)))
                return
            }
            
            guard (response as? HTTPURLResponse)?.statusCode != 401 else {
                handler(.failure(.unauthorized("")))
                return
            }
            
            guard let data = data, data.count > 0 else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.emptyResponseData(response?.url?.absoluteString ?? "")))
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
                            handler(.failure(.emptyResponseData(response?.url?.absoluteString ?? "")))
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
            
            if let response = response {
                print(response)
            }
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            guard error == nil else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.requestFailed(error!.localizedDescription)))
                return
            }
            
            guard (response as? HTTPURLResponse)?.statusCode != 401 else {
                handler(.failure(.unauthorized("")))
                return
            }
            
            guard let data = data, data.count > 0 else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.emptyResponseData(response?.url?.absoluteString ?? "")))
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
            
            if let response = response {
                print(response)
            }
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            guard error == nil else {
                handler(.failure(.requestFailed(error!.localizedDescription)))
                return
            }
            
            guard (response as? HTTPURLResponse)?.statusCode != 401 else {
                handler(.failure(.unauthorized("")))
                return
            }
            
            guard let url = url else {
                handler(.failure(.downloadFailed("Failing URL: \(response?.url?.absoluteString ?? "")")))
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
            
            if let response = response {
                print(response)
            }
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            guard error == nil else {
                request.didComplete(request: urlRequest, with: error)
                handler(.failure(.requestFailed(error!.localizedDescription)))
                return
            }
            
            guard (response as? HTTPURLResponse)?.statusCode != 401 else {
                handler(.failure(.unauthorized("")))
                return
            }
            
            guard let url = url else {
                let error = HTTPServiceError.downloadFailed("Failing URL: \(response?.url?.absoluteString ?? "")")
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
            
            if let response = response {
                print(response)
            }
            
            if let index = self?.tasks.firstIndex(of: task!) {
                self?.tasks.remove(at: index)
            }
            
            guard error == nil else {
                handler(.failure(.requestFailed(error!.localizedDescription)))
                return
            }
            
            guard (response as? HTTPURLResponse)?.statusCode != 401 else {
                handler(.failure(.unauthorized("")))
                return
            }
            
            guard let data = data, data.count > 0 else {
                handler(.failure(.emptyResponseData(response?.url?.absoluteString ?? "")))
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
