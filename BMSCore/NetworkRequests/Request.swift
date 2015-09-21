/*
*     Copyright 2015 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http://www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/

import Foundation
import Alamofire


// GET, POST, PUT, etc.
public typealias HttpMethod = Alamofire.Method


// TODO: Replace Alamofire with NSURLSession

public class Request {
    
    
    // MARK: Constants
    
    static let CONTENT_TYPE = "Content-Type"
    static let JSON_CONTENT_TYPE = "application/json"
    static let TEXT_PLAIN = "text/plain"
    
    
    
    // MARK: Properties (public)
    
    public let url: String
    public let method: HttpMethod
    
    public var timeout: Double
    public var headers: [String: String]?
    public var queryParameters: [String: AnyObject]?
    public var requestBody: String? {
        didSet {
            contentType = "application/x-www-form-urlencoded"
        }
    }
    
    
    
    // MARK: Properties (internal/private)
    
    let networkManager: Alamofire.Manager
    var contentType = "text/plain"
    private var startTime: NSTimeInterval = 0.0
    var allowRedirects: Bool {
        get {
            return self.allowRedirects
        }
        set(redirectionIsAllowed) {
            if redirectionIsAllowed {
                networkManager.delegate.taskWillPerformHTTPRedirection = { _, _, _, request in
                    return request
                }
            }
            else {
                networkManager.delegate.taskWillPerformHTTPRedirection = { _, _, _, _ in
                    return nil
                }
            }
        }
    }
    
    
    
    // MARK: Initializers
    
    /**
    *  Constructs a new request with the specified URL, using the specified HTTP method.
    *  Additionally this constructor sets a custom timeout.
    *
    *  @param url     The resource URL
    *  @param method  The HTTP method to use.
    *  @param headers  Optional headers to add to the request.
    *  @param parameters  Optional query parameters to add to the request.
    *  @param timeout The timeout in milliseconds for this request.
    *  @throws IllegalArgumentException if the method name is not one of the valid HTTP method names.
    *  @throws MalformedURLException    if the URL is not a valid URL
    */
    
    // TODO: Throws
    public init(url: String,
        method: HttpMethod,
        //               timeout: Double = BMSClient.sharedInstance.defaultRequestTimeout,
        timeout: Double = BMSClient.sharedInstance.defaultRequestTimeout,
        headers: [String: String]? = nil) {
            
            self.url = url
            self.method = method
            self.headers = headers
            self.timeout = timeout
            
            // Set timeout and initialize Alamofire manager
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            configuration.timeoutIntervalForRequest = timeout
            networkManager = Alamofire.Manager(configuration: configuration, serverTrustPolicyManager: nil)
    }
    
    
    
    // MARK: Methods (public)
    
    /**
    *  Send this resource request asynchronously.
    *
    *  @param completionHandler    The closure that will be called when this request finishes.
    */
    public func sendWithCompletionHandler(callback: (MFPResponse, ErrorType?) -> Void) {
        
        var resultString: String?
        var resultJSON: AnyObject?
        
        // TODO: Restructure into multiple methods
        
        // Build the BMSResponse object, and pass it to the user
        let buildAndSendResponse = {
            (request: NSURLRequest?, response: NSHTTPURLResponse?, data: NSData?, error: ErrorType?) -> Void in
            
            let endTime = NSDate.timeIntervalSinceReferenceDate()
            let roundTripTime = endTime - self.startTime
            
            let alamoFireResponse = MFPResponse(responseText: resultString, responseJSON: resultJSON, responseData: data, alamoFireResponse: response, isRedirect: self.allowRedirects)
            
            callback(alamoFireResponse, error)
            
        }
        
        let extractStringResponse = {
            (_: NSURLRequest?, _: NSHTTPURLResponse?, result: Result<String>) -> Void in
            resultString = result.value
        }
        
        let extractJSONResponse = {
            (_: NSURLRequest?, _: NSHTTPURLResponse?, result: Result<AnyObject>) -> Void in
            resultJSON = result.value
        }
        
        startTime = NSDate.timeIntervalSinceReferenceDate()
        
        networkManager.request(self.method, self.url, parameters: self.queryParameters, headers: self.headers)
            .responseString(completionHandler: extractStringResponse)
            .responseJSON(completionHandler: extractJSONResponse)
            .response(completionHandler: buildAndSendResponse)
    }
    
    
    
    // MARK: Methods (internal/private)
    
    // TODO: Network logging interceptor
    
    
}
