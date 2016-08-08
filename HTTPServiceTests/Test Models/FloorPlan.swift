//
//  FloorPlan.swift
//
//  Created by Jeremy Fox on 5/18/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Atlas

struct FloorPlan {
    var id: Int
    var available: Bool
    var baths: Int?
    var beds: Int?
    var photos: [String]?
    var createDate: String?
}

extension FloorPlan: AtlasMap {
    
    func toJSON() -> JSON? {
        var floorPlanDictionary: [String : AnyObject] = [
            "id": id,
            "available": available
        ]
        
        if let _baths = baths {
            floorPlanDictionary["baths"] = _baths
        }
        
        if let _beds = beds {
            floorPlanDictionary["beds"] = _beds
        }
        
        if let _photos = photos {
            floorPlanDictionary["photos"] = _photos
        }
        
        if let _createDate = createDate {
            floorPlanDictionary["create_date"] = _createDate
        }
        
        return floorPlanDictionary
    }
    
    init?(json: JSON) throws {
        do {
            let map = try Atlas(json)
            id = try map.objectFromKey("id")
            available = try map.objectFromKey("available")
            baths = try map.objectFromOptionalKey("baths")
            beds = try map.objectFromOptionalKey("beds")
            photos = try map.arrayFromOptionalKey("photos")
            createDate = try map.objectFromOptionalKey("create_date")
        } catch let e {
            throw e
        }
    }
}
