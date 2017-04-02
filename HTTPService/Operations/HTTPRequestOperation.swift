//
//  HTTPRequestOperation.swift
//
//  Created by Jeremy Fox on 2/24/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Foundation
import UIKit

open class HTTPRequestOperation: Operation {
    
    typealias SuccessHandler = (HTTPRequestOperation, Data?) -> Void
    typealias FailureHandler = (HTTPRequestOperation, Error) -> Void
    
    fileprivate let errorDomain = "HTTPRequestOperationErrorDomain"
    
    var _executing = false
    open override var isExecuting: Bool {
        get {
            return _executing
        }
        set {
            willChangeValue(forKey: "isExecuting")
            _executing = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    open var _finished = false
    open override var isFinished: Bool {
        get {
            return _finished
        }
        set {
            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    
    open fileprivate(set) var request: HTTPRequest
    open fileprivate(set) var response: HTTPURLResponse?
    open fileprivate(set) var responseData: Data?
    
    fileprivate var _error: Error?
    open fileprivate(set) var error: Error? {
        get {
            if _error != nil {
                return _error
            } else if self.response == nil {
                let userInfo = [NSLocalizedDescriptionKey: "Request failed"]
                return NSError(domain: errorDomain, code: NSURLErrorResourceUnavailable, userInfo: userInfo)
            }
            return nil
        }
        set {
            _error = newValue
        }
    }
    
    open override var isAsynchronous: Bool {
        get { return true }
    }
    
    //MARK: - Instantiation
    
    public required init(request: HTTPRequest) {
        self.request = request
        super.init()
    }
    
    //MARK: - Completion Blocks
    
    func setCompletionHandlerWithSuccess(_ success: @escaping SuccessHandler, failure: @escaping FailureHandler) {
        completionBlock = {
            if let _error = self.error {
                DispatchQueue.main.async {
                    failure(self, _error)
                }
            } else {
                DispatchQueue.main.async {
                    success(self, self.responseData)
                }
            }
        }
    }
    
    //MARK: - NSOperation Handling
    
    open override func main() {
        if isCancelled {
            completeOperation()
            return
        }
        
        if !Reachability.requestReachability() {
            error = NSError(domain: errorDomain, code: 1414, userInfo: [NSLocalizedDescriptionKey: "No internet connection currently available."])
            cancel()
            completeOperation()
            return
        }
        
        if isCancelled {
            completeOperation()
            return
        }
        
        let URLRequest: URLRequest
        if let _request = request.urlRequest() {
            URLRequest = _request
        } else {
            cancel()
            completeOperation()
            return
        }
        
        let semephore = DispatchSemaphore(value: 0)
        
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: self, delegateQueue: OperationQueue.current)
        let task = session.dataTask(with: URLRequest) { data, response, error in
            
            if let _response = response as? HTTPURLResponse {
                let statusCode = _response.statusCode
                self.response = _response
                
                if self.request.acceptibleStatusCodeRange ~= statusCode {
                    
                    self.responseData = data
                    self.error = error
                    
                } else {
                    
                    guard let _data = data else {
                        self.error = self.invlaidStatusCodeError(statusCode)
                        self.cancel()
                        return
                    }
                    
                    do {
                        let errorJSON = try JSONSerialization.jsonObject(with: _data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: Any]
                        guard let _error = errorJSON?["error"] as? String else {
                            self.error = self.invlaidStatusCodeError(statusCode)
                            self.cancel()
                            return
                        }
                        
                        self.error = NSError(domain: self.errorDomain, code: 9393, userInfo: [NSLocalizedDescriptionKey: _error])
                        
                    } catch _ {
                        self.error = self.invlaidStatusCodeError(statusCode)
                    }
                
                    self.cancel()
                }
            } else {
                self.error = error
                self.cancel()
            }
            
            semephore.signal()
        }
        
        task.resume()
        
        let timeout = Int(request.timeout)
        let additionalWait = 1
        let totalWait = DispatchTimeInterval.seconds(timeout + additionalWait)
        _ = semephore.wait(timeout: .now() + totalWait)
        
        if isCancelled {
            completeOperation()
            return
        }
        
        if response?.statusCode != 204 && responseData == nil {
            let userInfo = [NSLocalizedDescriptionKey: "Received empty response"]
            error = NSError(domain: errorDomain, code: NSURLErrorResourceUnavailable, userInfo: userInfo)
            completeOperation()
            return
        }
        
        completeOperation()
    }
    
    open override func start() {
        if isCancelled {
            isFinished = true
            return
        }
        isExecuting = true
        main()
    }
    
    func completeOperation() {
        isExecuting = false
        isFinished = true
    }
    
    func invlaidStatusCodeError(_ statusCode: Int) -> NSError {
        return NSError(domain: self.errorDomain, code: 3333, userInfo: [NSLocalizedDescriptionKey: "Status code received (\(statusCode)) was not within acceptable range (\(self.request.acceptibleStatusCodeRange.lowerBound))-(\(self.request.acceptibleStatusCodeRange.upperBound))"])
    }
    
}

extension HTTPRequestOperation: URLSessionDelegate {
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        
        print("\(#file): \(#function)")
        
    }
    
    //    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
    //
    //        print("\(__FILE__): \(__FUNCTION__)")
    //
    //    }
    
}

extension HTTPRequestOperation: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        print("\(#file): \(#function)")
        
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        print("\(#file): \(#function)")
        
    }
}

extension HTTPRequestOperation: URLSessionTaskDelegate {
    
    //    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
    //
    //        print("\(__FILE__): \(__FUNCTION__)")
    //
    //    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        
        print("\(#file): \(#function)")
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        print("\(#file): \(#function)")
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        print("\(#file): \(#function)")
        
    }
}
