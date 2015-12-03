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


import Foundation


/**
    Used in the `Logger` class, the `LogLevel` denotes the log severity.

    Lower integer raw values indicate higher severity.
*/
public enum LogLevel: Int {
    
    case None, Analytics, Fatal, Error, Warn, Info, Debug
    
    var stringValue: String {
        get {
            switch self {
            case .None:
                return "NONE"
            case .Analytics:
                return "ANALYTICS"
            case .Fatal:
                return "FATAL"
            case .Error:
                return "ERROR"
            case .Warn:
                return "WARN"
            case .Info:
                return "INFO"
            case .Debug:
                return "DEBUG"
            }
        }
    }
}



// TODO: Refactor this entire file so that it is better organized and more readable. Consider using extensions.

/**
    Logger is used to capture log messages and send them to a mobile analytics server.

    When this class's `enabled` property is set to `true` (which is the default value), logs will be persisted to a file on the client device in the following JSON format:

        {
            "timestamp"    : "17-02-2013 13:54:27:123",   // "dd-MM-yyyy hh:mm:ss:S"
            "level"        : "ERROR",                     // FATAL || ERROR || WARN || INFO || DEBUG
            "name"         : "your_logger_name",          // The name of the Logger (typically a class name or app name)
            "msg"          : "the message",               // Some log message
            "metadata"     : {"some key": "some value"},  // Additional JSON metadata (only for Analytics logging)
        }

    Logs are accumulated persistently to the log file until the file size is greater than the `Logger.maxLogStoreSize` property. At this point, half of the old logs will be deleted to make room for new log data.

    Log file data is sent to the Bluemix server when the Logger `send()` method is called, provided that the file is not empty and the BMSClient was initialized via the `initializeWithBluemixAppRoute()` method. When the log data is successfully uploaded, the persisted local log data is deleted.

    - Note: The `Logger` class sets an uncaught exception handler to log application crashes. If you wish to set your own exception handler, do so **before** calling `Logger.getLoggerForName()` or the `Logger` exception handler will be overwritten.
*/
public class Logger {
    
    
    // MARK: Properties (API)
    
    /// The name that identifies this Logger instance
    public let name: String
    
    /// Determines whether logs get written to file on the client device.
    /// Must be set to `true` to be able to send logs to the Bluemix server.
    public static var logStoreEnabled: Bool = true
    
    /// Only logs that are at or above this level will be stored and output to the console.
    /// Defaults to the `LogLevel.Debug`.
    ///
    /// Set the value to `LogLevel.None` to turn off all logging.
    public static var logLevelFilter: LogLevel = LogLevel.Debug
    
    /// The maximum file size (in bytes) for log storage.
    /// Both the Analytics and Logger log files are limited by `maxLogStoreSize`.
    public static var maxLogStoreSize: UInt64 = DEFAULT_MAX_STORE_SIZE
    
    /// If set to `false`, the internal BMSCore logs will not be displayed on the console. 
    /// However, the internal logs will continue to be written to file provided that `logStoreEnabled` is `true` and the log level surpasses the `logLevelFilter`.
    public static var sdkDebugLoggingEnabled: Bool = true
    
    /// True if the app crashed recently due to an uncaught exception.
    /// This property will be set back to `false` if the logs are sent to the server.
    public static var isUncaughtExceptionDetected: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(TAG_UNCAUGHT_EXCEPTION)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: TAG_UNCAUGHT_EXCEPTION)
        }
    }
    
    
    
    // MARK: Properties (internal/private)
    
    // Each logger instance is distinguished only by its "name" property
    internal static var loggerInstances: [String: Logger] = [:]
    
    // Internal instrumentation for troubleshooting issues in BMSCore
    // If Logger.sdkDebugLoggingEnabled is `false`, these logs will still be written to file but will not appear in the console.
    internal static let internalLogger = Logger.getLoggerForName(MFP_LOGGER_PACKAGE)
    
    
    
    // MARK: Class constants (internal/private)
    
    // By default, the dateFormater will convert to the local time zone, but we want to send the date based on UTC
    // so that logs from all clients in all timezones are normalized to the same GMT timezone.
    internal static let dateFormatter: NSDateFormatter = Logger.generateDateFormatter()
    
    private static func generateDateFormatter() -> NSDateFormatter {
        
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        formatter.timeZone = NSTimeZone(name: "GMT")
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss:SSS"
        
        return formatter
    }
    
    // Path to the log files on the client device
    internal static let logsDocumentPath: String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/"
    
    private static let fileManager = NSFileManager.defaultManager()
    
    
    
    // MARK: Dispatch queues
    
    // We use serial queues to prevent race conditions when multiple threads try to read/modify the same file
    
    private static let loggerFileIOQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.loggerFileIOQueue", DISPATCH_QUEUE_SERIAL)
    
    
    private static let analyticsFileIOQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.analyticsFileIOQueue", DISPATCH_QUEUE_SERIAL)
    
    
    private static let sendLogsToServerQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.sendLogsToServerQueue", DISPATCH_QUEUE_SERIAL)
    
    
    private static let sendAnalyticsToServerQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.sendAnalyticsToServerQueue", DISPATCH_QUEUE_SERIAL)
    
    
    private static let updateLogProfileQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.updateLogProfileQueue", DISPATCH_QUEUE_SERIAL)

    
    // Custom dispatch_sync that can incorporate throwable statements
    internal static func dispatch_sync_throwable(queue: dispatch_queue_t, block: () throws -> ()) throws {
        
        var error: ErrorType?
        dispatch_sync(queue) {
            do {
                try block()
            }
            catch let caughtError {
                error = caughtError
            }
        }
        if error != nil {
            throw error!
        }
    }
    
    

    // MARK: Initializers
    
    /**
        Create a Logger instance that will be identified by the supplied name. 
        If a Logger instance with that name already exists, the existing instance will be returned.
    
        - parameter loggerName: The name that identifies this Logger instance
    
        - returns: A Logger instance
    */
    public static func getLoggerForName(loggerName: String) -> Logger {
        if Logger.loggerInstances.isEmpty {
            // Only need to set uncaught exception handler once, when the first Logger instance is created
            captureUncaughtExceptions()
        }
        
        if let existingLogger = Logger.loggerInstances[loggerName] {
            return existingLogger
        }
        else {
            let newLogger = Logger(name: loggerName)
            Logger.loggerInstances[loggerName] = newLogger
            
            return newLogger
        }
    }
    
    
    private init(name: String) {
        self.name = name
    }
    
    
    
    // MARK: Log methods (API)
    
    /**
        Log at the Debug LogLevel.

        - parameter message: The message to log
    
        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func debug(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        
        logMessage(message, level: LogLevel.Debug, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    
    /**
        Log at the Info LogLevel.
        
        - parameter message: The message to log
        
        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func info(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
    
        logMessage(message, level: LogLevel.Info, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    
    /**
        Log at the Warn LogLevel.

        - parameter message: The message to log

        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func warn(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        
        logMessage(message, level: LogLevel.Warn, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    
    /**
        Log at the Error LogLevel.
        
        - parameter message: The message to log
        
        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func error(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        
        logMessage(message, level: LogLevel.Error, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    
    /**
        Log at the Fatal LogLevel.
        
        - parameter message: The message to log
        
        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func fatal(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        
        logMessage(message, level: LogLevel.Fatal, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    
    // Equivalent to the other log methods, but this method accepts data as JSON rather than a string
    internal func analytics(metadata: [String: AnyObject], file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        
        logMessage("", level: LogLevel.Analytics, calledFile: file, calledFunction: function, calledLineNumber: line, additionalMetadata: metadata)
    }
    

    
    // MARK: Log methods (helpers)

    // This is the master function that handles all of the logging, including level checking, printing to console, and writing to file
    // All other log functions below this one are helpers for this function
    internal func logMessage(message: String, level: LogLevel, calledFile: String, calledFunction: String, calledLineNumber: Int, additionalMetadata: [String: AnyObject]? = nil) {
        
        
        // Printing to console
        
        let group :dispatch_group_t = dispatch_group_create()
        
        
        // TODO: This should be a guard statement
        // The level must exceed the Logger.logLevelFilter, or we do nothing
        if canLogAtLevel(level) {
            // CODE REVIEW: sdkDebugLoggingEnabled should only prevent logging at Debug level
            // CODE REVIEW: self.name should check if it contains the package prefix
            if self.name == MFP_LOGGER_PACKAGE && !Logger.sdkDebugLoggingEnabled {
                // Don't show our internal logs in the console
            }
            else {
                // Print to console
                // Example: [DEBUG] [mfpsdk.logger] logMessage in Logger.swift:234 :: "Some random message"
                Logger.printLogToConsole(message, loggerName: self.name, level: level, calledFunction: calledFunction, calledFile: calledFile, calledLineNumber: calledLineNumber)
            }
        }
        else {
            return 
        }
        
        
        // Writing to file
        
        if level != LogLevel.Analytics {
            guard Logger.logStoreEnabled else {
                return
            }
        }
        
        // Get file names and the dispatch queue needed to access those files
        let (logFile, logOverflowFile, fileDispatchQueue) = getFilesForLogLevel(level)
        
        dispatch_group_async(group, fileDispatchQueue) { () -> Void in
            // Check if the log file is larger than the maxLogStoreSize. If so, move the log file to the "overflow" file, and start logging to a new log file. If an overflow file already exists, those logs get overwritten.
            if self.fileLogIsFull(logFile) {
                do {
                    try self.moveOldLogsToOverflowFile(logFile, overflowFile: logOverflowFile)
                }
                catch let error {
                    // CODE REVIEW: When logging about file operations, do not show full path, but only the file name
                    print("Log file \(logFile) is full but the old logs could not be removed. Try sending the logs. Error: \(error)")
                    return
                }
            }
            
            let timeStampString = Logger.dateFormatter.stringFromDate(NSDate())
            var logAsJsonString = self.convertLogToJson(message, level: level, timeStamp: timeStampString, additionalMetadata: additionalMetadata)
            
            guard logAsJsonString != nil else {
                let errorMessage = "Failed to write logs to file. This is likely because the analytics metadata could not be parsed."
                Logger.printLogToConsole(errorMessage, loggerName:self.name, level: .Error, calledFunction: __FUNCTION__, calledFile: __FILE__, calledLineNumber: __LINE__)
                return
            }
            
            logAsJsonString! += "," // Logs must be comma-separated
            
            Logger.writeToFile(logFile, logMessage: logAsJsonString!, loggerName: self.name)

        }
        
        // The wait is necessary to prevent race conditions - Only one operation can occur on this queue at a time
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
    }
    
    
    // Get the full path to the log file and overflow file, and get the dispatch queue that they need to be operated on.
    internal func getFilesForLogLevel(level: LogLevel) -> (String, String, dispatch_queue_t) {
        
        var logFile: String = Logger.logsDocumentPath
        var logOverflowFile: String = Logger.logsDocumentPath
        var fileDispatchQueue: dispatch_queue_t
        
        if level == LogLevel.Analytics {
            logFile += FILE_ANALYTICS_LOGS
            logOverflowFile += FILE_ANALYTICS_OVERFLOW
            fileDispatchQueue = Logger.analyticsFileIOQueue
        }
        else {
            logFile += FILE_LOGGER_LOGS
            logOverflowFile += FILE_LOGGER_OVERFLOW
            fileDispatchQueue = Logger.loggerFileIOQueue
        }
        
        return (logFile, logOverflowFile, fileDispatchQueue)
    }
    
    
    // Check if the log file size exceeds the limit set by the Logger.maxLogStoreSize property
    // Logs are actually distributed evenly between a "normal" log file and an "overflow" file, but we only care if the "normal" log file is full (half of the total maxLogStoreSize)
    internal func fileLogIsFull(logFileName: String) -> Bool {
        
        if (Logger.fileManager.fileExistsAtPath(logFileName)) {
            
            do {
                let attr : NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(logFileName)
                if let currentLogFileSize = attr?.fileSize() {
                    return currentLogFileSize > Logger.maxLogStoreSize / 2 // Divide by 2 since the total log storage gets shared between the log file and the overflow file
                }
            }
            catch let error {
                print("Cannot determine the size of file:\(logFileName) due to error: \(error). In case the file size is greater than the specified max log storage size, logs will not be written to file.")
            }
        }
        
        return false
    }
    
    
    // When the log file is full, the old logs are moved to the overflow file to make room for new logs
    internal func moveOldLogsToOverflowFile(logFile: String, overflowFile: String) throws {
        
        if Logger.fileManager.fileExistsAtPath(overflowFile) && Logger.fileManager.isDeletableFileAtPath(overflowFile) {
            try Logger.fileManager.removeItemAtPath(overflowFile)
        }
        try Logger.fileManager.moveItemAtPath(logFile, toPath: overflowFile)
    }
    
    
    // If false, logs will not print to the console and will not be written to file
    internal func canLogAtLevel(level: LogLevel) -> Bool {
        
        if level == LogLevel.Analytics && !Analytics.enabled {
            return false
        }
        if level.rawValue <= Logger.logLevelFilter.rawValue {
            return true
        }
        return false
    }
    
    
    // Convert log message and metadata into JSON format. This is the actual string that gets written to the log files.
    internal func convertLogToJson(logMessage: String, level: LogLevel, timeStamp: String, additionalMetadata: [String: AnyObject]?) -> String? {
        
        var logMetadata: [String: AnyObject] = [:]
        logMetadata["timestamp"] = timeStamp
        logMetadata["level"] = level.stringValue
        logMetadata["pkg"] = self.name
        logMetadata["msg"] = logMessage
        if additionalMetadata != nil {
            logMetadata["metadata"] = additionalMetadata! // Typically only available if the Logger.analytics method was called
        }

        let logData: NSData
        do {
            logData = try NSJSONSerialization.dataWithJSONObject(logMetadata, options: [])
        }
        catch {
            return nil
        }
        
        return String(data: logData, encoding: NSUTF8StringEncoding)
    }
    
    
    // Append log message to the end of the log file
    internal static func writeToFile(file: String, logMessage: String, loggerName: String) {
        
        if !Logger.fileManager.fileExistsAtPath(file) {
            Logger.fileManager.createFileAtPath(file, contents: nil, attributes: nil)
        }
        
        let fileHandle = NSFileHandle(forWritingAtPath: file)
        let data = logMessage.dataUsingEncoding(NSUTF8StringEncoding)
        if fileHandle != nil && data != nil {
            fileHandle!.seekToEndOfFile()
            fileHandle!.writeData(data!)
            fileHandle!.closeFile()
        }
        else {
            let errorMessage = "Cannot write to file: \(file)."
            printLogToConsole(errorMessage, loggerName: loggerName, level: LogLevel.Error, calledFunction: __FUNCTION__, calledFile: __FILE__, calledLineNumber: __LINE__)
        }
         
    }
    
    
    // Format: [DEBUG] [mfpsdk.logger] logMessage in Logger.swift:234 :: "Some random message"
    internal static func printLogToConsole(logMessage: String, loggerName: String, level: LogLevel, calledFunction: String, calledFile: String, calledLineNumber: Int) {
        
        if level != LogLevel.Analytics {
            print("[\(level.stringValue)] [\(loggerName)] \(calledFunction) in \(calledFile):\(calledLineNumber) :: \(logMessage)")
        }
    }
    
    
    
    // MARK: Uncaught Exceptions
    
    // If the user set their own uncaught exception handler earlier, it gets stored here
    internal static let existingUncaughtExceptionHandler = NSGetUncaughtExceptionHandler()
    
    // This flag prevents infinite loops of uncaught exceptions
    private static var exceptionHasBeenCalled = false
    
    internal static func captureUncaughtExceptions() {
        
        NSSetUncaughtExceptionHandler { (caughtException: NSException) -> Void in
            
            if (!Logger.exceptionHasBeenCalled) {
                Logger.exceptionHasBeenCalled = true
                Logger.logException(caughtException)
                // Persist a flag so that when the app starts back up, we can see if an exception occurred in the last session
                Logger.isUncaughtExceptionDetected = true
                Logger.existingUncaughtExceptionHandler?(caughtException)
            }
        }
    }
    
    
    internal static func logException(exception: NSException) {
        
        let logger = Logger.getLoggerForName(MFP_LOGGER_PACKAGE)
        var exceptionString = "Uncaught Exception: \(exception.name)."
        if let reason = exception.reason {
            exceptionString += " Reason: \(reason)."
        }
        logger.fatal(exceptionString)
    }
    
    
    
    // MARK: Sending logs
    
    
    /**
        Send the accumulated logs to the Bluemix server.
        
        Logger logs can only be sent if the BMSClient was initialized via the `initializeWithBluemixAppRoute()` method.
        
        - parameter completionHandler:  Optional callback containing the results of the send request
    */
    public static func send(completionHandler userCallback: MfpCompletionHandler? = nil) {

        let logSendCallback: MfpCompletionHandler = { (response: Response?, error: NSError?) in
            if error != nil {
                Logger.internalLogger.debug("Client logs successfully sent to the server.")
                // Remove the uncaught exception flag since the logs containing the exception(s) have just been sent to the server
                NSUserDefaults.standardUserDefaults().setBool(false, forKey: TAG_UNCAUGHT_EXCEPTION)
                deleteBufferFile(FILE_LOGGER_SEND)
                Logger.isUncaughtExceptionDetected = false
            }
            else {
                Logger.internalLogger.error("Request to send client logs has failed.")
            }
            
            userCallback?(response, error)
        }
        
        // Use a serial queue to ensure that the same logs do not get sent more than once
        dispatch_async(Logger.sendLogsToServerQueue) { () -> Void in
            do {
                let logsToSend: String? = try getLogs(fileName: FILE_LOGGER_LOGS, overflowFileName: FILE_LOGGER_OVERFLOW, bufferFileName: FILE_LOGGER_SEND)
                if logsToSend != nil {
                    if let (request, logPayload) = buildLogSendRequest(logsToSend!, withCallback: logSendCallback){
                        // Everything went as expected, so send the logs!
                        request.sendString(logPayload, withCompletionHandler: logSendCallback)
                    }
                    
                }
                else {
                    Logger.internalLogger.info("There are no logs to send.")
                }
            }
            catch let error as NSError {
                logSendCallback(nil, error)
            }
        }
    }
    
    
    // Same as the other send() method but for analytics
    internal static func sendAnalytics(completionHandler userCallback: MfpCompletionHandler? = nil) {
    
        // Internal completion handler - wraps around the user supplied completion handler (if supplied)
        let analyticsSendCallback: MfpCompletionHandler = { (response: Response?, error: NSError?) in
            if error != nil {
                Analytics.logger.debug("Analytics data successfully sent to the server.")
           deleteBufferFile(FILE_ANALYTICS_SEND)
            }
            else {
                Analytics.logger.error("Request to send analytics data to the server has failed.")
            }
            
            userCallback?(response, error)
        }
        
        // Use a serial queue to ensure that the same analytics data do not get sent more than once
        dispatch_async(Logger.sendAnalyticsToServerQueue) { () -> Void in
            do {
                let logsToSend: String? = try getLogs(fileName: FILE_ANALYTICS_LOGS, overflowFileName:FILE_ANALYTICS_OVERFLOW, bufferFileName: FILE_ANALYTICS_SEND)
                if logsToSend != nil {
                    if let (request, logPayload) = buildLogSendRequest(logsToSend!, withCallback: analyticsSendCallback){
                        request.sendString(logPayload, withCompletionHandler: analyticsSendCallback)
                    }

                }
                else {
                    Analytics.logger.info("There are no analytics data to send.")
                }
            }
            catch let error as NSError {
                analyticsSendCallback(nil, error)
            }
        }
    }
    
    
    // Build the Request object that will be used to send the logs to the server
    internal static func buildLogSendRequest(logs: String, withCallback callback: MfpCompletionHandler) -> (Request, String)?{
        
        let bmsClient = BMSClient.sharedInstance
        
        guard var appRoute = bmsClient.bluemixAppRoute else {
            returnClientInitializationError("bluemixAppRoute", callback: callback)
            return nil
        }
        guard let appGuid = bmsClient.bluemixAppGUID else {
            returnClientInitializationError("bluemixAppGUID", callback: callback)
            return nil
        }
        
        if appRoute[appRoute.endIndex.predecessor()] != "/" {
            appRoute += "/"
        }
        let logUploadPath = UPLOAD_PATH
        let logUploaderUrl = appRoute + logUploadPath + appGuid
        
        var headers = ["Content-Type": "application/json"]
        if let rewriteDomain = bmsClient.rewriteDomain {
            headers[REWRITE_DOMAIN_HEADER_NAME] = rewriteDomain
        }
        
        let logPayload = "[" + logs + "]"
        
        let request = Request(url: logUploaderUrl, headers: headers, queryParameters: nil, method: HttpMethod.POST)
        return (request, logPayload)
    }
    
    
    // If this is reached, the user most likely did not call BMSClient.initializeWithBluemixAppRoute() method
    internal static func returnClientInitializationError(missingValue: String, callback: MfpCompletionHandler) {
        
        Logger.internalLogger.error("No value found for the BMSClient \(missingValue) property.")
        let errorMessage = "Must initialize BMSClient before sending logs to the server."
        let error = NSError(domain: MFP_CORE_ERROR_DOMAIN, code: MFPErrorCode.ClientNotInitialized.rawValue, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        
        callback(nil, error)
    }
    
    
    // Read the logs from file, move them to the "send" buffer file, and return the logs
    internal static func getLogs(fileName fileName: String, overflowFileName: String, bufferFileName: String) throws -> String? {
        
        let logFile = Logger.logsDocumentPath + fileName // Original log file
        let overflowLogFile = Logger.logsDocumentPath + overflowFileName // Extra file in case original log file got full
        let bufferLogFile = Logger.logsDocumentPath + bufferFileName // Temporary file for sending logs
        
        // First check if the "*.log.send" buffer file already contains logs. This will be the case if the previous attempt to send logs failed.
        if Logger.fileManager.isReadableFileAtPath(bufferLogFile) {
            return try readLogsFromFile(bufferLogFile)
        }
        else if Logger.fileManager.isReadableFileAtPath(logFile) {
            // Merge the logs from the normal log file and the overflow log file (if necessary)
            if Logger.fileManager.isReadableFileAtPath(overflowLogFile) {
                let fileContents = try NSString(contentsOfFile: overflowLogFile, encoding: NSUTF8StringEncoding) as String
                writeToFile(logFile, logMessage: fileContents, loggerName: Logger.internalLogger.name)
            }
            
            // Since the buffer log is empty, we move the log file to the buffer file in preparation of sending the logs. When new logs are recorded, a new log file gets created to replace it.
            try Logger.fileManager.moveItemAtPath(logFile, toPath: bufferLogFile)
            return try readLogsFromFile(bufferLogFile)
        }
        else {
            Logger.internalLogger.error("Cannot send data to server. Unable to read file: \(fileName).")
            return nil
        }
    }
    
    
    // We should only be sending logs from a buffer file, which is a copy of the normal log file. This way, if the logs fail to get sent to the server, we can hold onto them until the send succeeds, while continuing to log to the normal log file.
    internal static func readLogsFromFile(bufferLogFile: String) throws -> String? {
        
        let ANALYTICS_SEND = Logger.logsDocumentPath + FILE_ANALYTICS_SEND
        let LOGGER_SEND = Logger.logsDocumentPath + FILE_LOGGER_SEND
        

        var fileContents: String?
        
        do {
            // Before sending the logs, we need to read them from the file. This is done in a serial dispatch queue to prevent conflicts if the log file is simulatenously being written to.
            switch bufferLogFile {
            case ANALYTICS_SEND:
                try dispatch_sync_throwable(Logger.analyticsFileIOQueue, block: { () -> () in
                    fileContents = try NSString(contentsOfFile: bufferLogFile, encoding: NSUTF8StringEncoding) as String
                })
            case LOGGER_SEND:
                try dispatch_sync_throwable(Logger.loggerFileIOQueue, block: { () -> () in
                    fileContents = try NSString(contentsOfFile: bufferLogFile, encoding: NSUTF8StringEncoding) as String
                })
            default:
                Logger.internalLogger.error("Cannot send data to server. Unrecognized file: \(bufferLogFile).")
            }
        }
        
        return fileContents
    }
    
    
    // The buffer file is typically the one used for storing logs that will be sent to the server
    internal static func deleteBufferFile(bufferFile: String) {
        
        if Logger.fileManager.isDeletableFileAtPath(bufferFile) {
            do {
                try Logger.fileManager.removeItemAtPath(bufferFile)
            }
            catch let error {
                Logger.internalLogger.error("Failed to delete log file \(bufferFile) after sending. Error: \(error)")
            }
        }
    }
    
    
    
    // MARK: Server configuration
    
    // TODO: Implement once the behavior of this method has been determined
    public func updateLogProfile(withCompletionHandler callback: MfpCompletionHandler? = nil) { }

}
