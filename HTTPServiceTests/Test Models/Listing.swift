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
        var listingDictionary: [String: Any] = [
            "id": id,
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
            id = try map.object(for: "id")
            title = try map.object(for: "title")
            latitude = try map.object(for: "latitude")
            longitude = try map.object(for: "longitude")
            petsAllowed = try map.object(for: "pets_allowed")
            address = try map.object(forOptional: "address")
            expired = try map.object(for: "expired")
            floorPlans = try map.array(forOptional: "floorplan_set")
        } catch let e {
            throw e
        }
    }
    
}
