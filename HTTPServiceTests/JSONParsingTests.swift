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

struct Listing {
    let id: Int64
    let title: String
    let latitude: Double
    let longitude: Double
    let petsAllowed: Bool
    let address: Address?
}

extension Listing: JSONSerializable {
    
    typealias DecodedType = Listing
    
    static func create(id: Int64)(title: String)(latitude: Double)(longitude: Double)(petsAllowed: Bool)(address: Address?) -> DecodedType {
        return Listing(id: id, title: title, latitude: latitude, longitude: longitude, petsAllowed: petsAllowed, address: address)
    }
    
    func toJSON() -> [String : AnyObject]? {
        return nil
    }
    
    static func fromJSON(j: JSON) -> DecodedType? {
        let listing = Listing.create
            <<! "id" => j
            <<& "title" => j
            <<& "latitude" => j
            <<& "longitude" => j
            <<& "pets_allowed" => j
            <<& "address" =>? j
    }
    
}

struct Address {
    let number: Int
    let street: String
}

extension Address: JSONSerializable {
    
    typealias DecodedType = Address
    
    static func create(number: Int)(street: String) -> Address {
        return Address(number: number, street: street)
    }
    
    static func toJSON() -> JSON? {
        return nil
    }
    static func fromJSON(j: JSON) -> DecodedType? {
        let address = Address.create
            <<! "number" => j
            <<& "street" => j
        return address
    }
}

class JSONParsingTests: XCTestCase {
    
    // Given
    let json = JSONParsingTests.listingJSON()
    var listing: Listing!
    
    override func setUp() {
        super.setUp()
        // When
        listing = Listing.fromJSON(json)
    }
    
    func testJSONParsingPerformance() {
        self.measureBlock {
            Listing.fromJSON(self.json)
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
    }
    
    func testJSONParsingSetsAddressStreet() {
        // Then
        XCTAssert(listing.address?.street == "Main St", "Expected listing.address.street to equal (Main St) but got \(listing.address?.street)")
    }
    
    func testJSONParsingSetsAmenities() {
        // Then
        XCTAssert(listing.amenities![2] == 7, "Expected listing.amenities to equal 7 but got \(listing.amenities![2])")
    }
    
    func testJSONParsingSetsCity() {
        // Then
        XCTAssert(listing.city! == "Norcross", "Expected listing.city to equal Norcross but got \(listing.city!)")
    }
    
    func testJSONParsingSetsEmail() {
        // Then
        XCTAssert(listing.email! == "test@email.com", "Expected listing.email to equal test@email.com but got \(listing.email!)")
    }
    
    func testJSONParsingSetsExpried() {
        // Then
        XCTAssert(listing.expired! == false, "Expected listing.expired to equal false but got \(listing.expired!)")
    }
    
    func testJSONParsingSetsFloorplans() {
        // When
        let floorplan = listing.floorplans![0]
        
        // Then
        XCTAssert(floorplan.available == true, "Expected floorplan.available to equal true but got \(floorplan.available)")
        XCTAssert(floorplan.baths == 3, "Expected floorplan.baths to equal 3 but got \(floorplan.baths)")
        XCTAssert(floorplan.beds == 2, "Expected floorplan.beds to equal 2 but got \(floorplan.beds)")
        XCTAssert(floorplan.create_date == "2/2/2015", "Expected floorplan.create_date to equal 2/2/2015 but got \(floorplan.create_date)")
        XCTAssert(floorplan.expired == true, "Expected floorplan.expired to equal true but got \(floorplan.expired)")
        XCTAssert(floorplan.id == 55, "Expected floorplan.id to equal 55 but got \(floorplan.id)")
        XCTAssert(floorplan.max_price == 4000, "Expected floorplan.max_price to equal 4000 but got \(floorplan.max_price)")
        XCTAssert(floorplan.min_price == 100, "Expected floorplan.min_price to equal 100 but got \(floorplan.min_price)")
        XCTAssert(floorplan.photos![0] == "/imgr/34505d862c70474b99042cbc8a168e04/800-", "Expected floorplan.photos![0] to equal (/imgr/34505d862c70474b99042cbc8a168e04/800-) but got (\(floorplan.photos![0]))")
        XCTAssert(floorplan.square_feet == 3500, "Expected floorplan.square_feet to equal 3500 but got (\(floorplan.square_feet))")
        XCTAssert(floorplan.title == "3A", "Expected floorplan.title to equal 3A but got (\(floorplan.title))")
    }
    
    func testJSONParsingSetsHasAvailability() {
        // Then
        XCTAssert(listing.has_availability == true, "Expected listing.has_availability to equal (true) but got \(listing.has_availability)")
    }
    
    func testJSONParsingSetsIsFeatured() {
        // Then
        XCTAssert(listing.is_featured == true, "Expected Listing.is_featured to equal (true) but got (\(listing.is_featured))")
    }
    
    func testJSONParsingSetsLocationTitle() {
        // Then
        XCTAssert(listing.location_title == "1300 Main St", "Expected listing.location_title to equal (1300 Main St) but got (\(listing.location_title))")
    }
    
    func testJSONParsingSetsOfficeHours() {
        // When
        let office_hour = listing.office_hours![0]
        
        // Then
        XCTAssert(office_hour.open_time == "08:30:00", "Expected office_hour.open_time to equal (08:30:00) but got (\(office_hour.open_time))")
        XCTAssert(office_hour.day_of_week == "Monday", "Expected office_hour.open_time to equal (Monday) but got (\(office_hour.open_time))")
        XCTAssert(office_hour.close_time == "17:30:00", "Expected office_hour.close_time to equal (17:30:00) but got (\(office_hour.close_time))")
    }
    
    func testJSONParsingSetsPhone() {
        // Then
        XCTAssert(listing.phone == 7705551234, "Expected listing.phone to equal (7705551234) but got (\(listing.phone))")
    }
    
    func testJSONParsingSetsPhoneExtension() {
        // Then
        XCTAssert(listing.phone_extension == "1234", "Expected listing.phone_extension to equal (1234) but got (\(listing.phone_extension))")
    }
    
    func testJSONParsingSetsPhotos() {
        XCTAssert(listing.photos![0] == "/imgr/739399due9w9393i3i3ie9eui399eiei/800-", "Expected listing.photos![0] to equal (/imgr/739399due9w9393i3i3ie9eui399eiei/800-) but got (\(listing.photos![0]))")
    }
}

extension JSONParsingTests {
    static func listingJSON() -> JSON {
        return JSON.Object([
            "id": JSON.Number(123),
            "title": JSON.String("Some Property Title"),
            "latitude": JSON.Number(12.4444),
            "longitude": JSON.Number(23.5555),
            "pets_allowed": JSON.Number(true),
            "address": JSON.Object(["number":JSON.Number(42), "street":JSON.String("Main St")]),
            "amenities": JSON.Array([JSON.Number(2), JSON.Number(4), JSON.Number(7)]),
            "city": JSON.String("Norcross"),
            "email": JSON.String("test@email.com"),
            "expired": JSON.Number(false),
            "floorplan_set": JSON.Array([JSON.Object([
                "available": JSON.Number(true),
                "baths": JSON.Number(3),
                "beds": JSON.Number(2),
                "create_date": JSON.String("2/2/2015"),
                "expired": JSON.Number(true),
                "id": JSON.Number(55),
                "max_price": JSON.Number(4000),
                "min_price": JSON.Number(100),
                "photos": JSON.Array([JSON.String("/imgr/34505d862c70474b99042cbc8a168e04/800-")]),
                "square_feet": JSON.Number(3500),
                "title": JSON.String("3A")
                ])]),
            "has_availability": JSON.Number(true),
            "is_featured": JSON.Number(true),
            "location_title": JSON.String("1300 Main St"),
            "office_hours": JSON.Array([JSON.Object([
                "close_time": JSON.String("17:30:00"),
                "day_of_week": JSON.String("Monday"),
                "open_time": JSON.String("08:30:00")])]),
            "phone": JSON.Number(7705551234),
            "phone_extension": JSON.String("1234"),
            "photos": JSON.Array([JSON.String("/imgr/739399due9w9393i3i3ie9eui399eiei/800-")]),
            "state": JSON.String("GA")
            ])
    }
}
