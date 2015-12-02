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


/**
    `Analytics` provides a means of capturing analytics data and sending the data to the Bluemix server.

    When this class's `enabled` property is set to `true` (which is the default value), all analytics data will be persisted to a file on the client device in the following JSON format:

        {
            "timestamp"    : "17-02-2013 13:54:27:123",     // "dd-MM-yyyy hh:mm:ss:S"
            "level"        : "ANALYTICS",
            "pkg"          : "mfpsdk.analytics",
            "msg"          : "",                            // Always an empty string for Analytics logs
            "metadata"     : {"some key": "some value"}     // Analytics data
        }

    Analytics data are accumulated persistently to the log file until the file size is greater than the `Logger.maxLogStoreSize` property. At this point, half of the old logs will be deleted to make room for new log data.

    Log file data is sent to the Bluemix server when this class's send() method is called, provided that the file is not empty and the BMSClient was initialized via the `initializeWithBluemixAppRoute()` method. When the log data is successfully uploaded, the persisted local log data is deleted.
*/
public class Analytics {
    
    
    // MARK: Properties (public)
    
    /// Determines whether analytics logs will be persisted to file.
    public static var enabled: Bool = true
    
    
    
    // MARK: Properties (internal/private)
    
    internal static let logger = Logger.getLoggerForName(MFP_ANALYTICS_PACKAGE)
    
    // Stores metadata (including a duration timer) for each app session
    // An app session is roughly defined as the time during which an app is being used (from becoming active to going inactive)
    internal static var lifecycleEvents: [String: AnyObject] = [:]
    
    
    
    // MARK: Methods (public)
    
    /**
        Write analytics data to file. 
    
        Similar to the `Logger` class logging methods, old logs will be removed if the file size exceeds the `Logger.maxLogStoreSize` property.
    
        When ready, use the `Analytics.send()` method to send the logs to the Bluemix server.
    
         - parameter metadata:  The analytics data
    */
    public static func log(metadata: [String: AnyObject]) {
        
        logger.analytics(metadata)
    }
    
    
    /**
        Send the accumulated analytics logs to the Bluemix server.
    
        Analytics logs can only be sent if the BMSClient was initialized via the `initializeWithBluemixAppRoute()` method.
        
        - parameter completionHandler:  Optional callback containing the results of the send request
    */
    public static func send(completionHandler: MfpCompletionHandler? = nil) {
        
        Logger.sendAnalytics(completionHandler: completionHandler)
    }
    
    
    // Log that the app is starting a new session, and start a timer to record the session duration
    // This method should be called when the app starts up.
    //      In iOS, this occurs when the app is about to enter the foreground.
    //      In WatchOS, the user decides when this method is executed, but we recommend calling it when the app becomes active.
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
    
    
    // Log that the app session is ending, and use the timer from logSessionStart() to record the duration of this session
    // This method should be called when the closes.
    //      In iOS, this occurs when the app enters the background.
    //      In WatchOS, the user decides when this method is executed, but we recommend calling it when the app becomes active.
    dynamic static internal func logSessionEnd() {
        
        // logSessionStart() must have been called first so that we can get the session start time
        guard !lifecycleEvents.isEmpty else {
            logger.warn("The current app session ended before the start event was triggered, so the session cannot be recorded.")
            return
        }
        
        // If the guard statement above passes, this if statement should always succeed
        if let startTime = lifecycleEvents[KEY_EVENT_START_TIME] as? NSTimeInterval {
            let sessionDuration = NSDate.timeIntervalSinceReferenceDate() - startTime
            lifecycleEvents[KEY_METADATA_DURATION] = sessionDuration
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
