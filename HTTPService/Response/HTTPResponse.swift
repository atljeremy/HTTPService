//
//  HTTPResponse.swift
//
//  Created by Jeremy Fox on 2/26/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

public struct HTTPResponse {
    
    public let data: NSData
    public let statusCode: Int
    
    public init(data: NSData, urlResponse: NSURLResponse) {
        self.data = data
        if let _urlResponse = urlResponse as? NSHTTPURLResponse {
            statusCode = _urlResponse.statusCode
        } else {
            statusCode = -1
        }
    }
    
    public enum HTTPStatusCode: Int {
        case StatusCodeUnkown = 000
        case StatusCode100    = 100 // 'Continue'
        case StatusCode101    = 101 // 'Switching Protocols'
        case StatusCode102    = 102 // 'Processing'
        case StatusCode200    = 200 // 'OK'
        case StatusCode201    = 201 // 'Created'
        case StatusCode202    = 202 // 'Accepted'
        case StatusCode203    = 203 // 'Non-Authoritative Information'
        case StatusCode204    = 204 // 'No Content'
        case StatusCode205    = 205 // 'Reset Content'
        case StatusCode206    = 206 // 'Partial Content'
        case StatusCode207    = 207 // 'Multi-Status'
        case StatusCode208    = 208 // 'Already Reported'
        case StatusCode226    = 226 // 'IM Used'
        case StatusCode300    = 300 // 'Multiple Choices'
        case StatusCode301    = 301 // 'Moved Permanently'
        case StatusCode302    = 302 // 'Found'
        case StatusCode303    = 303 // 'See Other'
        case StatusCode304    = 304 // 'Not Modified'
        case StatusCode305    = 305 // 'Use Proxy'
        case StatusCode306    = 306 // 'Reserved'
        case StatusCode307    = 307 // 'Temporary Redirect'
        case StatusCode308    = 308 // 'Permanent Redirect'
        case StatusCode400    = 400 // 'Bad Request'
        case StatusCode401    = 401 // 'Unauthorized'
        case StatusCode402    = 402 // 'Payment Required'
        case StatusCode403    = 403 // 'Forbidden'
        case StatusCode404    = 404 // 'Not Found'
        case StatusCode405    = 405 // 'Method Not Allowed'
        case StatusCode406    = 406 // 'Not Acceptable'
        case StatusCode407    = 407 // 'Proxy Authentication Required'
        case StatusCode408    = 408 // 'Request Timeout'
        case StatusCode409    = 409 // 'Conflict'
        case StatusCode410    = 410 // 'Gone'
        case StatusCode411    = 411 // 'Length Required'
        case StatusCode412    = 412 // 'Precondition Failed'
        case StatusCode413    = 413 // 'Request Entity Too Large'
        case StatusCode414    = 414 // 'Request-URI Too Long'
        case StatusCode415    = 415 // 'Unsupported Media Type'
        case StatusCode416    = 416 // 'Requested Range Not Satisfiable'
        case StatusCode417    = 417 // 'Expectation Failed'
        case StatusCode422    = 422 // 'Unprocessable Entity'
        case StatusCode423    = 423 // 'Locked'
        case StatusCode424    = 424 // 'Failed Dependency'
        case StatusCode425    = 425 // 'Reserved for WebDAV advanced collections expired proposal'
        case StatusCode426    = 426 // 'Upgrade Required'
        case StatusCode427    = 427 // 'Unassigned'
        case StatusCode428    = 428 // 'Precondition Required'
        case StatusCode429    = 429 // 'Too Many Requests'
        case StatusCode430    = 430 // 'Unassigned'
        case StatusCode431    = 431 // 'Request Header Fields Too Large'
        case StatusCode500    = 500 // 'Internal Server Error'
        case StatusCode501    = 501 // 'Not Implemented'
        case StatusCode502    = 502 // 'Bad Gateway'
        case StatusCode503    = 503 // 'Service Unavailable'
        case StatusCode504    = 504 // 'Gateway Timeout'
        case StatusCode505    = 505 // 'case  Version Not Supported'
        case StatusCode506    = 506 // 'Variant Also Negotiates (Experimental)'
        case StatusCode507    = 507 // 'Insufficient Storage'
        case StatusCode508    = 508 // 'Loop Detected'
        case StatusCode509    = 509 // 'Unassigned'
        case StatusCode510    = 510 // 'Not Extended'
        case StatusCode511    = 511 // 'Network Authentication Required'
    }

}
