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



class BMSUrlSessionTests: XCTestCase {

    
    var testBundle = Bundle.main
    var testUrl = URL(string: "BMSURLSessionTests")!
    
    
    override func setUp() {
        
        testBundle = Bundle(for: type(of: self))
        testUrl = testBundle.url(forResource: "Andromeda", withExtension: "jpg")!
        
        BMSURLSession.shouldRecordNetworkMetadata = true
    }
    
    
    
    // MARK: - Data Tasks
    
    // This also tests dataTaskWithURL(_ url: URL)
    func testDataTaskWithRequest() {
        
        let bmsSession = BMSURLSession()
        
        let request = URLRequest(url: testUrl)
        
        let dataTaskWithUrl: URLSessionDataTask = bmsSession.dataTask(with: testUrl)
        let dataTaskWithRequest: URLSessionDataTask = bmsSession.dataTask(with: request)
        
        // Make sure request has some BMS stuff in it
        XCTAssertNotNil(dataTaskWithUrl.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
        XCTAssertNotNil(dataTaskWithRequest.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
    }
    
    
    func testDataTaskWithRequestAndCompletionHandler() {
        
        let bmsSession = BMSURLSession()
        
        let request = URLRequest(url: testUrl)
        
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) { }
        
        let dataTaskWithUrl: URLSessionDataTask = bmsSession.dataTask(with: testUrl, completionHandler: testCompletionHandler)
        let dataTaskWithRequest: URLSessionDataTask = bmsSession.dataTask(with: request, completionHandler: testCompletionHandler)
        
        // Make sure request has some BMS stuff in it
        XCTAssertNotNil(dataTaskWithUrl.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
        XCTAssertNotNil(dataTaskWithRequest.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
    }
    
    
    
    // MARK: - Upload Tasks
    
    func testUploadTaskWithRequestFromData() {
        
        let bmsSession = BMSURLSession()
        
        let request = URLRequest(url: testUrl)
        
        let uploadTaskFromData: URLSessionUploadTask = bmsSession.uploadTask(with: request, from: Data())
        
        // Make sure request has some BMS stuff in it
        XCTAssertNotNil(uploadTaskFromData.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
    }
    
    
    func testUploadTaskWithRequestFromDataWithCompletionHandler() {
        
        let bmsSession = BMSURLSession()
        
        let request = URLRequest(url: testUrl)
        
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) { }
        
        let uploadTaskFromData: URLSessionUploadTask = bmsSession.uploadTask(with: request, from: Data(), completionHandler: testCompletionHandler)
        
        // Make sure request has some BMS stuff in it
        XCTAssertNotNil(uploadTaskFromData.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
    }
    
    
    func testUploadTaskWithRequestFromFile() {
        
        let bmsSession = BMSURLSession()
        
        let request = URLRequest(url: testUrl)
        
        let uploadTaskFromFile: URLSessionUploadTask = bmsSession.uploadTask(with: request, fromFile: testUrl)
        
        // Make sure request has some BMS stuff in it
        XCTAssertNotNil(uploadTaskFromFile.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
    }
    
    
    func testUploadTaskWithRequestFromFileWithCompletionHandler() {
        
        let bmsSession = BMSURLSession()
        
        let request = URLRequest(url: testUrl)
        
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) { }
        
        let uploadTaskFromFile: URLSessionUploadTask = bmsSession.uploadTask(with: request, fromFile: testUrl, completionHandler: testCompletionHandler)
        
        // Make sure request has some BMS stuff in it
        XCTAssertNotNil(uploadTaskFromFile.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
    }
    
    
    
    // MARK: - Helpers
    
    func testAddBMSHeaders() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override var cachedAuthorizationHeader:String? {
                get{
                    return "testHeader"
                }
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        XCTAssertNil(BaseRequest.requestAnalyticsData)
        BaseRequest.requestAnalyticsData = "testData"
        
        let originalRequest = URLRequest(url: testUrl)
        let preparedRequest = BMSURLSession.addBMSHeaders(to: originalRequest, onlyIf: true)
        
        XCTAssertEqual(preparedRequest.allHTTPHeaderFields?["Authorization"], "testHeader")
        XCTAssertEqual(preparedRequest.allHTTPHeaderFields?["x-mfp-analytics-metadata"], "testData")
        XCTAssertNotNil(preparedRequest.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
        
        BaseRequest.requestAnalyticsData = nil
    
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
    
    
    // No auto-retries, AuthorizationManager, redirects, or recorded metadata
    func testGenerateBmsCompletionHandlerDefaultCase() {
        
        let expectation = self.expectation(description: "Should reach original completion handler.")
        
        func bmsCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            
            expectation.fulfill()
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: URLSession(configuration: .default), request: URLRequest(url: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil, numberOfRetries: 0)
        
        testCompletionHandler(nil, nil, nil)
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testGenerateBmsCompletionHandlerWithAutoRetries() {
        
        let completionHandlerExpectation = self.expectation(description: "Should have reached the original completion handler.")
        
        func originalCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            
            completionHandlerExpectation.fulfill()
        }
        let originalDataTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(originalCompletionHandler)
        
        func bmsCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            
            XCTFail("Should have resent the original request instead of reaching the original completion handler.")
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: URLSession(configuration: .default), request: URLRequest(url: testUrl), originalTask: originalDataTask, requestBody: nil, numberOfRetries: 1)
        
        let serverErrorHttpResponse = HTTPURLResponse(url: testUrl, statusCode: 504, httpVersion: nil, headerFields: nil)
        testCompletionHandler(nil, serverErrorHttpResponse, nil)
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testGenerateBmsCompletionHandlerForRedirects() {
        
        let expectation = self.expectation(description: "Should reach original completion handler.")
        
        func bmsCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            
            expectation.fulfill()
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: URLSession(configuration: .default), request: URLRequest(url: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil, numberOfRetries: 0)
        
        let redirectHttpResponse = HTTPURLResponse(url: testUrl, statusCode: 300, httpVersion: nil, headerFields: nil)
        testCompletionHandler(nil, redirectHttpResponse, nil)
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testGenerateBmsCompletionHandlerWithFailedAuthentication() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                callback?(nil, NSError(domain: "", code: 401, userInfo: nil))
            }
            
            override func isAuthorizationRequired(for statusCode: Int, httpResponseAuthorizationHeader: String) -> Bool{
                return true
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let expectation = self.expectation(description: "Should reach original completion handler.")
        
        func bmsCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            
            expectation.fulfill()
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: URLSession(configuration: .default), request: URLRequest(url: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil, numberOfRetries: 0)
        let testResponse = HTTPURLResponse(url: testUrl, statusCode: 403, httpVersion: nil, headerFields: ["WWW-Authenticate": ""])
        
        testCompletionHandler(nil, testResponse, nil)
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
    
    
    func testGenerateBmsCompletionHandlerWithSuccessfulAuthentication() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = HTTPURLResponse(url: URL(string: "x")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
            
            override func isAuthorizationRequired(for statusCode: Int, httpResponseAuthorizationHeader: String) -> Bool{
                return true
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let expectation = self.expectation(description: "Should reach original completion handler.")
        
        func bmsCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            
            expectation.fulfill()
        }
        
        let originalTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(bmsCompletionHandler)
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: URLSession(configuration: .default), request: URLRequest(url: testUrl), originalTask: originalTask, requestBody: nil, numberOfRetries: 0)
        let testResponse = HTTPURLResponse(url: testUrl, statusCode: 200, httpVersion: nil, headerFields: ["WWW-Authenticate": ""])
        
        testCompletionHandler(nil, testResponse, nil)
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    
    func testGenerateBmsCompletionHandlerRecordsMetadata() {
        
        let expectation = self.expectation(description: "Should reach original completion handler.")
        let metadataRecordedExpectation = self.expectation(description: "Should have recorded the network metadata.")
        
        Logger.delegate = BMSLoggerMock(expectation: metadataRecordedExpectation)
        
        func bmsCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            
            expectation.fulfill()
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: URLSession(configuration: .default), request: URLRequest(url: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil, numberOfRetries: 0)
        
        let redirectHttpResponse = HTTPURLResponse(url: testUrl, statusCode: 200, httpVersion: nil, headerFields: nil)
        testCompletionHandler(nil, redirectHttpResponse, nil)
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testShouldRetryRequestForSuccessfulResponse() {
        
        let testSuccessfulResponse = HTTPURLResponse(url: testUrl, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        XCTAssertFalse(BMSURLSession.shouldRetryRequest(response: testSuccessfulResponse, error: nil, numberOfRetries: 1))
    }
    
    
    func testShouldRetryRequestForZeroRetries() {
        
        XCTAssertFalse(BMSURLSession.shouldRetryRequest(response: nil, error: nil, numberOfRetries: 0))
    }
    
    
    func testShouldRetryRequestForClientIssues() {
        
        let timedOutError = NSError(domain: "", code: NSURLErrorTimedOut, userInfo: nil)
        let cannotConnectToHostError = NSError(domain: "", code: NSURLErrorCannotConnectToHost, userInfo: nil)
        let networkConnectionLostError = NSError(domain: "", code: NSURLErrorNetworkConnectionLost, userInfo: nil)
        
        XCTAssertTrue(BMSURLSession.shouldRetryRequest(response: nil, error: timedOutError, numberOfRetries: 1))
        XCTAssertTrue(BMSURLSession.shouldRetryRequest(response: nil, error: cannotConnectToHostError, numberOfRetries: 1))
        XCTAssertTrue(BMSURLSession.shouldRetryRequest(response: nil, error: networkConnectionLostError, numberOfRetries: 1))
    }
    
    
    func testShouldRetryRequestForServerIssues() {
        
        let testHttpResponse = HTTPURLResponse(url: testUrl, statusCode: 504, httpVersion: nil, headerFields: nil)
        
        XCTAssertTrue(BMSURLSession.shouldRetryRequest(response: testHttpResponse, error: nil, numberOfRetries: 1))
    }
    
    
    func testRetryRequest() {
        
        let completionHandlerExpectation = self.expectation(description: "Should have reached the original completion handler.")
        
        let testSession = BMSURLSession()
        let testRequest = URLRequest(url: URL(string: "testRetryRequest")!)
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            completionHandlerExpectation.fulfill()
        }
        let dataTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(testCompletionHandler)
        
        BMSURLSession.retryRequest(originalRequest: testRequest, originalTask: dataTask, bmsUrlSession: testSession)
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testIsAuthorizationManagerRequired() {
        
        let responseWithoutAuthorization = URLResponse()
        XCTAssertFalse(BMSURLSession.isAuthorizationManagerRequired(for: responseWithoutAuthorization))
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func isAuthorizationRequired(for statusCode: Int, httpResponseAuthorizationHeader: String) -> Bool{
                return true
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let responseWithAuthorization = HTTPURLResponse(url: testUrl, statusCode: 403, httpVersion: "5", headerFields: ["WWW-Authenticate" : "asdf"])!
        XCTAssertTrue(BMSURLSession.isAuthorizationManagerRequired(for: responseWithAuthorization))
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
    
    
    func testHandleAuthorizationChallengeWithCachedAuthorizationHeader() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = HTTPURLResponse(url: URL(string: "x")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
            
            override var cachedAuthorizationHeader:String? {
                get{
                    return "testHeader"
                }
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let testSession = URLSession(configuration: .default)
        let testRequest = URLRequest(url: testUrl)
        let dataTaskType = BMSURLSessionTaskType.dataTask
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithDataTask() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = HTTPURLResponse(url: URL(string: "x")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let testSession = URLSession(configuration: .default)
        let testRequest = URLRequest(url: testUrl)
        let dataTaskType = BMSURLSessionTaskType.dataTask
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithDataTaskAndCompletionHandler() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = HTTPURLResponse(url: URL(string: "x")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) { }
        
        let testSession = URLSession(configuration: .default)
        let testRequest = URLRequest(url: testUrl)
        let dataTaskType = BMSURLSessionTaskType.dataTaskWithCompletionHandler(testCompletionHandler)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithUploadTaskFile() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = HTTPURLResponse(url: URL(string: "x")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let testSession = URLSession(configuration: .default)
        let testRequest = URLRequest(url: testUrl)
        let uploadTaskType = BMSURLSessionTaskType.uploadTaskWithFile(testUrl)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithUploadTaskFileAndCompletionHandler() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = HTTPURLResponse(url: URL(string: "x")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) { }
        
        let testSession = URLSession(configuration: .default)
        let testRequest = URLRequest(url: testUrl)
        let uploadTaskType = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(testUrl, testCompletionHandler)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        let bmsUrlSession = BMSURLSession()
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithUploadTaskData() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = HTTPURLResponse(url: URL(string: "x")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let testSession = URLSession(configuration: .default)
        let testRequest = URLRequest(url: testUrl)
        let testData = Data()
        let uploadTaskType = BMSURLSessionTaskType.uploadTaskWithData(testData)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithUploadTaskDataAndCompletionHandler() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = HTTPURLResponse(url: URL(string: "x")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) { }
        
        let testSession = URLSession(configuration: .default)
        let testRequest = URLRequest(url: testUrl)
        let testData = Data()
        let uploadTaskType = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(testData, testCompletionHandler)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithFailureResponse() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                callback?(nil, NSError(domain: "", code: 401, userInfo: nil))
            }
        }
        
        let expectation = self.expectation(description: "Should fail to handle the authorization challenge.")
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let testSession = URLSession(configuration: .default)
        let testRequest = URLRequest(url: testUrl)
        let dataTaskType = BMSURLSessionTaskType.dataTask
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleFailure: {
            
            expectation.fulfill()
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
        
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    
    func testRecordMetadataCompletionHandler() {
        
        let completionHandlerExpectation = self.expectation(description: "Should call the original completion handler.")
        let metadataRecordedExpectation = self.expectation(description: "Should have recorded the network metadata.")
    
        Logger.delegate = BMSLoggerMock(expectation: metadataRecordedExpectation)
        
        let testRequest = URLRequest(url: testUrl)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        let testData = "testRecordMetadataCompletionHandler".data(using: .utf8)
        
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            XCTAssertEqual(data, testData)
            completionHandlerExpectation.fulfill()
        }
        
        let metadataCompletionHandler = BMSURLSession.recordMetadataCompletionHandler(request: testRequest, requestMetadata: testRequestMetadata, originalCompletionHandler: testCompletionHandler)
        
        metadataCompletionHandler(testData, nil, nil)
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
}
    
    
    
class BMSURLSessionTaskTypeTests: XCTestCase {

    
    func testPrepareForResendingDataTask() {
        
        let testSession = BMSURLSession()
        let testRequest = URLRequest(url: URL(string: "testPrepareForResendingDataTask")!)
        
        let dataTask = BMSURLSessionTaskType.dataTask
        let dataTaskForResending: URLSessionTask = dataTask.prepareForResending(urlSession: testSession, request: testRequest)
        XCTAssertTrue(dataTaskForResending is URLSessionDataTask)
        XCTAssertEqual(dataTaskForResending.originalRequest?.url, testRequest.url)
    }
    
    
    func testPrepareForResendingDataTaskWithCompletionHandler() {
        
        let completionHandlerExpectation = self.expectation(description: "Should have reached the original completion handler.")
        
        let testSession = BMSURLSession()
        let testRequest = URLRequest(url: URL(string: "testPrepareForResendingDataTaskWithCompletionHandler")!)
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            completionHandlerExpectation.fulfill()
        }
        
        let dataTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(testCompletionHandler)
        let dataTaskForResending: URLSessionTask = dataTask.prepareForResending(urlSession: testSession, request: testRequest)
        XCTAssertTrue(dataTaskForResending is URLSessionDataTask)
        XCTAssertEqual(dataTaskForResending.originalRequest?.url, testRequest.url)
        
        dataTaskForResending.resume()
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testPrepareForResendingUploadTaskWithFile() {
        
        let testSession = BMSURLSession()
        let testRequest = URLRequest(url: URL(string: "testPrepareForResendingUploadTaskWithFile")!)
        let testFile = URL(fileURLWithPath: "testFile")
        
        let uploadTask = BMSURLSessionTaskType.uploadTaskWithFile(testFile)
        let uploadTaskForResending: URLSessionTask = uploadTask.prepareForResending(urlSession: testSession, request: testRequest)
        XCTAssertTrue(uploadTaskForResending is URLSessionUploadTask)
        XCTAssertEqual(uploadTaskForResending.originalRequest?.url, testRequest.url)
    }
    
    
    func testPrepareForResendingUploadTaskWithData() {
        
        let testSession = BMSURLSession()
        let testRequest = URLRequest(url: URL(string: "testPrepareForResendingUploadTaskWithData")!)
        let testData = Data(base64Encoded: "testData")!
        
        let uploadTask = BMSURLSessionTaskType.uploadTaskWithData(testData)
        let uploadTaskForResending: URLSessionTask = uploadTask.prepareForResending(urlSession: testSession, request: testRequest)
        XCTAssertTrue(uploadTaskForResending is URLSessionUploadTask)
        XCTAssertEqual(uploadTaskForResending.originalRequest?.url, testRequest.url)
    }
    
    
    func testPrepareForResendingUploadTaskWithFileAndCompletionHandler() {
        
        let completionHandlerExpectation = self.expectation(description: "Should have reached the original completion handler.")
        
        let testSession = BMSURLSession()
        let testRequest = URLRequest(url: URL(string: "testPrepareForResendingUploadTaskWithFileAndCompletionHandler")!)
        let testFile = URL(fileURLWithPath: "testFile")
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            completionHandlerExpectation.fulfill()
        }
        
        let uploadTask = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(testFile, testCompletionHandler)
        let uploadTaskForResending: URLSessionTask = uploadTask.prepareForResending(urlSession: testSession, request: testRequest)
        XCTAssertTrue(uploadTaskForResending is URLSessionUploadTask)
        XCTAssertEqual(uploadTaskForResending.originalRequest?.url, testRequest.url)
        
        uploadTaskForResending.resume()
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testPrepareForResendingUploadTaskWithDataAndCompletionHandler() {
        
        let completionHandlerExpectation = self.expectation(description: "Should have reached the original completion handler.")
        
        let testSession = BMSURLSession()
        let testRequest = URLRequest(url: URL(string: "testPrepareForResendingUploadTaskWithDataAndCompletionHandler")!)
        let testData = Data(base64Encoded: "testData")!
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            completionHandlerExpectation.fulfill()
        }
        
        let uploadTask = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(testData, testCompletionHandler)
        let uploadTaskForResending: URLSessionTask = uploadTask.prepareForResending(urlSession: testSession, request: testRequest)
        XCTAssertTrue(uploadTaskForResending is URLSessionUploadTask)
        XCTAssertEqual(uploadTaskForResending.originalRequest?.url, testRequest.url)
        
        uploadTaskForResending.resume()
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
}
    
    
    
// Used to check whether request metadata had been recorded by intercepting Analytics.log(metadata:), which delegates to BMSLogger
class BMSLoggerMock: LoggerDelegate {

    // Expect the LocationDelegate to log the metadata
    var metadataLoggedExpectation: XCTestExpectation?

    init(expectation: XCTestExpectation?) {
        self.metadataLoggedExpectation = expectation
    }

    var isUncaughtExceptionDetected: Bool = false

    // Here, we intercept the log to check if request metadata has been recorded
    func logToFile(message logMessage: String, level: LogLevel, loggerName: String, calledFile: String, calledFunction: String, calledLineNumber: Int, additionalMetadata: [String : Any]?) {

        // Check if the logged metadata matches the expected sampleMetadata
        if additionalMetadata != nil, additionalMetadata?["$category"] as? String == "network" {

            metadataLoggedExpectation?.fulfill()
            metadataLoggedExpectation = nil
        }
    }
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else

    
    
class BMSUrlSessionTests: XCTestCase {
    
    
    var testBundle = NSBundle.mainBundle()
    var testUrl = NSURL(fileURLWithPath: "BMSURLSessionTests")
    
    
    
    override func setUp() {
        
        testBundle = NSBundle(forClass: self.dynamicType)
        testUrl = testBundle.URLForResource("Andromeda", withExtension: "jpg")!
        
        BMSURLSession.shouldRecordNetworkMetadata = true
    }
    
    
    
    // MARK: - Data Tasks
    
    // This also tests dataTaskWithURL(_ url: URL)
    func testDataTaskWithRequest() {
        
        let bmsSession = BMSURLSession()
        
        let request = NSURLRequest(URL: testUrl)
        
        let dataTaskWithUrl: NSURLSessionDataTask = bmsSession.dataTaskWithURL(testUrl)
        let dataTaskWithRequest: NSURLSessionDataTask = bmsSession.dataTaskWithRequest(request)
        
        // Make sure request has some BMS stuff in it
        XCTAssertNotNil(dataTaskWithUrl.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
        XCTAssertNotNil(dataTaskWithRequest.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
    }
    
    
    func testDataTaskWithRequestAndCompletionHandler() {
        
        let bmsSession = BMSURLSession()
        
        let request = NSURLRequest(URL: testUrl)
        
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) { }
        
        let dataTaskWithUrl: NSURLSessionDataTask = bmsSession.dataTaskWithURL(testUrl, completionHandler: testCompletionHandler)
        let dataTaskWithRequest: NSURLSessionDataTask = bmsSession.dataTaskWithRequest(request, completionHandler: testCompletionHandler)
        
        // Make sure request has some BMS stuff in it
        XCTAssertNotNil(dataTaskWithUrl.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
        XCTAssertNotNil(dataTaskWithRequest.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
    }
    
    
    
    // MARK: - Upload Tasks
    
    func testUploadTaskWithRequestFromData() {
        
        let bmsSession = BMSURLSession()
        
        let request = NSURLRequest(URL: testUrl)
        
        let uploadTaskFromData: NSURLSessionUploadTask = bmsSession.uploadTaskWithRequest(request, fromData: NSData())
        
        // Make sure request has some BMS stuff in it
        XCTAssertNotNil(uploadTaskFromData.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
    }
    
    
    func testUploadTaskWithRequestFromDataWithCompletionHandler() {
        
        let bmsSession = BMSURLSession()
        
        let request = NSURLRequest(URL: testUrl)
        
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) { }
        
        let uploadTaskFromData: NSURLSessionUploadTask = bmsSession.uploadTaskWithRequest(request, fromData: NSData(), completionHandler: testCompletionHandler)
        
        // Make sure request has some BMS stuff in it
        XCTAssertNotNil(uploadTaskFromData.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
    }
    
    
    func testUploadTaskWithRequestFromFile() {
        
        let bmsSession = BMSURLSession()
        
        let request = NSURLRequest(URL: testUrl)
        
        let uploadTaskFromFile: NSURLSessionUploadTask = bmsSession.uploadTaskWithRequest(request, fromFile: testUrl)
        
        // Make sure request has some BMS stuff in it
        XCTAssertNotNil(uploadTaskFromFile.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
    }
    
    
    func testUploadTaskWithRequestFromFileWithCompletionHandler() {
        
        let bmsSession = BMSURLSession()
        
        let request = NSURLRequest(URL: testUrl)
        
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) { }
        
        let uploadTaskFromFile: NSURLSessionUploadTask = bmsSession.uploadTaskWithRequest(request, fromFile: testUrl, completionHandler: testCompletionHandler)
        
        // Make sure request has some BMS stuff in it
        XCTAssertNotNil(uploadTaskFromFile.originalRequest?.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
    }
    
    
    
    // MARK: - Helpers
    
    func testAddBMSHeaders() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override var cachedAuthorizationHeader:String? {
                get{
                    return "testHeader"
                }
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        XCTAssertNil(BaseRequest.requestAnalyticsData)
        BaseRequest.requestAnalyticsData = "testData"
        
        let originalRequest = NSURLRequest(URL: testUrl)
        let preparedRequest = BMSURLSession.addBMSHeaders(to: originalRequest, onlyIf: true)
        
        XCTAssertEqual(preparedRequest.allHTTPHeaderFields?["Authorization"], "testHeader")
        XCTAssertEqual(preparedRequest.allHTTPHeaderFields?["x-mfp-analytics-metadata"], "testData")
        XCTAssertNotNil(preparedRequest.allHTTPHeaderFields?["x-wl-analytics-tracking-id"])
        
        BaseRequest.requestAnalyticsData = nil
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
    
    
    // No auto-retries, AuthorizationManager, redirects, or recorded metadata
    func testGenerateBmsCompletionHandlerDefaultCase() {
        
        let expectation = self.expectationWithDescription("Should reach original completion handler.")
        
        func bmsCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            
            expectation.fulfill()
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()), request: NSURLRequest(URL: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil, numberOfRetries: 0)
        
        testCompletionHandler(nil, nil, nil)
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testGenerateBmsCompletionHandlerWithAutoRetries() {
        
        let completionHandlerExpectation = self.expectationWithDescription("Should have reached the original completion handler.")
        
        func originalCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            
            completionHandlerExpectation.fulfill()
        }
        let originalDataTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(originalCompletionHandler)
        
        func bmsCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            
            XCTFail("Should have resent the original request instead of reaching the original completion handler.")
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()), request: NSURLRequest(URL: testUrl), originalTask: originalDataTask, requestBody: nil, numberOfRetries: 1)
        
        let serverErrorHttpResponse = NSHTTPURLResponse(URL: testUrl, statusCode: 504, HTTPVersion: nil, headerFields: nil)
        testCompletionHandler(nil, serverErrorHttpResponse, nil)
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testGenerateBmsCompletionHandlerWithoutAuthorizationManager() {
        
        let expectation = self.expectationWithDescription("Should reach original completion handler.")
        
        func bmsCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            
            expectation.fulfill()
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: NSURLSession(configuration: .defaultSessionConfiguration()), request: NSURLRequest(URL: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil, numberOfRetries: 1)
        
        testCompletionHandler(nil, nil, nil)
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testGenerateBmsCompletionHandlerForRedirects() {
        
        let expectation = self.expectationWithDescription("Should reach original completion handler.")
        
        func bmsCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            
            expectation.fulfill()
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()), request: NSURLRequest(URL: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil, numberOfRetries: 0)
        
        let redirectHttpResponse = NSHTTPURLResponse(URL: testUrl, statusCode: 300, HTTPVersion: nil, headerFields: nil)
        testCompletionHandler(nil, redirectHttpResponse, nil)
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testGenerateBmsCompletionHandlerWithFailedAuthentication() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                callback?(nil, NSError(domain: "", code: 401, userInfo: nil))
            }
            
            override func isAuthorizationRequired(for statusCode: Int, httpResponseAuthorizationHeader: String) -> Bool{
                return true
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let expectation = self.expectationWithDescription("Should reach original completion handler.")
        
        func bmsCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            
            expectation.fulfill()
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: NSURLSession(configuration: .defaultSessionConfiguration()), request: NSURLRequest(URL: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil, numberOfRetries: 0)
        let testResponse = NSHTTPURLResponse(URL: testUrl, statusCode: 403, HTTPVersion: nil, headerFields: ["WWW-Authenticate": ""])
        
        testCompletionHandler(nil, testResponse, nil)
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
    
    
    func testGenerateBmsCompletionHandlerWithSuccessfulAuthentication() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = NSHTTPURLResponse(URL: NSURL(string: "x")!, statusCode: 200, HTTPVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
            
            override func isAuthorizationRequired(for statusCode: Int, httpResponseAuthorizationHeader: String) -> Bool{
                return true
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let expectation = self.expectationWithDescription("Should reach original completion handler.")
        
        func bmsCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            
            expectation.fulfill()
        }
        
        let originalTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(bmsCompletionHandler)
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: NSURLSession(configuration: .defaultSessionConfiguration()), request: NSURLRequest(URL: testUrl), originalTask: originalTask, requestBody: nil, numberOfRetries: 0)
        let testResponse = NSHTTPURLResponse(URL: testUrl, statusCode: 200, HTTPVersion: nil, headerFields: ["WWW-Authenticate": ""])
        
        testCompletionHandler(nil, testResponse, nil)
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
    
    
    func testGenerateBmsCompletionHandlerRecordsMetadata() {
        
        let expectation = self.expectationWithDescription("Should reach original completion handler.")
        let metadataRecordedExpectation = self.expectationWithDescription("Should have recorded the network metadata.")
        
        Logger.delegate = BMSLoggerMock(expectation: metadataRecordedExpectation)
        
        func bmsCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            
            expectation.fulfill()
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, bmsUrlSession: BMSURLSession(), urlSession: NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()), request: NSURLRequest(URL: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil, numberOfRetries: 0)
        
        let redirectHttpResponse = NSHTTPURLResponse(URL: testUrl, statusCode: 200, HTTPVersion: nil, headerFields: nil)
        testCompletionHandler(nil, redirectHttpResponse, nil)
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    
    func testShouldRetryRequestForSuccessfulResponse() {
        
        let testSuccessfulResponse = NSHTTPURLResponse(URL: testUrl, statusCode: 200, HTTPVersion: nil, headerFields: nil)
        
        XCTAssertFalse(BMSURLSession.shouldRetryRequest(response: testSuccessfulResponse, error: nil, numberOfRetries: 1))
    }
    
    
    func testShouldRetryRequestForZeroRetries() {
        
        XCTAssertFalse(BMSURLSession.shouldRetryRequest(response: nil, error: nil, numberOfRetries: 0))
    }
    
    
    func testShouldRetryRequestForClientIssues() {
        
        let timedOutError = NSError(domain: "", code: NSURLErrorTimedOut, userInfo: nil)
        let cannotConnectToHostError = NSError(domain: "", code: NSURLErrorCannotConnectToHost, userInfo: nil)
        let networkConnectionLostError = NSError(domain: "", code: NSURLErrorNetworkConnectionLost, userInfo: nil)
        
        XCTAssertTrue(BMSURLSession.shouldRetryRequest(response: nil, error: timedOutError, numberOfRetries: 1))
        XCTAssertTrue(BMSURLSession.shouldRetryRequest(response: nil, error: cannotConnectToHostError, numberOfRetries: 1))
        XCTAssertTrue(BMSURLSession.shouldRetryRequest(response: nil, error: networkConnectionLostError, numberOfRetries: 1))
    }
    
    
    func testShouldRetryRequestForServerIssues() {
        
        let testHttpResponse = NSHTTPURLResponse(URL: testUrl, statusCode: 504, HTTPVersion: nil, headerFields: nil)
        
        XCTAssertTrue(BMSURLSession.shouldRetryRequest(response: testHttpResponse, error: nil, numberOfRetries: 1))
    }
    
    
    func testRetryRequest() {
        
        let completionHandlerExpectation = self.expectationWithDescription("Should have reached the original completion handler.")
        
        let testSession = BMSURLSession()
        let testRequest = NSURLRequest(URL: NSURL(string: "testRetryRequest")!)
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            completionHandlerExpectation.fulfill()
        }
        let dataTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(testCompletionHandler)
        
        BMSURLSession.retryRequest(originalRequest: testRequest, originalTask: dataTask, bmsUrlSession: testSession)
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testIsAuthorizationManagerRequired() {
        
        let responseWithoutAuthorization = NSURLResponse()
        XCTAssertFalse(BMSURLSession.isAuthorizationManagerRequired(responseWithoutAuthorization))
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func isAuthorizationRequired(for statusCode: Int, httpResponseAuthorizationHeader: String) -> Bool{
                return true
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let responseWithAuthorization = NSHTTPURLResponse(URL: testUrl, statusCode: 403, HTTPVersion: "5", headerFields: ["WWW-Authenticate" : ""])!
        XCTAssertTrue(BMSURLSession.isAuthorizationManagerRequired(responseWithAuthorization))
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
    
    
    func testHandleAuthorizationChallengeWithCachedAuthorizationHeader() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = NSHTTPURLResponse(URL: NSURL(string: "x")!, statusCode: 200, HTTPVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
            
            override var cachedAuthorizationHeader:String? {
                get{
                    return "testHeader"
                }
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let testSession = NSURLSession(configuration: .defaultSessionConfiguration())
        let testRequest = NSMutableURLRequest(URL: testUrl)
        let dataTaskType = BMSURLSessionTaskType.dataTask
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        NSThread.sleepForTimeInterval(0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithDataTask() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = NSHTTPURLResponse(URL: NSURL(string: "x")!, statusCode: 200, HTTPVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let testSession = NSURLSession(configuration: .defaultSessionConfiguration())
        let testRequest = NSMutableURLRequest(URL: testUrl)
        let dataTaskType = BMSURLSessionTaskType.dataTask
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        NSThread.sleepForTimeInterval(0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithDataTaskAndCompletionHandler() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = NSHTTPURLResponse(URL: NSURL(string: "x")!, statusCode: 200, HTTPVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) { }
        
        let testSession = NSURLSession(configuration: .defaultSessionConfiguration())
        let testRequest = NSMutableURLRequest(URL: testUrl)
        let dataTaskType = BMSURLSessionTaskType.dataTaskWithCompletionHandler(testCompletionHandler)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        NSThread.sleepForTimeInterval(0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithUploadTaskFile() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = NSHTTPURLResponse(URL: NSURL(string: "x")!, statusCode: 200, HTTPVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let testSession = NSURLSession(configuration: .defaultSessionConfiguration())
        let testRequest = NSMutableURLRequest(URL: testUrl)
        let uploadTaskType = BMSURLSessionTaskType.uploadTaskWithFile(testUrl)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        NSThread.sleepForTimeInterval(0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithUploadTaskFileAndCompletionHandler() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = NSHTTPURLResponse(URL: NSURL(string: "x")!, statusCode: 200, HTTPVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) { }
        
        let testSession = NSURLSession(configuration: .defaultSessionConfiguration())
        let testRequest = NSMutableURLRequest(URL: testUrl)
        let uploadTaskType = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(testUrl, testCompletionHandler)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        NSThread.sleepForTimeInterval(0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithUploadTaskData() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = NSHTTPURLResponse(URL: NSURL(string: "x")!, statusCode: 200, HTTPVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let testSession = NSURLSession(configuration: .defaultSessionConfiguration())
        let testRequest = NSMutableURLRequest(URL: testUrl)
        let testData = NSData()
        let uploadTaskType = BMSURLSessionTaskType.uploadTaskWithData(testData)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        NSThread.sleepForTimeInterval(0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithUploadTaskDataAndCompletionHandler() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                let testHttpResponse = NSHTTPURLResponse(URL: NSURL(string: "x")!, statusCode: 200, HTTPVersion: nil, headerFields: nil)
                let testResponse = Response(responseData: nil, httpResponse: testHttpResponse, isRedirect: false)
                
                callback?(testResponse, nil)
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) { }
        
        let testSession = NSURLSession(configuration: .defaultSessionConfiguration())
        let testRequest = NSMutableURLRequest(URL: testUrl)
        let testData = NSData()
        let uploadTaskType = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(testData, testCompletionHandler)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleFailure: {
            
            XCTFail("Should have successfully regenerated the original request.")
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        NSThread.sleepForTimeInterval(0.1)
    }
    
    
    func testHandleAuthorizationChallengeWithFailureResponse() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                callback?(nil, NSError(domain: "", code: 401, userInfo: nil))
            }
        }
        
        let expectation = self.expectationWithDescription("Should fail to handle the authorization challenge")
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let testSession = NSURLSession(configuration: .defaultSessionConfiguration())
        let testRequest = NSMutableURLRequest(URL: testUrl)
        let dataTaskType = BMSURLSessionTaskType.dataTask
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleFailure:  {
            
            expectation.fulfill()
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
        
        NSThread.sleepForTimeInterval(0.1)
    }
    
    
    func testRecordMetadataCompletionHandler() {
        
        let completionHandlerExpectation = self.expectationWithDescription("Should call the original completion handler.")
        let metadataRecordedExpectation = self.expectationWithDescription("Should have recorded the network metadata.")
        
        Logger.delegate = BMSLoggerMock(expectation: metadataRecordedExpectation)
        
        let testRequest = NSURLRequest(URL: testUrl)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        let testData = "testRecordMetadataCompletionHandler".dataUsingEncoding(NSUTF8StringEncoding)
        
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            XCTAssertEqual(data, testData)
            completionHandlerExpectation.fulfill()
        }
        
        let metadataCompletionHandler = BMSURLSession.recordMetadataCompletionHandler(request: testRequest, requestMetadata: testRequestMetadata, originalCompletionHandler: testCompletionHandler)
        
        metadataCompletionHandler(testData, nil, nil)
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
}



class BMSURLSessionTaskTypeTests: XCTestCase {
    
    
    func testPrepareForResendingDataTask() {
        
        let testSession = BMSURLSession()
        let testRequest = NSURLRequest(URL: NSURL(string: "testPrepareForResendingDataTask")!)
        
        let dataTask = BMSURLSessionTaskType.dataTask
        let dataTaskForResending: NSURLSessionTask = dataTask.prepareForResending(urlSession: testSession, request: testRequest)
        XCTAssertTrue(dataTaskForResending is NSURLSessionDataTask)
        XCTAssertEqual(dataTaskForResending.originalRequest?.URL, testRequest.URL)
    }
    
    
    func testPrepareForResendingDataTaskWithCompletionHandler() {
        
        let completionHandlerExpectation = self.expectationWithDescription("Should have reached the original completion handler.")
        
        let testSession = BMSURLSession()
        let testRequest = NSURLRequest(URL: NSURL(string: "testPrepareForResendingDataTaskWithCompletionHandler")!)
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            completionHandlerExpectation.fulfill()
        }
        
        let dataTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(testCompletionHandler)
        let dataTaskForResending: NSURLSessionTask = dataTask.prepareForResending(urlSession: testSession, request: testRequest)
        XCTAssertTrue(dataTaskForResending is NSURLSessionDataTask)
        XCTAssertEqual(dataTaskForResending.originalRequest?.URL, testRequest.URL)
        
        dataTaskForResending.resume()
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testPrepareForResendingUploadTaskWithFile() {
        
        let testSession = BMSURLSession()
        let testRequest = NSURLRequest(URL: NSURL(string: "testPrepareForResendingUploadTaskWithFile")!)
        let testFile = NSURL(fileURLWithPath: "testFile")
        
        let uploadTask = BMSURLSessionTaskType.uploadTaskWithFile(testFile)
        let uploadTaskForResending: NSURLSessionTask = uploadTask.prepareForResending(urlSession: testSession, request: testRequest)
        XCTAssertTrue(uploadTaskForResending is NSURLSessionUploadTask)
        XCTAssertEqual(uploadTaskForResending.originalRequest?.URL, testRequest.URL)
    }
    
    
    func testPrepareForResendingUploadTaskWithData() {
        
        let testSession = BMSURLSession()
        let testRequest = NSURLRequest(URL: NSURL(string: "testPrepareForResendingUploadTaskWithData")!)
        let testData = "testData".dataUsingEncoding(NSUTF8StringEncoding)!
        
        let uploadTask = BMSURLSessionTaskType.uploadTaskWithData(testData)
        let uploadTaskForResending: NSURLSessionTask = uploadTask.prepareForResending(urlSession: testSession, request: testRequest)
        XCTAssertTrue(uploadTaskForResending is NSURLSessionUploadTask)
        XCTAssertEqual(uploadTaskForResending.originalRequest?.URL, testRequest.URL)
    }
    
    
    func testPrepareForResendingUploadTaskWithFileAndCompletionHandler() {
        
        let completionHandlerExpectation = self.expectationWithDescription("Should have reached the original completion handler.")
        
        let testSession = BMSURLSession()
        let testRequest = NSURLRequest(URL: NSURL(string: "testPrepareForResendingUploadTaskWithFileAndCompletionHandler")!)
        let testFile = NSURL(fileURLWithPath: "testFile")
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            completionHandlerExpectation.fulfill()
        }
        
        let uploadTask = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(testFile, testCompletionHandler)
        let uploadTaskForResending: NSURLSessionTask = uploadTask.prepareForResending(urlSession: testSession, request: testRequest)
        XCTAssertTrue(uploadTaskForResending is NSURLSessionUploadTask)
        XCTAssertEqual(uploadTaskForResending.originalRequest?.URL, testRequest.URL)
        
        uploadTaskForResending.resume()
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    
    func testPrepareForResendingUploadTaskWithDataAndCompletionHandler() {
        
        let completionHandlerExpectation = self.expectationWithDescription("Should have reached the original completion handler.")
        
        let testSession = BMSURLSession()
        let testRequest = NSURLRequest(URL: NSURL(string: "testPrepareForResendingUploadTaskWithDataAndCompletionHandler")!)
        let testData = "testData".dataUsingEncoding(NSUTF8StringEncoding)!
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            completionHandlerExpectation.fulfill()
        }
        
        let uploadTask = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(testData, testCompletionHandler)
        let uploadTaskForResending: NSURLSessionTask = uploadTask.prepareForResending(urlSession: testSession, request: testRequest)
        XCTAssertTrue(uploadTaskForResending is NSURLSessionUploadTask)
        XCTAssertEqual(uploadTaskForResending.originalRequest?.URL, testRequest.URL)
        
        uploadTaskForResending.resume()
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
}



// Used to check whether request metadata had been recorded by intercepting Analytics.log(metadata:), which delegates to BMSLogger
class BMSLoggerMock: LoggerDelegate {
    
    // Expect the LocationDelegate to log the metadata
    var metadataLoggedExpectation: XCTestExpectation?
    
    init(expectation: XCTestExpectation?) {
        self.metadataLoggedExpectation = expectation
    }
    
    var isUncaughtExceptionDetected: Bool = false
    
    // Here, we intercept the log to check if request metadata has been recorded
    func logToFile(message logMessage: String, level: LogLevel, loggerName: String, calledFile: String, calledFunction: String, calledLineNumber: Int, additionalMetadata: [String : AnyObject]?) {
        
        // Check if the logged metadata matches the expected sampleMetadata
        if additionalMetadata != nil && additionalMetadata?["$category"] as? String == "network" {
            
            metadataLoggedExpectation?.fulfill()
            metadataLoggedExpectation = nil
        }
    }
}



#endif
