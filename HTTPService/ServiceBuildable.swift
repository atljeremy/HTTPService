//
//  ServiceBuildable.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/8/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

/// A protocol that defines the requirements for building service instances.
///
/// Types that conform to `ServiceBuildable` must implement a static `build` method,
/// which is responsible for constructing and returning an instance of the associated `Service` type.
/// This protocol is intended to be used with service builders, enabling a standardized way to create service instances.
///
/// ### Example Conformance:
/// ```swift
/// struct MyServiceBuilder: ServiceBuildable {
///     static func build() -> MyService? {
///         // Implementation to build and return an instance of MyService
///     }
/// }
/// ```
///
/// - Note: The associated `Service` type must be specified by the conforming type.
public protocol ServiceBuildable {

    /// The type of service that will be built.
    associatedtype Service
    
    /// Builds and returns an instance of the associated `Service` type.
    ///
    /// This method should contain the logic to create and return an instance of the `Service` type.
    /// If the service cannot be built, this method may return `nil`.
    ///
    /// - Returns: An optional instance of the associated `Service` type.
    static func build() -> Service?
}

