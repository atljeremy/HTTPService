//
//  HTTPPagedRequest.swift
//  HTTPService
//
//  Created by Jeremy Fox on 10/6/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation

/// An enumeration representing the different types of pagination links in an HTTP response.
///
/// These links help in navigating through paginated API results.
public enum PagedLink: String {
    /// The link to the first page of results.
    case first
    /// The link to the previous page of results.
    case previous = "prev"
    /// The link to the next page of results.
    case next
    /// The link to the last page of results.
    case last
}

/// A structure representing the pagination links provided in an HTTP response.
///
/// These links allow clients to navigate through paginated API results.
public struct PagedLinks: Codable {
    /// The URL of the first page of results.
    public let first: URL?
    /// The URL of the previous page of results.
    public let previous: URL?
    /// The URL of the next page of results.
    public let next: URL?
    /// The URL of the last page of results.
    public let last: URL?
}

/// A protocol representing a paged result from an HTTP response.
///
/// Types conforming to `HTTPPagedResult` must provide pagination information
/// and a collection of objects retrieved from the API.
public protocol HTTPPagedResult: Codable {
    associatedtype ObjectsCollectionType: Codable
    
    /// The pagination links for navigating through the results.
    var links: PagedLinks? { get set }
    
    /// The number of results per page.
    var perPage: Int? { get set }
    
    /// The total number of results available.
    var total: Int? { get set }
    
    /// The collection of objects retrieved from the API.
    var objects: ObjectsCollectionType? { get }
}

/// A protocol representing an HTTP request that expects a paged result.
///
/// Types conforming to `HTTPPagedRequest` must expect a result conforming to `HTTPPagedResult`.
public protocol HTTPPagedRequest: HTTPRequest where ResultType: HTTPPagedResult {}

