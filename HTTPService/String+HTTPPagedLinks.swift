//
//  String+HTTPPagedLinks.swift
//  HTTPService
//
//  Created by Jeremy Fox on 10/6/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation

public extension String {
    var httpLinks: [PagedLink: URL] {
        split(separator: ",").reduce(into: [PagedLink: URL]()) { (result, part) in
            guard
                let first = part.firstIndex(of: "<"),
                let end = part.firstIndex(of: ">"),
                let url = URL(string: String(part[part.index(after: first)..<end]))else {
                return
            }
            if part.contains("rel=\"\(PagedLink.first.rawValue)\"") {
                result[.first] = url
            } else if part.contains("rel=\"\(PagedLink.previous.rawValue)\"") {
                result[.previous] = url
            } else if part.contains("rel=\"\(PagedLink.next.rawValue)\"") {
                result[.next] = url
            } else if part.contains("rel=\"\(PagedLink.last.rawValue)\"") {
                result[.last] = url
            }
        }
    }
}
