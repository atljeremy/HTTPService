//
//  HTTPService.swift
//  Rent
//
//  Created by Jeremy Fox on 2/24/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Foundation.NSOperation

/// The main class used for all Jeremy Fox API networking.
public class HTTPService {
    
    /// The queue used to schedule all incoming HTTPRequest's
    public let _queue = NSOperationQueue()
    
    /// The baseURL that should be prefixed to all HTTPRequest.path's
    public var baseURL: NSURL!
    
    /// The private default instance of HTTPService. Use defaultService() to access this instance.
    private class var _defaultService: HTTPService {
        struct Static {
            static let instance = HTTPService()
        }
        return Static.instance
    }
    
    /**
        The default HTTPService instance. Alternatively, you could initialize a new instace of HTTPService.
    
        :returns: The default (shared) instance of HTTPService
    */
    public class func defaultService() -> HTTPService {
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
    
        `HTTPService.defaultService().enqueue(searchRequest, mapResponseToObject: SearchResult.self) { request, result, response in
        }`
    
        :param: request The HTTPRequest to enqueue for execution
        :param: object The object conforming to JSONSerializable that will be used to map the JSON response to and returned in the completion handler
        :param: completion The completion handler that will be called when the request execution has completed. This will be called on the main thread.
        
        :returns: The instance of HTTPRequestOperation that was constructed based on the HTTPRequest and will be enqueued for execution. If you need to cancel a request, keep a reference to this operation and call cancel() on it. Note, if the request is currently executing this will mark the operation as cancelled and will eventually be cancelled. This may not necessarilly happen instantly but will evenutally be cancelled and the completion handler will be called.
    */
    public func enqueue<T where T: JSONSerializable, T == T.DecodedType>(request: HTTPRequest, mapResponseToObject object: T.Type, completion: ((HTTPRequest, HTTPResult<T>, NSHTTPURLResponse?) -> Void)?) -> HTTPRequestOperation {
        
        let operation = HTTPRequestOperation(request: request)
        operation.setCompletionHandlerWithSuccess({ operation, data in
            
            self.verifyAuthStatusFromResponse(operation.response)
            
            var result: HTTPResult<T>?
            if let _data = data {
                result = HTTPObjectMapping.mapResponse(operation.response, data: _data, toObject: object, forRequest: request)
            }
            
            if let _result = result {
                completion?(request, _result, operation.response)
            } else {
                completion?(request, .Failure(NSError(domain: "HTTPServiceErrorDomain", code: 1616, userInfo: [NSLocalizedDescriptionKey: "Unexpected error occurred"])), operation.response)
            }
            
        }, failure: { operation, error in
            
            self.verifyAuthStatusFromResponse(operation.response)
            
            completion?(request, .Failure(error), operation.response)
            
        })
        _queue.addOperation(operation)

        return operation
    }
    
    /**
        Use this to enqueue an HTTPRequest for execution. Example of usage...
        
        `HTTPService.defaultService().enqueue(searchRequest) { request, result, response in
        }`
        
        :param: request The HTTPRequest to enqueue for execution
        :param: completion The completion handler that will be called when the request execution has completed. This will be called on the main thread.
        
        :returns: The instance of HTTPRequestOperation that was constructed based on the HTTPRequest and will be enqueued for execution. If you need to cancel a request, keep a reference to this operation and call cancel() on it. Note, if the request is currently executing this will mark the operation as cancelled and will eventually be cancelled. This may not necessarilly happen instantly but will evenutally be cancelled and the completion handler will be called.
    */
    public func enqueue(request: HTTPRequest, completion: ((HTTPRequest, HTTPResult<AnyObject>, NSHTTPURLResponse?) -> Void)?) -> HTTPRequestOperation {
        
        let operation = HTTPRequestOperation(request: request)
        operation.setCompletionHandlerWithSuccess({ operation, data in
            
            self.verifyAuthStatusFromResponse(operation.response)
            
            var result: HTTPResult<AnyObject>?
            if let _data = data {
                
                // A DELETE request should return a 204 stats code indicating "No Content".
                if operation.response?.statusCode == 204 {
                    
                    result = HTTPResult.fromOptional("", nil)
                    
                } else {
                    
                    var _json: AnyObject? = nil
                    var _error: NSError? = nil
                    do {
                        _json = try NSJSONSerialization.JSONObjectWithData(_data, options: NSJSONReadingOptions(rawValue: 0))
                    } catch let error as NSError {
                        _error = error
                    }
                    
                    result = HTTPResult.fromOptional(_json, _error)
                    
                }
                
            }
            
            if let _result = result {
                completion?(request, _result, operation.response)
            } else {
                completion?(request, .Failure(NSError(domain: "HTTPServiceErrorDomain", code: 1616, userInfo: [NSLocalizedDescriptionKey: "Unexpected error occurred"])), operation.response)
            }
            
        }, failure: { operation, error in
            
            self.verifyAuthStatusFromResponse(operation.response)
                
            completion?(request, .Failure(error), operation.response)
                
        })
        _queue.addOperation(operation)
        
        return operation
    }
    
    /**
        Use this to suspend the internal operation queue. Once suspended, no further operations will be executed until un-suspended.
    */
    public func suspend(suspend: Bool) {
        _queue.suspended = suspend
    }
    
    private func verifyAuthStatusFromResponse(response: NSHTTPURLResponse?) {
        if let _statusCode = response?.statusCode where _statusCode == 401 {
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.UnauthorizedRequest, object: nil)
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
