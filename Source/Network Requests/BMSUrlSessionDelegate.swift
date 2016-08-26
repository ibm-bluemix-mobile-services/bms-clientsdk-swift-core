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


// MARK: Session Delegate

class BMSUrlSessionDelegate: NSObject, NSURLSessionDelegate {
    
    
    // The user-supplied session delegate
    internal let parentDelegate: NSURLSessionDelegate?
    
    internal let originalTask: BMSUrlSessionTaskType
    
    
    
    init(parentDelegate: NSURLSessionDelegate?, originalTask: BMSUrlSessionTaskType) {
        
        self.parentDelegate = parentDelegate
        self.originalTask = originalTask
    }

    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        
        parentDelegate?.URLSession?(session, didBecomeInvalidWithError: error)
    }
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        completionHandler(.PerformDefaultHandling, nil)
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
        parentDelegate?.URLSessionDidFinishEventsForBackgroundURLSession?(session)
    }
}



// MARK: Task delegate

extension BMSUrlSessionDelegate: NSURLSessionTaskDelegate {
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        
        (parentDelegate as? NSURLSessionTaskDelegate)?.URLSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        completionHandler(.PerformDefaultHandling, nil)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        
        (parentDelegate as? NSURLSessionTaskDelegate)?.URLSession?(session, task: task, needNewBodyStream: completionHandler)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        (parentDelegate as? NSURLSessionTaskDelegate)?.URLSession?(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        (parentDelegate as? NSURLSessionTaskDelegate)?.URLSession?(session, task: task, didCompleteWithError: error)
    }
}



// MARK: Data delegate

extension BMSUrlSessionDelegate: NSURLSessionDataDelegate {
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        func callParentDelegate() {
            (parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, didReceiveResponse: response, completionHandler: completionHandler)
        }
        
        if BMSUrlSession.isAuthorizationManagerRequired(response) {
            
            // originalRequest should always have a value. It can only be nil for stream tasks, which is not supported by BMSUrlSession.
            let originalRequest = dataTask.originalRequest!.mutableCopy() as! NSMutableURLRequest
            BMSUrlSession.handleAuthorizationChallenge(session, request: originalRequest, handleFailure: callParentDelegate, originalTask: self.originalTask)
        }
        else {
            callParentDelegate()
        }
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) {
        
        (parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, didBecomeDownloadTask: downloadTask)
    }
    
    @available(iOS 9.0, *)
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeStreamTask streamTask: NSURLSessionStreamTask) {
        
        (parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, didBecomeStreamTask: streamTask)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        (parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, didReceiveData: data)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        
        (parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
    }
}