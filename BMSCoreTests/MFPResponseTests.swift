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

class MFPResponseTests: XCTestCase {
    

    func testInit() {
        
        let responseData = "{\"key1\": \"value1\", \"key2\": \"value2\"}".dataUsingEncoding(NSUTF8StringEncoding)
        let httpURLResponse = NSHTTPURLResponse(URL: NSURL(string: "http://example.com")!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["key": "value"])
        let testResponse = MFPResponse(responseData: responseData!, httpResponse: httpURLResponse, isRedirect: true)
        
        XCTAssertEqual(testResponse.statusCode, 200)
        XCTAssertEqual(testResponse.headers as! [String: String], ["key": "value"])
        XCTAssertEqual(testResponse.responseData, responseData)
        XCTAssertEqual(testResponse.responseText, "{\"key1\": \"value1\", \"key2\": \"value2\"}")
        XCTAssertEqual(testResponse.responseJSON as? NSDictionary, ["key1": "value1", "key2": "value2"])
        XCTAssertEqual(testResponse.httpResponse, httpURLResponse)
        XCTAssertTrue(testResponse.isSuccessful != nil && testResponse.isSuccessful!)
        XCTAssertTrue(testResponse.isRedirect != nil && testResponse.isRedirect!)
    }
    
    func testInitWithNilParameters() {
        
        let emptyResponse = MFPResponse(responseData: nil, httpResponse: nil, isRedirect: nil)
        
        XCTAssertNil(emptyResponse.statusCode)
        XCTAssertNil(emptyResponse.headers)
        XCTAssertNil(emptyResponse.responseData)
        XCTAssertNil(emptyResponse.responseText)
        XCTAssertNil(emptyResponse.responseJSON)
        XCTAssertNil(emptyResponse.httpResponse)
        XCTAssertNil(emptyResponse.isSuccessful)
        XCTAssertNil(emptyResponse.isRedirect)
    }
    
    
    
    // MARK: buildResponseWithData()
    
    func testInitWithInvalidJSON() {
        
        let responseDataWithInvalidJSON = "INVALID JSON".dataUsingEncoding(NSUTF8StringEncoding)
        let httpURLResponse = NSHTTPURLResponse(URL: NSURL(string: "http://example.com")!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["key": "value"])
        let invalidJSONResponse = MFPResponse(responseData: responseDataWithInvalidJSON!, httpResponse: httpURLResponse, isRedirect: true)
        
        XCTAssertEqual(invalidJSONResponse.responseData, responseDataWithInvalidJSON)
        XCTAssertEqual(invalidJSONResponse.responseText, "INVALID JSON")
        XCTAssertNil(invalidJSONResponse.responseJSON)
    }
    
    func testInitWithInvalidJSONAndString() {
        
        let responseDataWithInvalidJSONAndString = NSData(bytes: [0x00, 0xFF] as [UInt8], length: 2)
        let httpURLResponse = NSHTTPURLResponse(URL: NSURL(string: "http://example.com")!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["key": "value"])
        let invalidStringResponse = MFPResponse(responseData: responseDataWithInvalidJSONAndString, httpResponse: httpURLResponse, isRedirect: true)
        
        XCTAssertEqual(invalidStringResponse.responseData, responseDataWithInvalidJSONAndString)
        XCTAssertNil(invalidStringResponse.responseText)
        XCTAssertNil(invalidStringResponse.responseJSON)
    }
    
}
