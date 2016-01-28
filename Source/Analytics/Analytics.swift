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
    `Analytics` provides a means of capturing analytics data and sending the data to the mobile analytics service.
*/
public class Analytics {
    
    // MARK: Properties (public)
    
    /// Determines whether analytics logs will be persisted to file.
    public static var enabled: Bool = true
    
    /// The unique ID used to send logs to the Analytics server
    public private(set) static var apiKey: String?
    
    /// The name of the iOS/WatchOS app
    public private(set) static var appName: String?
    
    
    
    // MARK: Properties (internal/private)
    
    internal static let logger = Logger.getLoggerForName(MFP_ANALYTICS_PACKAGE)
    
    // Stores metadata (including a duration timer) for each app session
    // An app session is roughly defined as the time during which an app is being used (from becoming active to going inactive)
    internal static var lifecycleEvents: [String: AnyObject] = [:]
    
    
    
    // MARK: Methods (public)
    
    /**
        The required initializer for the `Analytics` class. 
    
        This method must be called before sending `Analytics` or `Logger` logs.
        
        - parameter appName:  The application name.  Should be consistent across platforms (e.g. Android and iOS).
        - parameter apiKey:   A unique ID used to authenticate with the MFP analytics server
    */
    public static func initializeWithAppName(appName: String, apiKey: String) {
     
        // TODO: Add parameter for analytics events
        
        // Any required properties here should be checked for initialization in the private initializer
        if !appName.isEmpty {
            Analytics.appName = appName
        }
        if !apiKey.isEmpty {
            Analytics.apiKey = apiKey
        }
    }
    
    
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
        
        let startTime = Int(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
        
        lifecycleEvents[KEY_METADATA_CATEGORY] = TAG_CATEGORY_APP_SESSION
        lifecycleEvents[KEY_EVENT_START_TIME] = startTime
        lifecycleEvents[KEY_METADATA_SESSIONID] = NSUUID().UUIDString
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
        if let startTime = lifecycleEvents[KEY_EVENT_START_TIME] as? Int {
            let sessionDuration = Int(NSDate.timeIntervalSinceReferenceDate() * 1000) - startTime
            lifecycleEvents[KEY_METADATA_DURATION] = sessionDuration
            lifecycleEvents.removeValueForKey(KEY_EVENT_START_TIME)
            
            // Let the Analytics service know how the app was last closed
            if Logger.isUncaughtExceptionDetected {
                lifecycleEvents[KEY_METADATA_CLOSEDBY] = AppClosedBy.CRASH.rawValue
            }
            else {
                lifecycleEvents[KEY_METADATA_CLOSEDBY] = AppClosedBy.USER.rawValue
            }
            
            logger.analytics(lifecycleEvents)
        }
        
        lifecycleEvents = [:]
    }
    
    
    // Remove the observers registered in the Analytics+iOS "startRecordingApplicationLifecycleEvents" method
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    // MARK: Request analytics
    
    // Create a JSON string containing device/app data for the Analytics server to use
    // This data gets added to a Request header
    internal static func generateOutboundRequestMetadata() -> String? {
        
        let (osVersion, model, deviceId): (String, String, String) = getDeviceInfo()
        
        // All of this data will go in a header for the request
        var requestMetadata: [String: String] = [:]
        
        requestMetadata["os"] = "ios"
        requestMetadata["brand"] = "Apple"
        requestMetadata["osVersion"] = osVersion
        requestMetadata["model"] = model
        requestMetadata["deviceID"] = deviceId
        requestMetadata["mfpAppName"] = Analytics.appName
        requestMetadata["appStoreLabel"] = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String ?? ""
        requestMetadata["appStoreId"] = NSBundle.mainBundle().bundleIdentifier ?? ""
        requestMetadata["appVersionCode"] = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String ?? ""
        requestMetadata["appVersionDisplay"] = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? ""
        
        var requestMetadataString: String?
        do {
            let requestMetadataJson = try NSJSONSerialization.dataWithJSONObject(requestMetadata, options: [])
            requestMetadataString = String(data: requestMetadataJson, encoding: NSUTF8StringEncoding)
        }
        catch let error {
            Analytics.logger.error("Failed to append analytics metadata to request. Error: \(error)")
        }
        
        return requestMetadataString
    }
    
    
    // Gather response data as JSON to be recorded in an analytics log
    internal static func generateInboundResponseMetadata(request: MFPRequest, response: Response, url: String) -> [String: AnyObject] {
        
        Analytics.logger.debug("Network response inbound")
        
        let endTime = NSDate.timeIntervalSinceReferenceDate()
        let roundTripTime = endTime - request.startTime
        let bytesSent = request.requestBody?.length ?? 0
        
        // Data for analytics logging
        var responseMetadata: [String: AnyObject] = [:]
        
        responseMetadata["$category"] = "network"
        responseMetadata["$path"] = url
        responseMetadata["$trackingId"] = request.trackingId
        responseMetadata["$outboundTimestamp"] = request.startTime
        responseMetadata["$inboundTimestamp"] = endTime
        responseMetadata["$roundTripTime"] = roundTripTime
        responseMetadata["$responseCode"] = response.statusCode
        responseMetadata["$bytesSent"] = bytesSent
        
        if (response.responseText != nil && !response.responseText!.isEmpty) {
            responseMetadata["$bytesReceived"] = response.responseText?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        }
        
        return responseMetadata
    }
    
    // Get information about the device running the app
    internal static func getDeviceInfo() -> (String, String, String) {
        
        var osVersion = ""
        var model = ""
        var deviceId = ""
        
        #if os(iOS)
            let device = UIDevice.currentDevice()
            osVersion = device.systemVersion
            deviceId = device.identifierForVendor?.UUIDString ?? "unknown"
            model = device.modelName
        #elseif os(watchOS)
            let device = WKInterfaceDevice.currentDevice()
            osVersion = device.systemVersion
            // There is no "identifierForVendor" property for Apple Watch, so we generate a random ID
            deviceId = Request.uniqueDeviceId
            model = "Apple Watch"
        #endif
        
        return (osVersion, model, deviceId)
    }
    
}

// How the last app session ended
private enum AppClosedBy: String {
    
    case USER
    case CRASH
}


// For unit testing only
internal extension Analytics {
    
    internal static func uninitialize() {
        Analytics.apiKey = nil
        Analytics.appName = nil
    }
}
