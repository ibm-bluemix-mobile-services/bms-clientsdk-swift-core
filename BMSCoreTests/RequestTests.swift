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
        XCTAssertEqual(request.headers!, ["Content-Type": "text/plain"])
        XCTAssertEqual(request.queryParameters!, ["someKey": "someValue"])
        XCTAssertNotNil(request.networkRequest)
    }
    
    func testInitWithDefaultParameters() {
        
        let request = Request(url: "http://example.com", headers: nil, queryParameters: nil)
        
        XCTAssertEqual(request.resourceUrl, "http://example.com")
        XCTAssertEqual(request.httpMethod.rawValue, "GET")
        XCTAssertEqual(request.timeout, BMSClient.sharedInstance.defaultRequestTimeout)
        XCTAssertNil(request.headers)
        XCTAssertNil(request.headers)
        XCTAssertNotNil(request.networkRequest)
    }
    
    
    
    // MARK: send
    
    func testSendString() {
        
        let request = Request(url: "http://example.com", headers: nil, queryParameters: ["someKey": "someValue"])
        let dataString = "Some data text"
        
        request.sendString(dataString, withCompletionHandler: nil)
        let requestBodyAsString = NSString(data: request.requestBody!, encoding: NSUTF8StringEncoding) as? String
        
        XCTAssertEqual(requestBodyAsString, dataString)
        XCTAssertEqual(request.headers![Request.CONTENT_TYPE], Request.TEXT_PLAIN_TYPE)
        XCTAssertEqual(request.resourceUrl, "http://example.com?someKey=someValue")
    }
    
    func testSendStringWithoutOverwritingContentTypeHeader() {
        
        let request = Request(url: "http://example.com", headers: ["Content-Type": "media-type"], queryParameters: ["someKey": "someValue"])
        let dataString = "Some data text"
        
        request.sendString(dataString, withCompletionHandler: nil)
        let requestBodyAsString = NSString(data: request.requestBody!, encoding: NSUTF8StringEncoding) as? String
        
        XCTAssertEqual(requestBodyAsString, dataString)
        XCTAssertEqual(request.headers![Request.CONTENT_TYPE], "media-type")
        XCTAssertEqual(request.resourceUrl, "http://example.com?someKey=someValue")
    }
    
    func testSendData() {
        
        let request = Request(url: "http://example.com", headers: nil, queryParameters: ["someKey": "someValue"])
        let requestData = "{\"key1\": \"value1\", \"key2\": \"value2\"}".dataUsingEncoding(NSUTF8StringEncoding)
        
        request.sendData(requestData!, withCompletionHandler: nil)
        
        XCTAssertEqual(request.requestBody, requestData)
        XCTAssertEqual(request.resourceUrl, "http://example.com?someKey=someValue")
    }
    
    
    
    // MARK: addQueryParameters
    
    func testAddQueryParametersWithValidParameters() {
        
        let url = NSURL(string: "http://example.com")
        let parameters = ["key1": "value1", "key2": "value2"]
        let finalUrl = String( Request.appendQueryParameters(parameters, toURL: url!) )
        
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
        let finalUrl = String( Request.appendQueryParameters(parameters, toURL: url!) )
        
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
