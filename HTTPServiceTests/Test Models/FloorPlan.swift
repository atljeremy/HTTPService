//
//  FloorPlan.swift
//
//  Created by Jeremy Fox on 5/18/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import HTTPService

struct FloorPlan {
    var id: Int
    var available: Bool
    var baths: Int?
    var beds: Int?
    var photos: [String]?
    var create_date: String?
}

extension FloorPlan: JSONSerializable {
    
    typealias DecodedType = FloorPlan
    
    static func create(id: Int)(available: Bool)(baths: Int?)(beds: Int?)(photos: [String]?)(create_date: String?) -> FloorPlan {
        return FloorPlan(id: id, available: available, baths: baths, beds: beds, photos: photos, create_date: create_date)
    }
    
    func toJSON() -> [String : AnyObject]? {
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
        
        if let _create_date = create_date {
            floorPlanDictionary["create_date"] = _create_date
        }
        
        return floorPlanDictionary
    }
    
    static func fromJSON(j: JSON) -> DecodedType? {
        let floorPlan = FloorPlan.create
            <<! "id" => j
            <<& "available" => j
            <<& "baths" =>? j
            <<& "beds" =>? j
            <<& "photos" =>>? j
            <<& "create_date" =>? j
        return floorPlan
    }
}
