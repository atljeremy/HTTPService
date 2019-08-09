//
//  ServiceBuildable.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/8/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

public protocol ServiceBuildable {
    associatedtype Service
    
    static func build() -> Service?
}
