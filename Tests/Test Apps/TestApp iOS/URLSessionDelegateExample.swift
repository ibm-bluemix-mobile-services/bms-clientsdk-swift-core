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


import BMSCore


class URLSessionDelegateExample: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate {
    
    
    var response: NSURLResponse?
    var dataReceived = NSMutableData()
    
    let viewController: ViewController
    
    let logger = Logger.logger(forName: "TestAppiOS")
    
    
    
    init(viewController: ViewController) {
        
        self.viewController = viewController
    }
    
    
    
    // MARK: NSURLSessionDelegate
    
    internal func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        
        logger.error("Error: \(error.debugDescription)\n")
    }
    
    internal func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        logger.info("\n")
    }
    
    internal func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
        logger.debug("\n")
    }
    
    
    // MARK: NSURLSessionTaskDelegate
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        
        logger.debug("\n")
    }
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        logger.info("\n")
    }
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        
        logger.debug("\n")
    }
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        dispatch_async(dispatch_get_main_queue()) {
            let currentProgress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
            self.viewController.progressBar.setProgress(currentProgress, animated: true)
        }
    }
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        logger.error("Error: \(error.debugDescription)\n")
        
        self.viewController.displayData(dataReceived, response: self.response, error: nil)
        if error != nil {
            self.viewController.displayData(nil, response: nil, error: error)
        }
    }
    
    
    // MARK: NSURLSessionDataDelegate
    
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        logger.info("Response: \(response)\n")
        
        self.response = response
        self.viewController.displayData(nil, response: response, error: nil)
        
        completionHandler(NSURLSessionResponseDisposition.Allow)
    }
    
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) {
        
        logger.debug("\n")
    }
    
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        // Turned off for tasks that download/upload a lot of data
//        logger.info("")
        dataReceived.appendData(data)
    }
    
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        
        logger.debug("\n")
    }
}