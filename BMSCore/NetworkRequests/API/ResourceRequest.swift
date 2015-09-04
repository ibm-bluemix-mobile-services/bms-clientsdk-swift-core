//
//  ResourceRequest.swift
//  BMSCore
//
//  Created by Anthony Oliveri on 9/1/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import Foundation


public class ResourceRequest: BMSRequest {
    
    
    // MARK: Properties (public)
    
    override public var callBack: AnyObject {
        return ""
    }
    
    
    
    // MARK: Initializers
    
    /**
    *  Constructs a new resource request with the specified URL, using the specified HTTP method.
    *  Additionally this constructor sets a custom timeout.
    *
    *  @param url     The resource URL
    *  @param method  The HTTP method to use.
    *  @param timeout The timeout in milliseconds for this request.
    *  @throws IllegalArgumentException if the method name is not one of the valid HTTP method names.
    *  @throws MalformedURLException    if the URL is not a valid URL
    */
    // TODO: throws
    override init(url: String, method: String, timeout: Int = BMSRequest.DEFAULT_TIMEOUT) {
        super.init(url: url, method: method, timeout: timeout)
    }
    
    
    
    // MARK: Methods (internal/private)
    
    override func sendRequestWithRequestBody(requestBody: String, delegate: ResponseDelegate) {
        
    }
    
}
