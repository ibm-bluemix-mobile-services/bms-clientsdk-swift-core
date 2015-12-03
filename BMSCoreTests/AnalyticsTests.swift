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
    
    /**
        1) Call logSessionStart(), which should update Analytics.lifecycleEvents.
        2) Call logSessionStart() again. This should cause Analytics.lifecycleEvents to be updated:
            - The original start time (KEY_EVENT_START_TIME) should be replaced with the new start time.
            - The session (TAG_SESSION) is a unique ID that should contain a different value each time logSessionStart()
                is called.
    */
    func testLogSessionStartUpdatesCorrectly() {

        XCTAssertTrue(Analytics.lifecycleEvents.isEmpty)
        
        Analytics.logSessionStart()

        let firstSessionStartTime = Analytics.lifecycleEvents[KEY_EVENT_START_TIME] as? NSTimeInterval
        
        XCTAssertNotNil(firstSessionStartTime)

        Analytics.logSessionStart()

        XCTAssertNotNil(Analytics.lifecycleEvents)

        XCTAssertTrue(Analytics.lifecycleEvents[KEY_EVENT_START_TIME] as? NSTimeInterval > firstSessionStartTime);
    }
    
    /**
        1) Call logSessionStart(), which should update Analytics.lifecycleEvents.
        2) Call logSessionEnd(). This should reset Analytics.lifecycleEvents by removing the session ID.
        3) Call logSessionStart() again. This should cause Analytics.lifecycleEvents to be updated:
            - The original start time (KEY_EVENT_START_TIME) should be replaced with the new start time.
            - The session (TAG_SESSION) is a unique ID that should contain a different value each time logSessionStart()
                is called.
    */
    func testLogSessionAfterCompleteSession() {
        
        XCTAssertTrue(Analytics.lifecycleEvents.isEmpty)
        
        Analytics.logSessionStart()
        
        let firstSessionStartTime = Analytics.lifecycleEvents[KEY_EVENT_START_TIME] as? NSTimeInterval
        
        XCTAssertNotNil(firstSessionStartTime)
        
        Analytics.logSessionEnd()
        
        XCTAssertNil(Analytics.lifecycleEvents[TAG_SESSION])
        
        Analytics.logSessionStart()
        
        XCTAssertTrue(Analytics.lifecycleEvents[KEY_EVENT_START_TIME] as? NSTimeInterval > firstSessionStartTime);
    }
    
    /**
        1) Call logSessionEnd(). This should have no effect since logSessionStart() was never called.
        2) Call logSessionStart() again. This should cause Analytics.lifecycleEvents to be updated,
            - The original start time (KEY_EVENT_START_TIME) should be replaced with the new start time.
            - The session (TAG_SESSION) is a unique ID that should contain a different value each time logSessionStart()
                is called.
    */
    func testlogSessionEndBeforeLogSessionStart() {
        
        XCTAssertTrue(Analytics.lifecycleEvents.isEmpty)
        
        Analytics.logSessionEnd()
        
        XCTAssertTrue(Analytics.lifecycleEvents.isEmpty)
        
        Analytics.logSessionStart()
    
        let sessionStartTime = Analytics.lifecycleEvents[KEY_EVENT_START_TIME] as? NSTimeInterval
        
        XCTAssertNotNil(sessionStartTime)
    
        
    }
    
    

}