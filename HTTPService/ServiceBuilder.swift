//
//  ServiceBuilder.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/3/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation

/// A generic builder for creating and managing instances of type `T` that conform to `HTTPService`.
///
/// `ServiceBuilder` provides methods for building instances of `T`, optionally using a cached version,
/// and for purging the cached instance from the service cache. This class is designed to streamline the
/// process of managing service instances, ensuring that they are either retrieved from cache or constructed
/// as needed.
///
/// ### Example Usage:
/// ```swift
/// let service: MyService? = await ServiceBuilder<MyService>.build()
/// await ServiceBuilder<MyService>.purgeCache()
/// ```
///
/// - Note: The `ServiceBuilder` class is only available for types that conform to `HTTPService`.
///
/// - SeeAlso: `HTTPService`, `ServiceCache`
public class ServiceBuilder<T: HTTPService> {

    /// Purges the cached instance of type `T` from the service cache.
    ///
    /// This method deletes the cached instance associated with the type `T` from the service cache. 
    /// After calling this method, any subsequent requests for an instance of `T` will result in a new instance being built, 
    /// as the cached instance will no longer be available.
    ///
    /// - Returns: This function does not return a value.
    public static func purgeCache() async {
        let key = String(describing: T.self)
        await ServiceCache.shared.delete(key: key)
    }
    
    /// Builds an instance of type `T`, optionally ignoring any cached version.
    ///
    /// This method attempts to retrieve a cached instance of type `T` from the service cache. 
    /// If a cached instance exists and `ignoreCache` is `false`, the cached instance is returned. 
    /// Otherwise, a new instance of `T` is built, cached, and returned.
    ///
    /// - Parameter ignoreCache: A Boolean value that determines whether to ignore the cached instance.
    ///   If `true`, a new instance is built even if a cached instance exists. The default is `false`.
    /// - Returns: An optional instance of type `T`. If the instance could not be built, returns `nil`.
    public static func build(ignoringCache ignoreCache: Bool = false) async -> T? {
        let key = String(describing: T.self)
        let cachedService: T? = await ServiceCache.shared.get(key: key)
        guard ignoreCache || cachedService == nil else {
            return cachedService!
        }
        
        let service = T.Builder.build()
        if let service = service {
            await ServiceCache.shared.set(service: service, for: key)
        }
        
        return service as? T
    }
}

/// A thread-safe, actor-based cache for storing and retrieving instances of services.
///
/// `ServiceCache` is designed to cache instances of services that conform to the `HTTPService` protocol.
/// This cache is managed as a singleton, providing a shared instance that can be used across the application.
/// The actor-based approach ensures that access to the cache is safe and synchronized in concurrent environments.
fileprivate actor ServiceCache {

    /// The shared singleton instance of `ServiceCache`.
    static var shared = ServiceCache()
    
    /// A private dictionary that stores cached services, keyed by a unique string identifier.
    private var cache = [String: Any]()
    
    /// Retrieves a cached service of type `T` associated with the given key.
    ///
    /// This method attempts to retrieve a service instance of type `T` from the cache using the specified key.
    /// If no cached instance is found, `nil` is returned.
    ///
    /// - Parameter key: A unique string identifier used to look up the cached service.
    /// - Returns: An optional instance of type `T` if it exists in the cache; otherwise, `nil`.
    func get<T: HTTPService>(key: String) -> T? {
        return cache[key] as? T
    }
    
    /// Caches a service instance of type `T` using the specified key.
    ///
    /// This method adds or updates the cached service instance associated with the given key.
    ///
    /// - Parameters:
    ///   - service: The service instance to be cached.
    ///   - key: A unique string identifier used to store the service in the cache.
    func set<T: HTTPService>(service: T, for key: String) {
        cache[key] = service
    }
    
    /// Deletes the cached service associated with the given key.
    ///
    /// This method removes the service instance from the cache that is associated with the specified key.
    ///
    /// - Parameter key: A unique string identifier used to look up and remove the cached service.
    func delete(key: String) {
        cache.removeValue(forKey: key)
    }
}
