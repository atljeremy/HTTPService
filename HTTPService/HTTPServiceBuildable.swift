//
//  HTTPServiceBuilder.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/3/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

/// A protocol that extends `ServiceBuildable` for building services that conform to `HTTPService`.
///
/// `HTTPServiceBuildable` inherits from `ServiceBuildable` and adds the constraint that the associated `Service` type must conform to the `HTTPService` protocol.
/// This protocol is intended for use with builders that create HTTP-based services, ensuring that the services adhere to the `HTTPService` protocol.
///
/// ### Example Conformance:
/// ```swift
/// struct MyHTTPServiceBuilder: HTTPServiceBuildable {
///     static func build() -> MyHTTPService? {
///         // Implementation to build and return an instance of MyHTTPService
///     }
/// }
/// ```
///
/// - Note: The associated `Service` type must conform to `HTTPService`.
///
/// - SeeAlso: `ServiceBuildable`, `HTTPService`
public protocol HTTPServiceBuildable: ServiceBuildable where Service: HTTPService {}
