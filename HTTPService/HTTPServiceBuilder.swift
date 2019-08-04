//
//  HTTPServiceBuilder.swift
//  HTTPService
//
//  Created by Jeremy Fox on 8/3/19.
//  Copyright © 2019 Jeremy Fox. All rights reserved.
//

public protocol HTTPServiceBuilder {
    static func build<T>() -> T?
}
