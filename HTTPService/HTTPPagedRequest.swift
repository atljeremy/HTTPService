//
//  HTTPPagedRequest.swift
//  HTTPService
//
//  Created by Jeremy Fox on 10/6/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation

public enum PagedLink: String {
    case first, previous = "prev", next, last
}

public struct PagedLinks: Codable {
    public let first: URL?
    public let previous: URL?
    public let next: URL?
    public let last: URL?
}

public protocol HTTPPagedResult: Codable {
    associatedtype ObjectType: Codable
    var links: PagedLinks? { get set }
    var perPage: Int? { get set }
    var total: Int? { get set }
    var objects: [ObjectType]? { get }
}

public protocol HTTPPagedRequest: HTTPRequest where ResultType: HTTPPagedResult {}
