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


import XCTest
@testable import BMSCore



// MARK: - Swift 3

#if swift(>=3.0)
    


/*
    These tests ensure that the BMSURLSessionDelegate methods
    call the appropriate URLSession methods in the parent delegate.
*/
class BMSUrlSessionDelegateTests: XCTestCase {

    
    let testUrl = URL(string: "x")!
    
    
    
    // MARK: Session delegate
    
    func testDidBecomeInvalidWithError() {
        
        let delegateExpectation = self.expectation(description: "Called didBecomeInvalidWithError")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), didBecomeInvalidWithError: nil)
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testDidReceiveChallengeSessionDelegate() {
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: nil), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), didReceive: URLAuthenticationChallenge(), completionHandler: {(_, _) in })
        
        // No expectation because this method should not be called in the parent delegate.
        // We check for failure in the TestBmsDelegate class.
    }
    
    
    func testUrlSessionDidFinishEvents() {
        
        let delegateExpectation = self.expectation(description: "Called urlSessionDidFinishEvents")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.urlSessionDidFinishEvents(forBackgroundURLSession: URLSession())
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    
    // MARK: Task delegate
    
    func testWillPerformHTTPRedirection() {
        
        let delegateExpectation = self.expectation(description: "Called willPerformHTTPRedirection")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), task: URLSessionTask(), willPerformHTTPRedirection: HTTPURLResponse(), newRequest: URLRequest(url: testUrl), completionHandler: {(_) in })
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testDidReceiveChallengeTaskDelegate() {
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: nil), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), task: URLSessionTask(), didReceive: URLAuthenticationChallenge(), completionHandler: {(_, _) in })
        
        // No expectation because this method should not be called in the parent delegate.
        // We check for failure in the TestBmsDelegate class.
    }
    
    
    func testNeedNewBodyStream() {
        
        let delegateExpectation = self.expectation(description: "Called needNewBodyStream")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), task: URLSessionTask(), needNewBodyStream: { (_) in })
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testDidSendBodyData() {
        
        let delegateExpectation = self.expectation(description: "Called didSendBodyData")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), task: URLSessionTask(), didSendBodyData: 1, totalBytesSent: 1, totalBytesExpectedToSend: 1)
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testDidCompleteWithError() {
        
        let delegateExpectation = self.expectation(description: "Called didCompleteWithError")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), task: URLSessionTask(), didCompleteWithError: nil)
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    @available(iOS, introduced: 10)
    func testDidFinishCollecting() {
        
        let delegateExpectation = self.expectation(description: "Called didFinishCollecting")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), task: URLSessionTask(), didFinishCollecting: URLSessionTaskMetrics())
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    
    // MARK: Data delegate
    
    func testDidReceiveResponse() {
        
        let delegateExpectation = self.expectation(description: "Called didReceiveResponse")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), dataTask: URLSessionDataTask(), didReceive: URLResponse(), completionHandler: {(_) in })
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    // Go through the authorization manager flow and return an authentication failure so we can delegate to the TestBmsDelegate
    func testDidReceiveResponseWithAuthorizationManager() {
        
        let delegateExpectation = self.expectation(description: "Called didReceiveResponse with Authorization Manager")
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func isAuthorizationRequired(for statusCode: Int, httpResponseAuthorizationHeader: String) -> Bool{
                return true
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        let authorizationResponse = HTTPURLResponse(url: testUrl, statusCode: 403, httpVersion: "5", headerFields: ["WWW-Authenticate" : ""])!
        let testDataTask = URLSession(configuration: .default).dataTask(with: testUrl)
        
        bmsDelegate.urlSession(URLSession(), dataTask: testDataTask, didReceive: authorizationResponse, completionHandler: {(_) in })
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
    
    
    func testDidBecomeDownloadTask() {
        
        let delegateExpectation = self.expectation(description: "Called didBecomeDownloadTask")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), dataTask: URLSessionDataTask(), didBecome: URLSessionDownloadTask())
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    @available(iOS 9.0, *)
    func testDidBecomeStreamTask() {
        
        let delegateExpectation = self.expectation(description: "Called didBecomeStreamTask")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), dataTask: URLSessionDataTask(), didBecome: URLSessionStreamTask())
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testDidReceiveData() {
        
        let delegateExpectation = self.expectation(description: "Called didReceiveData")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), dataTask: URLSessionDataTask(), didReceive: Data())
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testWillCacheResponse() {
        
        let delegateExpectation = self.expectation(description: "Called willCacheResponse")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.urlSession(URLSession(), dataTask: URLSessionDataTask(), willCacheResponse: CachedURLResponse(), completionHandler: {(_) in })
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
 
    
    
    // MARK:
    
    private class TestBmsDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
        
        
        let delegateExpectation: XCTestExpectation?
        
        
        init(expectation: XCTestExpectation?) {
            
            delegateExpectation = expectation
        }
    
    
        
        // Session Delegate
        
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            
            XCTFail("BMSURLSession should not have called the didReceiveChallenge method in the parent delegate")
        }
        
        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            
            delegateExpectation!.fulfill()
        }
        
        func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
            
            delegateExpectation!.fulfill()
        }
    
    
    
        // Task Delegate
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
            
            delegateExpectation!.fulfill()
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            
            XCTFail("BMSURLSession should not have called the didReceiveChallenge method in the parent delegate")
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
            
            delegateExpectation!.fulfill()
        }
        
        @available(iOS, introduced: 10)
        func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
            
            delegateExpectation!.fulfill()
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            
            delegateExpectation!.fulfill()
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            
            delegateExpectation!.fulfill()
        }
    
    
        // Data Delegate
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
            
            delegateExpectation!.fulfill()
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            
            delegateExpectation!.fulfill()
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
            
            delegateExpectation!.fulfill()
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
            
            delegateExpectation!.fulfill()
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            
            delegateExpectation!.fulfill()
        }
    }
    
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
  
    
/*
    These tests ensure that the BMSURLSessionDelegate methods
    call the appropriate URLSession methods in the parent delegate.
*/
class BMSUrlSessionDelegateTests: XCTestCase {
    
    
    let testUrl = NSURL(string: "x")!
    
    
    
    // MARK: Session delegate
    
    func testDidBecomeInvalidWithError() {
        
        let delegateExpectation = self.expectationWithDescription("Called didBecomeInvalidWithError")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.URLSession(NSURLSession(), didBecomeInvalidWithError: nil)
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testDidReceiveChallengeSessionDelegate() {
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: nil), originalTask: .dataTask)
        bmsDelegate.URLSession(NSURLSession(), didReceiveChallenge: NSURLAuthenticationChallenge(), completionHandler: {(_,_) in })
        
        // No expectation because this method should not be called in the parent delegate.
        // We check for failure in the TestBmsDelegate class.
    }
    
    
    func testUrlSessionDidFinishEvents() {
        
        let delegateExpectation = self.expectationWithDescription("Called urlSessionDidFinishEvents")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.URLSessionDidFinishEventsForBackgroundURLSession(NSURLSession())
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    
    // MARK: Task delegate
    
    func testWillPerformHTTPRedirection() {
        
        let delegateExpectation = self.expectationWithDescription("Called willPerformHTTPRedirection")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.URLSession(NSURLSession(), task: NSURLSessionTask(), willPerformHTTPRedirection: NSHTTPURLResponse(), newRequest: NSURLRequest(), completionHandler: {(_) in })
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testDidReceiveChallengeTaskDelegate() {
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: nil), originalTask: .dataTask)
        bmsDelegate.URLSession(NSURLSession(), task: NSURLSessionTask(), didReceiveChallenge: NSURLAuthenticationChallenge(), completionHandler: {(_,_) in })
        
        // No expectation because this method should not be called in the parent delegate.
        // We check for failure in the TestBmsDelegate class.
    }
    
    
    func testNeedNewBodyStream() {
        
        let delegateExpectation = self.expectationWithDescription("Called needNewBodyStream")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.URLSession(NSURLSession(), task: NSURLSessionTask(), needNewBodyStream: {(_) in })
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testDidSendBodyData() {
        
        let delegateExpectation = self.expectationWithDescription("Called didSendBodyData")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.URLSession(NSURLSession(), task: NSURLSessionTask(), didSendBodyData: 1, totalBytesSent: 1, totalBytesExpectedToSend: 1)
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testDidCompleteWithError() {
        
        let delegateExpectation = self.expectationWithDescription("Called didCompleteWithError")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.URLSession(NSURLSession(), task: NSURLSessionTask(), didCompleteWithError: nil)
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    
    // MARK: Data delegate
    
    func testDidReceiveResponse() {
        
        let delegateExpectation = self.expectationWithDescription("Called didReceiveResponse")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.URLSession(NSURLSession(), dataTask: NSURLSessionDataTask(), didReceiveResponse: NSURLResponse(), completionHandler: {(_) in })
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    // Go through the authorization manager flow and return an authentication failure so we can delegate to the TestBmsDelegate
    func testDidReceiveResponseWithAuthorizationManager() {
        
        let delegateExpectation = self.expectationWithDescription("Called didReceiveResponse with Authorization Manager")
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func isAuthorizationRequired(for statusCode: Int, httpResponseAuthorizationHeader: String) -> Bool{
                return true
            }
        }
    
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
    
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        let authorizationResponse = NSHTTPURLResponse(URL: testUrl, statusCode: 403, HTTPVersion: "5", headerFields: ["WWW-Authenticate" : ""])!
        let testDataTask = NSURLSession(configuration: .defaultSessionConfiguration()).dataTaskWithURL(testUrl)
        
        bmsDelegate.URLSession(NSURLSession(), dataTask: testDataTask, didReceiveResponse: authorizationResponse, completionHandler: {(_) in })
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
    
    
    func testDidBecomeDownloadTask() {
        
        let delegateExpectation = self.expectationWithDescription("Called didBecomeDownloadTask")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.URLSession(NSURLSession(), dataTask: NSURLSessionDataTask(), didBecomeDownloadTask: NSURLSessionDownloadTask())
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    @available(iOS 9.0, *)
    func testDidBecomeStreamTask() {
        
        let delegateExpectation = self.expectationWithDescription("Called didBecomeStreamTask")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.URLSession(NSURLSession(), dataTask: NSURLSessionDataTask(), didBecomeStreamTask: NSURLSessionStreamTask())
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testDidReceiveData() {
        
        let delegateExpectation = self.expectationWithDescription("Called didReceiveData")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.URLSession(NSURLSession(), dataTask: NSURLSessionDataTask(), didReceiveData: NSData())
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testWillCacheResponse() {
        
        let delegateExpectation = self.expectationWithDescription("Called willCacheResponse")
        
        let bmsDelegate = BMSURLSessionDelegate(parentDelegate: TestBmsDelegate(expectation: delegateExpectation), originalTask: .dataTask)
        bmsDelegate.URLSession(NSURLSession(), dataTask: NSURLSessionDataTask(), willCacheResponse: NSCachedURLResponse(), completionHandler: {(_) in })
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    
    // MARK:
    
    private class TestBmsDelegate: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate {
        
        
        let delegateExpectation: XCTestExpectation?
        
        
        init(expectation: XCTestExpectation?) {
            
            delegateExpectation = expectation
        }
        
        
        
        // Session Delegate
        
        @objc func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
            
            XCTFail("BMSURLSession should not have called the didReceiveChallenge method in the parent delegate")
        }
        
        @objc func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
            
            delegateExpectation!.fulfill()
        }
        
        @objc func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
            
            delegateExpectation!.fulfill()
        }
        
        
        
        // Task Delegate
        
        @objc func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
            
            delegateExpectation!.fulfill()
        }
        
        @objc func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
            
            XCTFail("BMSURLSession should not have called the didReceiveChallenge method in the parent delegate")
        }
        
        @objc func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
            
            delegateExpectation!.fulfill()
        }
        
        @objc func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
            
            delegateExpectation!.fulfill()
        }
        
        @objc func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
            
            delegateExpectation!.fulfill()
        }
        
        
        
        // Data task
        
        @objc func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
            
            delegateExpectation!.fulfill()
        }
        
        @objc func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
            
            delegateExpectation!.fulfill()
        }
        
        @objc func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) {
            
            delegateExpectation!.fulfill()
        }
        
        @objc func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeStreamTask streamTask: NSURLSessionStreamTask) {
            
            delegateExpectation!.fulfill()
        }
        
        @objc func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
            
            delegateExpectation!.fulfill()
        }
    }
    
}



#endif
