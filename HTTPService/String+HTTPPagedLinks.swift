//
//  String+HTTPPagedLinks.swift
//  HTTPService
//
//  Created by Jeremy Fox on 10/6/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation

public extension String {
    /// A computed property that extracts pagination links from an HTTP `Link` header string.
    ///
    /// The `Link` header in an HTTP response often contains multiple links for navigating
    /// through paginated results, each associated with a `rel` attribute, such as "first",
    /// "prev", "next", and "last". This property parses the string into a dictionary mapping
    /// each `PagedLink` to its corresponding `URL`.
    ///
    /// - Returns: A dictionary where the keys are `PagedLink` cases (e.g., `.first`, `.previous`)
    ///            and the values are the corresponding `URL` objects extracted from the string.
    ///
    /// Example usage:
    /// ```
    /// let linkHeader = "<https://api.example.com?page=1>; rel=\"first\", <https://api.example.com?page=2>; rel=\"next\""
    /// let links = linkHeader.httpLinks
    /// print(links[.next])  // Prints: Optional(https://api.example.com?page=2)
    /// ```
    var httpLinks: [PagedLink: URL] {
        // Split the string by commas, then reduce it into a dictionary mapping PagedLink to URL.
        split(separator: ",").reduce(into: [PagedLink: URL]()) { (result, part) in
            // Extract the URL from the part between "<" and ">"
            guard
                let first = part.firstIndex(of: "<"),
                let end = part.firstIndex(of: ">"),
                let url = URL(string: String(part[part.index(after: first)..<end]))
            else {
                return
            }
            // Map the extracted URL to the appropriate PagedLink based on the "rel" attribute.
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

