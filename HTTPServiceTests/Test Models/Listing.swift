//
//  Listing.swift
//
//  Created by Jeremy Fox on 5/18/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Foundation

struct Listing: Codable {
    var id: Int64
    var title: String
    var latitude: Double
    var longitude: Double
    var petsAllowed: Bool
    var address: Address?
    var expired: Bool
    var floorPlans: [FloorPlan]?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case latitude
        case longitude
        case petsAllowed = "pets_allowed"
        case address
        case expired
        case floorPlans = "floorplan_set"
    }
}
