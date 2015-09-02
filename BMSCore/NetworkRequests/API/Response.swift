//
//  Response.swift
//  BMSCore
//
//  Created by Anthony Oliveri on 9/1/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import Foundation


public struct Response: CustomStringConvertible {
    
    
    // MARK: Properties (public)
    
    public var description: String {
        return ""
    }
    
    /**
     *  HTTP status of the response. Returns "0" for no response.
     */
    public var status: String {
        return ""
    }
    
    /**
    *  Dictionary with all the headers and the corresponding values for each one.
    */
    public func responseHeaders() -> [String: String] {
        return [:]
    }
    
    /**
     *  The body of the response as a String. Returns nil if there is no body or exception occurred when building the response string.
     */
    public var responseText: String {
        return ""
    }
    
    /**
     *  The body of the response as a JSONObject. Returns nil if there is no body or if it is not a valid JSONObject.
     */
    public var responseJSON: [String: AnyObject] {
        return [:]
    }
    
    /**
     *  The body of the response as a byte array. Returns nil if there is no body.
     */
    public func responseBytes() -> [UInt8] {
        return [UInt8]()
    }
    
    /** 
     *  Returns true if this response redirects to another resource.
     */
    public var isRedirect: Bool {
        return false
    }
    
    /**
     *  Returns true if the code is in [200..300), which means the request was
     *  successfully received, understood, and accepted.
     */
    public var isSuccessful: Bool {
        return false
    }
    
    /**
     *  The error code for the cause of the failure.
     */
    public var errorCode: ErrorCode?
    
    
    
    // MARK: Properties (internal/private)
    
    private var alamoFireResponse: NSHTTPURLResponse
    private var headers: [String: String]


    
    // MARK: Initializer
    
    // TODO: Add AlamoFire response parameter
    init(response: NSHTTPURLResponse, error: ErrorCode?) {
        alamoFireResponse = response
        headers = [:]
        
        errorCode = error
    }
    
}



/**
 *  Error codes explaining why the request failed.
 */
public enum ErrorCode {
    
    /**
     *  The client failed to connect to the server. Possible reasons include connection timeout,
     *  DNS failures, secure connection problems, etc.
     */
    case UNABLE_TO_CONNECT
    
    /**
     *  The server responded with a failure code.
     */
    case SERVER_ERROR
}



