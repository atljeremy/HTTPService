//
//  HTTPRequestOperation.swift
//
//  Created by Jeremy Fox on 2/24/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import UIKit

public class HTTPRequestOperation: NSOperation {
    
    typealias SuccessHandler = (HTTPRequestOperation, NSData?) -> Void
    typealias FailureHandler = (HTTPRequestOperation, NSError) -> Void
    
    private let errorDomain = "HTTPRequestOperationErrorDomain"
    
    private var isExecuting = false
    public private(set) override var executing: Bool {
        get { return isExecuting }
        set {
            willChangeValueForKey("isExecuting")
            isExecuting = newValue
            didChangeValueForKey("isExecuting")
        }
    }
    
    private var isFinished = false
    public override var finished: Bool {
        get { return isFinished }
        set {
            willChangeValueForKey("isFinished")
            isFinished = newValue
            didChangeValueForKey("isFinished")
        }
    }
    
    public private(set) var request: HTTPRequest
    public private(set) var response: NSHTTPURLResponse?
    public private(set) var responseData: NSData?
    
    private var _error: NSError?
    public private(set) var error: NSError? {
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
    
    public override var asynchronous: Bool {
        get { return true }
    }
    
    //MARK: ----------------------
    //MARK: Instantiation
    //MARK: ----------------------
    
    public required init(request: HTTPRequest) {
        self.request = request
        super.init()
    }
    
    //MARK: ----------------------
    //MARK: Completion Blocks
    //MARK: ----------------------
    
    func setCompletionHandlerWithSuccess(success: SuccessHandler, failure: FailureHandler) {
        completionBlock = {
            if let _error = self.error {
                dispatch_async(dispatch_get_main_queue()) {
                    failure(self, _error)
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    success(self, self.responseData)
                }
            }
        }
    }
    
    //MARK: ----------------------
    //MARK: NSOperation Handling
    //MARK: ----------------------
    
    public override func main() {
        if cancelled {
            completeOperation()
            return
        }
        
        if !Reachability.requestReachability() {
            error = NSError(domain: errorDomain, code: 1414, userInfo: [NSLocalizedDescriptionKey: "No internet connection currently available."])
            cancel()
            completeOperation()
            return
        }
        
        if cancelled {
            completeOperation()
            return
        }
        
        let URLRequest: NSMutableURLRequest
        if let _request = request.mutableURLRequest() {
            URLRequest = _request
        } else {
            cancel()
            completeOperation()
            return
        }
        
        let semephore = dispatch_semaphore_create(0)
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.currentQueue())
        session.dataTaskWithRequest(URLRequest) { data, response, error in
            
            if let _response = response as? NSHTTPURLResponse {
                let statusCode = _response.statusCode
                self.response = _response
                
                if self.request.acceptibleStatusCodeRange.contains(statusCode) {
                    
                    self.responseData = data
                    self.error = error
                    
                } else {
                    
                    guard let _data = data else {
                        self.error = self.invlaidStatusCodeError(statusCode)
                        self.cancel()
                        return
                    }
                    
                    do {
                        let errorJSON = try NSJSONSerialization.JSONObjectWithData(_data, options: NSJSONReadingOptions(rawValue: 0))
                        guard let _error = errorJSON["error"] as? String else {
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
            
            dispatch_semaphore_signal(semephore)
        }.resume()
        
        dispatch_semaphore_wait(semephore, dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(request.timeout + 1) * NSEC_PER_SEC)))
        
        if cancelled {
            completeOperation()
            return
        }
        
        if responseData == nil {
            let userInfo = [NSLocalizedDescriptionKey: "Received empty response"]
            error = NSError(domain: errorDomain, code: NSURLErrorResourceUnavailable, userInfo: userInfo)
            completeOperation()
            return
        }
        
        completeOperation()
    }
    
    public override func start() {
        if cancelled {
            finished = true
            return
        }
        executing = true
        main()
    }
    
    func completeOperation() {
        executing = false
        finished = true
    }
    
    func invlaidStatusCodeError(statusCode: Int) -> NSError {
        return NSError(domain: self.errorDomain, code: 3333, userInfo: [NSLocalizedDescriptionKey: "Status code received (\(statusCode)) was not within acceptable range (\(self.request.acceptibleStatusCodeRange.startIndex))-(\(self.request.acceptibleStatusCodeRange.endIndex))"])
    }
    
}

extension HTTPRequestOperation: NSURLSessionDelegate {
    
    public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        
        print("\(#file): \(#function)")
        
    }
    
    //    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
    //
    //        print("\(__FILE__): \(__FUNCTION__)")
    //
    //    }
    
}

extension HTTPRequestOperation: NSURLSessionDataDelegate {
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        print("\(#file): \(#function)")
        
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        
        print("\(#file): \(#function)")
        
    }
}

extension HTTPRequestOperation: NSURLSessionTaskDelegate {
    
    //    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
    //
    //        print("\(__FILE__): \(__FUNCTION__)")
    //
    //    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        
        print("\(#file): \(#function)")
        
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        print("\(#file): \(#function)")
        
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        print("\(#file): \(#function)")
        
    }
}
