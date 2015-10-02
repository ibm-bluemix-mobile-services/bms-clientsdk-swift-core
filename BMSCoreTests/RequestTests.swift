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
        
        let request = Request(url: NSURL(string: "http://example.com")!, method: HttpMethod.GET, timeout: 10.0, headers:["Content-Type": "text/plain"], queryParameters: ["someKey": "someValue"])
        
        XCTAssertEqual(String(request.resourceUrl), "http://example.com?someKey=someValue")
        XCTAssertEqual(request.httpMethod.rawValue, "GET")
        XCTAssertEqual(request.timeout, 10.0)
        XCTAssertEqual(request.headers, ["Content-Type": "text/plain"])
        XCTAssertEqual(request.queryParameters!, ["someKey": "someValue"])
        XCTAssertNotNil(request.networkRequest)
    }
    
    func testInitWithDefaultParameters() {
        
        let request = Request(url: NSURL(string: "http://example.com")!)
        
        XCTAssertEqual(String(request.resourceUrl), "http://example.com")
        XCTAssertEqual(request.httpMethod.rawValue, "GET")
        XCTAssertEqual(request.timeout, BMSClient.sharedInstance.defaultRequestTimeout)
        XCTAssertEqual(request.headers, [:])
        XCTAssertEqual(request.queryParameters!, [:])
        XCTAssertNotNil(request.networkRequest)
    }
    
    
    
    // MARK: setRequestBody
    
    func testSetRequestBodyWithValidJSON() {
        
        let request = Request(url: NSURL(string: "http://example.com")!)
        let json = ["key1": "value1", "key2": "value2"]
        var requestBodyAsJSON: AnyObject?
        request.setRequestBodyWithJSON(json)
        do {
            requestBodyAsJSON = try NSJSONSerialization.JSONObjectWithData(request.requestBody!, options: .MutableContainers)
        }
        catch let jsonError {
            XCTFail("Failed to create JSON object. Error: \(jsonError)")
        }
        
        XCTAssertEqual(requestBodyAsJSON as! [String: String], json)
        XCTAssertEqual(request.headers[Request.CONTENT_TYPE], Request.JSON_CONTENT_TYPE)
    }
    
    func testSetRequestBodyWithInvalidJSON() {
        
        // Cannot implement the below test because it causes an NSException.
        // Swift cannot catch NSExceptions, so this test will always fail. 
        // Uncomment below to confirm that the test fails with an NSInvalidArgumentException: Invalid top-level type in JSON write
        
//        let request = Request(url: "http://example.com")
//        let json = "INVALID JSON"
//        request.setRequestBodyWithJSON(json)
    }
    
    func testSetRequestBodyWithJSONAndContentHeader() {
        
        let request = Request(url: NSURL(string: "http://example.com")!, headers: ["Content-Type": "media-type"])
        let json = ["key1": "value1", "key2": "value2"]
        var requestBodyAsJSON: AnyObject?
        request.setRequestBodyWithJSON(json)
        do {
            requestBodyAsJSON = try NSJSONSerialization.JSONObjectWithData(request.requestBody!, options: .MutableContainers)
        }
        catch let jsonError {
            XCTFail("Failed to create JSON object. Error: \(jsonError)")
        }
        
        XCTAssertEqual(requestBodyAsJSON as! [String: String], json)
        XCTAssertEqual(request.headers[Request.CONTENT_TYPE], "media-type")
    }
    
    func testSetRequestBodyWithString() {
        
        let request = Request(url: NSURL(string: "http://example.com")!)
        let dataString = "Some data text"
        request.setRequestBodyWithString(dataString)
        let requestBodyAsString = NSString(data: request.requestBody!, encoding: NSUTF8StringEncoding) as? String
        
        XCTAssertEqual(requestBodyAsString, dataString)
        XCTAssertEqual(request.headers[Request.CONTENT_TYPE], Request.TEXT_PLAIN_TYPE)
    }
    
    func testSetRequestBodyWithStringAndContentHeader() {
        
        let request = Request(url: NSURL(string: "http://example.com")!, headers: ["Content-Type": "media-type"])
        let dataString = "Some data text"
        request.setRequestBodyWithString(dataString)
        let requestBodyAsString = NSString(data: request.requestBody!, encoding: NSUTF8StringEncoding) as? String
        
        XCTAssertEqual(requestBodyAsString, dataString)
        XCTAssertEqual(request.headers[Request.CONTENT_TYPE], "media-type")
    }
    
    func testSetRequestBodyWithData() {
        
        let request = Request(url: NSURL(string: "http://example.com")!)
        let requestData = "{\"key1\": \"value1\", \"key2\": \"value2\"}".dataUsingEncoding(NSUTF8StringEncoding)
        request.setRequestBodyWithData(requestData!)
        
        XCTAssertEqual(request.requestBody, requestData)
        // The setRequestBodyWithData(requestData: NSData) method should not affect the Content-Type header
    }
    
    
    
    // MARK: addQueryParameters
    
    func testAddQueryParametersWithValidParameters() {
        
        let url = NSURL(string: "http://example.com")
        let parameters = ["key1": "value1", "key2": "value2"]
        let finalUrl = String( Request.appendQueryParameters(parameters, toURL: url!) )
        
        XCTAssertEqual(finalUrl, "http://example.com?key1=value1&key2=value2")
    }
    
    func testAddQueryParametersWithRemovedQuestionMark() {
        
        let url = NSURL(string: "http://example.com?")
        
        let parameters = ["key1": "value1", "key2": "value2"]
        let finalUrl = String( Request.appendQueryParameters(parameters, toURL: url!) )
        
        XCTAssertEqual(finalUrl, "http://example.com?key1=value1&key2=value2")
    }
    
    func testAddQueryParametersWithCorrectNumberOfAmpersands() {
        
        let url = NSURL(string: "http://example.com")
        let parameters = ["k1": "v1", "k2": "v2", "k3": "v3", "k4": "v4"]
        let finalUrl = String( Request.appendQueryParameters(parameters, toURL: url!) )
        
        let numberOfAmpersands = finalUrl.componentsSeparatedByString("&")
        
        XCTAssertEqual(numberOfAmpersands.count - 1, 3)
    }
    
    func testAddQueryParametersWithReservedCharacters() {
        
        let url = NSURL(string: "http://example.com")
        let parameters = ["Reserved_characters": "\"#%<>[\\]^`{|}"]
        let finalUrl = String( Request.appendQueryParameters(parameters, toURL: url!) )
        
        XCTAssert(finalUrl.containsString("%22%23%25%3C%3E%5B%5C%5D%5E%60%7B%7C%7D"))
    }
    
}
