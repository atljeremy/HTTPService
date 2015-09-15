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
        autoreleasepool {
            if self.cancelled {
                self.completeOperation()
                return
            }
            
            let baseURLString = HTTPService.defaultService().baseURL.absoluteString
            var URL: NSURL
            if let _URL = NSURL(string: baseURLString + self.request.path) {
                URL = _URL
            } else {
                self.cancel()
                self.completeOperation()
                return
            }
            
            let URLRequest = self.URLRequest(URL)
            
            let semephore = dispatch_semaphore_create(0)
            
            let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.currentQueue())
            session.dataTaskWithRequest(URLRequest) { data, response, error in
                
                if let _response = response {
                    self.response = _response as? NSHTTPURLResponse
                    let statusCode = (_response as! NSHTTPURLResponse).statusCode
                    if self.request.acceptibleStatusCodeRange.contains(statusCode) {
                        self.responseData = data
                        self.error = error
                    } else {
                        self.error = NSError(domain: self.errorDomain, code: 3333, userInfo: [NSLocalizedDescriptionKey: "Status code received (\(statusCode)) was not within acceptable range (\(self.request.acceptibleStatusCodeRange.startIndex))-(\(self.request.acceptibleStatusCodeRange.endIndex))"])
                        self.cancel()
                    }
                } else {
                    self.error = error
                    self.cancel()
                }
                
                dispatch_semaphore_signal(semephore)
                }.resume()
            
            dispatch_semaphore_wait(semephore, DISPATCH_TIME_FOREVER)
            
            if self.cancelled {
                self.completeOperation()
                return
            }
            
            if self.responseData == nil {
                let userInfo = [NSLocalizedDescriptionKey: "Received empty response"]
                self.error = NSError(domain: self.errorDomain, code: NSURLErrorResourceUnavailable, userInfo: userInfo)
                self.completeOperation()
                return
            }
            
            self.completeOperation()
        }
    }
    
    public override func start() {
        if cancelled {
            finished = true
            return
        }
        
        main()
        executing = true
    }
    
    func completeOperation() {
        executing = false
        finished = true
    }
    
    func URLRequest(URL: NSURL) -> NSMutableURLRequest {
        
        let URLRequest = NSMutableURLRequest(URL: URL, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: request.timeout)
        URLRequest.HTTPMethod = request.method.rawValue
        
        if let _image = request.imageUpload?.image, _field = request.imageUpload?.field {
            if let imageData = UIImageJPEGRepresentation(_image, 1.0) {
                if imageData.length > 0 {
                    
                    let uniqueId = NSProcessInfo.processInfo().globallyUniqueString
                    
                    let postBody = NSMutableData()
                    var postData = ""
                    let boundary = "------WebKitFormBoundary\(uniqueId)"
                    
                    URLRequest.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField:"Content-Type")
                    
                    if let _params = request.body {
                        postData += "--\(boundary)\r\n"
                        for (key, value) in _params {
                            postData += "--\(boundary)\r\n"
                            postData += "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n"
                            postData += "\(value)\r\n"
                        }
                    }
                    postData += "--\(boundary)\r\n"
                    postData += "Content-Disposition: form-data; name=\"\(_field)\"; filename=\"\(Int64(NSDate().timeIntervalSince1970*1000)).jpg\"\r\n"
                    postData += "Content-Type: image/jpeg\r\n\r\n"
                    postBody.appendData(postData.dataUsingEncoding(NSUTF8StringEncoding)!)
                    postBody.appendData(imageData)
                    postData = String()
                    postData += "\r\n"
                    postData += "\r\n--\(boundary)--\r\n"
                    postBody.appendData(postData.dataUsingEncoding(NSUTF8StringEncoding)!)
                    
                    URLRequest.HTTPBody = NSData(data: postBody)
                }
            }
        } else {
            if let _body = request.body {
                if let _bodyData = try? NSJSONSerialization.dataWithJSONObject(_body, options: NSJSONWritingOptions(rawValue: 0)) {
                    URLRequest.HTTPBody = _bodyData
                }
            }
        }
        
        if let _headers = self.request.headers {
            for (headerFeld, value) in _headers {
                URLRequest.addValue(value, forHTTPHeaderField: headerFeld)
            }
        }
        
        return URLRequest
    }
    
}

extension HTTPRequestOperation: NSURLSessionDelegate {
    
    public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        
        print("\(__FILE__): \(__FUNCTION__)")
        
    }
    
    //    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
    //
    //        print("\(__FILE__): \(__FUNCTION__)")
    //
    //    }
    
}

extension HTTPRequestOperation: NSURLSessionDataDelegate {
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        print("\(__FILE__): \(__FUNCTION__)")
        
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        
        print("\(__FILE__): \(__FUNCTION__)")
        
    }
}

extension HTTPRequestOperation: NSURLSessionTaskDelegate {
    
    //    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
    //
    //        print("\(__FILE__): \(__FUNCTION__)")
    //
    //    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        
        print("\(__FILE__): \(__FUNCTION__)")
        
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        print("\(__FILE__): \(__FUNCTION__)")
        
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        print("\(__FILE__): \(__FUNCTION__)")
        
    }
}
