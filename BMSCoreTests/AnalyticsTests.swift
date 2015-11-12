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

class AnalyticsTests: XCTestCase {
    
    override func tearDown() {
        Analytics.lifecycleEvents = [:]
    }
    
    func testLogSessionStartUpdatesCorrectly(){

        XCTAssertTrue(Analytics.lifecycleEvents.isEmpty)
        
        Analytics.logSessionStart()

        let firstSession = Analytics.lifecycleEvents[TAG_SESSION] as? String
        let originalStartTime = Analytics.lifecycleEvents[KEY_EVENT_START_TIME] as? Double
        
        XCTAssertNotNil(firstSession)
        XCTAssertNotNil(originalStartTime)

        Analytics.logSessionStart()

        XCTAssertNotNil(Analytics.lifecycleEvents[TAG_SESSION])

        XCTAssertTrue(Analytics.lifecycleEvents[KEY_EVENT_START_TIME] as! Double > originalStartTime!);
        XCTAssertTrue(firstSession! != Analytics.lifecycleEvents[TAG_SESSION] as! String);
    
    }
    
    func testLogSessionAfterCompleteSession(){
        
        XCTAssertTrue(Analytics.lifecycleEvents.isEmpty)
        
        Analytics.logSessionStart()
        
        let firstSession = Analytics.lifecycleEvents[TAG_SESSION] as? String
        let originalStartTime = Analytics.lifecycleEvents[KEY_EVENT_START_TIME] as? Double
        
        XCTAssertNotNil(firstSession)
        XCTAssertNotNil(originalStartTime)
        
        Analytics.logSessionEnd()
        
        XCTAssertNil(Analytics.lifecycleEvents[TAG_SESSION])
        
        Analytics.logSessionStart()
        
        XCTAssertTrue(Analytics.lifecycleEvents[KEY_EVENT_START_TIME] as! Double > originalStartTime!);
        XCTAssertTrue(firstSession! != Analytics.lifecycleEvents[TAG_SESSION] as! String);
    
    }
    
    func testlogSessionEndBeforeLogSessionStart(){
        
        XCTAssertTrue(Analytics.lifecycleEvents.isEmpty)
        
        Analytics.logSessionEnd()
        
        XCTAssertNil(Analytics.lifecycleEvents[TAG_SESSION])
        XCTAssertNil(Analytics.lifecycleEvents[KEY_EVENT_START_TIME])
        
        Analytics.logSessionStart()
    
        let session = Analytics.lifecycleEvents[TAG_SESSION] as? String
        let startTime = Analytics.lifecycleEvents[KEY_EVENT_START_TIME] as? Double
        
        XCTAssertNotNil(session)
        XCTAssertNotNil(startTime)
    
        
    }
    
    

}