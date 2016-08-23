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


/**
    A custom wrapper of NSURLSession that incorporates analytics and security from Bluemix Mobile Services.
*/
public class BMSUrlSession: NSObject {

    /// The network session
    public let urlSession: NSURLSession
    
    // The NSURLSessionTask created by the user
    // Used to recreate the original task after authenticating with MCA
    // For each new task, a new instance of BMSUrlSession must be created (only one originalTask per BMSUrlSession).
    private var originalTask: BMSUrlSessionTaskType
    
    // The user-supplied session delegate
    internal let parentDelegate: NSURLSessionDelegate?
    
    static let logger = Logger.logger(forName: Logger.bmsLoggerPrefix + "urlSession")
    
    
    
    public init(configuration: NSURLSessionConfiguration = .defaultSessionConfiguration(),
               delegate: NSURLSessionDelegate? = nil,
               delegateQueue: NSOperationQueue? = nil) {
        
        parentDelegate = delegate
        
        urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        // This should be overriden by a new task created by the user before it is needed in the handleAuthorizationChallenge() method.
        originalTask = BMSUrlSessionTaskType.dataTask
    }
    
    
    // Inject BMSSecurity and BMSAnalytics into the request object by adding headers
    internal func prepareRequest(request: NSURLRequest) -> NSURLRequest {
        
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
    
    internal func isAuthorizationManagerRequired(response: NSURLResponse?) -> Bool {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        
        if let response = response as? NSHTTPURLResponse,
            let wwwAuthHeader = response.allHeaderFields["WWW-Authenticate"] as? String
            where authManager.isAuthorizationRequired(forStatusCode: response.statusCode, httpResponseAuthorizationHeader: wwwAuthHeader) {
            
            return true
        }
        return false
    }
    
    
    // Handle the challenge with AuthorizationManager from BMSSecurity
    internal func handleAuthorizationChallenge(urlSession: NSURLSession, request: NSMutableURLRequest, handleFailure: () -> Void) {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        let authCallback: BmsCompletionHandler = {(response: Response?, error:NSError?) in
            
            if error == nil && response?.statusCode >= 200 && response?.statusCode < 300 {
                
                // Resend the original request with the "Authorization" header
                
                let authManager = BMSClient.sharedInstance.authorizationManager
                if let authHeader: String = authManager.cachedAuthorizationHeader {
                    request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                }
                
                // Figure out the original NSURLSessionTask created by the user, and resend it
                switch self.originalTask {
                    
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
}



// MARK: Data tasks

extension BMSUrlSession {
    
    public func dataTaskWithURL(url: NSURL) -> NSURLSessionDataTask {

        return self.dataTaskWithRequest(NSURLRequest(URL: url))
    }

    public func dataTaskWithURL(url: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask {

        return self.dataTaskWithRequest(NSURLRequest(URL: url), completionHandler: completionHandler)
    }
    
    public func dataTaskWithRequest(request: NSURLRequest) -> NSURLSessionDataTask {
        
        let bmsRequest = prepareRequest(request)
        let dataTask = urlSession.dataTaskWithRequest(bmsRequest)
        
        self.originalTask = BMSUrlSessionTaskType.dataTask
        
        return dataTask
    }
    
    public func dataTaskWithRequest(request: NSURLRequest, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask {
        
        let bmsRequest = prepareRequest(request)
        let bmsCompletionHandler = generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request)
        let dataTask = urlSession.dataTaskWithRequest(bmsRequest, completionHandler: bmsCompletionHandler)
        
        self.originalTask = BMSUrlSessionTaskType.dataTaskWithCompletionHandler(completionHandler)
        
        return dataTask
    }
}



// MARK: Upload tasks

extension BMSUrlSession {

    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData) -> NSURLSessionUploadTask {

        let bmsRequest = prepareRequest(request)
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromData: bodyData)
        
        self.originalTask = BMSUrlSessionTaskType.uploadTaskWithData(bodyData)
        
        return uploadTask
    }

    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData?, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask {
        
        let bmsRequest = prepareRequest(request)
        let bmsCompletionHandler = generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request)
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromData: bodyData, completionHandler: bmsCompletionHandler)
        
        self.originalTask = BMSUrlSessionTaskType.uploadTaskWithDataAndCompletionHandler(bodyData, completionHandler)
        
        return uploadTask
    }

    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL) -> NSURLSessionUploadTask {

        let bmsRequest = prepareRequest(request)
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromFile: fileURL)
        
        self.originalTask = BMSUrlSessionTaskType.uploadTaskWithFile(fileURL)
        
        return uploadTask
    }

    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask {

        let bmsRequest = prepareRequest(request)
        let bmsCompletionHandler = generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request)
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromFile: fileURL, completionHandler: bmsCompletionHandler)
        
        self.originalTask = BMSUrlSessionTaskType.uploadTaskWithFileAndCompletionHandler(fileURL, completionHandler)
        
        return uploadTask
    }
}



// List of the supported types of NSURLSessionTask
// Stored in BMSUrlSession to determine what type of task to use when resending the request after authenticating with MCA
private enum BMSUrlSessionTaskType {
    
    case dataTask
    case dataTaskWithCompletionHandler(BMSDataTaskCompletionHandler)
    
    case uploadTaskWithFile(NSURL)
    case uploadTaskWithData(NSData)
    case uploadTaskWithFileAndCompletionHandler(NSURL, BMSDataTaskCompletionHandler)
    case uploadTaskWithDataAndCompletionHandler(NSData?, BMSDataTaskCompletionHandler)
}

