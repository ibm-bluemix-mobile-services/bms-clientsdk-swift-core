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


/**
    The HTTP method to be used in the `Request` initializer.
*/
public enum HttpMethod: String {
    case GET, POST, PUT, DELETE, TRACE, HEAD, OPTIONS, CONNECT, PATCH
}


// CODE REVIEW: Create custom ErrorType called "MFPError" - case for NSURL and case for appendQueryParameters
// Figure out how to create a message associated with the error
private enum MFPError: String, ErrorType {
    case test = "aadsf"
}
 

/**
    Build and send HTTP network requests.

    When building a Request object, all properties must be provided in the initializer, 
        except for the `requestBody`, which can be supplied as either NSData or plain text 
        when sending the request via one of the following methods:

        sendString(requestBody: String, withCompletionHandler callback: mfpCompletionHandler?)
        sendData(requestBody: NSData, withCompletionHandler callback: mfpCompletionHandler?)
*/
public class Request: NSObject, NSURLSessionTaskDelegate {
    
    
    /// The type of the completion handler parameters in the `sendString` and `sendData` methods
    public typealias mfpCompletionHandler = (Response, ErrorType?) -> Void

    
    // MARK: Constants
    
    static let CONTENT_TYPE = "Content-Type"
    static let TEXT_PLAIN_TYPE = "text/plain"
    
    
    
    // MARK: Properties (public)
    
    /// URL that the request is being sent to
    public private(set) var resourceUrl: String
    
    /// HTTP method (GET, POST, etc.)
    public let httpMethod: HttpMethod
    
    /// Request timeout measured in seconds
    public var timeout: Double
    
    /// All request headers. The "Content-Type" header is set by the `setRequestBody` methods.
    public private(set) var headers: [String: String]?
    
    /// Query parameters to append to the `resourceURL`
    public var queryParameters: [String: String]?
    
    /// The request body can be supplied as NSData or String, but is always converted to NSData
    ///     before sending the request.
    public private(set) var requestBody: NSData?
    
    
    
    // MARK: Properties (internal/private)
    
    var networkSession: NSURLSession
    var networkRequest: NSMutableURLRequest
    var allowRedirects: Bool = true
    private var startTime: NSTimeInterval = 0.0
    
    
    
    // MARK: Initializers
    
    /**
        Constructs a new request with the specified URL, using the specified HTTP method.
        Additionally this constructor sets a custom timeout.

        - parameter url:             The resource URL
        - parameter method:          The HTTP method to use
        - parameter headers:         Optional headers to add to the request.
        - parameter queryParameters: Optional query parameters to add to the request.
        - parameter timeout:         Timeout in seconds for this request
    */
    public init(url: String,
               headers: [String: String]?,
               queryParameters: [String: String]?,
               method: HttpMethod = HttpMethod.GET,
               timeout: Double = BMSClient.sharedInstance.defaultRequestTimeout) {
        
        self.resourceUrl = url
        self.httpMethod = method
        self.headers = headers
        self.timeout = timeout
        self.queryParameters = queryParameters
        
        // Set timeout and initialize network session and request
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = timeout
        networkSession = NSURLSession(configuration: configuration)
        networkRequest = NSMutableURLRequest()
    }

    
    /**
        Add a request body and send the request asynchronously.
    
        If the Content-Type header is not already set, it will be set to "text/plain".
    
        The response received from the server is packaged into a `Response` object which is passed back
        via the completion handler parameter.
    
        - parameter requestBody: HTTP request body as a String
        - parameter withCompletionHandler: The closure that will be called when this request finishes
    */
    func sendString(requestBody: String, withCompletionHandler callback: mfpCompletionHandler?) {
        
        self.requestBody = requestBody.dataUsingEncoding(NSUTF8StringEncoding)
        
        if headers == nil {
            headers = [Request.CONTENT_TYPE: Request.TEXT_PLAIN_TYPE]
        }
        else {
            if headers![Request.CONTENT_TYPE] == nil {
                headers![Request.CONTENT_TYPE] = Request.TEXT_PLAIN_TYPE
            }
        }
        
        
        self.sendWithCompletionHandler(callback)
    }
    
    
    /**
        Add a request body and send the request asynchronously.
        
        The response received from the server is packaged into a `Response` object which is passed back
        via the completion handler parameter.
    
        - parameter requestBody: HTTP request body as NSData
        - parameter withCompletionHandler: The closure that will be called when this request finishes
    */
    func sendData(requestBody: NSData, withCompletionHandler callback: mfpCompletionHandler?) {
        
        self.requestBody = requestBody
        self.sendWithCompletionHandler(callback)
    }
    
    
    /**
        Send the request asynchronously.
    
        The response received from the server is packaged into a `Response` object which is passed back
        via the completion handler parameter.

        - parameter completionHandler: The closure that will be called when this request finishes
    */
    public func sendWithCompletionHandler(callback: mfpCompletionHandler?) {
        
        // Build the BMSResponse object, and pass it to the user
        let buildAndSendResponse = {
            (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            // TODO: Make use of the round trip time with Analytics
            let roundTripTime = NSDate.timeIntervalSinceReferenceDate() - self.startTime
            
            let networkResponse = Response(responseData: data, httpResponse: response as? NSHTTPURLResponse, isRedirect: self.allowRedirects)
            
            callback?(networkResponse as Response, error)
        }
        
        // Build request
        if var url = NSURL(string: self.resourceUrl) {
            
            url = Request.appendQueryParameters(queryParameters, toURL: url)
            resourceUrl = String(url)
            
            networkRequest.URL = url
            networkRequest.HTTPMethod = httpMethod.rawValue
            networkRequest.allHTTPHeaderFields = headers
            networkRequest.HTTPBody = requestBody
            
            startTime = NSDate.timeIntervalSinceReferenceDate()
            
            // Send request
            networkSession.dataTaskWithRequest(networkRequest as NSURLRequest, completionHandler: buildAndSendResponse).resume()
        }
        else {
            // CODE REVIEW: Handle error
        }
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
    
    /**
        Returns the supplied URL with query parameters appended to it; the original URL is not modified.
        Characters in the query parameters that are not URL safe are automatically converted to percent-encoding.
    
        - parameter parameters:  The query parameters to be appended to the end of the url string
        - parameter originalURL: The url that the `parameters` will be appeneded to
    
        - returns: The original URL with the query parameters appended to it
    */
    static func appendQueryParameters(parameters: [String: String]?, toURL originalUrl: NSURL) -> NSURL {
        
        if parameters == nil {
            return originalUrl
        }
        
        var parametersInURLFormat = [NSURLQueryItem]()
        for (key, value) in parameters! {
            parametersInURLFormat += [NSURLQueryItem(name: key, value: value)]
        }
        
        let newUrlComponents = NSURLComponents(URL: originalUrl, resolvingAgainstBaseURL: false)
        if newUrlComponents?.queryItems != nil {
            newUrlComponents?.queryItems?.appendContentsOf(parametersInURLFormat)
        }
        else {
            newUrlComponents?.queryItems = parametersInURLFormat
        }
        if let newUrl = newUrlComponents?.URL {
            return newUrl
        }
        else {
            // CODE REVIEW: Error handling
            
            // TODO: Log a warning or error here
            return originalUrl
        }
    }
    
}
