//
//  Extensions.swift
//
//  Created by Jeremy Fox on 3/2/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

/// A JSONSerializable extension of String to allow parsing a String into JSON.String()
extension String: JSONSerializable {
    public typealias DecodedType = String
    public func toJSON() -> [String: AnyObject]? {
        return nil
    }
    public static func fromJSON(json: JSON) -> DecodedType? {
        switch json {
        case let .String(s): return s
        default: return nil
        }
    }
}

/// A JSONSerializable extension of Int to allow parsing an Int into JSON.Number()
extension Int: JSONSerializable {
    public typealias DecodedType = Int
    public func toJSON() -> [String: AnyObject]? {
        return nil
    }
    public static func fromJSON(json: JSON) -> DecodedType? {
        switch json {
        case let .Number(i): return Int(i)
        default: return nil
        }
    }
}

/// A JSONSerializable extension of Int to allow parsing an Int into JSON.Number()
extension Int32: JSONSerializable {
    public typealias DecodedType = Int32
    public func toJSON() -> [String: AnyObject]? {
        return nil
    }
    public static func fromJSON(json: JSON) -> DecodedType? {
        switch json {
        case let .Number(i): return Int32(i.longValue)
        default: return nil
        }
    }
}

/// A JSONSerializable extension of Int to allow parsing an Int into JSON.Number()
extension Int64: JSONSerializable {
    public typealias DecodedType = Int64
    public func toJSON() -> [String: AnyObject]? {
        return nil
    }
    public static func fromJSON(json: JSON) -> DecodedType? {
        switch json {
        case let .Number(i): return Int64(i.longLongValue)
        default: return nil
        }
    }
}

/// A JSONSerializable extension of Float to allow parsing a Float into JSON.Number()
extension Float: JSONSerializable {
    public typealias DecodedType = Float
    public func toJSON() -> [String: AnyObject]? {
        return nil
    }
    public static func fromJSON(json: JSON) -> DecodedType? {
        switch json {
        case let .Number(f): return Float(f)
        default: return nil
        }
    }
}

/// A JSONSerializable extension of Double to allow parsing a Double into JSON.Number()
extension Double: JSONSerializable {
    public typealias DecodedType = Double
    public func toJSON() -> [String: AnyObject]? {
        return nil
    }
    public static func fromJSON(json: JSON) -> DecodedType? {
        switch json {
        case let .Number(d): return Double(d)
        default: return nil
        }
    }
}

/// A JSONSerializable extension of Bool to allow parsing a Bool into JSON.Number()
extension Bool: JSONSerializable {
    public typealias DecodedType = Bool
    public func toJSON() -> [String: AnyObject]? {
        return nil
    }
    public static func fromJSON(json: JSON) -> DecodedType? {
        switch json {
        case let .Number(b): return Bool(b)
        default: return nil
        }
    }
}

/// Array deserialization. Used to parse a JSON.Array to [T]?.
func deserializeArray<T where T: JSONSerializable, T == T.DecodedType>(json: JSON?) -> [T]? {
    if let _json = json {
        switch _json {
        case let .Array(a):
            var array = [T]()
            for (_, json) in a.enumerate() {
                if let val = T.fromJSON(json) {
                    array.append(val)
                }
            }
            return array
        default: return nil
        }
    }
    return nil
}
