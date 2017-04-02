//
//  HTTPService.swift
//  Rent
//
//  Created by Jeremy Fox on 2/24/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Foundation.NSOperation
import Atlas

/// The main class used for all Jeremy Fox API networking.
open class HTTPService {
    
    /// The queue used to schedule all incoming HTTPRequest's
    open let _queue = OperationQueue()
    
    /// The baseURL that should be prefixed to all HTTPRequest.path's
    open var baseURL: URL!
    
    /// The private default instance of HTTPService. Use defaultService() to access this instance.
    fileprivate class var _defaultService: HTTPService {
        struct Static {
            static let instance = HTTPService()
        }
        return Static.instance
    }
    
    /**
        The default HTTPService instance. Alternatively, you could initialize a new instace of HTTPService.
    
        :returns: The default (shared) instance of HTTPService
    */
    open class func defaultService() -> HTTPService {
        return _defaultService
    }
    
    /**
        Default standard initializer
    
        :returns: A newly initialized instance of HTTPService
    */
    public init() {
        _queue.name = "HTTPService"
    }
    
    /**
        Use this to enqueue an HTTPRequest for execution. Example of usage...
    
        `HTTPService.defaultService().enqueue(searchRequest, mapResponseToObject: SearchResult.self) { operation, result in
        }`
    
        - Parameters: 
            - request: The HTTPRequest to enqueue for execution
            - completion: The completion handler that will be called when the request execution has completed. This will be called on the main thread.
        
        - Returns: The instance of HTTPRequestOperation that was constructed based on the HTTPRequest and will be enqueued for execution. If you need to cancel a request, keep a reference to this operation and call cancel() on it. Note, if the request is currently executing this will mark the operation as cancelled and will eventually be cancelled. This may not necessarilly happen instantly but will evenutally be cancelled and the completion handler will be called.
    */
    open func enqueue<T: AtlasMap>(_ request: HTTPRequest, completion: ((HTTPRequestOperation, HTTPResult<T>) -> Void)?) -> HTTPRequestOperation {
        
        let operation = HTTPRequestOperation(request: request)
        operation.setCompletionHandlerWithSuccess({ operation, data in
            
            self.verifyAuthStatusFromResponse(operation.response)
            
            var result: HTTPResult<T>?
            if let _data = data, _data.count > 0 {
                result = HTTPObjectMapping.mapResponse(operation.response, data: _data, forRequest: request)
            }
                
            if let _result = result {
                completion?(operation, _result)
            } else if operation.response?.statusCode == 204 {
                completion?(operation, .success(nil))
            } else {
                completion?(operation, .failure(NSError(domain: "HTTPServiceErrorDomain", code: 1616, userInfo: [NSLocalizedDescriptionKey: "Unexpected error occurred"])))
            }
            
        }, failure: { operation, error in
            
            self.verifyAuthStatusFromResponse(operation.response)
            
            completion?(operation, .failure(error))
            
        })
        _queue.addOperation(operation)

        return operation
    }
    
    /**
        Use this to enqueue an HTTPRequest for execution. Example of usage...
        
        `HTTPService.defaultService().enqueue(searchRequest) { operation, result in
        }`
        
        - Parameters:
            - request: The HTTPRequest to enqueue for execution
            - completion: The completion handler that will be called when the request execution has completed. This will be called on the main thread.
     
        - Returns: The instance of HTTPRequestOperation that was constructed based on the HTTPRequest and will be enqueued for execution. If you need to cancel a request, keep a reference to this operation and call cancel() on it. Note, if the request is currently executing this will mark the operation as cancelled and will eventually be cancelled. This may not necessarilly happen instantly but will evenutally be cancelled and the completion handler will be called.
    */
    open func enqueue(_ request: HTTPRequest, completion: ((HTTPRequestOperation, HTTPResult<AnyObject>) -> Void)?) -> HTTPRequestOperation {
        
        let operation = HTTPRequestOperation(request: request)
        operation.setCompletionHandlerWithSuccess({ operation, data in
            
            self.verifyAuthStatusFromResponse(operation.response)
            
            var result: HTTPResult<AnyObject>?
            if let _data = data {
                
                // A DELETE request should return a 204 stats code indicating "No Content".
                if operation.response?.statusCode == 204 {
                    
                    result = HTTPResult.from(value: "" as AnyObject?)
                    
                } else {
                    
                    var _json: AnyObject? = nil
                    var _error: Error? = nil
                    do {
                        _json = try JSONSerialization.jsonObject(with: _data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as AnyObject?
                    } catch let error {
                        _error = error
                    }
                    
                    result = HTTPResult.from(value: _json , with: _error)
                    
                }
                
            }
            
            if let _result = result {
                completion?(operation, _result)
            } else {
                completion?(operation, .failure(NSError(domain: "HTTPServiceErrorDomain", code: 1616, userInfo: [NSLocalizedDescriptionKey: "Unexpected error occurred"])))
            }
            
        }, failure: { operation, error in
            
            self.verifyAuthStatusFromResponse(operation.response)
                
            completion?(operation, .failure(error))
                
        })
        _queue.addOperation(operation)
        
        return operation
    }
    
    /**
        Use this to suspend the internal operation queue. Once suspended, no further operations will be executed until un-suspended.
    */
    open func suspend(_ suspend: Bool) {
        _queue.isSuspended = suspend
    }
    
    fileprivate func verifyAuthStatusFromResponse(_ response: HTTPURLResponse?) {
        if let _statusCode = response?.statusCode, _statusCode == 401 {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.UnauthorizedRequest), object: nil)
        }
    }
    
}

extension HTTPService {
    
    public struct Notifications {
        
        public static var UnauthorizedRequest: String {
            get {
                return "UnauthorizedRequest"
            }
        }
        
    }
    
}
