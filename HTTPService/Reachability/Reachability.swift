//
//  Reachability.swift
//  merchcat
//
//  Created by Jeremy Fox on 6/15/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import SystemConfiguration

public class Reachability {
    
    static var reachabilityRefs = [String: SCNetworkReachability]()
    static let reachabilityQueue = dispatch_queue_create("Operations.Reachability", DISPATCH_QUEUE_SERIAL)
    
    public static func requestReachability(url: NSURL? = nil) -> Bool {
        
        var isReachable = false
        
        dispatch_sync(reachabilityQueue) {
            
            var ref: SCNetworkReachability?
            
            if let _url = url, let _host = _url.host {

                ref = self.reachabilityRefs[_host]
                
                if ref == nil {
                    let hostString = _host as NSString
                    ref = SCNetworkReachabilityCreateWithName(nil, hostString.UTF8String)
                    self.reachabilityRefs[_host] = ref
                }
            } else {

                var zeroAddress = sockaddr_in()
                zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
                zeroAddress.sin_family = sa_family_t(AF_INET)
                ref = withUnsafePointer(&zeroAddress) {
                    SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
                }
                
            }

            if let ref = ref {
                var flags: SCNetworkReachabilityFlags = []
                if SCNetworkReachabilityGetFlags(ref, &flags) {
                    isReachable = flags.contains(.Reachable)
                }
            }
            
        }
        
        return isReachable
    }
    
}