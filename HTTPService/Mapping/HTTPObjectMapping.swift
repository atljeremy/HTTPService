//
//  HTTPObjectMapping.swift
//
//  Created by Jeremy Fox on 2/24/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Atlas

/// Used by the HTTPService to map a response to a JSONSerializable model
open class HTTPObjectMapping {
    
    public enum Errors: Int {
        case deserializationFailure = 2828
    }
    
    /**
        The main endpoint for mapping a response to a JSONSerializable model. If the response's status code is within the acceptable range and the data received can be parsed into a JSON object this function will parse the JSON object into an instance of the JSONSerializable model. After this is complete, an instance of HTTPResult with a .Success containing the Box'ed JSONSerializable model instance will be returned. If the response was not within the acceptable status code range or the data couldn't be parsed into a valid JSON object this will return an HTTPResult with a .Failure that contains an NSError that can be used to help determine was went wrong.
    
        - Parameters:
            - response: The NSURLResponse of the request. Used to get information like statusCode to determine if the request was executed successfuly of not.
            - data: The NSData containing the response body that will be mapped to the JSONSerializable model
    
        - Returns: An instance of HTTPResult which will have either a .Success containg a Box'ed JSONSerializable model instance of a .Failure containg an NSError.
    */
    open class func mapResponse<T: AtlasMap>(_ response: URLResponse!, data: Data!, forRequest request: HTTPRequest) -> HTTPResult<T> {
        
        let resultResponse = HTTPResult.from(value: HTTPResponse(data: data, urlResponse: response))
        let resultData = parseDataFromResult(resultResponse, forRequest: request)
        let resultJSON = deserializeJSON(resultData)
        let _object: HTTPResult<T> = deserializeObject(withResultJSON: resultJSON)
        
        return _object
    }
    
    /**
        Used to simply pull out the NSData that is wrapped up in the HTTPResult<HTTPResponse> and return a new instance of HTTPResult<NSData>
    
        - Parameters:
            - result: The instance of HTTPResult<HTTPResponse> that contains the NSData
            - request: The HTTPRequest from which the HTTPResult was received. This is used to get the requests acceptableStatusCodeRange.
    
        - Returns: A new instance of HTTPResult<NSData>
    */
    class func parseDataFromResult(_ result: HTTPResult<HTTPResponse>, forRequest request: HTTPRequest) -> HTTPResult<Data> {
        switch result {
        case let .success(box):
            let response = box.value
            let successRange = request.acceptibleStatusCodeRange
            if !successRange.contains(response.statusCode) {
                return .failure(NSError(domain: "HTTPObjectMappingErrorDomain", code: 8989, userInfo: [NSLocalizedDescriptionKey: "Response status code not in acceptable range"]))
            }
            return .success(Box(response.data))
        case let .failure(error):
            return .failure(error)
        }
    }
    
    /**
        Used to deserialize NSData into JSON (AnyObject) using NSJSONSerializaiton.JSONObjectWithData.
    
        :params: resultData An instance of HTTPResult<NSData>.Success containing the Box'ed NSData to be deserialized into a JSON (AnyObject).
    
        :returns: A new instance of HTTPResult<AnyObject>.Success which is a Box'ed value of JSON (AnyObject) or HTTPResult<AnyObject>.Failure which contains an NSError
    */
    class func deserializeJSON(_ resultData: HTTPResult<Data>) -> HTTPResult<AnyObject> {
        switch resultData {
        case let .success(box):
            let data = box.value
            let jsonOptional = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as AnyObject
            return .from(value: jsonOptional)
        case let .failure(resultError):
            return .failure(resultError)
        }
    }
    
    /**
        Used to deserialize JSON (AnyObject) into a JSONSerializable model instance.
    
        :param: object The JSONSerializable model to be used for deserialization of the JSON (AnyObject)
        :param: resultJSON An instance of HTTPResult<AnyObject> which contains a Box'ed value of JSON (AnyObect) to be deserialized into an instance of "object".
    
        :returns: A new instance of HTTPResult<T>.Success containing the newly created and parsed instance of "object" or HTTPResult<T>.Failure containing an NSError
    */
    class func deserializeObject<T: AtlasMap>(withResultJSON resultJSON: HTTPResult<AnyObject>) -> HTTPResult<T> {
        switch resultJSON {
        case let .success(box):
            do {
                let jsonObject: JSON = box.value
                let parsedObject = try T.init(json: jsonObject)
                var error: NSError?
                if parsedObject == nil {
                    error = NSError(domain: "HTTPObjectMappingErrorDomain", code: 2828, userInfo: [NSLocalizedDescriptionKey: "Uable to deserialize object"])
                }
                return .from(value: parsedObject, with: error)
            } catch let e {
                let error = NSError(domain: "HTTPObjectMappingErrorDomain", code: 118822, userInfo: [NSLocalizedDescriptionKey: "\(e)"])
                return .failure(error)
            }
        case let .failure(error):
            return .failure(error)
        }
    }
}

