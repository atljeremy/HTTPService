//
//  FloorPlan.swift
//
//  Created by Jeremy Fox on 5/18/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Foundation

struct FloorPlan: Codable {
    var id: Int
    var available: Bool
    var baths: Int?
    var beds: Int?
    var photos: [String]?
    var createDate: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case available
        case baths
        case beds
        case photos
        case createDate = "create_date"
    }
}
