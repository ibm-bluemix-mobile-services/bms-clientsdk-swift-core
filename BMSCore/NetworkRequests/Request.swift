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



// Headers 
//      Can have multiple values per key
//      Do not overwrite content-type if user already set it
// Query parameters
//      Don't allow multiple values - keep as [String: String] type
//      For appending to URL - does not affect MIME type
// HTTP body
//      NSData
//      String - Set Content-type to "text/plain" if not already set



// TODO: Error handling (throws)

public class Request: NSObject, NSURLSessionTaskDelegate {
    
    
    
    // MARK: Constants
    
    static let CONTENT_TYPE = "Content-Type"
    static let JSON_CONTENT_TYPE = "application/json"
    static let TEXT_PLAIN_TYPE = "text/plain"
    
    
    
    // MARK: Properties (public)
    
    public private(set) var resourceUrl: String
    public let httpMethod: HttpMethod
    public var timeout: Double
    public private(set) var headers: [String: String]?
    // TODO: Append query parameters to the URL right before sending the request (like in Android SDK)
    public var queryParameters: [String: String]?
    public var requestBody: String?
    
    
    
    // MARK: Properties (internal/private)
    
    var networkSession: NSURLSession
    var networkRequest: NSMutableURLRequest
    private var startTime: NSTimeInterval = 0.0
    var allowRedirects: Bool = true
    
    
    
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
    
    public init(url: String,
               method: HttpMethod = HttpMethod.GET,
               timeout: Double = BMSClient.sharedInstance.defaultRequestTimeout,
               headers: [String: String]?,
               queryParameters: [String: String]?) {
            
        self.resourceUrl = url
        self.httpMethod = method
        self.headers = headers
        self.timeout = timeout
        self.queryParameters = queryParameters
        
        // Set timeout and initialize network session
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = timeout
        networkSession = NSURLSession(configuration: configuration)
            
        // TODO: Add URL after it is built
        networkRequest = NSMutableURLRequest()
    }
    
    
    
    // MARK: Methods (public)
    
    /**
    *  Send this resource request asynchronously.
    *
    *  @param completionHandler    The closure that will be called when this request finishes.
    */
    public func sendWithCompletionHandler(callback: (MFPResponse, ErrorType?) -> Void) {
        
        // Build the BMSResponse object, and pass it to the user
        let buildAndSendResponse = {
            (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            let endTime = NSDate.timeIntervalSinceReferenceDate()
            let roundTripTime = endTime - self.startTime
            
            let networkResponse = MFPResponse(responseData: data, httpResponse: response as? NSHTTPURLResponse, isRedirect: self.allowRedirects)
            
            callback(networkResponse, error)
            
        }
        
        networkRequest.HTTPMethod = self.httpMethod.rawValue
        networkRequest.allHTTPHeaderFields = headers
        
        startTime = NSDate.timeIntervalSinceReferenceDate()
        
        networkSession.dataTaskWithRequest(networkRequest as NSURLRequest, completionHandler: buildAndSendResponse).resume()
    }
    
    
    
    // MARK: Methods (internal/private)
    
    
    
    // MARK: NSURLSessionTaskDelegate
    
    // Handle HTTP redirection
    public func URLSession(session: NSURLSession,
                          task: NSURLSessionTask,
                          willPerformHTTPRedirection response: NSHTTPURLResponse,
                          newRequest request: NSURLRequest,
                          completionHandler: ((NSURLRequest?) -> Void))
    {
        var redirectRequest: NSURLRequest?
        
        if allowRedirects {
            redirectRequest = request
        }
        
        completionHandler(redirectRequest)
    }
    
}



public enum HttpMethod: String {
    case GET, POST, PUT, DELETE, TRACE, HEAD, OPTIONS, CONNECT, PATCH
}
