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
    
    // TODO: Should this class use a singleton? Static methods/properties seem to work fine.
    public static let sharedInstance = Analytics()
    
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
        
        let startTime = NSDate.timeIntervalSinceReferenceDate() * 1000 //milliseconds
        
        var logMetadata: [String: AnyObject] = [:]
        logMetadata[KEY_METADATA_CATEGORY] = TAG_CATEGORY_EVENT
        logMetadata[KEY_METADATA_TYPE] = TAG_SESSION
        logMetadata[KEY_EVENT_START_TIME] = startTime
        
        logger.analytics(logMetadata)
        
        let sessionMetadata = NSUUID().UUIDString
        
        if Analytics.lifecycleEvents[TAG_SESSION] != nil {
            logger.warn("The previous session did not end properly so the session will not be recorded. This new session will override the previous session.")
        }
            
        Analytics.lifecycleEvents[TAG_SESSION] = sessionMetadata
        Analytics.lifecycleEvents[KEY_EVENT_START_TIME] = startTime
        
    }
    
    
    dynamic static internal func logSessionEnd() {
        
        guard var eventMetadata = Analytics.lifecycleEvents[TAG_SESSION] as? [String: AnyObject] else {
            logger.warn("App background event reached before the foreground event of the same session was recorded.")
            Analytics.lifecycleEvents.removeValueForKey(TAG_SESSION)
            return
        }
        
        if let startTime = eventMetadata[KEY_EVENT_START_TIME] as? NSTimeInterval {
            let eventDuration = NSDate.timeIntervalSinceReferenceDate() - startTime
            
            eventMetadata[KEY_METADATA_CATEGORY] = TAG_CATEGORY_EVENT
            eventMetadata[KEY_METADATA_DURATION] = eventDuration
            eventMetadata[KEY_METADATA_TYPE] = TAG_SESSION
            
            logger.analytics(eventMetadata)
        } else {
            logger.warn("The session ended before the timer started so the current session duration cannot be recorded")
        }
        
        Analytics.lifecycleEvents.removeValueForKey(TAG_SESSION)
    }
    
    
    
    // Remove the observers registered in the Analytics+iOS "startRecordingApplicationLifecycleEvents" method
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
