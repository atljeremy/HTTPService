//
//  Listing.swift
//
//  Created by Jeremy Fox on 5/18/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Atlas

struct Listing {
    var id: Int64
    var title: String
    var latitude: Double
    var longitude: Double
    var petsAllowed: Bool
    var address: Address?
    var expired: Bool
    var floorPlans: [FloorPlan]?
}

extension Listing: AtlasMap {
    
    func toJSON() -> JSON? {
        var listingDictionary: [String : AnyObject] = [
            "id": NSNumber(longLong: id),
            "title": title,
            "latitude": latitude,
            "longitude": longitude,
            "pets_allowed": petsAllowed,
            "expired": expired
        ]
        
        if let _address = address {
            listingDictionary["address"] = _address.toJSON()
        }
        
        if let _floorPlans = floorPlans {
            listingDictionary["floorPlans"] = _floorPlans.map { $0.toJSON()! }
        }
        
        return listingDictionary
    }
    
    init?(json: JSON) throws {
        do {
            let map = try Atlas(json)
            id = try map.objectFromKey("id")
            title = try map.objectFromKey("title")
            latitude = try map.objectFromKey("latitude")
            longitude = try map.objectFromKey("longitude")
            petsAllowed = try map.objectFromKey("pets_allowed")
            address = try map.objectFromOptionalKey("address")
            expired = try map.objectFromKey("expired")
            floorPlans = try map.arrayFromOptionalKey("floorplan_set")
        } catch let e {
            throw e
        }
    }
    
}
