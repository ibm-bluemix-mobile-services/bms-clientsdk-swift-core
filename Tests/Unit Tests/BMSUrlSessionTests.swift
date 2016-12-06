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
    var testUrl = URL(fileURLWithPath: "x")
    
    
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
    
    
    func testGenerateBmsCompletionHandlerWithoutAuthorizationManager() {
        
        let expectation = self.expectation(description: "Should reach original completion handler.")
        
        func bmsCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            
            expectation.fulfill()
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, urlSession: URLSession(configuration: .default), request: URLRequest(url: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil)
        
        testCompletionHandler(nil, nil, nil)
        
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
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, urlSession: URLSession(configuration: .default), request: URLRequest(url: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil)
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
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, urlSession: URLSession(configuration: .default), request: URLRequest(url: testUrl), originalTask: originalTask, requestBody: nil)
        let testResponse = HTTPURLResponse(url: testUrl, statusCode: 200, httpVersion: nil, headerFields: ["WWW-Authenticate": ""])
        
        testCompletionHandler(nil, testResponse, nil)
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
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
    
    
    // The `testHandleAuthorizationChallenge...` methods below test both `handleAuthorizationChallenge` and `resendOriginalRequest`
    
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
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertEqual(taskWithAuthorization.currentRequest!.allHTTPHeaderFields?["Authorization"], "testHeader")
            }
            else {
                XCTFail("URLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertTrue(taskWithAuthorization is URLSessionDataTask)
            }
            else {
                XCTFail("URLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
        
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            let httpResponse = response as! HTTPURLResponse
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
        
        let testSession = URLSession(configuration: .default)
        let testRequest = URLRequest(url: testUrl)
        let dataTaskType = BMSURLSessionTaskType.dataTaskWithCompletionHandler(testCompletionHandler)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertTrue(taskWithAuthorization is URLSessionDataTask)
            }
            else {
                XCTFail("URLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertTrue(taskWithAuthorization is URLSessionUploadTask)
            }
            else {
                XCTFail("URLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
        
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            let httpResponse = response as! HTTPURLResponse
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
        
        let testSession = URLSession(configuration: .default)
        let testRequest = URLRequest(url: testUrl)
        let uploadTaskType = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(testUrl, testCompletionHandler)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertTrue(taskWithAuthorization is URLSessionUploadTask)
            }
            else {
                XCTFail("URLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertTrue(taskWithAuthorization is URLSessionUploadTask)
            }
            else {
                XCTFail("URLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
        
        func testCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
            let httpResponse = response as! HTTPURLResponse
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
        
        let testSession = URLSession(configuration: .default)
        let testRequest = URLRequest(url: testUrl)
        let testData = Data()
        let uploadTaskType = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(testData, testCompletionHandler)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertTrue(taskWithAuthorization is URLSessionUploadTask)
            }
            else {
                XCTFail("URLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
    
    
    func testHandleAuthorizationChallengeWithFailureResponse() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                callback?(nil, NSError(domain: "", code: 401, userInfo: nil))
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let testSession = URLSession(configuration: .default)
        let testRequest = URLRequest(url: testUrl)
        let dataTaskType = BMSURLSessionTaskType.dataTask
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleTask: { (urlSessionTask) in
            
            XCTAssertNil(urlSessionTask)
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
    
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else

    
    
class BMSUrlSessionTests: XCTestCase {
    
    
    var testBundle = NSBundle.mainBundle()
    var testUrl = NSURL(fileURLWithPath: "x")
    
    
    
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
    
    
    func testGenerateBmsCompletionHandlerWithoutAuthorizationManager() {
        
        let expectation = self.expectationWithDescription("Should reach original completion handler.")
        
        func bmsCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            
            expectation.fulfill()
        }
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, urlSession: NSURLSession(configuration: .defaultSessionConfiguration()), request: NSURLRequest(URL: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil)
        
        testCompletionHandler(nil, nil, nil)
        
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
        
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, urlSession: NSURLSession(configuration: .defaultSessionConfiguration()), request: NSURLRequest(URL: testUrl), originalTask: BMSURLSessionTaskType.dataTask, requestBody: nil)
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
        let testCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: bmsCompletionHandler, urlSession: NSURLSession(configuration: .defaultSessionConfiguration()), request: NSURLRequest(URL: testUrl), originalTask: originalTask, requestBody: nil)
        let testResponse = NSHTTPURLResponse(URL: testUrl, statusCode: 200, HTTPVersion: nil, headerFields: ["WWW-Authenticate": ""])
        
        testCompletionHandler(nil, testResponse, nil)
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
    
    
    // The `testHandleAuthorizationChallenge...` methods below test both `handleAuthorizationChallenge` and `resendOriginalRequest`
    
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
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertEqual(taskWithAuthorization.currentRequest!.allHTTPHeaderFields?["Authorization"], "testHeader")
            }
            else {
                XCTFail("NSURLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertTrue(taskWithAuthorization is NSURLSessionDataTask)
            }
            else {
                XCTFail("NSURLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
        
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            let httpResponse = response as! NSHTTPURLResponse
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
        
        let testSession = NSURLSession(configuration: .defaultSessionConfiguration())
        let testRequest = NSMutableURLRequest(URL: testUrl)
        let dataTaskType = BMSURLSessionTaskType.dataTaskWithCompletionHandler(testCompletionHandler)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertTrue(taskWithAuthorization is NSURLSessionDataTask)
            }
            else {
                XCTFail("NSURLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertTrue(taskWithAuthorization is NSURLSessionUploadTask)
            }
            else {
                XCTFail("NSURLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
        
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            let httpResponse = response as! NSHTTPURLResponse
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
        
        let testSession = NSURLSession(configuration: .defaultSessionConfiguration())
        let testRequest = NSMutableURLRequest(URL: testUrl)
        let uploadTaskType = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(testUrl, testCompletionHandler)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertTrue(taskWithAuthorization is NSURLSessionUploadTask)
            }
            else {
                XCTFail("NSURLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertTrue(taskWithAuthorization is NSURLSessionUploadTask)
            }
            else {
                XCTFail("NSURLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
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
        
        func testCompletionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
            let httpResponse = response as! NSHTTPURLResponse
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
        
        let testSession = NSURLSession(configuration: .defaultSessionConfiguration())
        let testRequest = NSMutableURLRequest(URL: testUrl)
        let testData = NSData()
        let uploadTaskType = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(testData, testCompletionHandler)
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: uploadTaskType, handleTask: { (urlSessionTask) in
            
            if let taskWithAuthorization = urlSessionTask {
                XCTAssertTrue(taskWithAuthorization is NSURLSessionUploadTask)
            }
            else {
                XCTFail("NSURLSessionTask should not be nil")
            }
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
    
    
    func testHandleAuthorizationChallengeWithFailureResponse() {
        
        class TestAuthorizationManager: BaseAuthorizationManager {
            
            override func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
                callback?(nil, NSError(domain: "", code: 401, userInfo: nil))
            }
        }
        
        BMSClient.sharedInstance.authorizationManager = TestAuthorizationManager()
        
        let testSession = NSURLSession(configuration: .defaultSessionConfiguration())
        let testRequest = NSMutableURLRequest(URL: testUrl)
        let dataTaskType = BMSURLSessionTaskType.dataTask
        let testRequestMetadata = RequestMetadata(url: nil, startTime: 0, trackingId: "")
        
        BMSURLSession.handleAuthorizationChallenge(session: testSession, request: testRequest, requestMetadata: testRequestMetadata, originalTask: dataTaskType, handleTask: { (urlSessionTask) in
            
            XCTAssertNil(urlSessionTask)
        })
        
        BMSClient.sharedInstance.authorizationManager = BaseAuthorizationManager()
    }
}



#endif
