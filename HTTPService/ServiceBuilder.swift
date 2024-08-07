//
//  ServiceBuilder.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/3/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

import Foundation

public class ServiceBuilder<T: HTTPService> {
    public static func purgeCache() async {
        let key = String(describing: T.self)
        await ServiceCache.shared.delete(key: key)
    }
    
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

fileprivate actor ServiceCache {
    static var shared = ServiceCache()
    private var cache = [String: Any]()
    
    func get<T: HTTPService>(key: String) -> T? {
        return cache[key] as? T
    }
    
    func set<T: HTTPService>(service: T, for key: String) {
        cache[key] = service
    }
    
    func delete(key: String) {
        cache.removeValue(forKey: key)
    }
}
