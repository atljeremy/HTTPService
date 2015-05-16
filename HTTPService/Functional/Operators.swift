//
//  Functional.swift
//
//  Created by Jeremy Fox on 3/2/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

infix operator =>   { associativity left precedence 150 }
infix operator =>?  { associativity left precedence 150 }
infix operator =>>  { associativity left precedence 150 }
infix operator =>>? { associativity left precedence 150 }
infix operator <<!  { associativity left }
infix operator <<&  { associativity left }

/**
    Used to pull a value for key from a JSON.Object and deserialize the value into an instance of a JSONSerializable.

    Exmaple: `"address" => json`

    :param: key The key within the JSON.Object for the value that you would like to retreive.
    :param: json The JSON (enum) that contains a .Object to retreive the value from.

    :returns: An Optional JSONSerializable instance if the value for "key" was found, otherwise nil.
*/
public func =><T where T: JSONSerializable, T == T.DecodedType>(key: String, json: JSON) -> T? {
    switch json {
    case let .Object(o):
        if let value = o[key] {
            return T.fromJSON(value)
        }
        return nil
    default: return nil
    }
}

/**
    Used to pull an Optional value for key from a JSON.Object and deserialize the value into an instance of a JSONSerializable model.

    Exmaple: `"address" =>? json`

    :param: key The key within the JSON.Object for the value that you would like to retreive.
    :param: json The JSON (enum) that contains a .Object to retreive the value from.

    :returns: An Optional JSONSerializable instance wrapped in another Optional if the value for "key" was found, otherwise nil.
*/
public func =>?<T where T: JSONSerializable, T == T.DecodedType>(key: String, json: JSON) -> T?? {
    return .Some(key => json)
}

/**
    Used to pull an array of JSONSerializable instances for key from a JSON.Object. Alternatively, if the root object in the JSON (AnyObject) is an Array, you can pass "nil" for the "key".

    Exmaples: `"results" =>> json` or `nil =>> json`

    :param: key The key within the JSON.Object for the array that you would like to retreive or "nil" if the root object is the array you need.
    :param: json The JSON (enum) that contains a .Object (when "key" is present) or .Array (when key is "nil") to retreive the array from.

    :returns: An Optional Array of JSONSerializable instances if the value for "key" was found, otherwise nil.
*/
public func =>><T where T: JSONSerializable, T == T.DecodedType>(key: String?, json: JSON) -> [T]? {
    if let _key = key {
        return deserializeArray(_key => json)
    }
    return deserializeArray(json)
}

/**
    Used to pull an Optional array of JSONSerializable instances for key from a JSON.Object. Alternatively, if the root object in the JSON (AnyObject) is an Array, you can pass "nil" for the "key".

    Exmaples: `"results" =>>? json` or `nil =>>? json`

    :param: key The key within the JSON.Object for the array that you would like to retreive or "nil" if the root object is the array you need.
    :param: json The JSON (enum) that contains a .Object (when "key" is present) or .Array (when key is "nil") to retreive the array from.

    :returns: An Optional Array of JSONSerializable instances wrapped in another Optional if the value for "key" was found, otherwise nil.
*/
public func =>>?<T where T: JSONSerializable, T == T.DecodedType>(key: String?, json: JSON) -> [T]?? {
    return .Some(key =>> json)
}

/**
    Used to map an Optional object to a closure. First, the **object** passed in will be unwrapped using map(). If this is successful and the **object** is successfully unwrapped, it will be passed into **closure**. If unwrapping is unsuccessful, this operator will return nil. The **closure** must return a B which will untimately be returned by this operator as an Optional (B?).

    This operator should be used as the first argument operator when being used in a sequence of operations since this operator doesn't accept an Optional closure. For all successive object to closure maps, you should use the `<<&` operator. 

    Exmaples:
    `Listing.create <<! "address" => json`
    In this example **create** is a static function on **Listing**. The first thing that will happen here is that the value for key **address** will be parsed from json (JSON.Object). The returned value will then be passed into the **create** function of **Listing**. The order in which these operations happen is dictated by the operators **precendence** value. Since the `<<!` operator doesn't have a defined precedence and the => has a precendence of 150, the => operation will happen first.

:param: closure The closure that accepts A and returns B.
:param: object An Optional A that will be passed into **closure**.

    :returns: An Optional B instance.
*/
public func <<!<A, B>(closure: A -> B, object: A?) -> B? {
    return object.map(closure)
}

/**
    Used to map an Optional object to an Optional closure. First, the **closure** will be unwrapped. If **closure** is successfully unwrapped this operator will delegate the rest of the operation to the `<<!` operator. See it's description for it's particular usage. If **closure** is not able to be unwrapped or is nil, this operator will return nil.

    This operator should be used after the `<<!` operator since this operator accepts an Optional closure. This allows the first operator (`<<!`) to fail, thus allowing this operator to fail and simply return nil.

    Exmaples:
    `Listing.create <<! "address" => json <<& "title" => json`
    In this example **create** is a static function on **Listing**. The first thing that will happen here is that the value for key **address** will be parsed from json (JSON.Object). The returned value will then be passed into the **create** function of **Listing**. The order in which these operations happen is dictated by the operators **precendence** value. Since the `<<!` operator doesn't have a defined precedence and the => has a precendence of 150, the => operation will happen first.

    :param: closure An Optional closure that accepts A and returns B.
    :param: object An Optional A that will be passed into **closure**.

    :returns: An Optional B instance.
*/
public func <<&<A, B>(closure: (A -> B)?, object: A?) -> B? {
    if let _closure = closure {
        return _closure <<! object
    }
    return nil
}
