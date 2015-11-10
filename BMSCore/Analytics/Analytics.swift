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
    
    private static var lifecycleEvents: [String: AnyObject] = [:]
    
    private static let analyticsLogger = Logger.getLoggerForName(MFP_ANALYTICS_PACKAGE)
    
    
    
    // MARK: Methods (public)
    
    public static func log(metadata: [String: AnyObject]) {
        
        analyticsLogger.analytics(metadata)
    }
    
    public static func send(completionHandler: MfpCompletionHandler? = nil) {
    
        analyticsLogger.send(completionHandler: completionHandler)
    }
    
    
    /**
        Records the duration of the app's lifecycle from when it enters the foreground to when it goes to the background.
        This data will be sent to the Analytics server, provided that the `Analytics.enabled` property is set to `true`.

        This method should be called in the `AppDelegate didFinishLaunchingWithOptions` method.
    */
    public static func startRecordingApplicationLifecycleEvents() {
        
        // By now, the app will have already passed the "will enter foreground" event. Therefore, we must manually start the timer for the current session.
        logAppSessionBegin()
    
        // TODO: These notifications are not possible for WatchOS. Need a toggle or a separate class.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "logAppSessionBegin", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "logAppEnterBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    

    /** 
        Cease recording app lifecycle events.
    */
    public static func stopRecordingApplicationLifecycleEvents() {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    
    
    // MARK: Methods (internal/private)
    
    dynamic static private func logAppSessionBegin() {
        
        let startTime = NSDate.timeIntervalSinceReferenceDate()
        
        var logMetadata: [String: AnyObject] = [:]
        logMetadata[KEY_METADATA_CATEGORY] = TAG_CATEGORY_EVENT
        logMetadata[KEY_METADATA_TYPE] = TAG_SESSION
        logMetadata[KEY_EVENT_START_TIME] = startTime
        
        analyticsLogger.analytics(logMetadata)
        
        let sessionMetadata = [TAG_SESSION_ID: NSUUID().UUIDString]
        
        if Analytics.lifecycleEvents[TAG_SESSION] == nil {
            let startTime = NSDate.timeIntervalSinceReferenceDate() * 1000 // milliseconds
            
            Analytics.lifecycleEvents[TAG_SESSION] = sessionMetadata ?? [:]
            Analytics.lifecycleEvents[KEY_EVENT_START_TIME] = startTime
        }
        else {
            analyticsLogger.warn("App foreground event reached before the background event for the previous session was recorded.")
        }
    }
    
    
    dynamic static private func logAppEnterBackground() {
        
        guard var eventMetadata = Analytics.lifecycleEvents[TAG_SESSION] as? [String: AnyObject] else {
            analyticsLogger.warn("App background event reached before the foreground event of the same session was recorded.")
            
            return
        }
        
        if let startTime = eventMetadata[KEY_EVENT_START_TIME] as? NSTimeInterval {
            let eventDuration = NSDate.timeIntervalSinceReferenceDate() - startTime
            
            eventMetadata[KEY_METADATA_CATEGORY] = TAG_CATEGORY_EVENT
            eventMetadata[KEY_METADATA_DURATION] = eventDuration
            eventMetadata[KEY_METADATA_TYPE] = TAG_SESSION
            
            analyticsLogger.analytics(eventMetadata)
        }
        
        Analytics.lifecycleEvents.removeValueForKey(TAG_SESSION)
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}



// MARK: Constants

private let MFP_ANALYTICS_PACKAGE = "mfpsdk.analytics"

private let KEY_METADATA_CATEGORY = "$category"
private let KEY_METADATA_TYPE = "$type"
private let KEY_EVENT_START_TIME = "$startTime"
private let KEY_METADATA_DURATION = "$duration"

private let TAG_CATEGORY_EVENT = "event"
private let TAG_SESSION = "$session"
private let TAG_SESSION_ID = "$sessionId"
private let TAG_APP_STARTUP = "$startup"
