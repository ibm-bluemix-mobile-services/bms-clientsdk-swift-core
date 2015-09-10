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


// TODO: INCORPORATE ALAMOFIRE

// ANTON: Worth it to prefix classes? Not necessary or even encouraged in Swift.
public class BMSRequest {
    
    
    // MARK: Constants
    
    static let DEFAULT_TIMEOUT: Int = 60000;
    static let CONTENT_TYPE: String = "Content-Type"
    static let JSON_CONTENT_TYPE: String = "application/json"
    static let TEXT_PLAIN: String = "text/plain"
    
    
    
    // MARK: Properties (public)
    
    // TODO: Access levels - which properties should be publicly settable?
    public private(set) var method: String
    public private(set) var url: String
    public private(set) var queryParameters: [String: String]?
    public private(set) var headers: [String: String]?
    public private(set) var timeout: Int
    // TODO: AlamoFire client?
    // TODO: Callback object?
    private var callBack: AnyObject {
        return ""
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
    init(url: String, method: String, headers: [String: String]?, parameters: [String: String]?, timeout: Int = BMSRequest.DEFAULT_TIMEOUT) {
        self.url = url
        self.method = method
        self.headers = headers
        self.queryParameters = parameters
        self.timeout = timeout
    }
    
    
    
    // MARK: Methods (public)
    
    // ANTON: Add send with delegate method(s)?
    
    /**
     *  Send this resource request asynchronously, without a request body.
     *
     *  @param delegate The delegate whose onSuccess or onFailure methods will be called when this request finishes.
     */
    public func sendWithCompletionHandler(delegate: ResponseDelegate) {
        
    }
    
    /**
     *  Send this resource request asynchronously, with the given string as the request body.
     *  If no content type header was set, this method will set it to "text/plain".
     *
     *  @param completionHandler    The closure that will be called when this request finishes.
     *  @param requestBody          The request body text
     */
    public func sendWithCompletionHandler(completionHandler: (NSURLRequest?, NSHTTPURLResponse?, NSData?, ErrorType?) -> Void,
                                         requestBody: String) {
        
    }
    
    /**
     *  Send this resource request asynchronously, with the given JSON object as the request body.
     *  If no content type header was set, this method will set it to "application/json".
     *
     *  @param completionHandler    The closure that will be called when this request finishes.
     *  @param requestJson          The JSON object to put in the request body
     */
    public func sendWithCompletionHandler(completionHandler: (NSURLRequest?, NSHTTPURLResponse?, NSData?, ErrorType?) -> Void,
                                         requestJson: [String: AnyObject]) {
        
    }
    
    /**
     *  Send this resource request asynchronously, with the content of the given byte array as the request body.
     *  Note that this method does not set any content type header, if such a header is required it must be set before calling this method.
     *
     *  @param completionHandler    The closure that will be called when this request finishes.
     *  @param requestData          The data containing the request body
     */
    public func sendWithCompletionHandler(completionHandler: (NSURLRequest?, NSHTTPURLResponse?, NSData?, ErrorType?) -> Void,
                                         requestData: [NSData]) {
        
    }
    
    /**
    *  Send this resource request asynchronously, with the given form parameters as the request body.
    *  This method will set the content type header to "application/x-www-form-urlencoded".
    *
    *  @param completionHandler     The closure that will be called when this request finishes.
    *  @param requestFormParameters The parameters to put in the request body
    */
    public func sendWithCompletionHandler(completionHandler: (NSURLRequest?, NSHTTPURLResponse?, NSData?, ErrorType?) -> Void,
                                         requestFormParameters: [String: String]) {
        
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
