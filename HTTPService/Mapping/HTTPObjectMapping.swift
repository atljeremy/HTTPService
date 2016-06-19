//
//  HTTPObjectMapping.swift
//
//  Created by Jeremy Fox on 2/24/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Foundation

/// Used by the HTTPService to map a response to a JSONSerializable model
public class HTTPObjectMapping {
    
    public enum Errors: Int {
        case DeserializationFailure = 2828
    }
    
    /**
        The main endpoint for mapping a response to a JSONSerializable model. If the response's status code is within the acceptable range and the data received can be parsed into a JSON object this function will parse the JSON object into an instance of the JSONSerializable model. After this is complete, an instance of HTTPResult with a .Success containing the Box'ed JSONSerializable model instance will be returned. If the response was not within the acceptable status code range or the data couldn't be parsed into a valid JSON object this will return an HTTPResult with a .Failure that contains an NSError that can be used to help determine was went wrong.
    
        :param: response The NSURLResponse of the request. Used to get information like statusCode to determine if the request was executed successfuly of not.
        :param: data The NSData containing the response body that will be mapped to the JSONSerializable model
        :param: object The model conforming to JSONSerializable that will be used to map the response JOSN to and returned within the HTTPResult
    
        :returns: An instance of HTTPResult which will have either a .Success containg a Box'ed JSONSerializable model instance of a .Failure containg an NSError.
    */
    public class func mapResponse<T where T: JSONSerializable, T == T.DecodedType>(response: NSURLResponse!, data: NSData!, toObject object: T.Type, forRequest request: HTTPRequest) -> HTTPResult<T> {
        
        let resultResponse = HTTPResult(HTTPResponse(data: data, urlResponse: response), nil)
        let resultData = parseDataFromResult(resultResponse, forRequest: request)
        let resultJSON = deserializeJSON(resultData)
        let _object = deserializeObject(object, withResultJSON: resultJSON)
        
        return _object
    }
    
    /** 
        Used to simply pull out the NSData that is wrapped up in the HTTPResult<HTTPResponse> and return a new instance of HTTPResult<NSData>
    
        :param: result The instance of HTTPResult<HTTPResponse> that contains the NSData
        :param: request The HTTPRequest from which the HTTPResult was received. This is used to get the requests acceptableStatusCodeRange.
    
        :returns: A new instance of HTTPResult<NSData>
    */
    class func parseDataFromResult(result: HTTPResult<HTTPResponse>, forRequest request: HTTPRequest) -> HTTPResult<NSData> {
        switch result {
        case let .Success(box):
            let response = box.value
            let successRange = request.acceptibleStatusCodeRange
            if !successRange.contains(response.statusCode) {
                return .Failure(NSError(domain: "HTTPObjectMappingErrorDomain", code: 8989, userInfo: [NSLocalizedDescriptionKey: "Response status code not in acceptable range"]))
            }
            return .Success(Box(response.data))
        case let .Failure(error):
            return .Failure(error)
        }
    }
    
    /**
        Used to deserialize NSData into JSON (AnyObject) using NSJSONSerializaiton.JSONObjectWithData.
    
        :params: resultData An instance of HTTPResult<NSData>.Success containing the Box'ed NSData to be deserialized into a JSON (AnyObject).
    
        :returns: A new instance of HTTPResult<AnyObject>.Success which is a Box'ed value of JSON (AnyObject) or HTTPResult<AnyObject>.Failure which contains an NSError
    */
    class func deserializeJSON(resultData: HTTPResult<NSData>) -> HTTPResult<AnyObject> {
        switch resultData {
        case let .Success(box):
            let data = box.value
            let jsonOptional: AnyObject? = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
            return HTTPResult.fromOptional(jsonOptional, nil)
        case let .Failure(resultError):
            return .Failure(resultError)
        }
    }
    
    /**
        Used to deserialize JSON (AnyObject) into a JSONSerializable model instance.
    
        :param: object The JSONSerializable model to be used for deserialization of the JSON (AnyObject)
        :param: resultJSON An instance of HTTPResult<AnyObject> which contains a Box'ed value of JSON (AnyObect) to be deserialized into an instance of "object".
    
        :returns: A new instance of HTTPResult<T>.Success containing the newly created and parsed instance of "object" or HTTPResult<T>.Failure containing an NSError
    */
    class func deserializeObject<T where T: JSONSerializable, T == T.DecodedType>(object: T.Type, withResultJSON resultJSON: HTTPResult<AnyObject>) -> HTTPResult<T> {
        switch resultJSON {
        case let .Success(box):
            let jsonObject: AnyObject = box.value
            let json = JSON.parse(jsonObject)
            let parsedObject = object.fromJSON(json)
            var error: NSError?
            if parsedObject == nil {
                error = NSError(domain: "HTTPObjectMappingErrorDomain", code: 2828, userInfo: [NSLocalizedDescriptionKey: "Uable to deserialize object"])
            }
            return HTTPResult.fromOptional(parsedObject, error)
        case let .Failure(error):
            return .Failure(error)
        }
    }
}

