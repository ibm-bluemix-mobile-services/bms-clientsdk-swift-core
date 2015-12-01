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


public class Analytics {
    
    
    // MARK: Properties (public)
    
    public static var enabled: Bool = true
    
    
    
    // MARK: Properties (internal/private)
    
    internal static let logger = Logger.getLoggerForName(MFP_ANALYTICS_PACKAGE)
    
    internal static var lifecycleEvents: [String: AnyObject] = [:]
    
    
    
    // MARK: Methods (public)
    
    public static func log(metadata: [String: AnyObject]) {
        
        logger.analytics(metadata)
    }
    
    
    public static func send(completionHandler: MfpCompletionHandler? = nil) {
        
        Logger.sendAnalytics(completionHandler: completionHandler)
    }
    
    
    dynamic static internal func logSessionStart() {
        
        if !lifecycleEvents.isEmpty {
            logger.warn("The previous session did not end properly so the session will not be recorded. This new session will override the previous session.")
        }
        
        let startTime = NSDate.timeIntervalSinceReferenceDate() * 1000 // milliseconds
        
        lifecycleEvents[KEY_METADATA_CATEGORY] = TAG_CATEGORY_EVENT
        lifecycleEvents[KEY_METADATA_TYPE] = TAG_SESSION
        lifecycleEvents[KEY_EVENT_START_TIME] = startTime
        
        // CODE REVIEW: Is there a reason this key/value pair is set after logging in the Android SDK?
        lifecycleEvents[KEY_SESSION_ID] = NSUUID().UUIDString
    
        logger.analytics(Analytics.lifecycleEvents)
    }
    
    
    dynamic static internal func logSessionEnd() {
        
        guard !lifecycleEvents.isEmpty else {
            logger.warn("The current app session ended before the start event was triggered, so the session cannot be recorded.")
            return
        }
        
        if let startTime = lifecycleEvents[KEY_EVENT_START_TIME] as? NSTimeInterval {
            let eventDuration = NSDate.timeIntervalSinceReferenceDate() - startTime
            lifecycleEvents[KEY_METADATA_DURATION] = eventDuration
            lifecycleEvents.removeValueForKey(KEY_EVENT_START_TIME)
            
            logger.analytics(lifecycleEvents)
        }
        
        lifecycleEvents = [:]
    }
    
    
    
    // Remove the observers registered in the Analytics+iOS "startRecordingApplicationLifecycleEvents" method
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
