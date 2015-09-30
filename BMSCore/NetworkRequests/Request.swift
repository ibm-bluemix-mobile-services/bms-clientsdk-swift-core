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



public enum HttpMethod: String {
    case GET, POST, PUT, DELETE, TRACE, HEAD, OPTIONS, CONNECT, PATCH
}



public class Request: NSObject, NSURLSessionTaskDelegate {
    

    
    // MARK: Constants
    
    static let CONTENT_TYPE = "Content-Type"
    static let JSON_CONTENT_TYPE = "application/json"
    static let TEXT_PLAIN_TYPE = "text/plain"
    
    
    
    // MARK: Properties (public)
    
    public private(set) var resourceUrl: String
    public let httpMethod: HttpMethod
    public var timeout: Double
    public private(set) var headers: [String: String]
    // TODO: Append query parameters to the URL right before sending the request (like in Android SDK)
    public var queryParameters: [String: String]?
    public private(set) var requestBody: NSData?
    
    
    
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
    *  @param timeout The timeout in seconds for this request.
    *  @throws IllegalArgumentException if the method name is not one of the valid HTTP method names.
    *  @throws MalformedURLException    if the URL is not a valid URL
    */
    
    public init(url: String,
               method: HttpMethod = HttpMethod.GET,
               timeout: Double = BMSClient.sharedInstance.defaultRequestTimeout,
               headers: [String: String] = [:],
               queryParameters: [String: String] = [:]) {
            
        self.resourceUrl = url
        self.httpMethod = method
        self.headers = headers
        self.timeout = timeout
        self.queryParameters = queryParameters
        
        // Set timeout and initialize network session
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = timeout
        networkSession = NSURLSession(configuration: configuration)
            
        networkRequest = NSMutableURLRequest()
    }
    
    
    
    // MARK: Methods (public)
    
    // TODO: Perform error handling or make the developer do it?
    // Sets Content-Type to "application/json"
    public func setRequestBodyWithJSON(requestJSON: AnyObject) {
        
        do {
            requestBody = try NSJSONSerialization.dataWithJSONObject(requestJSON, options: NSJSONWritingOptions.PrettyPrinted)
        }
        catch {
            // Swift cannot catch NSExceptions anyway, so no use in making the user implement a do/catch
            // Log Error!
        }
        
        if let _ = headers[Request.CONTENT_TYPE] {}
        else {
            headers[Request.CONTENT_TYPE] = Request.JSON_CONTENT_TYPE
        }
    }
    
    // Sets Content-Type to "text/plain"
    // Only supports UTF-8 encoding
    public func setRequestBodyWithString(requestString: String) {
        
        requestBody = requestString.dataUsingEncoding(NSUTF8StringEncoding)
        
        if let _ = headers[Request.CONTENT_TYPE] {}
        else {
            headers[Request.CONTENT_TYPE] = Request.TEXT_PLAIN_TYPE
        }
    }
    
    public func setRequestBodyWithData(requestData: NSData) {
        
        requestBody = requestData
    }
    
    /**
    *  Send this resource request asynchronously.
    *
    *  @param completionHandler    The closure that will be called when this request finishes.
    */
    public func sendWithCompletionHandler(callback: (Response, ErrorType?) -> Void) {
        
        // Build the BMSResponse object, and pass it to the user
        let buildAndSendResponse = {
            (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            let roundTripTime = NSDate.timeIntervalSinceReferenceDate() - self.startTime
            
            let networkResponse = MFPResponse(responseData: data, httpResponse: response as? NSHTTPURLResponse, isRedirect: self.allowRedirects)
            
            callback(networkResponse as Response, error)
            
        }
        
        // Build request
        if let _ = queryParameters {
            resourceUrl = Request.appendQueryParameters(queryParameters!, toURL: self.resourceUrl)
        }
        networkRequest.HTTPMethod = httpMethod.rawValue
        networkRequest.allHTTPHeaderFields = headers
        networkRequest.HTTPBody = requestBody
        
        startTime = NSDate.timeIntervalSinceReferenceDate()
        
        networkSession.dataTaskWithRequest(networkRequest as NSURLRequest, completionHandler: buildAndSendResponse).resume()
    }
    
    
    
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

    
    
    // MARK: Methods (internal/private)
    
    // Returns the URL with query parameters appended to it
    static func appendQueryParameters(parameters: [String: String], toURL originalUrl: String) -> String {
        
        if parameters.isEmpty {
            return originalUrl
        }
        
        var parametersInURLFormat = [String]()
        for (key, var value) in parameters {
            
            if let urlSafeValue = value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
                value = urlSafeValue
            }
            else {
                value = ""
                // Log an error here
            }
            parametersInURLFormat += [key + "=" + "\(value)"]
        }
        
        return originalUrl + (originalUrl[originalUrl.endIndex.predecessor()] == "?" ? "" : "?") + parametersInURLFormat.joinWithSeparator("&")
    }
    
}
