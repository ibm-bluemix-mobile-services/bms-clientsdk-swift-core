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


class RequestTests: XCTestCase {

    
    func testSendWithCompletionHandlerWithNoRequestBody() {
        let request = Request(url: "http://example.com", method: HttpMethod.GET)
        
        request.sendWithCompletionHandler(nil)
        XCTAssertNil(request.savedRequestBody)
        XCTAssertEqual(request.oauthFailCounter, 0)
    }

    
    func testSendWithCompletionHandlerWithRequestBody() {
        let request = Request(url: "http://example.com", headers:[Request.CONTENT_TYPE: "text/plain"], queryParameters: ["someKey": "someValue"], method: HttpMethod.GET, timeout: 10.0)
        
        let requestBody = "request data".dataUsingEncoding(NSUTF8StringEncoding)!
        // sendData() should populate the the BaseRequest.requestBody parameter, which gets assigned to savedRequestBody
        request.sendData(requestBody, completionHandler: nil)
        
        XCTAssertEqual(request.savedRequestBody, requestBody)
    }
    
}
