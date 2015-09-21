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


// TODO: Split into 2 classes like Response?
public class Request {
    
    
    // MARK: Constants
    
    static let DEFAULT_TIMEOUT = 60000.0;
    static let CONTENT_TYPE = "Content-Type"
    static let JSON_CONTENT_TYPE = "application/json"
    static let TEXT_PLAIN = "text/plain"
    
    
    
    // MARK: Properties (public)
    
    // TODO: Access levels - which properties should be publicly settable?
    public let method: HttpMethod
    public let url: String
    public let headers: [String: String]?
    public let timeout: Double
    public private(set) var queryParameters: [String: AnyObject]?
    
    
    
    // MARK: Properties (internal/private)
    
    let networkManager: Alamofire.Manager
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
               headers: [String: String]?,
               timeout: Double = Request.DEFAULT_TIMEOUT) {
        
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
    
    // TODO: Add JSON or text
    
    // If no content type header was set, this method will set it to "text/plain"
    public func setRequestBody(requestString: String) {
        
    }
    
    // If no content type header was set, this method will set it to "application/json"
    public func setRequestBody(requestJson: [String: AnyObject]?) {
        
    }
    
    // This method will set the content type header to "application/x-www-form-urlencoded".
    public func setQueryParameters(requestParameters: [String: String]) {
        
    }
    
    /**
     *  Send this resource request asynchronously.
     *
     *  @param completionHandler    The closure that will be called when this request finishes.
     */
    public func sendWithCompletionHandler(callback: (MFPResponse) -> Void) {
        
        var resultString: String?
        var resultJSON: AnyObject?
        
        // TODO: Restructure into multiple methods
        
        // Build the BMSResponse object, and pass it to the user
        let buildAndSendResponse = {
            (request: NSURLRequest?, response: NSHTTPURLResponse?, data: NSData?, error: ErrorType?) -> Void in
            
            // TODO: Rewrite timer to be better organized (possibly separate method)
            let endTime = NSDate.timeIntervalSinceReferenceDate()
            let roundTripTime = endTime - self.startTime
            
            let alamoFireResponse = MFPResponse(responseText: resultString, responseJSON: resultJSON, responseData: data, alamoFireResponse: response, isRedirect: self.allowRedirects)
            
            // TODO: Callback with only one parameter?
            callback(alamoFireResponse)
            
        }
        
        let extractStringResponse = {
            (_: NSURLRequest?, _: NSHTTPURLResponse?, result: Result<String>) -> Void in
                resultString = result.value
        }
        
        let extractJsonResponse = {
            (_: NSURLRequest?, _: NSHTTPURLResponse?, result: Result<AnyObject>) -> Void in
            resultJSON = result.value
        }
        
        startTime = NSDate.timeIntervalSinceReferenceDate()
        
        networkManager.request(self.method, self.url, parameters: self.queryParameters, headers: self.headers)
                      .responseString(completionHandler: extractStringResponse)
                      .responseJSON(completionHandler: extractJsonResponse)
                      .response(completionHandler: buildAndSendResponse)
    }
    
    
    
    // MARK: Methods (internal/private)
    
    // TODO: Network logging interceptor
    
    
}
