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
            "id": id as AnyObject,
            "available": available as AnyObject
        ]
        
        if let _baths = baths {
            floorPlanDictionary["baths"] = _baths as AnyObject?
        }
        
        if let _beds = beds {
            floorPlanDictionary["beds"] = _beds as AnyObject?
        }
        
        if let _photos = photos {
            floorPlanDictionary["photos"] = _photos as AnyObject?
        }
        
        if let _createDate = createDate {
            floorPlanDictionary["create_date"] = _createDate as AnyObject?
        }
        
        return floorPlanDictionary
    }
    
    init?(json: JSON) throws {
        do {
            let map = try Atlas(json)
            id = try map.object(for: "id")
            available = try map.object(for: "available")
            baths = try map.object(forOptional: "baths")
            beds = try map.object(forOptional: "beds")
            photos = try map.array(forOptional: "photos")
            createDate = try map.object(forOptional: "create_date")
        } catch let e {
            throw e
        }
    }
}
