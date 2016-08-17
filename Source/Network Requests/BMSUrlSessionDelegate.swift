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


// Custom wrapper for NSURLSessionDelegate
// Uses AuthorizationManager from the BMSSecurity framework to handle network requests to MCA protected backends
internal class BMSUrlSessionDelegate: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate {
    
    // The user-supplied session delegate
    internal let parentSessionDelegate: NSURLSessionDelegate?
    
    // The user-supplied task delegate
    internal let parentTaskDelegate: NSURLSessionTaskDelegate?
    
    // The user-supplied data delegate
    internal let parentDataDelegate: NSURLSessionDataDelegate?
    
    
    
    init(parentDelegate: NSURLSessionDelegate) {
        
        if parentDelegate.conformsToProtocol(NSURLSessionDelegate) {
            self.parentSessionDelegate = parentDelegate
        }
        else {
            self.parentSessionDelegate = nil
        }
        
        if parentDelegate.conformsToProtocol(NSURLSessionTaskDelegate) {
            self.parentTaskDelegate = parentDelegate as! NSURLSessionTaskDelegate
        }
        else {
            self.parentTaskDelegate = nil
        }
        
        if parentDelegate.conformsToProtocol(NSURLSessionDataDelegate) {
            self.parentDataDelegate = parentDelegate as! NSURLSessionDataDelegate
        }
        else {
            self.parentDataDelegate = nil
        }
    }
    
    
    // Handle the challenge with AuthorizationManager from BMSSecurity
    internal func handleAuthorizationChallenge(urlSession: NSURLSession, dataTask: NSURLSessionDataTask, handleFailure: () -> Void) {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        let authCallback: BmsCompletionHandler = {(response: Response?, error:NSError?) in
            
            if error == nil && response?.statusCode >= 200 && response?.statusCode < 300 {
                
                // Resend the original request with the "Authorization" header
                
                let originalRequest = dataTask.currentRequest!.mutableCopy() as! NSMutableURLRequest
                
                let authManager = BMSClient.sharedInstance.authorizationManager
                if let authHeader: String = authManager.cachedAuthorizationHeader {
                    originalRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
                }
                
                urlSession.dataTaskWithRequest(originalRequest).resume()
            }
            else {
                BMSUrlSession.logger.error("Authorization process failed. \nError: \(error). \nResponse: \(response).")
                handleFailure()
            }
        }
        authManager.obtainAuthorization(completionHandler: authCallback)
    }
}



// MARK: Session Delegate

internal extension BMSUrlSessionDelegate {
    
    internal func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        
        parentSessionDelegate?.URLSession?(session, didBecomeInvalidWithError: error)
    }
    
    internal func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        completionHandler(.PerformDefaultHandling, nil)
    }
    
    internal func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
        parentSessionDelegate?.URLSessionDidFinishEventsForBackgroundURLSession?(session)
    }
}



// MARK: Task delegate

internal extension BMSUrlSessionDelegate {
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        
        parentTaskDelegate?.URLSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
    }
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        completionHandler(.PerformDefaultHandling, nil)
    }
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        
        parentTaskDelegate?.URLSession?(session, task: task, needNewBodyStream: completionHandler)
    }
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        parentTaskDelegate?.URLSession?(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        parentTaskDelegate?.URLSession?(session, task: task, didCompleteWithError: error)
    }
}



// MARK: Data delegate

internal extension BMSUrlSessionDelegate {
    
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        func callParentDelegate() {
            parentDataDelegate?.URLSession?(session, dataTask: dataTask, didReceiveResponse: response, completionHandler: completionHandler)
        }
        
        if BMSUrlSession.isAuthorizationManagerRequired(response) {
            handleAuthorizationChallenge(session, dataTask: dataTask, handleFailure: callParentDelegate)
        }
        else {
            callParentDelegate()
        }
    }
    
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) {
        
        parentDataDelegate?.URLSession?(session, dataTask: dataTask, didBecomeDownloadTask: downloadTask)
    }
    
    @available(iOS 9.0, *)
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeStreamTask streamTask: NSURLSessionStreamTask) {
        
        parentDataDelegate?.URLSession?(session, dataTask: dataTask, didBecomeStreamTask: streamTask)
    }
    
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        parentDataDelegate?.URLSession?(session, dataTask: dataTask, didReceiveData: data)
    }
    
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        
        parentDataDelegate?.URLSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
    }
}