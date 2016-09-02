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


#if swift(>=3.0)


    
/// Callback for data tasks invoked by BMSURLSession
public typealias BMSDataTaskCompletionHandler = (Data?, URLResponse?, Error?) -> Void
    

public struct BMSURLSession {

    
    private let configuration: URLSessionConfiguration
    
    private let delegate: URLSessionDelegate?
    
    private let delegateQueue: OperationQueue?
    
    private static let logger = Logger.logger(forName: Logger.bmsLoggerPrefix + "urlSession")
    
    
    
    public init(configuration: URLSessionConfiguration = .default,
                delegate: URLSessionDelegate? = nil,
                delegateQueue: OperationQueue? = nil) {
        
        self.configuration = configuration
        self.delegate = delegate
        self.delegateQueue = delegateQueue
    }
    
    
    
    // MARK: Data tasks
    
    public func dataTaskWithURL(_ url: URL) -> URLSessionDataTask {
        
        return dataTaskWithRequest(URLRequest(url: url))
    }
    
    public func dataTaskWithURL(_ url: URL, completionHandler: BMSDataTaskCompletionHandler) -> URLSessionDataTask {
        
        return dataTaskWithRequest(URLRequest(url: url), completionHandler: completionHandler)
    }
    
    public func dataTaskWithRequest(_ request: URLRequest) -> URLSessionDataTask {
        
        let bmsRequest = BMSURLSession.prepare(request: request)
        
        let originalTask = BMSURLSessionTaskType.dataTask
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        let urlSession = URLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let dataTask = urlSession.dataTask(with: bmsRequest)
        
        return dataTask
    }
    
    public func dataTaskWithRequest(_ request: URLRequest, completionHandler: BMSDataTaskCompletionHandler) -> URLSessionDataTask {
        
        let bmsRequest = BMSURLSession.prepare(request: request)
        
        let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let dataTask = urlSession.dataTask(with: bmsRequest, completionHandler: bmsCompletionHandler)
        
        return dataTask
    }
    
    
    
    // MARK: Upload tasks
        
    public func uploadTaskWithRequest(_ request: URLRequest, fromData bodyData: Data) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.prepare(request: request)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithData(bodyData)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        let urlSession = URLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, from: bodyData)
        
        return uploadTask
    }
    
    public func uploadTaskWithRequest(_ request: URLRequest, fromData bodyData: Data?, completionHandler: BMSDataTaskCompletionHandler) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.prepare(request: request)
        
        let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(bodyData, completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, from: bodyData, completionHandler: bmsCompletionHandler)
        
        return uploadTask
    }
    
    public func uploadTaskWithRequest(_ request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.prepare(request: request)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFile(fileURL)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        let urlSession = URLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, fromFile: fileURL)
        
        return uploadTask
    }
    
    public func uploadTaskWithRequest(_ request: URLRequest, fromFile fileURL: URL, completionHandler: BMSDataTaskCompletionHandler) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.prepare(request: request)
        
        let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(fileURL, completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, fromFile: fileURL, completionHandler: bmsCompletionHandler)
        
        return uploadTask
    }
    
    
    
    // MARK: Helpers
    
    // Inject BMSSecurity and BMSAnalytics into the request object by adding headers
    internal static func prepare(request: URLRequest) -> URLRequest {
        
        var bmsRequest = request
        
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
        
        return bmsRequest
    }
    
    internal static func isAuthorizationManagerRequired(for response: URLResponse?) -> Bool {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        
        if let response = response as? HTTPURLResponse,
            let wwwAuthHeader = response.allHeaderFields["WWW-Authenticate"] as? String,
            authManager.isAuthorizationRequired(forStatusCode: response.statusCode, httpResponseAuthorizationHeader: wwwAuthHeader) {
            
            return true
        }
        return false
    }
    
    
    // Handle the challenge with AuthorizationManager from BMSSecurity
    internal static func handleAuthorizationChallenge(session urlSession: URLSession, request: URLRequest, handleFailure: () -> Void, originalTask: BMSURLSessionTaskType) {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        let authCallback: BmsCompletionHandler = {(response: Response?, error:NSError?) in
            
            if error == nil && response?.statusCode >= 200 && response?.statusCode < 300 {
                
                // Resend the original request with the "Authorization" header
                
                var request = request
                
                let authManager = BMSClient.sharedInstance.authorizationManager
                if let authHeader: String = authManager.cachedAuthorizationHeader {
                    request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                }
                
                // Figure out the original URLSessionTask created by the user, and resend it
                switch originalTask {
                    
                case .dataTask:
                    urlSession.dataTask(with: request).resume()
                    
                case .dataTaskWithCompletionHandler(let completionHandler):
                    urlSession.dataTask(with: request, completionHandler: completionHandler).resume()
                    
                case .uploadTaskWithFile(let file):
                    urlSession.uploadTask(with: request, fromFile: file).resume()
                    
                case .uploadTaskWithData(let data):
                    urlSession.uploadTask(with: request, from: data).resume()
                    
                case .uploadTaskWithFileAndCompletionHandler(let file, let completionHandler):
                    urlSession.uploadTask(with: request, fromFile: file, completionHandler: completionHandler).resume()
                    
                case .uploadTaskWithDataAndCompletionHandler(let data, let completionHandler):
                    urlSession.uploadTask(with: request, from: data, completionHandler: completionHandler).resume()
                }
            }
            else {
                BMSURLSession.logger.error(message: "Authorization process failed. \nError: \(error). \nResponse: \(response).")
                handleFailure()
            }
        }
        authManager.obtainAuthorization(completionHandler: authCallback)
    }
    
    
    // Required to hook in challenge handling via AuthorizationManager
    internal static func generateBmsCompletionHandler(from completionHandler: BMSDataTaskCompletionHandler, urlSession: URLSession, request: URLRequest, originalTask: BMSURLSessionTaskType) -> BMSDataTaskCompletionHandler {
        
        return { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if self.isAuthorizationManagerRequired(for: response) {
                
                func callParentCompletionHandler() {
                    completionHandler(data, response, error)
                }
                
                BMSURLSession.handleAuthorizationChallenge(session: urlSession, request: request, handleFailure: callParentCompletionHandler, originalTask: originalTask)
            }
            else {
                completionHandler(data, response, error)
            }
        }
    }
}
    
    
    
// List of the supported types of URLSessionTask
// Stored in BMSURLSession to determine what type of task to use when resending the request after authenticating with MCA
internal enum BMSURLSessionTaskType {
    
    case dataTask
    case dataTaskWithCompletionHandler(BMSDataTaskCompletionHandler)
    
    case uploadTaskWithFile(URL)
    case uploadTaskWithData(Data)
    case uploadTaskWithFileAndCompletionHandler(URL, BMSDataTaskCompletionHandler)
    case uploadTaskWithDataAndCompletionHandler(Data?, BMSDataTaskCompletionHandler)
}

    

#else

    
    
// Callback for data tasks invoked by BMSURLSession
public typealias BMSDataTaskCompletionHandler = (NSData?, NSURLResponse?, NSError?) -> Void


public struct BMSURLSession {
    
    
    private let configuration: NSURLSessionConfiguration
    
    private let delegate: NSURLSessionDelegate?
    
    private let delegateQueue: NSOperationQueue?
    
    private static let logger = Logger.logger(forName: Logger.bmsLoggerPrefix + "urlSession")
    
    
    
    public init(configuration: NSURLSessionConfiguration = .defaultSessionConfiguration(),
                delegate: NSURLSessionDelegate? = nil,
                delegateQueue: NSOperationQueue? = nil) {
        
        self.configuration = configuration
        self.delegate = delegate
        self.delegateQueue = delegateQueue
    }
    
    
    
    // MARK: Data tasks
    
    public func dataTaskWithURL(url: NSURL) -> NSURLSessionDataTask {
        
        return dataTaskWithRequest(NSURLRequest(URL: url))
    }
    
    public func dataTaskWithURL(url: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask {
        
        return dataTaskWithRequest(NSURLRequest(URL: url), completionHandler: completionHandler)
    }
    
    public func dataTaskWithRequest(request: NSURLRequest) -> NSURLSessionDataTask {
        
        let bmsRequest = BMSURLSession.prepareRequest(request)
        
        let originalTask = BMSURLSessionTaskType.dataTask
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let dataTask = urlSession.dataTaskWithRequest(bmsRequest)
        
        return dataTask
    }
    
    public func dataTaskWithRequest(request: NSURLRequest, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask {
        
        let bmsRequest = BMSURLSession.prepareRequest(request)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let dataTask = urlSession.dataTaskWithRequest(bmsRequest, completionHandler: bmsCompletionHandler)
        
        return dataTask
    }
    
    
    
    // MARK: Upload tasks
    
    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.prepareRequest(request)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithData(bodyData)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromData: bodyData)
        
        return uploadTask
    }
    
    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData?, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.prepareRequest(request)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(bodyData, completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromData: bodyData, completionHandler: bmsCompletionHandler)
        
        return uploadTask
    }
    
    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.prepareRequest(request)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFile(fileURL)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromFile: fileURL)
        
        return uploadTask
    }
    
    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.prepareRequest(request)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(fileURL, completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromFile: fileURL, completionHandler: bmsCompletionHandler)
        
        return uploadTask
    }
    
    
    
    // MARK: Helpers
    
    // Inject BMSSecurity and BMSAnalytics into the request object by adding headers
    internal static func prepareRequest(request: NSURLRequest) -> NSURLRequest {
        
        let bmsRequest = request.mutableCopy() as! NSMutableURLRequest
        
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
        
        return bmsRequest
    }
    
    internal static func isAuthorizationManagerRequired(response: NSURLResponse?) -> Bool {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        
        if let response = response as? NSHTTPURLResponse,
            let wwwAuthHeader = response.allHeaderFields["WWW-Authenticate"] as? String
            where authManager.isAuthorizationRequired(forStatusCode: response.statusCode, httpResponseAuthorizationHeader: wwwAuthHeader) {
            
            return true
        }
        return false
    }
    
    
    // Handle the challenge with AuthorizationManager from BMSSecurity
    internal static func handleAuthorizationChallenge(urlSession: NSURLSession, request: NSMutableURLRequest, handleFailure: () -> Void, originalTask: BMSURLSessionTaskType) {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        let authCallback: BmsCompletionHandler = {(response: Response?, error:NSError?) in
            
            if error == nil && response?.statusCode >= 200 && response?.statusCode < 300 {
                
                // Resend the original request with the "Authorization" header
                
                let authManager = BMSClient.sharedInstance.authorizationManager
                if let authHeader: String = authManager.cachedAuthorizationHeader {
                    request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                }
                
                // Figure out the original NSURLSessionTask created by the user, and resend it
                switch originalTask {
                    
                case .dataTask:
                    urlSession.dataTaskWithRequest(request).resume()
                    
                case .dataTaskWithCompletionHandler(let completionHandler):
                    urlSession.dataTaskWithRequest(request, completionHandler: completionHandler).resume()
                    
                case .uploadTaskWithFile(let file):
                    urlSession.uploadTaskWithRequest(request, fromFile: file).resume()
                    
                case .uploadTaskWithData(let data):
                    urlSession.uploadTaskWithRequest(request, fromData: data).resume()
                    
                case .uploadTaskWithFileAndCompletionHandler(let file, let completionHandler):
                    urlSession.uploadTaskWithRequest(request, fromFile: file, completionHandler: completionHandler).resume()
                    
                case .uploadTaskWithDataAndCompletionHandler(let data, let completionHandler):
                    urlSession.uploadTaskWithRequest(request, fromData: data, completionHandler: completionHandler).resume()
                }
            }
            else {
                BMSURLSession.logger.error("Authorization process failed. \nError: \(error). \nResponse: \(response).")
                handleFailure()
            }
        }
        authManager.obtainAuthorization(completionHandler: authCallback)
    }
    
    
    // Required to hook in challenge handling via AuthorizationManager
    internal static func generateBmsCompletionHandler(from completionHandler: BMSDataTaskCompletionHandler, urlSession: NSURLSession, request: NSURLRequest, originalTask: BMSURLSessionTaskType) -> BMSDataTaskCompletionHandler {
        
        return { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if self.isAuthorizationManagerRequired(response) {
                
                func callParentCompletionHandler() {
                    completionHandler(data, response, error)
                }
                
                let originalRequest = request.mutableCopy() as! NSMutableURLRequest
                BMSURLSession.handleAuthorizationChallenge(urlSession, request: originalRequest, handleFailure: callParentCompletionHandler, originalTask: originalTask)
            }
            else {
                completionHandler(data, response, error)
            }
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