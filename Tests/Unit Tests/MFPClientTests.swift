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


class MFPClientTests: XCTestCase {

    
    func testInitialization() {
        
        let clientInstance = MFPClient.sharedInstance
        XCTAssertNil(clientInstance.mfpProtocol, "MFPClient has not yet been initialized")
        XCTAssertNil(clientInstance.mfpHost, "MFPClient has not yet been initialized")
        XCTAssertNil(clientInstance.mfpPort, "MFPClient has not yet been initialized")
        
        clientInstance.initializeWithUrlComponents(mfpProtocol: "http://", mfpHost: "example.com", mfpPort: ":9080")
        XCTAssertEqual(clientInstance.mfpProtocol, "http")
        XCTAssertEqual(clientInstance.mfpHost, "example.com")
        XCTAssertEqual(clientInstance.mfpPort, "9080")
        
        // Make sure the sharedInstance singleton is persistent
        let newClientInstance = MFPClient.sharedInstance
        XCTAssertEqual(newClientInstance.mfpProtocol, "http")
        XCTAssertEqual(newClientInstance.mfpHost, "example.com")
        XCTAssertEqual(newClientInstance.mfpPort, "9080")
    }

}
