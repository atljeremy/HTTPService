//
//  Reachability.swift
//  merchcat
//
//  Created by Jeremy Fox on 6/15/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import SystemConfiguration

open class Reachability {
    
    static private var reachabilityRefs = [String: SCNetworkReachability]()
    static private let reachabilityQueue = DispatchQueue(label: "Operations.Reachability")
    
    public static func requestReachability(url: URL? = nil) -> Bool {
        
        var isReachable = false
        
        reachabilityQueue.sync {
            
            var ref: SCNetworkReachability?
            
            if let _url = url, let _host = _url.host {
                
                ref = reachabilityRefs[_host]
                if ref == nil {
                    ref = SCNetworkReachabilityCreateWithName(nil, _host)
                    reachabilityRefs[_host] = ref
                }
                
            } else {
                
                var zeroAddress = sockaddr_in()
                zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
                zeroAddress.sin_family = sa_family_t(AF_INET)
                ref = withUnsafePointer(to: &zeroAddress) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        SCNetworkReachabilityCreateWithAddress(nil, $0)
                    }
                }
                
            }
            
            if let ref = ref {
                var flags: SCNetworkReachabilityFlags = []
                if SCNetworkReachabilityGetFlags(ref, &flags) {
                    isReachable = flags.contains(.reachable)
                }
            }
            
        }
        
        return isReachable
    }
    
    
}
