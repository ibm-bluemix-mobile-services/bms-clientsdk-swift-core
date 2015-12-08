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


import WatchKit
 

/**
    The HTTP method to be used in the `Request` class initializer.
*/
public enum HttpMethod: String {
    case GET, POST, PUT, DELETE, TRACE, HEAD, OPTIONS, CONNECT, PATCH
}
 
 
/**
    The type of callback sent with MFP network requests
*/
public typealias MfpCompletionHandler = (Response?, NSError?) -> Void

 
/**
    Build and send HTTP network requests.

    When building a Request object, all components of the HTTP request must be provided in the initializer, except for the `requestBody`, which can be supplied as either NSData or plain text when sending the request via one of the following methods:

        sendString(requestBody: String, withCompletionHandler callback: mfpCompletionHandler?)
        sendData(requestBody: NSData, withCompletionHandler callback: mfpCompletionHandler?)
*/
public class Request: NSObject, NSURLSessionTaskDelegate {

    
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
    
    /// All request headers
    public private(set) var headers: [String: String] = [:]
    
    /// Query parameters to append to the `resourceURL`
    public var queryParameters: [String: String]?
    
    /// The request body can be set when sending the request via the `sendString` or `sendData` methods.
    public private(set) var requestBody: NSData?
    
    
    
    
    // MARK: Properties (internal/private)
    
    var networkSession: NSURLSession
    var networkRequest: NSMutableURLRequest
    var allowRedirects: Bool = true
    private var startTime: NSTimeInterval = 0.0
    private var trackingId: String = ""
    private let logger = Logger.getLoggerForName(MFP_REQUEST_PACKAGE)
    
    
    
    // MARK: Initializer
    
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
        if headers != nil {
            self.headers = headers!
        }
        self.timeout = timeout
        self.queryParameters = queryParameters
        
        // Set timeout and initialize network session and request
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = timeout
        networkSession = NSURLSession(configuration: configuration)
        networkRequest = NSMutableURLRequest()
    }
    
    
    
    // MARK: Methods (public)
    
    /**
        Add a request body and send the request asynchronously.
    
        If the Content-Type header is not already set, it will be set to "text/plain".
    
        The response received from the server is packaged into a `Response` object which is passed back via the completion handler parameter.
    
        If the `resourceUrl` string is a malformed url or if the `queryParameters` cannot be appended to it, the completion handler will be called back with an error and a nil `Response`.
    
        - parameter requestBody: HTTP request body
        - parameter withCompletionHandler: The closure that will be called when this request finishes
    */
    func sendString(requestBody: String, withCompletionHandler callback: MfpCompletionHandler?) {
        self.requestBody = requestBody.dataUsingEncoding(NSUTF8StringEncoding)
        
        // Don't want to overwrite content type if it has already been specified as something else
        if headers[Request.CONTENT_TYPE] == nil {
            headers[Request.CONTENT_TYPE] = Request.TEXT_PLAIN_TYPE
        }
        
        self.sendWithCompletionHandler(callback)
    }
    
    
    /**
        Add a request body and send the request asynchronously.
        
        The response received from the server is packaged into a `Response` object which is passed back via the completion handler parameter.
    
        If the `resourceUrl` string is a malformed url or if the `queryParameters` cannot be appended to it, the completion handler will be called back with an error and a nil `Response`.
    
        - parameter requestBody: HTTP request body
        - parameter withCompletionHandler: The closure that will be called when this request finishes
    */
    func sendData(requestBody: NSData, withCompletionHandler callback: MfpCompletionHandler?) {
        
        self.requestBody = requestBody
        self.sendWithCompletionHandler(callback)
    }
    
    
    /**
        Send the request asynchronously.
    
        The response received from the server is packaged into a `Response` object which is passed back via the completion handler parameter.
    
        If the `resourceUrl` string is a malformed url or if the `queryParameters` cannot be appended to it, the completion handler will be called back with an error and a nil `Response`.

        - parameter completionHandler: The closure that will be called when this request finishes
    */
    public func sendWithCompletionHandler(callback: MfpCompletionHandler?) {
        // Build the Response object and pass it to the user
        let originalUrl = self.resourceUrl // Copy the url before query parameters get added to it
        let buildAndSendResponse = {
            (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            let networkResponse = Response(responseData: data, httpResponse: response as? NSHTTPURLResponse, isRedirect: self.allowRedirects)
            
            self.logInboundResponse(networkResponse, url: originalUrl)
            
            callback?(networkResponse as Response, error)
        }
        
        // Add metadata to the request header so that analytics data can be obtained for ALL mfp network requests
        // Must be called before query parameters are added to self.resourceUrl
        addAnalyticsMetadataToRequest()
        
        self.startTime = NSDate.timeIntervalSinceReferenceDate()
        
        if var url = NSURL(string: self.resourceUrl) {
            
            if queryParameters != nil {
                guard let urlWithQueryParameters = Request.appendQueryParameters(queryParameters!, toURL: url) else {
                    // This scenario does not seem possible due to the robustness of appendQueryParameters(), but it will stay just in case
                    let urlErrorMessage = "Failed to append the query parameters to the resource url."
                    logger.error(urlErrorMessage)
                    let malformedUrlError = NSError(domain: MFP_CORE_ERROR_DOMAIN, code: MFPErrorCode.MalformedUrl.rawValue, userInfo: [NSLocalizedDescriptionKey: urlErrorMessage])
                    callback?(nil, malformedUrlError)
                    return
                }
                url = urlWithQueryParameters
            }
            
            // Build request
            resourceUrl = String(url)
            networkRequest.URL = url
            networkRequest.HTTPMethod = httpMethod.rawValue
            networkRequest.allHTTPHeaderFields = headers
            networkRequest.HTTPBody = requestBody
            
            logger.info("Sending Request to " + resourceUrl)
            
            // Send request
            networkSession.dataTaskWithRequest(networkRequest as NSURLRequest, completionHandler: buildAndSendResponse).resume()
        }
        else {
            let urlErrorMessage = "The supplied resource url is not a valid url."
            logger.error(urlErrorMessage)
            let malformedUrlError = NSError(domain: MFP_CORE_ERROR_DOMAIN, code: MFPErrorCode.MalformedUrl.rawValue, userInfo: [NSLocalizedDescriptionKey: urlErrorMessage])
            callback?(nil, malformedUrlError)
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
            logger.info("Redirecting: " + String(session))
            redirectRequest = request
        }
        
        completionHandler(redirectRequest)
    }

    
    
    // MARK: Methods (internal/private)
    
    internal func addAnalyticsMetadataToRequest() {
        
        logger.debug("Network request outbound")
        
        // The analytics server needs this ID to match each request with its corresponding response
        self.trackingId = NSUUID().UUIDString
        headers["x-wl-analytics-tracking-id"] = self.trackingId
        
        // CODE REVIEW: Should I log an warning/error if certain header fields are nil?

        // Build the analytics metadata header
        
        // Device info
        var osVersion = ""
        var model = ""
        var deviceId = ""
        #if TARGET_OS_WATCH
            let device = WKInterfaceDevice.currentDevice()
            osVersion = device.systemVersion
            deviceId = Request.getUniqueDeviceId() // No "identifierForVendor" property for Apple Watch
            model = "Apple Watch"
        #elseif TARGET_OS_IOS
            let device = UIDevice.currentDevice()
            osVersion = device.systemVersion
            deviceId = device.identifierForVendor?.UUIDString as String
            model = device.modelName
        #endif
        
        // All of this data will go in a header for the request
        var requestMetadata: [String: String] = [:]
        
        requestMetadata["os"] = "ios"
        requestMetadata["brand"] = "Apple"
        requestMetadata["osVersion"] = osVersion
        requestMetadata["model"] = model
        requestMetadata["deviceID"] = deviceId
        requestMetadata["mfpAppName"] = "" // TODO: Get from Analytics or Logger initializer
        requestMetadata["appStoreLabel"] = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String ?? ""
        requestMetadata["appStoreId"] = NSBundle.mainBundle().bundleIdentifier ?? ""
        requestMetadata["appVersionCode"] = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String ?? ""
        requestMetadata["appVersionDisplay"] = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? ""

        do {
            let requestMetadataJson = try NSJSONSerialization.dataWithJSONObject(requestMetadata, options: [])
            let requestMetadataString = String(data: requestMetadataJson, encoding: NSUTF8StringEncoding)
            if requestMetadataString != nil {
                self.headers["x-mfp-analytics-metadata"] = requestMetadataString
            }
            logger.analytics(requestMetadata)
        }
        catch let error {
            logger.error("Failed to append analytics metadata to request. Error: \(error)")
        }
    }
    
    
    // Create a UUID for the current device and save it to the keychain
    // Currently only used for Apple Watch devices
    internal func getUniqueDeviceId() -> String {
        
        // First, check if a UUID was already created
        let mfpUserDefaults = NSUserDefaults(suiteName: "com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore")
        guard mfpUserDefaults != nil else {
            logger.error("Failed to get an ID for this device.")
            return ""
        }
        
        var deviceId = mfpUserDefaults!.stringForKey("deviceId")
        if deviceId == nil {
            deviceId = NSUUID().UUIDString
            mfpUserDefaults!.setValue(deviceId, forKey: "deviceId")
        }
        return deviceId!
    }
    
    
    internal func logInboundResponse(response: Response, url: String) {
        
        logger.debug("Network response inbound")
        
        let endTime = NSDate.timeIntervalSinceReferenceDate()
        let roundTripTime = endTime - startTime
        let bytesSent = self.requestBody?.length ?? 0
        
        // Data for analytics logging
        var responseMetadata: [String: AnyObject] = [:]
        
        responseMetadata["$category"] = "network"
        responseMetadata["$path"] = url
        responseMetadata["$trackingId"] = self.trackingId
        responseMetadata["$outboundTimestamp"] = startTime
        responseMetadata["$inboundTimestamp"] = endTime
        responseMetadata["$roundTripTime"] = roundTripTime
        responseMetadata["$responseCode"] = response.statusCode
        responseMetadata["$bytesSent"] = bytesSent
        
        if (response.responseText != nil && !response.responseText!.isEmpty) {
            responseMetadata["$bytesReceived"] = response.responseText?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        }
        logger.analytics(responseMetadata)
    }
    
    
    /**
        Returns the supplied URL with query parameters appended to it; the original URL is not modified.
        Characters in the query parameters that are not URL safe are automatically converted to percent-encoding.
    
        - parameter parameters:  The query parameters to be appended to the end of the url
        - parameter originalURL: The url that the parameters will be appeneded to
    
        - returns: The original URL with the query parameters appended to it
    */
    static func appendQueryParameters(parameters: [String: String], toURL originalUrl: NSURL) -> NSURL? {
        
        if parameters.isEmpty {
            return originalUrl
        }
        
        var parametersInURLFormat = [NSURLQueryItem]()
        for (key, value) in parameters {
            parametersInURLFormat += [NSURLQueryItem(name: key, value: value)]
        }
        
        if let newUrlComponents = NSURLComponents(URL: originalUrl, resolvingAgainstBaseURL: false) {
            if newUrlComponents.queryItems != nil {
                newUrlComponents.queryItems!.appendContentsOf(parametersInURLFormat)
            }
            else {
                newUrlComponents.queryItems = parametersInURLFormat
            }
            return newUrlComponents.URL
        }
        else {
            return nil
        }
    }
    
}
