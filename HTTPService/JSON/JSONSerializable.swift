//
//  JSONSerializable.swift
//
//  Created by Jeremy Fox on 3/2/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

public protocol JSONSerializable {
    associatedtype DecodedType = Self
    static func fromJSON(json: JSON) -> DecodedType?
    func toJSON() -> [String: AnyObject]?
}
