//
//  Listing.swift
//
//  Created by Jeremy Fox on 5/18/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import HTTPService

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

extension Listing: JSONSerializable {
    
    typealias DecodedType = Listing
    
    static func create(id: Int64)(title: String)(latitude: Double)(longitude: Double)(petsAllowed: Bool)(address: Address?)(expired: Bool)(floorPlans: [FloorPlan]?) -> DecodedType {
        return Listing(id: id, title: title, latitude: latitude, longitude: longitude, petsAllowed: petsAllowed, address: address, expired: expired, floorPlans: floorPlans)
    }
    
    func toJSON() -> [String : AnyObject]? {
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
    
    static func fromJSON(j: JSON) -> DecodedType? {
        let listing = Listing.create
            <<! "id" => j
            <<& "title" => j
            <<& "latitude" => j
            <<& "longitude" => j
            <<& "pets_allowed" => j
            <<& "address" =>? j
            <<& "expired" => j
            <<& "floorplan_set" =>>? j
        return listing
    }
    
}
