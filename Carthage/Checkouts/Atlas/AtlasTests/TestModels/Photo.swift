//
//  Photo.swift
//  Atlas
//
//  Created by Jeremy Fox on 7/7/16.
//  Copyright © 2016 RentPath. All rights reserved.
//

import Foundation
import Atlas

struct Photo {

    let abstract: String?
    let urlString: String?

}

extension Photo: AtlasMap {

    func toJSON() -> JSON? {
        return nil
    }

    init?(json: JSON) throws {
        do {
            let map = try Atlas(json)
            abstract = try map.object(forOptional: "abstract")
            urlString = try map.object(forOptional: "url")
        } catch let error {
            throw error
        }
    }
}
