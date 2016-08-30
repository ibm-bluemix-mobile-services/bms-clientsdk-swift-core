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


/// Callback for data tasks invoked by BmsUrlSession
public typealias BMSDataTaskCompletionHandler = (NSData?, NSURLResponse?, NSError?) -> Void



public struct BMSUrlSession {

    
    internal let configuration: NSURLSessionConfiguration
    
    internal let delegate: NSURLSessionDelegate?
    
    internal let delegateQueue: NSOperationQueue?
    
    static let logger = Logger.logger(forName: Logger.bmsLoggerPrefix + "urlSession")
    
    
    
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
        
        let bmsRequest = BMSUrlSession.prepareRequest(request)
        
        let originalTask = BMSUrlSessionTaskType.dataTask
        let parentDelegate = BMSUrlSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let dataTask = urlSession.dataTaskWithRequest(bmsRequest)
        
        return dataTask
    }
    
    public func dataTaskWithRequest(request: NSURLRequest, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask {
        
        let bmsRequest = BMSUrlSession.prepareRequest(request)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSUrlSessionTaskType.dataTaskWithCompletionHandler(completionHandler)
        let bmsCompletionHandler = BMSUrlSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let dataTask = urlSession.dataTaskWithRequest(bmsRequest, completionHandler: bmsCompletionHandler)
        
        return dataTask
    }
    
    
    
    // MARK: Upload tasks
        
    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSUrlSession.prepareRequest(request)
        
        let originalTask = BMSUrlSessionTaskType.uploadTaskWithData(bodyData)
        let parentDelegate = BMSUrlSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromData: bodyData)
        
        return uploadTask
    }
    
    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData?, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSUrlSession.prepareRequest(request)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSUrlSessionTaskType.uploadTaskWithDataAndCompletionHandler(bodyData, completionHandler)
        let bmsCompletionHandler = BMSUrlSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromData: bodyData, completionHandler: bmsCompletionHandler)
        
        return uploadTask
    }
    
    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSUrlSession.prepareRequest(request)
        
        let originalTask = BMSUrlSessionTaskType.uploadTaskWithFile(fileURL)
        let parentDelegate = BMSUrlSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromFile: fileURL)
        
        return uploadTask
    }
    
    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSUrlSession.prepareRequest(request)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSUrlSessionTaskType.uploadTaskWithFileAndCompletionHandler(fileURL, completionHandler)
        let bmsCompletionHandler = BMSUrlSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
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
    internal static func handleAuthorizationChallenge(urlSession: NSURLSession, request: NSMutableURLRequest, handleFailure: () -> Void, originalTask: BMSUrlSessionTaskType) {
        
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
                BMSUrlSession.logger.error("Authorization process failed. \nError: \(error). \nResponse: \(response).")
                handleFailure()
            }
        }
        authManager.obtainAuthorization(completionHandler: authCallback)
    }
    
    
    // Required to hook in challenge handling via AuthorizationManager
    internal static func generateBmsCompletionHandler(from completionHandler: BMSDataTaskCompletionHandler, urlSession: NSURLSession, request: NSURLRequest, originalTask: BMSUrlSessionTaskType) -> BMSDataTaskCompletionHandler {
        
        return { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if self.isAuthorizationManagerRequired(response) {
                
                func callParentCompletionHandler() {
                    completionHandler(data, response, error)
                }
                
                let originalRequest = request.mutableCopy() as! NSMutableURLRequest
                BMSUrlSession.handleAuthorizationChallenge(urlSession, request: originalRequest, handleFailure: callParentCompletionHandler, originalTask: originalTask)
            }
            else {
                completionHandler(data, response, error)
            }
        }
    }
}



/**
    A custom wrapper of NSURLSession that incorporates analytics and security from Bluemix Mobile Services.
 */
public struct BMSUrlSessionConfiguration {
    
    
    internal let configuration: NSURLSessionConfiguration
    
    internal let parentDelegate: NSURLSessionDelegate?
    
    internal let delegateQueue: NSOperationQueue?
    
    
    
    public init(configuration: NSURLSessionConfiguration = .defaultSessionConfiguration(),
               delegate: NSURLSessionDelegate? = nil,
               delegateQueue: NSOperationQueue? = nil) {
        
        self.configuration = configuration
        self.parentDelegate = delegate
        self.delegateQueue = delegateQueue
    }
}



// List of the supported types of NSURLSessionTask
// Stored in BMSUrlSession to determine what type of task to use when resending the request after authenticating with MCA
internal enum BMSUrlSessionTaskType {
    
    case dataTask
    case dataTaskWithCompletionHandler(BMSDataTaskCompletionHandler)
    
    case uploadTaskWithFile(NSURL)
    case uploadTaskWithData(NSData)
    case uploadTaskWithFileAndCompletionHandler(NSURL, BMSDataTaskCompletionHandler)
    case uploadTaskWithDataAndCompletionHandler(NSData?, BMSDataTaskCompletionHandler)
}
