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


import WatchKit


public extension Analytics {
    
    
    /**
         Starts a timer to record the length of time the WatchOS app is being used before becoming inactive.
         This event will be recorded and sent to the Analytics console, provided that the `Analytics.enabled` property is set to `true`.
         
         This should be called in the `ExtensionDelegate applicationDidBecomeActive` method.
     */
    public static func recordApplicationDidBecomeActive() {
        
        Analytics.analyticsImplementer?.logSessionStart()
    }
    
    
    /**
         Ends the timer started by the `Analytics startRecordingApplicationLifecycleEvents` method.
         This event will be recorded and sent to the Analytics console, provided that the `Analytics.enabled` property is set to `true`.
         
         This should be called in the `ExtensionDelegate applicationWillResignActive` method.
     */
    public static func recordApplicationWillResignActive() {
        
        Analytics.analyticsImplementer?.logSessionEnd()
    }
    
}
