//
//  Address.swift
//
//  Created by Jeremy Fox on 5/18/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Atlas

struct Address {
    var number: Int
    var street: String
}

extension Address: AtlasMap {
    
    func toJSON() -> JSON? {
        return [
            "number": number,
            "street": street
        ]
    }
    
    init?(json: JSON) throws {
        do {
            let map = try Atlas(json)
            number = try map.objectFromKey("number")
            street = try map.objectFromKey("street")
        } catch let e {
            throw e
        }
    }
}
