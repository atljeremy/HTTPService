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
    
    /// A private queue used to schedule all incoming HTTPRequest's
    private let _queue = NSOperationQueue()
    
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
    
        `HTTPService.defaultService().enqueue(searchRequest, returningObject: SearchResult.self) { request, result in
        }`
    
        :param: request The HTTPRequest to enqueue for execution
        :param: object The class conforming to JSONSerializable the will be used to map the JSON response to and returned in the completion handler
        :param: completion The completion handler that will called when the request execution has completed. This will be called on the main thread.
        
        :returns: The instance of HTTPServiceOperation that was constructed based on the HTTPRequest and will be enqueued for execution. If you need to cancel a request, keep a reference to this operation and call cancel() on it. Note, if the request is currently executing this will mark the operation as cancelled and will eventually be cancelled. This may not necessarilly happen instantly but will evenutally be cancelled and the completion handler will be called.
    */
    public func enqueue<T where T: JSONSerializable, T == T.DecodedType>(request: HTTPRequest, returningObject object: T.Type, completion: ((HTTPRequest, HTTPResult<T>) -> Void)?) -> HTTPServiceOperation {
        
        let operation = HTTPServiceOperation(request: request)
        operation.setCompletionHandlerWithSuccess({ operation, data in
            
            var result: HTTPResult<T>?
            if let _data = data {
                result = HTTPObjectMapping.mapResponse(operation.response, data: data, toObject: object, forRequest: request)
            }
            
            if let _result = result {
                completion?(request, _result)
            } else {
                completion?(request, HTTPResult.Failure(NSError(domain: "HTTPServiceErrorDomain", code: 1616, userInfo: [NSLocalizedDescriptionKey: "Unexpected error occurred"])))
            }
            
        }, failure: { operation, error in
            
            if let _completionHanlder = completion {
                _completionHanlder(request, .Failure(error))
            }
            
        })
        _queue.addOperation(operation)

        return operation
    }
    
}