//
//  Address.swift
//
//  Created by Jeremy Fox on 5/18/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import HTTPService

struct Address {
    var number: Int
    var street: String
}

extension Address: JSONSerializable {
    
    typealias DecodedType = Address
    
    static func create(number: Int)(street: String) -> Address {
        return Address(number: number, street: street)
    }
    
    func toJSON() -> [String : AnyObject]? {
        return [
            "number": number,
            "street": street
        ]
    }
    
    static func fromJSON(j: JSON) -> DecodedType? {
        let address = Address.create
            <<! "number" => j
            <<& "street" => j
        return address
    }
}
