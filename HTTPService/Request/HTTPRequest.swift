//
//  HTTPRequest.swift
//
//  Created by Jeremy Fox on 2/24/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import UIKit
import Atlas

public struct ImageUpload {
    
    public let image: UIImage
    public let field: String
    
    public init(image: UIImage, field: String) {
        self.image = image
        self.field = field
    }
}

public struct HTTPRequest {
    
    public typealias Params = [String: Any]
    public typealias Headers = [String: String]
    
    public enum Method: String {
        case GET = "GET"
        case PUT = "PUT"
        case POST = "POST"
        case PATCH = "PATCH"
        case DELETE = "DELETE"
    }
    
    public let path: String
    public let method: Method
    public var headers: Headers?
    public let body: Params?
    public let imageUpload: ImageUpload?
    public var timeout: TimeInterval = 30
    public var acceptibleStatusCodeRange = 200..<300
    
    public init(path: String, method: Method, headers: Headers? = nil, body: Params? = nil) {
        self.path        = path
        self.method      = method
        self.headers     = headers
        self.body        = body
        self.imageUpload = nil
    }
    
    public init(path: String, method: Method, headers: Headers? = nil, body: Params? = nil, imageUpload: ImageUpload) {
        self.path        = path
        self.method      = method
        self.headers     = headers
        self.body        = body
        self.imageUpload = imageUpload
    }
    
    public mutating func add(_ _headers: Headers) -> HTTPRequest {
        if headers == nil {
            headers = HTTPRequest.Headers()
        }
        
        for (key, value) in _headers {
            _ = headers?.updateValue(value, forKey: key)
        }
        
        return self
    }
    
    public mutating func remove(_ _headers: Headers) -> HTTPRequest {
        for (key, value) in _headers {
            if let containsHeader = headers?.contains(where: { $0.1 == value }), containsHeader {
                _ = headers?.removeValue(forKey: key)
            }
        }
        
        return self
    }
    
    public func execute<T: AtlasMap>(_ completion: ((HTTPRequestOperation, HTTPResult<T>) -> Void)?) -> HTTPRequestOperation? {
        return HTTPService.defaultService().enqueue(self, completion: completion)
    }
    
    public func execute(_ completion: ((HTTPRequestOperation, HTTPResult<AnyObject>) -> Void)?) -> HTTPRequestOperation? {
        return HTTPService.defaultService().enqueue(self, completion: completion)
    }
    
    func urlRequest() -> URLRequest? {
        
        let baseURLString = HTTPService.defaultService().baseURL.absoluteString
        
        var URL: Foundation.URL
        if let _URL = Foundation.URL(string: baseURLString + path) {
            URL = _URL
        } else {
            return nil
        }
        
        var urlRequest = URLRequest(url: URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
        urlRequest.httpMethod = method.rawValue
        
        if let _image = imageUpload?.image, let _field = imageUpload?.field {
            
            guard let imageData = UIImageJPEGRepresentation(_image, 1.0) else {
                return nil
            }
            
            if imageData.count > 0 {
                
                let uniqueId = ProcessInfo.processInfo.globallyUniqueString
                let postBody = NSMutableData()
                var postData = ""
                let boundary = "------WebKitFormBoundary\(uniqueId)"
                
                urlRequest.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField:"Content-Type")
                
                if let _params = body {
                    postData += "--\(boundary)\r\n"
                    postData += appendParams(_params, withBoundary: boundary)
                    postData += "--\(boundary)\r\n"
                }
                
                postData += "Content-Disposition: form-data; name=\"\(_field)\"; filename=\"\(Int64(Date().timeIntervalSince1970*1000)).jpg\"\r\n"
                postData += "Content-Type: image/jpeg\r\n\r\n"
                postBody.append(postData.data(using: String.Encoding.utf8)!)
                postBody.append(imageData)
                postData = String()
                postData += "\r\n"
                postData += "\r\n--\(boundary)--\r\n"
                postBody.append(postData.data(using: String.Encoding.utf8)!)
                
                urlRequest.httpBody = NSData(data: postBody as Data) as Data
            }
        } else {
            if let _body = body {
                if let _bodyData = try? JSONSerialization.data(withJSONObject: _body, options: JSONSerialization.WritingOptions(rawValue: 0)) {
                    urlRequest.httpBody = _bodyData
                }
            }
        }
        
        if let _headers = headers {
            for (headerFeld, value) in _headers {
                urlRequest.addValue(value, forHTTPHeaderField: headerFeld)
            }
        }
        
        return urlRequest
    }
    
    fileprivate func appendParams(_ params: [String: Any], withBoundary boundary: String, parentKey: String? = nil, atIndex index: Int? = nil) -> String {
        var postData = ""
        for (key, value) in params {
            if let nestedParams = value as? [String: AnyObject] {
                postData += appendParams(nestedParams, withBoundary: boundary, parentKey: key)
            } else if let arrayParams = value as? [AnyObject] {
                postData += appendArrayParams(arrayParams, withBoundary: boundary, parentKey: key)
            } else {
                postData += "--\(boundary)\r\n"
                let _key: String
                if let _parentKey = parentKey {
                    if index != nil {
                        _key = "\(_parentKey)[][\(key)]"
                    } else {
                        _key = "\(_parentKey)[\(key)]"
                    }
                } else {
                    _key = key
                }
                postData += "Content-Disposition: form-data; name=\"\(_key)\"\r\n\r\n"
                postData += "\(value)\r\n"
            }
            
        }
        return postData
    }
    
    fileprivate func appendArrayParams(_ arrayParams: [AnyObject], withBoundary boundary: String, parentKey: String) -> String {
        var postData = ""
        for (index, param) in arrayParams.enumerated() {
            if let _param = param as? [String: AnyObject] {
                postData += appendParams(_param, withBoundary: boundary, parentKey: parentKey, atIndex: index)
            }
        }
        return postData
    }
    
}
