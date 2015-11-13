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


public enum LogLevel: Int {
    
    case Analytics = 1, Fatal, Error, Warn, Info, Debug, None
}


public class Logger {
    
    
    // MARK: API (properties)
    
    public let name: String
    
    public static var logStoreEnabled: Bool = true
    
    public static var logLevel: LogLevel {
        get {
            let level = NSUserDefaults.standardUserDefaults().integerForKey(TAG_LOG_LEVEL)
            if level >= LogLevel.Analytics.rawValue && level <= LogLevel.None.rawValue {
                return LogLevel(rawValue: level)! // The above condition guarantees a non-nil LogLevel
            }
            else {
                return LogLevel.Debug
            }
        }
        set {
            NSUserDefaults.standardUserDefaults().setInteger(newValue.rawValue, forKey: TAG_LOG_LEVEL)
        }
    }
    
    public static var maxLogStoreSize: Int {
        get {
            return NSUserDefaults.standardUserDefaults().integerForKey(TAG_MAX_STORE_SIZE) ?? DEFAULT_MAX_STORE_SIZE
        }
        set {
            NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: TAG_MAX_STORE_SIZE)
        }
    }
    
    public static var uncaughtExceptionDetected: Bool {
        get {
            return false
        }
    }
    
    public static var internalSDKLoggingEnabled: Bool {
        get {
            return true
        }
        set {
            
        }
    }
    
    
    
    // MARK: API (methods)
    
    // Initializers
    
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
    
    
    // Log methods
    
    public func debug(message: String, error: ErrorType? = nil) { }
    
    public func info(message: String, error: ErrorType? = nil) { }
    
    public func warn(message: String, error: ErrorType? = nil) { }
    
    public func error(message: String, error: ErrorType? = nil) { }
    
    public func fatal(message: String, error: ErrorType? = nil) { }
    
    internal func analytics(metadata: [String: AnyObject], error: ErrorType? = nil) { }
    
    
    
    // Server communication
    
    public func send(completionHandler callback: MfpCompletionHandler? = nil) { }
    
    public func updateLogProfile(withCompletionHandler callback: MfpCompletionHandler? = nil) { }
    
    
    
    // Uncaught Exceptions
    
    // TODO: Make this private, and just document it? It looks like this is not part of the API in Android anyway.
    // TODO: In documentation, explain that developer must not set their own uncaught exception handler or this one will be overwritten
    private static func captureUncaughtExceptions() {
        
        NSSetUncaughtExceptionHandler { (caughtException: NSException) -> Void in
            
            // Persist a flag so that when the app starts back up, we can see if an exception occurred in the last session
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: TAG_UNCAUGHT_EXCEPTION)
            
            Logger.logException(caughtException)
            existingUncaughtExceptionHandler?(caughtException)
        }
    }
    
    
    private static func logException(exception: NSException) {
        
        let logger = Logger.getLoggerForName(MFP_LOGGER_PACKAGE)
        var exceptionString = "Uncaught Exception: \(exception.name)."
        if let reason = exception.reason {
            exceptionString += " Reason: \(reason)."
        }
        logger.fatal(exceptionString)
    }
    
    
    
    // MARK: Properties (internal/private)
    
    private static var loggerInstances: [String: Logger] = [:]
    
    
    
    // MARK: Class constants
    
    // By default, the dateFormater will convert to the local time zone, but we want to send the date based on UTC
    // so that logs from all clients in all timezones are normalized to the same GMT timezone.
    private static let dateFormatter: NSDateFormatter = Logger.generateDateFormatter()
    
    private static func generateDateFormatter() -> NSDateFormatter {
        
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        formatter.timeZone = NSTimeZone(name: "GMT")
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss:SSS"
        
        return formatter
    }

    
    private static let logsDocumentPath: String = Logger.generateLogDocumentPath()
    
    private static func generateLogDocumentPath() -> String {
        
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        return paths[0]
    }
    
    private static let writeLogsToFileQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.writeLogsToFileQueue", DISPATCH_QUEUE_SERIAL)
    
    private static let sendLogsToServerQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.sendLogsToServerQueue", DISPATCH_QUEUE_SERIAL)
    
    private static let updateLogProfileQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.updateLogProfileQueue", DISPATCH_QUEUE_SERIAL)

    
    
    // MARK: Methods (internal/private)
    
    private init(name: String) {
        self.name = name
    }

}


let existingUncaughtExceptionHandler = NSGetUncaughtExceptionHandler()


// MARK: FOUNDATION SDK

//
//@implementation OCLogger
//
//
//+(void) sendFileToServer:(NSData*)file withRequestDelegate:(id<WLRequestDelegate>)requestDelegate andUserDelegate:(id<WLDelegate>)userDelegate
//{
//    @synchronized (self) {
//        NSString* dataString = [[NSString alloc] initWithData:file encoding:NSUTF8StringEncoding];
//        
//        // build request options
//        WLRequestOptions *requestOptions = [[WLRequestOptions alloc] init];
//        [requestOptions setMethod:POST];
//        [requestOptions setParameters:@{@"__logdata": dataString}];
//        requestOptions.compress = TRUE;
//        
//        if (userDelegate != nil) {
//            [requestOptions setUserInfo:@{@"userSendLogsDelegate" : userDelegate}];
//        }
//        
//        NSMutableDictionary* headers = [NSMutableDictionary new];
//        
//        NSDictionary* deviceInfo = [OCLogger getDeviceInformation];
//        for(NSString* key in deviceInfo){
//            NSString *headerName = [NSString stringWithFormat:@"%@%@", @"x-wl-clientlog-", key];
//            [headers setObject:[deviceInfo valueForKey:key] forKey:headerName];
//        }
//        
//        [requestOptions setHeaders:headers];
//        
//        WLRequest *sendFileRequest = [[WLRequest alloc] initWithDelegate:requestDelegate];
//        [sendFileRequest makeRequestForRootUrl:@"/apps/services/loguploader" withOptions:requestOptions];
//        
//    }
//}
//
//+(void) send{
//    @synchronized (self) {
//        if(!logInFlight){
//            logInFlight = 1;
//            NSData *dataToSend = [OCLogger getDataFromLogFile];
//            
//            if(dataToSend != nil){
//                SendLogsDelegate *sendLogsDelegate = [SendLogsDelegate new];
//                [OCLogger sendFileToServer:dataToSend withRequestDelegate:sendLogsDelegate andUserDelegate:nil];
//            }
//        }
//        
//    }
//}
//
//+(void) sendWithDelegate:(id<WLDelegate>)userSendLogsDelegate{
//    @synchronized (self) {
//        NSData *dataToSend = [OCLogger getDataFromLogFile];
//        
//        if(dataToSend != nil){
//            SendLogsDelegate *sendLogsDelegate = [SendLogsDelegate new];
//            [OCLogger sendFileToServer:dataToSend withRequestDelegate:sendLogsDelegate andUserDelegate:userSendLogsDelegate];
//        }
//    }
//}
//
//+(void) sendAnalytics{
//    @synchronized (self) {
//        NSData *dataToSend = [OCLogger getDataFromAnalyticsFile];
//        
//        if(dataToSend != nil){
//            SendAnalyticsDelegate *sendAnalyticsDelegate = [SendAnalyticsDelegate new];
//            [OCLogger sendFileToServer:dataToSend withRequestDelegate:sendAnalyticsDelegate andUserDelegate:nil];
//        }
//    }
//}
//
//+(void) sendAnalyticsWithDelegate:(id<WLDelegate>)userSendAnalyticsDelegate{
//    @synchronized (self) {
//        NSData *dataToSend = [OCLogger getDataFromAnalyticsFile];
//        
//        if(dataToSend != nil){
//            SendAnalyticsDelegate *sendLogsDelegate = [SendAnalyticsDelegate new];
//            [OCLogger sendFileToServer:dataToSend withRequestDelegate:sendLogsDelegate andUserDelegate:userSendAnalyticsDelegate];
//        }
//    }
//}
//
//+(void) updateConfigFromServer{
//    @synchronized (self) {
//        WLRequestOptions *requestOptions = [[WLRequestOptions alloc] init];
//        [requestOptions setMethod:POST];
//        
//        NSMutableDictionary* headers = [NSMutableDictionary new];
//        
//        NSDictionary* deviceInfo = [OCLogger getDeviceInformation];
//        for(NSString* key in deviceInfo){
//            NSString *headerName = [NSString stringWithFormat:@"%@%@", @"x-wl-clientlog-", key];
//            [headers setObject:[deviceInfo valueForKey:key] forKey:headerName];
//        }
//        
//        [requestOptions setHeaders:headers];
//        
//        UpdateConfigDelegate *updateConfigDelegate = [UpdateConfigDelegate new];
//        WLRequest *updateConfigRequest = [(WLRequest *)[WLRequest alloc] initWithDelegate:updateConfigDelegate];
//        [updateConfigRequest makeRequestForRootUrl:CONFIG_URI_PATH withOptions:requestOptions];
//    }
//}
//
//+(void) processUpdateConfigFromServer:(int)statusCode withResponse:(NSString*)responseString
//{
//    @synchronized (self) {
//        NSDictionary* parsedResponse = [OCLoggerWorklight parseWorklightServerResponse:responseString];
//        
//        if(statusCode == HTTP_SC_OK){
//            NSLog(@"[DEBUG] [OCLogger] Logger configuration successfully retrieved from the server.");
//            [OCLogger processConfigResponseFromServer:parsedResponse];
//            
//        }else if(statusCode == HTTP_SC_NO_CONTENT){
//            NSLog(@"[DEBUG] [OCLogger] No matching client configuration profiles were found at the IBM MobileFirst Platform server. Logger now using local configurations.");
//            [OCLogger clearServerConfig];
//            
//        }
//    }
//}
//
//
//-(void) logWithLevel:(OCLogType)level message:(NSString*) message args:(va_list) arguments userInfo:(NSDictionary*) userInfo
//{
//    [OCLogger logWithLevel:(OCLogType)level
//        andPackage:self.package
//        andText:message
//        andVariableArguments:arguments
//        andSkipLevelCheck:NO
//        andTimestamp:[NSDate date]
//        andMetadata:userInfo];
//}
//
//#pragma mark - Private Methods
//
//+(void) logWithLevel: (OCLogType) level
//andPackage: (NSString*) package
//andText: (NSString*) text
//andVariableArguments: (va_list) args
//andSkipLevelCheck: (BOOL) skipLevelFlag
//andTimestamp: (NSDate*) timestamp
//andMetadata:(NSDictionary*) metadata
//{
//    
//    if (![self canLogWithLevel:level withPackage:package]) {
//        return;
//    }
//    
//    // TODO just make a separate method for capturing analytics instead of all the branching
//    dispatch_sync(globalLoggerQueue, ^{
//        
//        NSString* levelTag = [OCLogger getLevelTag:level];
//        
//        NSString *msg = [OCLogger getMessageWith:text andArgs:args];
//        
//        if(level != OCLogger_ANALYTICS){
//            [OCLogger printMessage:msg withMetadata:metadata andLevelTag:levelTag andPackage:package];
//        }
//        
//        if (! [OCLogger shouldCaptureLog:level]) {
//            return;
//        }
//        
//        NSString* currentLogFile;
//        
//        if(level == OCLogger_ANALYTICS){
//            currentLogFile = [OCLogger getDocumentPath:FILENAME_ANALYTICS_LOG];
//        }else{
//            currentLogFile = [OCLogger getDocumentPath:FILENAME_WL_LOG];
//        }
//        
//        if (level != OCLogger_ANALYTICS &&
//            [[NSFileManager defaultManager] fileExistsAtPath:currentLogFile] &&
//            [OCLogger isFileSize:currentLogFile greaterThan:[OCLogger getMaxFileSize]]) {
//                [OCLogger swapLogFile];
//        }
//        
//        NSString* timestampStr = [OCLogger getCurrentTimestamp:timestamp];
//        
//        NSDictionary* dict = @{TAG_PKG : package,
//            TAG_TIMESTAMP : timestampStr,
//            TAG_LEVEL : levelTag,
//            TAG_MSG : msg,
//            TAG_META_DATA: metadata
//        };
//        [OCLogger writeString:[dict WLJSONRepresentation] toLogFile:currentLogFile];
//        });
//    
//}
//
//#pragma mark - Getters and Setters
//
//
//+(void) setAutoUpdateConfigFromServer: (BOOL) flag
//{
//    // noop since 6.3.  Retained for deprecation.
//}
//
//+(BOOL) getAutoUpdateConfigFromServer{
//    return false;  // noop since 6.3.  Retained for deprecation.
//}
//
//+(void) setCapture: (BOOL) flag
//{
//    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
//    [standardUserDefaults setBool:flag forKey:TAG_CAPTURE];
//    [standardUserDefaults synchronize];
//}
//
//+(void) setServerCapture: (BOOL) flag
//{
//    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
//    [standardUserDefaults setBool:flag forKey:TAG_SERVER_CAPTURE];
//    [standardUserDefaults synchronize];
//}
//
//+(BOOL) getCapture
//    {
//        if([OCLogger shouldUseServerConfig]){
//            return [[NSUserDefaults standardUserDefaults] boolForKey:TAG_SERVER_CAPTURE];
//        }
//        
//        return [[NSUserDefaults standardUserDefaults] boolForKey:TAG_CAPTURE];
//}
//
//+(void) setAnalyticsCapture: (BOOL) flag
//{
//    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
//    [standardUserDefaults setBool:flag forKey:TAG_ANALYTICS_CAPTURE];
//    [standardUserDefaults synchronize];
//}
//
//+(BOOL) getAnalyticsCapture
//    {
//        return [[NSUserDefaults standardUserDefaults] boolForKey:TAG_ANALYTICS_CAPTURE];
//}
//
//+(void) processConfigResponseFromServer: (NSDictionary*) logConfig
//{
//    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
//    [standardUserDefaults setBool:TRUE forKey:TAG_SERVER_CAPTURE];
//    
//    NSDictionary* wllogger =[logConfig objectForKey:@"wllogger"];
//    
//    if(wllogger != nil){
//        
//        NSDictionary* filters = [wllogger objectForKey:@"filters"];
//        
//        if(filters != nil){
//            [standardUserDefaults setObject:filters forKey:TAG_SERVER_FILTERS];
//        }
//        
//        NSString* level = [wllogger objectForKey:@"level"];
//        
//        if(level != nil){
//            OCLogType serverLevel = [OCLogger getLevelType:level];
//            [standardUserDefaults setInteger:serverLevel forKey:TAG_SERVER_LOG_LEVEL];
//        }
//    }
//    
//    [standardUserDefaults synchronize];
//}
//
//+(void)clearServerConfig{
//    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
//    [standardUserDefaults removeObjectForKey:TAG_SERVER_CAPTURE];
//    [standardUserDefaults removeObjectForKey:TAG_SERVER_FILTERS];
//    [standardUserDefaults removeObjectForKey:TAG_SERVER_LOG_LEVEL];
//    [standardUserDefaults synchronize];
//}
//
//
//#pragma mark - Log Instance Methods - No Context
//
//-(void) debug: (NSString*) text, ...
//{
//    va_list args;
//    va_start(args, text);
//    
//    [OCLogger logWithLevel:OCLogger_DEBUG andPackage:self.package andText:text andVariableArguments:args andSkipLevelCheck:NO andTimestamp:[NSDate date] andMetadata:@{}];
//    
//    va_end(args);
//}
//
//-(void) info: (NSString*) text, ...
//{
//    va_list args;
//    va_start(args, text);
//    
//    [OCLogger logWithLevel:OCLogger_INFO andPackage:self.package andText:text andVariableArguments:args andSkipLevelCheck:NO andTimestamp:[NSDate date] andMetadata:@{}];
//    
//    va_end(args);
//}
//
//-(void) warn: (NSString*) text, ...
//{
//    va_list args;
//    va_start(args, text);
//    
//    [OCLogger logWithLevel:OCLogger_WARN andPackage:self.package andText:text andVariableArguments:args andSkipLevelCheck:NO andTimestamp:[NSDate date] andMetadata:@{}];
//    
//    va_end(args);
//}
//
//-(void) error: (NSString*) text, ...
//{
//    va_list args;
//    va_start(args, text);
//    
//    [OCLogger logWithLevel:OCLogger_ERROR andPackage:self.package andText:text andVariableArguments:args andSkipLevelCheck:NO andTimestamp:[NSDate date] andMetadata:@{}];
//    
//    va_end(args);
//}
//
//-(void) fatal: (NSString*) text, ...
//{
//    va_list args;
//    va_start(args, text);
//    
//    [OCLogger logWithLevel:OCLogger_FATAL andPackage:self.package andText:text andVariableArguments:args andSkipLevelCheck:NO andTimestamp:[NSDate date] andMetadata:@{}];
//    
//    va_end(args);
//}
//
//-(void) analytics: (NSString*) text, ...
//{
//    va_list args;
//    va_start(args, text);
//    
//    [OCLogger logWithLevel:OCLogger_ANALYTICS andPackage:self.package andText:text andVariableArguments:args andSkipLevelCheck:NO andTimestamp:[NSDate date] andMetadata:@{}];
//    
//    va_end(args);
//}
//
//
//#pragma mark - Helper Functions
//
//+(OCLogType) getLevelType: (NSString*) level
//{
//    level = [level stringByReplacingOccurrencesOfString:@"_" withString:@""];
//    
//    OCLogType OCLevel;
//    level = [level uppercaseString];
//    
//    if ([level isEqualToString:TAG_LABEL_LOG]) {
//        OCLevel = OCLogger_LOG;
//    } else if([level isEqualToString:TAG_LABEL_INFO]) {
//        OCLevel = OCLogger_INFO;
//    } else if([level isEqualToString:TAG_LABEL_WARN]) {
//        OCLevel = OCLogger_WARN;
//    } else if([level isEqualToString:TAG_LABEL_ERROR]) {
//        OCLevel = OCLogger_ERROR;
//    } else if([level isEqualToString:TAG_LABEL_DEBUG]) {
//        OCLevel = OCLogger_DEBUG;
//    } else if([level isEqualToString:TAG_LABEL_TRACE]) {
//        OCLevel = OCLogger_TRACE;
//    }else if([level isEqualToString:TAG_LABEL_ANALYTICS]) {
//        OCLevel = OCLogger_ANALYTICS;
//    }else{
//        OCLevel = OCLogger_FATAL;
//    }
//    
//    return OCLevel;
//}
//
//+(NSString*) getDocumentPath:(NSString*) fileName
//{
//    return [globalDocumentPath stringByAppendingPathComponent:fileName];
//}
//
//+(NSString*) getLevelTag:(OCLogType) level
//{
//    NSString* levelTag;
//    
//    switch (level) {
//    case OCLogger_LOG:
//        levelTag = TAG_LABEL_LOG;
//        break;
//        
//    case OCLogger_INFO:
//        levelTag = TAG_LABEL_INFO;
//        break;
//        
//    case OCLogger_WARN:
//        levelTag = TAG_LABEL_WARN;
//        break;
//        
//    case OCLogger_ERROR:
//        levelTag = TAG_LABEL_ERROR;
//        break;
//        
//    case OCLogger_DEBUG:
//        levelTag = TAG_LABEL_DEBUG;
//        break;
//        
//    case OCLogger_TRACE:
//        levelTag = TAG_LABEL_TRACE;
//        break;
//        
//    case OCLogger_ANALYTICS:
//        levelTag = TAG_LABEL_ANALYTICS;
//        break;
//        
//    default:
//        levelTag = TAG_LABEL_FATAL;
//        break;
//    }
//    
//    return [NSString stringWithFormat:@"%@", levelTag];
//}
//
//+(NSDictionary*) getDeviceInformation
//    {
//        UIDevice* currentDevice = [UIDevice currentDevice];
//        
//        NSDictionary* deviceInfo = @{KEY_DEVICEINFO_ENV : [OCLoggerWorklight getWorklightEnvironment],
//            KEY_DEVICEINFO_OS_VERSION : [currentDevice systemVersion],
//            KEY_DEVICEINFO_MODEL : [OCLoggerWorklight getWorklightDeviceModel],
//            KEY_DEVICEINFO_APP_NAME : [OCLoggerWorklight getWorklightApplicationName],
//            KEY_DEVICEINFO_APP_VERSION : [OCLoggerWorklight getWorklightApplicationVersion],
//            KEY_DEVICEINFO_DEVICE_ID : [OCLoggerWorklight getWorklightDeviceId]
//        };
//        
//        return deviceInfo;
//}
//
//+(void) removeCurrentLogFile
//    {
//        NSString* currentLogFile = [OCLogger getDocumentPath:FILENAME_WL_LOG];
//        NSError* error = nil;
//        
//        if ([[NSFileManager defaultManager] fileExistsAtPath:currentLogFile]){
//            [[NSFileManager defaultManager] removeItemAtPath:currentLogFile error:&error];
//            if (error) {
//                NSLog(@"[DEBUG] [OCLogger] Error removing the current log file: %@", error);
//            }
//        }
//}
//
//+(void) removeBufferLogFile
//    {
//        NSString* new = [OCLogger getDocumentPath:FILENAME_WL_LOG_SEND];
//        NSError* error = nil;
//        
//        if ([[NSFileManager defaultManager] fileExistsAtPath:new]){
//            [[NSFileManager defaultManager] removeItemAtPath:new error:&error];
//            if (error) {
//                NSLog(@"[DEBUG] [OCLogger] Error removing the buffer log file: %@", error);
//            }
//        }
//}
//
//+(void) removeSwapLogFile
//    {
//        NSString* swapLogFile = [OCLogger getDocumentPath:FILENAME_WL_LOG_SWAP];
//        NSError* error = nil;
//        
//        if ([[NSFileManager defaultManager] fileExistsAtPath:swapLogFile]){
//            [[NSFileManager defaultManager] removeItemAtPath:swapLogFile error:&error];
//            if (error) {
//                NSLog(@"[DEBUG] [OCLogger] Error removing the swap log file: %@", error);
//            }
//        }
//}
//
//+(void) removeAnalyticsBufferFile
//    {
//        NSString* currentLogFile = [OCLogger getDocumentPath:FILENAME_ANALYTICS_SEND];
//        NSError* error = nil;
//        
//        if ([[NSFileManager defaultManager] fileExistsAtPath:currentLogFile]){
//            [[NSFileManager defaultManager] removeItemAtPath:currentLogFile error:&error];
//            if (error) {
//                NSLog(@"[DEBUG] [OCLogger] Error removing the current log file: %@", error);
//            }
//        }
//}
//
//+(NSURL*) getWorklightPostURL
//    {
//        return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [OCLoggerWorklight getWorklightBaseURL], LOG_UPLOADER_PATH]];
//}
//
//
//+(NSData*) getDataFromLogFile
//    {
//        NSData* data = [OCLogger getDataFromFile:FILENAME_WL_LOG withBufferFile:FILENAME_WL_LOG_SEND];
//        NSData *swapData = [OCLogger getDataFromSwapFile];
//        
//        if(swapData != nil){
//            
//            NSMutableData* mergedData = [NSMutableData dataWithData:swapData] ;
//            [mergedData appendData:data];
//            
//            return mergedData;
//        }
//        
//        return data;
//}
//
//+(NSData*) getDataFromAnalyticsFile
//    {
//        return [OCLogger getDataFromFile:FILENAME_ANALYTICS_LOG withBufferFile:FILENAME_ANALYTICS_SEND];
//}
//
//+(NSData*) getDataFromFile:(NSString*)currentFile withBufferFile:(NSString*)bufferFile
//{
//    NSString* currentLogFile = [OCLogger getDocumentPath:currentFile];
//    NSString* bufferLogFile = [OCLogger getDocumentPath:bufferFile];
//    
//    NSFileHandle *myHandle;
//    
//    myHandle = [NSFileHandle fileHandleForReadingAtPath:bufferLogFile];
//    
//    if (myHandle == nil) {
//        
//        NSError *error = nil;
//        if([[NSFileManager defaultManager] fileExistsAtPath:currentLogFile]){
//            
//            [[NSFileManager defaultManager] moveItemAtPath:currentLogFile toPath:bufferLogFile error:&error];
//            if (error) {
//                NSLog(@"[DEBUG] [OCLogger] Failed to move current file to buffer file.");
//                return nil;
//            }
//            
//            myHandle = [NSFileHandle fileHandleForReadingAtPath:bufferLogFile];
//            
//            if (myHandle == nil) {
//                NSLog(@"[DEBUG] [OCLogger] No file to send, could not get a file handle.");
//                return nil;
//            }
//        }else{
//            NSLog(@"[DEBUG] [OCLogger] The log file is empty. There are no persisted logs to send.");
//            return nil;
//        }
//        
//        
//    }
//    
//    NSData* data = [myHandle readDataToEndOfFile];
//    [myHandle closeFile];
//    
//    return data;
//}
//
//+(NSData*)getDataFromSwapFile
//    {
//        NSString* swapLogFile = [OCLogger getDocumentPath:FILENAME_WL_LOG_SWAP];
//        NSFileHandle *myHandle = [NSFileHandle fileHandleForReadingAtPath:swapLogFile];
//        
//        if(myHandle != nil){
//            NSData* swapLogData = [myHandle readDataToEndOfFile];
//            [myHandle closeFile];
//            
//            [OCLogger removeSwapLogFile];
//            return swapLogData;
//        }
//        
//        return nil;
//}
//
//+(void) swapLogFile
//    {
//        NSString* currentLogFile = [OCLogger getDocumentPath:FILENAME_WL_LOG];
//        NSString* logSwapFile = [OCLogger getDocumentPath:FILENAME_WL_LOG_SWAP];
//        [OCLogger removeSwapLogFile];
//        
//        NSError* error = nil;
//        [[NSFileManager defaultManager] moveItemAtPath:currentLogFile toPath:logSwapFile  error:&error];
//        if (error) {
//            NSLog(@"[DEBUG] [OCLogger] Error moving the current log (%@) to path (%@) file: %@",
//                currentLogFile, logSwapFile, error);
//        }
//}
//
//+(BOOL) canLogWithLevel:(OCLogType) level withPackage:(NSString*)package {
//    NSDictionary* filters = [OCLogger getFilters];
//    
//    if(filters != nil && [filters count] > 0 && level != OCLogger_ANALYTICS){
//        NSObject* logLevel = [filters objectForKey:package];
//        
//        if(logLevel == nil){
//            return false;
//        }
//        
//        OCLogType filterLevel;
//        
//        if([logLevel isKindOfClass:[NSString class]]){
//            filterLevel = [OCLogger getLevelType:(NSString*)logLevel];
//        }else{
//            filterLevel = (OCLogType)[(NSNumber*)logLevel integerValue];
//        }
//        
//        if(level > filterLevel){
//            return false;
//        }
//    } else {
//        return [OCLogger getLevel] >= level;
//    }
//    
//    return true;
//}
//
//+(BOOL)shouldCaptureLog: (OCLogType)level{
//    if(level == OCLogger_ANALYTICS){
//        if([OCLogger getAnalyticsCapture] == NO){
//            return false;
//        }
//    }
//        
//    else if([OCLogger getCapture] == NO){
//        return false;
//    }
//    
//    return true;
//}
//
//+(BOOL) shouldUseServerConfig
//    {
//        NSObject *serverConfigSet = [[NSUserDefaults standardUserDefaults] objectForKey:TAG_SERVER_CAPTURE];
//        return (serverConfigSet != NULL);
//}
//
//+(NSString*) getCurrentTimestamp:(NSDate*)date
//{
//    NSString* dateStr = [globalFormatter stringFromDate:date];
//    
//    return dateStr;
//}
//
//+(BOOL) isFileSize:(NSString*) filePath greaterThan:(int) max
//{
//    NSError* error = nil;
//    long long sizeAtPath = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error][NSFileSize] longLongValue];
//    if (error) {
//        NSLog(@"[DEBUG] [OCLogger] Failed with error: %@, getting the file size for path: %@", error, filePath);
//    }
//    
//    if(sizeAtPath > max) {
//        NSLog(@"[DEBUG] [OCLogger] Max file size exceeded for log messages.");
//        return true;
//    }
//    
//    return false;
//}
//
//+(NSString*) getMessageWith:(NSString*) text andArgs:(va_list) args
//{
//    NSString *msg;
//    
//    if (args == nil) {
//        msg = text;
//    } else {
//        //printf-style replacements, for example: 'hello %@', 'world' returns 'hello world'
//        msg = [[NSString alloc] initWithFormat:text arguments:args];
//    }
//    
//    return msg;
//}
//
//+(NSFileHandle*) getHandleAtEndOfFileWithPath:(NSString*) path
//{
//    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:path];
//    
//    if (myHandle == nil) {
//        
//        //file not found, create it
//        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
//        myHandle = [NSFileHandle fileHandleForWritingAtPath:path];
//        
//    }
//    
//    [myHandle seekToEndOfFile];
//    
//    return myHandle;
//}
//
//+(void) writeString:(NSString*) dictStr toLogFile:(NSString*) logFilePath
//{
//    NSFileHandle* myHandle = [OCLogger getHandleAtEndOfFileWithPath:logFilePath];
//    
//    [myHandle writeData:[dictStr dataUsingEncoding:NSUTF8StringEncoding]];
//    [myHandle writeData:[@"," dataUsingEncoding:NSUTF8StringEncoding]];
//    
//    [myHandle closeFile];
//}
//
//+(void) printMessage:(NSString*) msg withMetadata:(NSDictionary*) metadata andLevelTag:(NSString*) levelTag andPackage:(NSString*) package
//{
//    NSString* $method = [metadata objectForKey:KEY_METADATA_METHOD];
//    NSString* $line = [metadata objectForKey:KEY_METADATA_LINE];
//    NSString* $file = [metadata objectForKey:KEY_METADATA_FILE];
//    
//    if ($method != nil && $line != nil && $file != nil) {
//        NSLog(@"[%@] [%@] %@ in %@:%@ :: %@", levelTag, package, $method, $file, $line, msg);
//    } else {
//        NSLog(@"[%@] [%@] %@", levelTag, package, msg);
//    }
//}
//
//@end
//
//
//#pragma mark - Delegate Implementations
//
//@implementation SendLogsDelegate
//
//-(void)onSuccessWithResponse:(WLResponse *)response userInfo:(NSDictionary *)userInfo{
//    NSLog(@"[DEBUG] [OCLogger] Client Logs successfully sent to server.");
//    [OCLogger removeBufferLogFile];
//    [OCLogger setUnCaughtExceptionFound:NO];
//    logInFlight = 0;
//}
//
//-(void)onFailureWithResponse:(WLFailResponse *)response userInfo:(NSDictionary *)userInfo{
//    NSLog(@"[DEBUG] [OCLogger] Request to send client logs has failed.");
//}
//@end
//
//
//@implementation SendAnalyticsDelegate
//-(void)onSuccessWithResponse:(WLResponse *)response userInfo:(NSDictionary *)userInfo{
//    NSLog(@"[DEBUG] [OCLogger] Analytics data successfully sent to server.");
//    [OCLogger removeAnalyticsBufferFile];
//}
//
//-(void)onFailureWithResponse:(WLFailResponse *)response userInfo:(NSDictionary *)userInfo{
//    NSLog(@"[DEBUG] [OCLogger] Request to send analytics data has failed.");
//}
//@end
//
//
//@implementation UpdateConfigDelegate
//
//// TODO to be removed when piggybacker is done
//-(void)onSuccessWithResponse:(WLResponse *)response userInfo:(NSDictionary *)userInfo{
//    [OCLogger processUpdateConfigFromServer:response.status withResponse:response.responseText];
//}
//
//-(void)onFailureWithResponse:(WLFailResponse *)response userInfo:(NSDictionary *)userInfo{
//    NSLog(@"[DEBUG] [OCLogger] Request to update configuration profile has failed.");
//}
//@end
//
//
