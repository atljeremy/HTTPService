//
//  HTTPServiceBuilder.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/3/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

/// A protocol that extends `ServiceBuildable` for building services that conform to `NetworkService`.
///
/// `NetworkServiceBuildable` inherits from `ServiceBuildable` and adds the constraint that the associated `Service` type must conform to the `NetworkService` protocol.
/// This protocol is intended for use with builders that create HTTP-based services, ensuring that the services adhere to the `NetworkService` protocol.
///
/// ### Example Conformance:
/// ```swift
/// struct MyServiceBuilder: NetworkServiceBuildable {
///     static func build() -> MyService? {
///         // Implementation to build and return an instance of MyService
///     }
/// }
/// ```
///
/// - Note: The associated `Service` type must conform to `NetworkService`.
///
/// - SeeAlso: `ServiceBuildable`, `NetworkService`
public protocol NetworkServiceBuildable: ServiceBuildable where Service: NetworkService {}
