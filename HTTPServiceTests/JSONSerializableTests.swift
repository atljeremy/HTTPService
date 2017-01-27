//
//  JSONParsingTests.swift
//
//  Created by Jeremy Fox on 5/18/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//
//

import UIKit
import XCTest
import HTTPService
import Atlas

class JSONSerializableTests: XCTestCase {
    
    // Given
    let json = JSONSerializableTests.listingJSON()
    var listing: Listing!
    
    override func setUp() {
        super.setUp()
        // When
        listing = try! Listing.init(json: json)
    }
    
    func testJSONParsingPerformance() {
        self.measure {
            let _ = try! Listing.init(json: self.json)
        }
    }
    
    func testJSONParsingParsesIntegerValues() {
        // Then
        XCTAssert(listing.id == 123, "Expected listing.id to equal (123) but got (\(listing.id))")
    }
    
    func testJSONParsingParsesStringValues() {
        // Then
        XCTAssert(listing.title == "Some Property Title", "Expected listing.title to equal (Some Property Title) but got (\(listing.title))")
    }
    
    func testJSONParsingParsesDoublevalues() {
        // Then
        XCTAssert(listing.latitude == 12.4444, "Expected listing.lat to equal (12.4444) but got (\(listing.latitude))")
        XCTAssert(listing.longitude == 23.5555, "Expected listing.lng to equal (23.5555) but got (\(listing.longitude))")
    }
    
    func testJSONParsingParsesBoolValues() {
        // Then
        XCTAssert(listing.petsAllowed == true, "Expected listing.cats_allowed to equal (false but got \(listing.petsAllowed)")
    }
    
    func testJSONParsingParsesCustomObjectValues() {
        // Then
        XCTAssert(listing.address?.number == 42, "Expected listing.address.number to equal 42 but got \(listing.address?.number)")
        XCTAssert(listing.address?.street == "Main St", "Expected listing.address.street to equal (Main St) but got \(listing.address?.street)")
    }
    
    func testJSONParsingParsesArrayOfCustomObjectValues() {
        // When
        let floorplan = listing.floorPlans![0]
        
        // Then
        XCTAssert(floorplan.available == true, "Expected floorplan.available to equal true but got \(floorplan.available)")
        XCTAssert(floorplan.baths == 3, "Expected floorplan.baths to equal 3 but got \(floorplan.baths)")
        XCTAssert(floorplan.beds == 2, "Expected floorplan.beds to equal 2 but got \(floorplan.beds)")
        XCTAssert(floorplan.createDate == "2/2/2015", "Expected floorplan.create_date to equal 2/2/2015 but got \(floorplan.createDate)")
        XCTAssert(floorplan.id == 55, "Expected floorplan.id to equal 55 but got \(floorplan.id)")
        XCTAssert(floorplan.photos![0] == "/imgr/34505d862c70474b99042cbc8a168e04/800-", "Expected floorplan.photos![0] to equal (/imgr/34505d862c70474b99042cbc8a168e04/800-) but got (\(floorplan.photos![0]))")
    }
    
    func testCustomObjectIsConvertedToJSONObject() {
        // When
        let listingDictionary = listing.toJSON() as! [String: AnyObject]
        let listingID = listingDictionary["id"] as! NSNumber
        
        // Then
        XCTAssert(listingID == 123, "Expected listingDictionary[\"id\"] to equal 123 but got \(listingID)")
    }
}

extension JSONSerializableTests {
    static func listingJSON() -> JSON {
        let json: [String: Any] = [
            "id": 123,
            "title": "Some Property Title",
            "latitude": 12.4444,
            "longitude": 23.5555,
            "pets_allowed": true,
            "address": [
                "number": 42,
                "street": "Main St"
            ],
            "expired": false,
            "floorplan_set": [
                [
                "available": true,
                "baths": 3,
                "beds": 2,
                "create_date": "2/2/2015",
                "id": 55,
                "photos": ["/imgr/34505d862c70474b99042cbc8a168e04/800-"]
                ]
            ]
        ]
        
        return json
    }
}
