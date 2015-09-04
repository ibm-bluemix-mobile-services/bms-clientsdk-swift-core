//
//  BMSRequest.swift
//  BMSCore
//
//  Created by Anthony Oliveri on 9/1/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import Foundation


// TODO: INCORPORATE ALAMOFIRE
public class BMSRequest {
    
    
    // MARK: Constants
    
    static let DEFAULT_TIMEOUT: Int = 60000;
    static let CONTENT_TYPE: String = "Content-Type"
    static let JSON_CONTENT_TYPE: String = "application/json"
    static let TEXT_PLAIN: String = "text/plain"
    
    
    
    // MARK: Properties (public)
    
    public private(set) var method: String
    public private(set) var url: String
    public var queryParameters: [String: String]?
    public var headers: [String: String]?
    public var timeout: Int
    // TODO: AlamoFire client?
    // TODO: Callback object?
    public var callBack: AnyObject {
        return ""
    }
    
    
    
    // MARK: Properties (internal/private)
    
    
    
    // MARK: Initializers
    
    /**
    *  Constructs a new request with the specified URL, using the specified HTTP method.
    *  Additionally this constructor sets a custom timeout.
    *
    *  @param url     The resource URL
    *  @param method  The HTTP method to use.
    *  @param timeout The timeout in milliseconds for this request.
    *  @throws IllegalArgumentException if the method name is not one of the valid HTTP method names.
    *  @throws MalformedURLException    if the URL is not a valid URL
    */
    // TODO: Throws
    
    // DGONZ: Why not include query parameters and headers in initializers?
    init(url: String, method: String, timeout: Int = BMSRequest.DEFAULT_TIMEOUT) {
        self.url = url
        self.method = method
        self.timeout = timeout
    }
    
    
    
    // MARK: Methods (public)
    
    // DGONZ: Public properties instead of getters and setters?
    
    // DGONZ: Is removeHeaders necessary? User can just set to nil.
    
    // DGONZ: Is addHeader and addQueryParams necessary? They are just String:String dictionaries
    
    // TODO: Delegates vs completion blocks 
    // (Obj-C API had only 1 send method, and it took a block as its only parameter)
    
    /**
     *  Send this resource request asynchronously, without a request body.
     *
     *  @param delegate The delegate whose onSuccess or onFailure methods will be called when this request finishes.
     */
    public func sendWithDelegate(delegate: ResponseDelegate) {
        
    }
    
    /**
     *  Send this resource request asynchronously, with the given string as the request body.
     *  If no content type header was set, this method will set it to "text/plain".
     *
     *  @param requestBody The request body text
     *  @param delegate    The delegate whose onSuccess or onFailure methods will be called when this request finishes.
     */
    public func sendWithRequestBody(requestBody: String, delegate: ResponseDelegate) {
        
    }
    
    /**
     *  Send this resource request asynchronously, with the given JSON object as the request body.
     *  If no content type header was set, this method will set it to "application/json".
     *
     *  @param json     The JSON object to put in the request body
     *  @param delegate The delegate whose onSuccess or onFailure methods will be called when this request finishes.
     */
    public func sendWithRequestJson(jsonData: [String: AnyObject], delegate: ResponseDelegate) {
        
    }
    
    /**
     *  Send this resource request asynchronously, with the content of the given byte array as the request body.
     *  Note that this method does not set any content type header, if such a header is required it must be set before calling this method.
     *
     *  @param data     The byte array containing the request body
     *  @param delegate The delegate whose onSuccess or onFailure methods will be called when this request finishes.
     */
    public func sendWithRequestBytes(byteData: [UInt8], delegate: ResponseDelegate) {
        
    }
    
    /**
    *  Send this resource request asynchronously, with the given form parameters as the request body.
    *  This method will set the content type header to "application/x-www-form-urlencoded".
    *
    *  @param formParameters The parameters to put in the request body
    *  @param delegate       The delegate whose onSuccess or onFailure methods will be called when this request finishes.
    */
    public func sendWithFormParameters(formParameters: [String: String], delegate: ResponseDelegate) {
        
    }
    
    
    
    // MARK: Methods (internal/private)
    
    // TODO: Figure out how to handle redirects with AlamoFire
    
    func sendRequestWithRequestBody(requestBody: String, delegate: ResponseDelegate) {
        
    }
    
    func combineUrlWithQueryParameters(queryParameters: [String: String], url: String) {
        
    }
    
    func urlContainsUriPath(url: String) {
        
    }
    
    func setUp() {
        
    }
    
    func registerInterceptor() {
        
    }
    
    func unregisterInterceptor() {
        
    }
    
}
