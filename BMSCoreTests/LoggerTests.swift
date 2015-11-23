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


//OCLogger , IMFLogger, BMSCoreAndroidLogger
class LoggerTests: XCTestCase {

//TODO: test for getLoggerForName, uncaughtExceptionDetected (check if default to false)
// send (it should be deleting the wl.log)
    
    func testGetLoggerForName(){
        let name = "sample"
        
        let logger = Logger.getLoggerForName(name)
        
        XCTAssertTrue(logger.name == Logger.loggerInstances[name]?.name)
    }
    
//TODO:  Need to figure out why you can't set maxLogStoreSize
//    func testSetGetMaxLogStoreSize(){
//    
//        let size1 = Logger.maxLogStoreSize
//        XCTAssertTrue(size1 == DEFAULT_MAX_STORE_SIZE)
//
//        Logger.maxLogStoreSize = 12345678 as UInt64
//        let size3 = Logger.maxLogStoreSize
//        XCTAssertTrue(size3 == 12345678)
//    }
//
    func testlogStoreEnabled(){
        
        let capture1 = Logger.logStoreEnabled
        XCTAssertTrue(capture1, "should default to true");

        Logger.logStoreEnabled = false
    
        let capture2 = Logger.logStoreEnabled
        XCTAssertFalse(capture2)
    }
    
//    func testGetFilesForLogLevel(){
//        let fakePKG = "MYPKG"
//        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
//        let pathToOverflowFile = Logger.logsDocumentPath + FILE_LOGGER_OVERFLOW
//        
//
//        do {
//            try NSFileManager().removeItemAtPath(pathToFile)
//        } catch {
//            print("Could not delete " + pathToFile)
//        }
//
//        let loggerInstance = Logger.getLoggerForName(fakePKG)
//
//        let (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Debug)
//        
//        XCTAssertTrue(logFile == path
//        
//    }
    
    func testGetFilesForLogLevel(){
        let fakePKG = "MYPKG"
        let pathToLoggerFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        let pathToAnalyticsFile = Logger.logsDocumentPath + FILE_ANALYTICS_LOGS
        let pathToLoggerFileOverflow = Logger.logsDocumentPath + FILE_LOGGER_OVERFLOW
        let pathToAnalyticsFileOverflow = Logger.logsDocumentPath + FILE_ANALYTICS_OVERFLOW
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
    
        var (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Debug)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Error)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Fatal)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Info)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Error)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Analytics)
        
        XCTAssertTrue(logFile == pathToAnalyticsFile)
        XCTAssertTrue(logOverflowFile == pathToAnalyticsFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)

    }
    
    func testAnalyticsLog(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + FILE_ANALYTICS_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Analytics
        Logger.maxLogStoreSize = DEFAULT_MAX_STORE_SIZE
        let meta = ["hello": 1]
        
        loggerInstance.analytics(meta)
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        let debugMessage = jsonDict![0]
        XCTAssertTrue(debugMessage[TAG_MSG] == "")
        XCTAssertTrue(debugMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(debugMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(debugMessage[TAG_LEVEL] == "ANALYTICS")
        print(debugMessage[TAG_META_DATA])
        XCTAssertTrue(debugMessage[TAG_META_DATA] == meta)
        
    }
    
    func testDisableAnalyticsLogging(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + FILE_ANALYTICS_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logLevelFilter = LogLevel.Analytics
        Analytics.enabled = false
        Logger.maxLogStoreSize = DEFAULT_MAX_STORE_SIZE
        let meta = ["hello": 1]
        
        loggerInstance.analytics(meta)
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)

    }
    
    func testNoInternalLogging(){
        let fakePKG = MFP_LOGGER_PACKAGE
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = DEFAULT_MAX_STORE_SIZE
        Logger.internalSDKLoggingEnabled = false
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")

        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        let debugMessage = jsonDict![0]
        XCTAssertTrue(debugMessage[TAG_MSG] == "Hello world")
        XCTAssertTrue(debugMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(debugMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(debugMessage[TAG_LEVEL] == "DEBUG")
        
        let infoMessage = jsonDict![1]
        XCTAssertTrue(infoMessage[TAG_MSG] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(infoMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(infoMessage[TAG_LEVEL] == "INFO")
        
        let warnMessage = jsonDict![2]
        XCTAssertTrue(warnMessage[TAG_MSG] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(warnMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(warnMessage[TAG_LEVEL] == "WARN")
        
        let errorMessage = jsonDict![3]
        XCTAssertTrue(errorMessage[TAG_MSG] == "1 2 3 4")
        XCTAssertTrue(errorMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(errorMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[TAG_LEVEL] == "ERROR")
        
        let fatalMessage = jsonDict![4]
        XCTAssertTrue(fatalMessage[TAG_MSG] == "StephenColbert")
        XCTAssertTrue(fatalMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(fatalMessage[TAG_TIMESTAMP] != nil)
        
        
        
        
    }

    
    func testLogMethods(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = DEFAULT_MAX_STORE_SIZE

        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
    
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)

        let debugMessage = jsonDict![0]
        XCTAssertTrue(debugMessage[TAG_MSG] == "Hello world")
        XCTAssertTrue(debugMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(debugMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(debugMessage[TAG_LEVEL] == "DEBUG")

        let infoMessage = jsonDict![1]
        XCTAssertTrue(infoMessage[TAG_MSG] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(infoMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(infoMessage[TAG_LEVEL] == "INFO")

        let warnMessage = jsonDict![2]
        XCTAssertTrue(warnMessage[TAG_MSG] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(warnMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(warnMessage[TAG_LEVEL] == "WARN")

        let errorMessage = jsonDict![3]
        XCTAssertTrue(errorMessage[TAG_MSG] == "1 2 3 4")
        XCTAssertTrue(errorMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(errorMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[TAG_LEVEL] == "ERROR")

        let fatalMessage = jsonDict![4]
        XCTAssertTrue(fatalMessage[TAG_MSG] == "StephenColbert")
        XCTAssertTrue(fatalMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(fatalMessage[TAG_TIMESTAMP] != nil)
    }
    
    func testIncorrectLogLevel(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Fatal
        Logger.maxLogStoreSize = DEFAULT_MAX_STORE_SIZE
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)

    }
    
    func testDisableLogging(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = false
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = DEFAULT_MAX_STORE_SIZE
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
    func testLogException(){
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let e = NSException(name:"crashApp", reason:"No reason at all just doing it for fun", userInfo:["user":"nana"])
        
        Logger.logException(e)
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        //let reason = e.reason!
        //let errorMessage = "Uncaught Exception: \(e.name)." + " Reason: \(reason)."
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        let exceptionMessage = jsonDict![0]
       // XCTAssertTrue(exceptionMessage[TAG_MSG] == errorMessage) TODO: Figure out why this string is not what is expected
        XCTAssertTrue(exceptionMessage[TAG_PKG] == MFP_LOGGER_PACKAGE)
        XCTAssertTrue(exceptionMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(exceptionMessage[TAG_LEVEL] == "FATAL")
        
    }

//    
//    func testProcessResponseFromServer(){
//        let level = "DEBUG"
//        let filters = ["package": "WARN"]
//        let serverResponse = ["wllogger": ["level": level]]
//
//        Logger.processConfigResponseFromServer(serverResponse)
//
//        let newCapture = Logger.logStoreEnabled
//        let newLevel = Logger.logLevelFilter
//
//        XCTAssertTrue(newCapture)
//        XCTAssertTrue(newLevel == LogLevel.Debug)
//    }
//        
//    func testServerConfigOverridesLocalConfig(){
//        let serverLevel = "ERROR"
//        let serverFilters = ["JSONStore": "INFO"]
//        let serverResponse = ["wllogger": ["level": serverLevel]]
//
//        Logger.logStoreEnabled = false
//        Logger.logLevelFilter = LogLevel.Warn
//        
//        XCTAssertFalse(Logger.logStoreEnabled)
//        XCTAssertTrue(Logger.logLevelFilter == LogLevel.Warn)
//
//        Logger.processConfigResponseFromServer(serverResponse)
//
//        let newCapture = Logger.logStoreEnabled
//        let newLevel = Logger.logLevelFilter
//
//        XCTAssertTrue(newCapture)
//        XCTAssertTrue(newLevel == LogLevel.Error)
//    }
//    
//    func testLocalSettingsRestoredOnClear(){
//        let serverLevel = "ERROR"
//        let serverFilters = ["JSONStore": "INFO"]
//        let serverResponse = ["wllogger": ["filters": serverFilters, "level": serverLevel]]
//
//        Logger.logStoreEnabled = false
//        Logger.logLevelFilter = LogLevel.Warn
//
//        XCTAssertFalse(Logger.logStoreEnabled)
//        XCTAssertTrue(Logger.logLevelFilter == LogLevel.Warn)
//
//        Logger.processConfigResponseFromServer(serverResponse);
//    
//        let newCapture = Logger.logStoreEnabled
//        let newLevel = Logger.logLevelFilter
//        
//        XCTAssertTrue(newCapture)
//        XCTAssertTrue(newLevel == LogLevel.Error)
//
//        Logger.clearServerConfig()
//
//        XCTAssertFalse(Logger.logStoreEnabled)
//        XCTAssertTrue(Logger.logLevelFilter == LogLevel.Warn)
//    }
    
}
