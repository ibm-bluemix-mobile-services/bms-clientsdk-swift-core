/*
*     Copyright 2015 IBM Corp.
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

class RequestTests: XCTestCase {
    
    
    // MARK: init
    
    func testInitWithAllParameters() {
        
        let request = Request(url: "http://example.com", headers:["Content-Type": "text/plain"], queryParameters: ["someKey": "someValue"], method: HttpMethod.GET, timeout: 10.0)
        
        XCTAssertEqual(request.resourceUrl, "http://example.com")
        XCTAssertEqual(request.httpMethod.rawValue, "GET")
        XCTAssertEqual(request.timeout, 10.0)
        XCTAssertEqual(request.headers, ["Content-Type": "text/plain"])
        XCTAssertEqual(request.queryParameters!, ["someKey": "someValue"])
        XCTAssertNotNil(request.networkRequest)
    }
    
    func testInitWithDefaultParameters() {
        
        let request = Request(url: "http://example.com", headers: nil, queryParameters: nil)
        
        XCTAssertEqual(request.resourceUrl, "http://example.com")
        XCTAssertEqual(request.httpMethod.rawValue, "GET")
        XCTAssertEqual(request.timeout, BMSClient.sharedInstance.defaultRequestTimeout)
        XCTAssertTrue(request.headers.isEmpty)
        XCTAssertTrue(request.headers.isEmpty)
        XCTAssertNotNil(request.networkRequest)
    }
    
    
    
    // MARK: request analytics
    
    func testAddAnalyticsMetadataToRequestWithoutAnalyticsAppName() {
        
        let request = Request(url: "http://example.com", headers: ["test key": "test value"], queryParameters: nil)
        
        XCTAssertEqual(request.headers.count, 1)
        
        Analytics.uninitialize()
        
        request.addAnalyticsMetadataToRequest()
        
        XCTAssertNotNil(request.headers["x-wl-analytics-tracking-id"])
        
        let requestMetadata: String? = request.headers["x-mfp-analytics-metadata"]
        XCTAssertNotNil(requestMetadata)
        // Since Analytics has not been initialized, there will be no app name. 
        // In a real app, this should default to the bundle ID. Unit tests have no bundle ID.
        XCTAssert(!requestMetadata!.containsString("mfpAppName"))
    }
    
    func testAddAnalyticsMetadataToRequestWithAnalyticsAppName() {
        
        let request = Request(url: "http://example.com", headers: nil, queryParameters: nil)
        
        Analytics.initializeWithAppName("Test app", apiKey: "asdfjasdfj")
        
        request.addAnalyticsMetadataToRequest()
        
        XCTAssertNotNil(request.headers["x-wl-analytics-tracking-id"])
        
        let requestMetadata: String? = request.headers["x-mfp-analytics-metadata"]
        XCTAssertNotNil(requestMetadata)
        // Since Analytics has not been initialized, there will be no app name.
        // In a real app, this should default to the bundle ID. Unit tests have no bundle ID.
        XCTAssert(requestMetadata!.containsString("\"mfpAppName\":\"Test app\""))
    }
    
    func testUniqueDeviceId() {
        
        let mfpUserDefaults = NSUserDefaults(suiteName: "com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore")
        mfpUserDefaults?.removeObjectForKey("deviceId")
        
        // Generate new ID
        let generatedId = Request.uniqueDeviceId
        
        // Since an ID was already created, this method should keep returning the same one
        let retrievedId = Request.uniqueDeviceId
        XCTAssertEqual(retrievedId, generatedId)
        let retrievedId2 = Request.uniqueDeviceId
        XCTAssertEqual(retrievedId2, generatedId)
    }
    
    func testGenerateInboundResponseMetadata() {
        
        let request = Request(url: "http://example.com", headers: nil, queryParameters: nil)
        request.sendWithCompletionHandler(nil)
        
        let responseData = "{\"key1\": \"value1\", \"key2\": \"value2\"}".dataUsingEncoding(NSUTF8StringEncoding)
        let httpURLResponse = NSHTTPURLResponse(URL: NSURL(string: "http://example.com")!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["key": "value"])
        let response = Response(responseData: responseData!, httpResponse: httpURLResponse, isRedirect: true)
        
        let responseMetadata = request.generateInboundResponseMetadata(response, url: "http://example.com")
        
        let outboundTime = responseMetadata["$outboundTimestamp"] as? NSTimeInterval
        let inboundTime = responseMetadata["$inboundTimestamp"] as? NSTimeInterval
        let roundTripTime = responseMetadata["$roundTripTime"] as? NSTimeInterval
        
        XCTAssertNotNil(outboundTime)
        XCTAssertNotNil(inboundTime)
        XCTAssertNotNil(roundTripTime)
        
        XCTAssert(inboundTime > outboundTime)
        XCTAssert(roundTripTime > 0)
        
        let responseBytes = responseMetadata["$bytesReceived"] as? Int
        XCTAssertNotNil(responseBytes)
        XCTAssert(responseBytes == 36)
    }
    
    
    
    // MARK: send
    
    func testSendData() {
        
        let request = Request(url: "http://example.com", headers: nil, queryParameters: ["someKey": "someValue"])
        let requestData = "{\"key1\": \"value1\", \"key2\": \"value2\"}".dataUsingEncoding(NSUTF8StringEncoding)
        
        request.sendData(requestData!, withCompletionHandler: nil)
        
        XCTAssertEqual(request.requestBody, requestData)
        XCTAssertEqual(request.resourceUrl, "http://example.com?someKey=someValue")
    }

    
    func testSendString() {
        
        let request = Request(url: "http://example.com", headers: nil, queryParameters: ["someKey": "someValue"])
        let dataString = "Some data text"
        
        request.sendString(dataString, withCompletionHandler: nil)
        let requestBodyAsString = NSString(data: request.requestBody!, encoding: NSUTF8StringEncoding) as? String
        
        XCTAssertEqual(requestBodyAsString, dataString)
        XCTAssertEqual(request.headers[Request.CONTENT_TYPE], Request.TEXT_PLAIN_TYPE)
        XCTAssertEqual(request.resourceUrl, "http://example.com?someKey=someValue")
    }
    
    func testSendStringWithoutOverwritingContentTypeHeader() {
        
        let request = Request(url: "http://example.com", headers: ["Content-Type": "media-type"], queryParameters: ["someKey": "someValue"])
        let dataString = "Some data text"
        
        request.sendString(dataString, withCompletionHandler: nil)
        let requestBodyAsString = NSString(data: request.requestBody!, encoding: NSUTF8StringEncoding) as? String
        
        XCTAssertEqual(requestBodyAsString, dataString)
        XCTAssertEqual(request.headers[Request.CONTENT_TYPE], "media-type")
        XCTAssertEqual(request.resourceUrl, "http://example.com?someKey=someValue")
    }
    
    func testSendWithMalformedUrl() {
        
        let responseReceivedExpectation = self.expectationWithDescription("Receive network response")
        
        let badUrl = "!@#$%^&*()"
        let request = Request(url: badUrl, headers: nil, queryParameters: nil)
        request.sendWithCompletionHandler { (response: Response?, error: NSError?) -> Void in
            XCTAssertNil(response)
            XCTAssertEqual(error?.domain, MFP_CORE_ERROR_DOMAIN)
            XCTAssertEqual(error?.code, MFPErrorCode.MalformedUrl.rawValue)
            
            responseReceivedExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0) { (error: NSError?) -> Void in
            if error != nil {
                XCTFail("Expectation failed with error: \(error)")
            }
        }
    }
    
    
    
    // MARK: addQueryParameters
    
    func testAddQueryParametersWithEmptyParameters() {
        
        let url = NSURL(string: "http://example.com")
        let parameters: [String: String] = [:]
        let finalUrl = String( Request.appendQueryParameters(parameters, toURL: url!)! )
        
        XCTAssertEqual(finalUrl, "http://example.com")
    }
    
    
    func testAddQueryParametersWithValidParameters() {
        
        let url = NSURL(string: "http://example.com")
        let parameters = ["key1": "value1", "key2": "value2"]
        let finalUrl = String( Request.appendQueryParameters(parameters, toURL: url!)! )
        
        XCTAssertEqual(finalUrl, "http://example.com?key1=value1&key2=value2")
    }
    
    func testAddQueryParametersWithReservedCharacters() {
        
        let url = NSURL(string: "http://example.com")
        let parameters = ["Reserved_characters": "\"#%<>[\\]^`{|}"]
        let finalUrl = String( Request.appendQueryParameters(parameters, toURL: url!) )
        
        XCTAssert(finalUrl.containsString("%22%23%25%3C%3E%5B%5C%5D%5E%60%7B%7C%7D"))
    }
    
    func testAddQueryParametersDoesNotOverwriteUrlParameters() {
        
        let url = NSURL(string: "http://example.com?hardCodedKey=hardCodedValue")
        
        let parameters = ["key1": "value1", "key2": "value2"]
        let finalUrl = String( Request.appendQueryParameters(parameters, toURL: url!)! )
        
        XCTAssertEqual(finalUrl, "http://example.com?hardCodedKey=hardCodedValue&key1=value1&key2=value2")
    }
    
    func testAddQueryParametersWithCorrectNumberOfAmpersands() {
        
        let url = NSURL(string: "http://example.com")
        let parameters = ["k1": "v1", "k2": "v2", "k3": "v3", "k4": "v4"]
        let finalUrl = String( Request.appendQueryParameters(parameters, toURL: url!) )
        
        let numberOfAmpersands = finalUrl.componentsSeparatedByString("&")
        
        XCTAssertEqual(numberOfAmpersands.count - 1, 3)
    }

}
