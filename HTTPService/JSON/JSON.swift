//
//  JSON.swift
//
//  Created by Jeremy Fox on 3/2/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

/**
    A JSON enum used to wrap up each valid JSON type into for easier parsing and object serialization.

    - String(Swift.Sting): An isntance of String
    - Number(NSNumber): An Int, Float or Double
    - Object([Swift.String: JSON]): A instance of Dictionary containing a key of type String and a value of any valid JSON type
    - Array([JSON]): An instance of Array containing any valid JSON type
    - Empty: Means there is no valid JSON type or that the value was nil
*/
public enum JSON {
    case String(Swift.String)
    case Number(NSNumber)
    case Object([Swift.String: JSON])
    case Array([JSON])
    case Empty
}


/// JSON enum extension to add parsing functionality.
extension JSON {
    /**
        This should be used to parse JSON (AnyObject) returned from JSONSerialization.JSONObjectWithData into JSON (enum).
    
        `let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error)
         let json = JSON.parse(jsonObject)`
    
        :param: json The JSON (AnyObject) to be parsed into JSON (enum)
    
        :returns: A new instance of JSON (enum) containing the parsed values from JSON (AnyObject)
    */
    static func parse(json: AnyObject) -> JSON {
        switch json {
        case let array as [AnyObject]: return .Array(array.map { self.parse($0) })
            
        case let object as [Swift.String: AnyObject]:
            return .Object(reduce(object.keys, [:]) { accum, key in
                var parsedValue = JSON.Empty
                if let value: AnyObject = object[key] {
                    parsedValue = self.parse(value)
                }
                return accum += [key: parsedValue]
                })
            
        case let string as Swift.String: return .String(string)
        case let number as NSNumber:     return .Number(number)
        default: return .Empty
        }
    }
}

/// A JSON (enum) extension to ensure that if "parse" is called on an instance of JSON (enum) the same value is returned
extension JSON: JSONSerializable {
    
    public typealias DecodedType = JSON
    
    public func toJSON() -> [Swift.String : AnyObject]? {
        return nil
    }
    
    public static func fromJSON(json: JSON) -> DecodedType? {
        return json
    }
    
}
