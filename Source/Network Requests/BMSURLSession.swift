/*
*     Copyright 2016 IBM Corp.
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


import BMSAnalyticsAPI

// MARK: - Swift 3

#if swift(>=3.0)


    
/// Callback for data tasks created with `BMSURLSession`.
public typealias BMSDataTaskCompletionHandler = (Data?, URLResponse?, Error?) -> Void


    
/**
    A wrapper around Swift's [URLSession](https://developer.apple.com/reference/foundation/urlsession) API that incorporates
    Bluemix Mobile Services. Use `BMSURLSession` to gather [Mobile Analytics](https://console.ng.bluemix.net/docs/services/mobileanalytics/mobileanalytics_overview.html) data on your network requests
    and/or to access backends that are protected by [Mobile Client Access](https://console.ng.bluemix.net/docs/services/mobileaccess/overview.html).

    Currently, `BMSURLSession` only supports [URLSessionDataTask](https://developer.apple.com/reference/foundation/urlsessiondatatask) and [URLSessionUploadTask](https://developer.apple.com/reference/foundation/urlsessionuploadtask).
*/
public struct BMSURLSession: NetworkSession {

    
    // Determines whether metadata gets recorded for all BMSURLSession network requests
    // Should only be set to true by passing DeviceEvent.network in the Analytics.initialize() method in the BMSAnalytics framework
    public static var shouldRecordNetworkMetadata: Bool = false
    
    // Should only be set to true by the BMSSecurity framework when creating a BMSURLSession request for authenticating with the MCA authorization server
    public var isBMSAuthorizationRequest: Bool = false
    
    
    // User-specified URLSession configuration
    internal let configuration: URLSessionConfiguration
    
    // User-specified URLSession delegate
    internal let delegate: URLSessionDelegate?
    
    // User-specified URLSession delegate queue
    internal let delegateQueue: OperationQueue?
    
    
    // The number of times a failed request should be retried, specified by the user
    internal let numberOfRetries: Int
    
    // Internal logger for BMSURLSession activity
    private static let logger = Logger.logger(name: Logger.bmsLoggerPrefix + "urlSession")
    
    
    
    /**
        Creates a network session similar to `URLSession`.

        - parameter configuration:  Defines the behavior of the session.
        - parameter delegate:       Handles session-related events. If nil, use task methods that take completion handlers.
        - parameter delegateQueue:  Queue for scheduling the delegate calls and completion handlers.
        - parameter autoRetries:    The number of times to retry each request if it fails to send (due to network issues, for example).
    */
    public init(configuration: URLSessionConfiguration = .default,
                delegate: URLSessionDelegate? = nil,
                delegateQueue: OperationQueue? = nil,
                autoRetries: Int = 0) {
        
        self.configuration = configuration
        self.delegate = delegate
        self.delegateQueue = delegateQueue
        self.numberOfRetries = autoRetries
    }
    
    
    
    // MARK: - Data tasks
    
    /**
        Creates a task that retrieves the contents of the specified URL.
     
        To start the task, you must call its `resume()` method.

        - parameter url:  The URL to retrieve data from.
     
        - returns: A data task.
    */
    public func dataTask(with url: URL) -> URLSessionDataTask {
        
        return dataTask(with: URLRequest(url: url))
    }
    
    
    /**
        Creates a task that retrieves the contents of the specified URL, and passes the response to the completion handler.

        To start the task, you must call its `resume()` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter url:                The URL to retrieve data from.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: A data task.
    */
    public func dataTask(with url: URL, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionDataTask {
        
        return dataTask(with: URLRequest(url: url), completionHandler: completionHandler)
    }
    
    
    /**
        Creates a task that retrieves the contents of a URL based on the specified request object.

        To start the task, you must call its `resume()` method.

        - parameter request:  An object that provides request-specific information
                              such as the URL, cache policy, request type, and body data.
     
        - returns: A data task.
    */
    public func dataTask(with request: URLRequest) -> URLSessionDataTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let originalTask = BMSURLSessionTaskType.dataTask
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, bmsUrlSession: self, originalTask: originalTask, numberOfRetries: numberOfRetries)
        let urlSession = URLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let dataTask = urlSession.dataTask(with: bmsRequest)
        return dataTask
    }
    
    
    /**
        Creates a task that retrieves the contents of a URL based on the specified request object,
        and passes the response to the completion handler.

        To start the task, you must call its `resume()` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL, cache policy, request type, and body data.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: A data task.
    */
    public func dataTask(with request: URLRequest, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionDataTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, bmsUrlSession: self, urlSession: urlSession, request: bmsRequest, originalTask: originalTask, requestBody: nil, numberOfRetries: numberOfRetries)
        
        let dataTask = urlSession.dataTask(with: bmsRequest, completionHandler: bmsCompletionHandler)
        return dataTask
    }
    
    
    
    // MARK: - Upload tasks
    
    /**
        Creates a task that uploads data to the URL specified in the request object.

        To start the task, you must call its `resume()` method.

        - parameter request:   An object that provides request-specific information
                               such as the URL and cache policy. The request body is ignored.
        - parameter bodyData:  The body data for the request.
     
        - returns: An upload task.
    */
    public func uploadTask(with request: URLRequest, from bodyData: Data) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithData(bodyData)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, bmsUrlSession: self, originalTask: originalTask, numberOfRetries: numberOfRetries)
        let urlSession = URLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, from: bodyData)
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads data to the URL specified in the request object.

        To start the task, you must call its `resume()` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL and cache policy. The request body is ignored.
        - parameter bodyData:           The body data for the request.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: An upload task.
    */
    public func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(bodyData, completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, bmsUrlSession: self, urlSession: urlSession, request: bmsRequest, originalTask: originalTask, requestBody: bodyData, numberOfRetries: numberOfRetries)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, from: bodyData, completionHandler: bmsCompletionHandler)
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads a file to the URL specified in the request object.

        To start the task, you must call its `resume()` method.

        - parameter request:  An object that provides request-specific information
                              such as the URL and cache policy. The request body is ignored.
        - parameter fileURL:  The location of the file to upload.
     
        - returns: An upload task.
    */
    public func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFile(fileURL)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, bmsUrlSession: self, originalTask: originalTask, numberOfRetries: numberOfRetries)
        let urlSession = URLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, fromFile: fileURL)
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads a file to the URL specified in the request object.

        To start the task, you must call its `resume()` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL and cache policy. The request body is ignored.
        - parameter fileURL:            The location of the file to upload.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: An upload task.
    */
    public func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionUploadTask {
        
        var fileContents: Data? = nil
        do {
            fileContents = try Data(contentsOf: fileURL)
        }
        catch(let error) {
            BMSURLSession.logger.warn(message: "Cannot retrieve the contents of the file \(fileURL.absoluteString). Error: \(error)")
        }
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(fileURL, completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, bmsUrlSession: self, urlSession: urlSession, request: bmsRequest, originalTask: originalTask, requestBody: fileContents, numberOfRetries: numberOfRetries)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, fromFile: fileURL, completionHandler: bmsCompletionHandler)
        return uploadTask
    }
    
    
    
    // MARK: - Helpers
    
    // Inject BMSSecurity and BMSAnalytics into the request object by adding headers
    internal static func addBMSHeaders(to request: URLRequest, onlyIf precondition: Bool) -> URLRequest {
        
        var bmsRequest = request
    
        // If the request is in the process of authentication with the MCA authorization server, do not attempt to add headers, since this is an intermediary request.
        if precondition {
            
            // Security
            let authManager = BMSClient.sharedInstance.authorizationManager
            if let authHeader: String = authManager.cachedAuthorizationHeader {
                bmsRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
            }
            
            // Analytics
            bmsRequest.setValue(UUID().uuidString, forHTTPHeaderField: "x-wl-analytics-tracking-id")
            if let requestMetadata = BaseRequest.requestAnalyticsData {
                bmsRequest.setValue(requestMetadata, forHTTPHeaderField: "x-mfp-analytics-metadata")
            }
        }
        
        return bmsRequest
    }
    
    
    // Required to hook in challenge handling via AuthorizationManager
    internal static func generateBmsCompletionHandler(from completionHandler: @escaping BMSDataTaskCompletionHandler, bmsUrlSession: BMSURLSession, urlSession: URLSession, request: URLRequest, originalTask: BMSURLSessionTaskType, requestBody: Data?, numberOfRetries: Int) -> BMSDataTaskCompletionHandler {
        
        let trackingId = UUID().uuidString
        let startTime = Int64(Date.timeIntervalSinceReferenceDate * 1000) // milliseconds
        var requestMetadata = RequestMetadata(url: request.url, startTime: startTime, trackingId: trackingId)

        return { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if shouldRetryRequest(response: response, error: error, numberOfRetries: numberOfRetries) {
                
                retryRequest(originalRequest: request, originalTask: originalTask, bmsUrlSession: bmsUrlSession)
            }
            else if BMSURLSession.isAuthorizationManagerRequired(for: response) {
                
                // If authentication is successful, resend the original request with the "Authorization" header added
                BMSURLSession.handleAuthorizationChallenge(session: urlSession, request: request, requestMetadata: requestMetadata, originalTask: originalTask, handleFailure: {
                        completionHandler(data, response, error)
                })
            }
            // Don't log the request metadata if the response is a redirect
            else if let response = response as? HTTPURLResponse, response.statusCode >= 300 && response.statusCode < 400 {
                
                completionHandler(data, response, error)
            }
            // Only log the request metadata if a response was received so that we have all of the required data for logging
            else if response != nil {
                
                if BMSURLSession.shouldRecordNetworkMetadata {
    
                    requestMetadata.response = response
                    requestMetadata.bytesReceived = Int64(data?.count ?? 0)
                    requestMetadata.bytesSent = Int64(requestBody?.count ?? 0)
                    requestMetadata.endTime = Int64(Date.timeIntervalSinceReferenceDate * 1000) // milliseconds
        
                    requestMetadata.recordMetadata()
                }
                
                completionHandler(data, response, error)
            }
            else {
                completionHandler(data, response, error)
            }
        }
    }
    
    
    // Determines whether auto-retry is appropriate given the conditions of the request failure.
    internal static func shouldRetryRequest(response: URLResponse?, error: Error?, numberOfRetries: Int) -> Bool {
        
        // Make sure auto-retries are even allowed
        guard numberOfRetries > 0 else {
            return false
        }
        
        // Client-side issues eligible for retries
        let errorCodesForRetries: [Int] = [NSURLErrorTimedOut, NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost]
        if let error = error as? NSError,
            errorCodesForRetries.contains(error.code) {
            
            // If the device is running iOS, we should make sure that it has a network connection before resending the request
            #if os(iOS)
                let networkDetector = NetworkDetection()
                if networkDetector?.currentNetworkConnection != NetworkConnection.noConnection {
                    return true
                }
                else {
                    BMSURLSession.logger.error(message: "Cannot retry the last BMSURLSession request because the device has no internet connection.")
                }
            #else
                return true
            #endif
        }
        
        // Server-side issues eligible for retries
        if let response = response as? HTTPURLResponse,
            response.statusCode == 504 {
            
            return true
        }
        
        return false
    }
    
    
    // Send the request again
    // For auto-retries
    internal static func retryRequest(originalRequest: URLRequest, originalTask: BMSURLSessionTaskType, bmsUrlSession: BMSURLSession) {
        
        // Duplicate the original BMSURLSession, but with 1 fewer retry available
        let newBmsUrlSession = BMSURLSession(configuration: bmsUrlSession.configuration, delegate: bmsUrlSession.delegate, delegateQueue: bmsUrlSession.delegateQueue, autoRetries: bmsUrlSession.numberOfRetries - 1)
        originalTask.prepareForResending(urlSession: newBmsUrlSession, request: originalRequest).resume()
    }
    
    
    // Determines if the response is an authentication challenge from an MCA-protected server
    // If true, we must use BMSSecurity to authenticate
    internal static func isAuthorizationManagerRequired(for response: URLResponse?) -> Bool {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        
        if let response = response as? HTTPURLResponse,
            let wwwAuthHeader = response.allHeaderFields["Www-Authenticate"] as? String,
            authManager.isAuthorizationRequired(for: response.statusCode, httpResponseAuthorizationHeader: wwwAuthHeader) {
            
            return true
        }
        return false
    }
    
    
    // First, obtain authorization with AuthorizationManager from BMSSecurity.
    // If authentication is successful, a new URLSessionTask is generated.
    // This new task is the same as the original task, but now with the "Authorization" header needed to complete the request successfully.
    internal static func handleAuthorizationChallenge(session urlSession: URLSession, request: URLRequest, requestMetadata: RequestMetadata, originalTask: BMSURLSessionTaskType, handleFailure: @escaping () -> Void) {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        let authCallback: BMSCompletionHandler = {(response: Response?, error:Error?) in
            
            if error == nil && response?.statusCode != nil && (response?.statusCode)! >= 200 && (response?.statusCode)! < 300 {
                
                var request = request
                
                let authManager = BMSClient.sharedInstance.authorizationManager
                if let authHeader: String = authManager.cachedAuthorizationHeader {
                    request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                }
                
                originalTask.prepareForResending(urlSession: urlSession, request: request, requestMetadata: requestMetadata).resume()
            }
            else {
                BMSURLSession.logger.error(message: "Authorization process failed. \nError: \(error). \nResponse: \(response).")
                handleFailure()
            }
        }
        authManager.obtainAuthorization(completionHandler: authCallback)
    }
    
    
    internal static func recordMetadataCompletionHandler(request: URLRequest, requestMetadata: RequestMetadata, originalCompletionHandler: @escaping BMSDataTaskCompletionHandler) -> BMSDataTaskCompletionHandler {
        
        var requestMetadata = requestMetadata
        
        let newCompletionHandler = {(data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if BMSURLSession.shouldRecordNetworkMetadata {
                
                requestMetadata.bytesReceived = Int64(data?.count ?? 0)
                requestMetadata.bytesSent = Int64(request.httpBody?.count ?? 0)
                requestMetadata.endTime = Int64(Date.timeIntervalSinceReferenceDate * 1000) // milliseconds
                
                requestMetadata.recordMetadata()
            }
            
            originalCompletionHandler(data, response, error)
        }
        
        return newCompletionHandler
    }

}
    
    
    
// List of the supported types of URLSessionTask
// Stored in BMSURLSession to determine what type of task to use if the request needs to be resent
// Used for:
    // AuthorizationManager - After successfully authenticating with MCA, the original request must be resent with the newly-obtained authorization header.
    // Auto-retries - If the original request failed due to network issues, the request can be sent again for a number of attempts specified by the user
internal enum BMSURLSessionTaskType {
    
    case dataTask
    case dataTaskWithCompletionHandler(BMSDataTaskCompletionHandler)
    
    case uploadTaskWithFile(URL)
    case uploadTaskWithData(Data)
    case uploadTaskWithFileAndCompletionHandler(URL, BMSDataTaskCompletionHandler)
    case uploadTaskWithDataAndCompletionHandler(Data?, BMSDataTaskCompletionHandler)
    
    
    // Recreate the URLSessionTask from the original request to later resend it
    func prepareForResending(urlSession: NetworkSession, request: URLRequest, requestMetadata: RequestMetadata? = nil) -> URLSessionTask {
        
        // If this request is considered a continuation of the original request, then we record metadata from the original request instead of creating a new set of metadata (i.e. for MCA authorization requests). Otherwise, return the original completion handler (i.e. for auto-retries).
        // This is not required for delegates since this is already taken care of in BMSURLSessionDelegate
        func createNewCompletionHandler(originalCompletionHandler: @escaping BMSDataTaskCompletionHandler) -> BMSDataTaskCompletionHandler {
            
            var completionHandler = originalCompletionHandler
            if let requestMetadata = requestMetadata {
                completionHandler = BMSURLSession.recordMetadataCompletionHandler(request: request, requestMetadata: requestMetadata, originalCompletionHandler: completionHandler)
            }
            return completionHandler
        }
        
        switch self {
        
        case .dataTask:
            return urlSession.dataTask(with: request)
            
        case .dataTaskWithCompletionHandler(let completionHandler):
            let newCompletionHandler = createNewCompletionHandler(originalCompletionHandler: completionHandler)
            return urlSession.dataTask(with: request, completionHandler: newCompletionHandler)
            
        case .uploadTaskWithFile(let file):
            return urlSession.uploadTask(with: request, fromFile: file)
            
        case .uploadTaskWithData(let data):
            return urlSession.uploadTask(with: request, from: data)
            
        case .uploadTaskWithFileAndCompletionHandler(let file, let completionHandler):
            let newCompletionHandler = createNewCompletionHandler(originalCompletionHandler: completionHandler)
            return urlSession.uploadTask(with: request, fromFile: file, completionHandler: newCompletionHandler)
            
        case .uploadTaskWithDataAndCompletionHandler(let data, let completionHandler):
            let newCompletionHandler = createNewCompletionHandler(originalCompletionHandler: completionHandler)
            return urlSession.uploadTask(with: request, from: data, completionHandler: newCompletionHandler)
        }
    }
}

    

// Needed to use BMSURLSession and URLSession interchangeably
internal protocol NetworkSession {
    
    func dataTask(with url: URL) -> URLSessionDataTask
    func dataTask(with url: URL, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionDataTask
    func dataTask(with request: URLRequest) -> URLSessionDataTask
    func dataTask(with request: URLRequest, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionDataTask
    
    func uploadTask(with request: URLRequest, from bodyData: Data) -> URLSessionUploadTask
    func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionUploadTask
    func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask
    func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionUploadTask
}

extension URLSession: NetworkSession { }
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    
   
// MARK: BMSURLSession (Swift 2)
    
/// Callback for data tasks created with `BMSURLSession`.
public typealias BMSDataTaskCompletionHandler = (NSData?, NSURLResponse?, NSError?) -> Void


/**
    A wrapper around Swift's `NSURLSession` API that incorporates
    Bluemix Mobile Services. Use this API to gather analytics data on your network requests
    and/or to access backends that are protected by Mobile Client Access.

    Currently, `BMSURLSession` only supports `NSURLSessionDataTask` and `NSURLSessionUploadTask`.

    For more information, refer to the documentation for `NSURLSession` in the Swift Foundation framework.
*/
public struct BMSURLSession {
    
    
    // Determines whether metadata gets recorded for all BMSURLSession network requests
    // Should only be set to true by passing DeviceEvent.network in the Analytics.initialize() method in the BMSAnalytics framework
    public static var shouldRecordNetworkMetadata: Bool = false
    
    // Should only be set to true by the BMSSecurity framework when creating a BMSURLSession request for authenticating with the MCA authorization server
    public var isBMSAuthorizationRequest: Bool = false
    
    private let configuration: NSURLSessionConfiguration
    
    private let delegate: NSURLSessionDelegate?
    
    private let delegateQueue: NSOperationQueue?
    
    private static let logger = Logger.logger(name: Logger.bmsLoggerPrefix + "urlSession")
    
    
    
    /**
        Creates a network session similar to `NSURLSession`.
     
        - parameter configuration:  Defines the behavior of the session.
        - parameter delegate:       Handles session-related events. If nil, use task methods that take completion handlers.
        - parameter delegateQueue:  Queue for scheduling the delegate calls and completion handlers.
    */
    public init(configuration: NSURLSessionConfiguration = .defaultSessionConfiguration(),
                delegate: NSURLSessionDelegate? = nil,
                delegateQueue: NSOperationQueue? = nil) {
        
        self.configuration = configuration
        self.delegate = delegate
        self.delegateQueue = delegateQueue
    }
    
    
    
    // MARK: - Data tasks
    
    /**
        Creates a task that retrieves the contents of the specified URL.
     
        To start the task, you must call its `resume()` method.
     
        - parameter url:  The URL to retrieve data from.
     
        - returns: A data task.
    */
    public func dataTaskWithURL(url: NSURL) -> NSURLSessionDataTask {
        
        return dataTaskWithRequest(NSURLRequest(URL: url))
    }
    
    
    /**
        Creates a task that retrieves the contents of the specified URL, and passes the response to the completion handler.
     
        To start the task, you must call its `resume()` method.
     
        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.
     
        - parameter url:                The URL to retrieve data from.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: A data task.
    */
    public func dataTaskWithURL(url: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask {
        
        return dataTaskWithRequest(NSURLRequest(URL: url), completionHandler: completionHandler)
    }
    
    
    /**
        Creates a task that retrieves the contents of a URL based on the specified request object.
     
        To start the task, you must call its `resume()` method.
     
        - parameter request:  An object that provides request-specific information
                              such as the URL, cache policy, request type, and body data.
     
        - returns: A data task.
    */
    public func dataTaskWithRequest(request: NSURLRequest) -> NSURLSessionDataTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let originalTask = BMSURLSessionTaskType.dataTask
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let dataTask = urlSession.dataTaskWithRequest(bmsRequest)
        return dataTask
    }
    
    
    /**
        Creates a task that retrieves the contents of a URL based on the specified request object, 
        and passes the response to the completion handler.
     
        To start the task, you must call its `resume()` method.
     
        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.
     
        - parameter request:            An object that provides request-specific information
                                        such as the URL, cache policy, request type, and body data.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: A data task.
    */
    public func dataTaskWithRequest(request: NSURLRequest, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask, requestBody: nil)
        
        let dataTask = urlSession.dataTaskWithRequest(bmsRequest, completionHandler: bmsCompletionHandler)
        return dataTask
    }
    
    
    
    // MARK: - Upload tasks
    
    /**
        Creates a task that uploads data to the URL specified in the request object.
     
        To start the task, you must call its `resume()` method.

        - parameter request:   An object that provides request-specific information
                               such as the URL and cache policy. The request body is ignored.
        - parameter bodyData:  The body data for the request.
     
        - returns: An upload task.
    */
    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithData(bodyData)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromData: bodyData)
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads data to the URL specified in the request object.

        To start the task, you must call its `resume()` method.
     
        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL and cache policy. The request body is ignored.
        - parameter bodyData:           The body data for the request.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: An upload task.
    */
    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData?, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(bodyData, completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask, requestBody: bodyData)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromData: bodyData, completionHandler: bmsCompletionHandler)
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads a file to the URL specified in the request object.

        To start the task, you must call its `resume()` method.

        - parameter request:  An object that provides request-specific information
                              such as the URL and cache policy. The request body is ignored.
        - parameter fileURL:  The location of the file to upload.
     
        - returns: An upload task.
    */
    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFile(fileURL)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromFile: fileURL)
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads a file to the URL specified in the request object.

        To start the task, you must call its `resume()` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
        The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL and cache policy. The request body is ignored.
        - parameter fileURL:            The location of the file to upload.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: An upload task.
    */
    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask {
        
        let fileContents = NSData(contentsOfURL: fileURL)
        if fileContents == nil {
            BMSURLSession.logger.warn(message: "Cannot retrieve the contents of the file \(fileURL.absoluteString).")
        }
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(fileURL, completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask, requestBody: fileContents)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromFile: fileURL, completionHandler: bmsCompletionHandler)
        return uploadTask
    }
    
    
    
    // MARK: - Helpers
    
    // Inject BMSSecurity and BMSAnalytics into the request object by adding headers
    internal static func addBMSHeaders(to request: NSURLRequest, onlyIf precondition: Bool) -> NSURLRequest {
        
        let bmsRequest = request.mutableCopy() as! NSMutableURLRequest
        
        // If the request is in the process of authentication with the MCA authorization server, do not attempt to add headers, since this is an intermediary request.
        if precondition {
            
            // Security
            let authManager = BMSClient.sharedInstance.authorizationManager
            if let authHeader: String = authManager.cachedAuthorizationHeader {
                bmsRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
            }
            
            // Analytics
            bmsRequest.setValue(NSUUID().UUIDString, forHTTPHeaderField: "x-wl-analytics-tracking-id")
            if let requestMetadata = BaseRequest.requestAnalyticsData {
                bmsRequest.setValue(requestMetadata, forHTTPHeaderField: "x-mfp-analytics-metadata")
            }
        }
        
        return bmsRequest
    }
    
    
    // Required to hook in challenge handling via AuthorizationManager
    internal static func generateBmsCompletionHandler(from completionHandler: BMSDataTaskCompletionHandler, urlSession: NSURLSession, request: NSURLRequest, originalTask: BMSURLSessionTaskType, requestBody: NSData?) -> BMSDataTaskCompletionHandler {
        
        let trackingId = NSUUID().UUIDString
        let startTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
        var requestMetadata = RequestMetadata(url: request.URL, startTime: startTime, trackingId: trackingId)
        
        return { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if BMSURLSession.isAuthorizationManagerRequired(response) {
                
                // Resend the original request with the "Authorization" header added
                let originalRequest = request.mutableCopy() as! NSMutableURLRequest
                BMSURLSession.handleAuthorizationChallenge(session: urlSession, request: originalRequest, requestMetadata: requestMetadata, originalTask: originalTask, handleTask: { (urlSessionTask) in
                    
                    if let taskWithAuthorization = urlSessionTask {
                        taskWithAuthorization.resume()
                    }
                    else {
                        completionHandler(data, response, error)
                    }
                })
            }
            // Don't log the request metadata if the response is a redirect
            else if let response = response as? NSHTTPURLResponse where response.statusCode >= 300 && response.statusCode < 400 {
                
                completionHandler(data, response, error)
            }
            else {
    
                if BMSURLSession.shouldRecordNetworkMetadata {
    
                    requestMetadata.response = response
                    requestMetadata.bytesReceived = Int64(data?.length ?? 0)
                    requestMetadata.bytesSent = Int64(requestBody?.length ?? 0)
                    requestMetadata.endTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
                    
                    requestMetadata.recordMetadata()
                }
    
                completionHandler(data, response, error)
            }
        }
    }
    
    
    internal static func isAuthorizationManagerRequired(response: NSURLResponse?) -> Bool {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        
        if let response = response as? NSHTTPURLResponse,
            let wwwAuthHeader = response.allHeaderFields["WWW-Authenticate"] as? String
            where authManager.isAuthorizationRequired(for: response.statusCode, httpResponseAuthorizationHeader: wwwAuthHeader) {
            
            return true
        }
        return false
    }
    
    
    // First, obtain authorization with AuthorizationManager from BMSSecurity.
    // If authentication is successful, a new URLSessionTask is generated.
    // This new task is the same as the original task, but now with the "Authorization" header needed to complete the request successfully.
    internal static func handleAuthorizationChallenge(session urlSession: NSURLSession, request: NSMutableURLRequest, requestMetadata: RequestMetadata, originalTask: BMSURLSessionTaskType, handleTask: (NSURLSessionTask?) -> Void) {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        let authCallback: BMSCompletionHandler = {(response: Response?, error:NSError?) in
            
            if error == nil && response?.statusCode != nil && (response?.statusCode)! >= 200 && (response?.statusCode)! < 300 {
                BMSURLSession.resendOriginalRequest(urlSession: urlSession, request: request, requestMetadata: requestMetadata, originalTask: originalTask, handleTask: handleTask)
            }
            else {
                BMSURLSession.logger.error(message: "Authorization process failed. \nError: \(error). \nResponse: \(response).")
                handleTask(nil)
            }
        }
        authManager.obtainAuthorization(completionHandler: authCallback)
    }
    
    
    // Resend the original request with the "Authorization" header
    // For completion handlers, also record request metadata (for delegates, this is already taken care of in BMSURLSessionDelegate)
    internal static func resendOriginalRequest(urlSession urlSession: NSURLSession, request: NSMutableURLRequest, requestMetadata: RequestMetadata, originalTask: BMSURLSessionTaskType, handleTask: (NSURLSessionTask?) -> Void) {
        
        var request = request
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        if let authHeader: String = authManager.cachedAuthorizationHeader {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        // Gather network metadata for logging (only used with completion handlers, not delegates)
        func completionHandlerWithMetadata(requestMetadata: RequestMetadata, originalCompletionHandler: BMSDataTaskCompletionHandler) -> BMSDataTaskCompletionHandler {
            
            var requestMetadata = requestMetadata
            
            let newCompletionHandler = {(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
    
                if BMSURLSession.shouldRecordNetworkMetadata {
    
                    requestMetadata.bytesReceived = Int64(data?.length ?? 0)
                    requestMetadata.bytesSent = Int64(request.HTTPBody?.length ?? 0)
                    requestMetadata.endTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
                    
                    requestMetadata.recordMetadata()
                }
    
                originalCompletionHandler(data, response, error)
            }
            
            return newCompletionHandler
        }
        
        // Figure out the original URLSessionTask created by the user, and pass it back to the completionHandler
        switch originalTask {
            
        case .dataTask:
            handleTask(urlSession.dataTaskWithRequest(request))
            
        case .dataTaskWithCompletionHandler(let completionHandler):
            let metadataCompletionHandler = completionHandlerWithMetadata(requestMetadata, originalCompletionHandler: completionHandler)
           handleTask(urlSession.dataTaskWithRequest(request, completionHandler: metadataCompletionHandler))
            
        case .uploadTaskWithFile(let file):
            handleTask(urlSession.uploadTaskWithRequest(request, fromFile: file))
            
        case .uploadTaskWithData(let data):
            handleTask(urlSession.uploadTaskWithRequest(request, fromData: data))
            
        case .uploadTaskWithFileAndCompletionHandler(let file, let completionHandler):
            let metadataCompletionHandler = completionHandlerWithMetadata(requestMetadata, originalCompletionHandler: completionHandler)
            handleTask(urlSession.uploadTaskWithRequest(request, fromFile: file, completionHandler: metadataCompletionHandler))
            
        case .uploadTaskWithDataAndCompletionHandler(let data, let completionHandler):
            let metadataCompletionHandler = completionHandlerWithMetadata(requestMetadata, originalCompletionHandler: completionHandler)
            handleTask(urlSession.uploadTaskWithRequest(request, fromData: data, completionHandler: metadataCompletionHandler))
        }
    }
}
    
    
    
// List of the supported types of NSURLSessionTask
// Stored in BMSURLSession to determine what type of task to use when resending the request after authenticating with MCA
internal enum BMSURLSessionTaskType {
    
    case dataTask
    case dataTaskWithCompletionHandler(BMSDataTaskCompletionHandler)
    
    case uploadTaskWithFile(NSURL)
    case uploadTaskWithData(NSData)
    case uploadTaskWithFileAndCompletionHandler(NSURL, BMSDataTaskCompletionHandler)
    case uploadTaskWithDataAndCompletionHandler(NSData?, BMSDataTaskCompletionHandler)
}

    
    
#endif
