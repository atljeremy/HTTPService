//
//  ServiceBuilder.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/3/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation

public class ServiceBuilder<T: HTTPService> {
    public static func purgeCache() {
        let key = String(describing: T.self)
        ServiceCache.shared.delete(key: key)
    }
    
    public static func build(ignoringCache ignoreCache: Bool = false) -> T? {
        let key = String(describing: T.self)
        let cachedService: T? = ServiceCache.shared.get(key: key)
        guard ignoreCache || cachedService == nil else {
            return cachedService!
        }
        
        let service: T? = T.Builder.build()
        if let service = service {
            ServiceCache.shared.set(service: service, for: key)
        }
        
        return service
    }
}

fileprivate struct ServiceCache {
    static var shared = ServiceCache()
    private var cache = [String: Any]()
    
    func get<T: HTTPService>(key: String) -> T? {
        return cache[key] as? T
    }
    
    mutating func set<T: HTTPService>(service: T, for key: String) {
        cache[key] = service
    }
    
    mutating func delete(key: String) {
        cache.removeValue(forKey: key)
    }
}
