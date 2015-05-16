//
//  Dictionary.swift
//  Rent
//
//  Created by Jeremy Fox on 3/8/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

/// Use to combine two Dictionaries
func +=<K, V>(var left: [K: V], right: [K: V]) -> [K: V] {
    for (key, val) in right {
        left.updateValue(val, forKey: key)
    }
    return left
}
