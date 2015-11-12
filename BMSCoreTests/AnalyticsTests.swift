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
    
    //Test end to end session -->
    //Test if logSessionEnd  before logSessionStart
    //Test individually
    /// Test if tag session gets removed after logSession is called
    
    func testLogSessionStartUpdatesCorrectly(){

        XCTAssertTrue(Analytics.lifecycleEvents.isEmpty)
        
        Analytics.logSessionStart()

        let oldSession = Analytics.lifecycleEvents[TAG_SESSION] as? String
        let oldStartTime = Analytics.lifecycleEvents[KEY_EVENT_START_TIME] as? Double
        
        XCTAssertNotNil(oldSession)
        XCTAssertNotNil(oldStartTime)

        Analytics.logSessionStart()

        XCTAssertNotNil(Analytics.lifecycleEvents[TAG_SESSION])

        XCTAssertTrue(Analytics.lifecycleEvents[KEY_EVENT_START_TIME] as! Double > oldStartTime!);
        XCTAssertTrue(oldSession! != Analytics.lifecycleEvents[TAG_SESSION] as! String);
    }
    
    
    

}