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

class LoggerTests: XCTestCase {
    
    func testGetLoggerForName(){
        let name = "sample"
        
        let logger = Logger.getLoggerForName(name)
        
        XCTAssertTrue(logger.name == Logger.loggerInstances[name]?.name)
    }
    
    func testIsUncaughtException(){

        Logger.isUncaughtExceptionDetected = false
        XCTAssertFalse(Logger.isUncaughtExceptionDetected)
        Logger.isUncaughtExceptionDetected = true
        XCTAssertTrue(Logger.isUncaughtExceptionDetected)
        
    }

    func testSetGetMaxLogStoreSize(){
    
        let size1 = Logger.maxLogStoreSize
        XCTAssertTrue(size1 == DEFAULT_MAX_STORE_SIZE)

        Logger.maxLogStoreSize = 12345678 as UInt64
        let size3 = Logger.maxLogStoreSize
        XCTAssertTrue(size3 == 12345678)
    }

    func testlogStoreEnabled(){
        
        let capture1 = Logger.logStoreEnabled
        XCTAssertTrue(capture1, "should default to true");

        Logger.logStoreEnabled = false
    
        let capture2 = Logger.logStoreEnabled
        XCTAssertFalse(capture2)
    }
    
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
    
    func testLogWithNone(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.None
        Logger.maxLogStoreSize = DEFAULT_MAX_STORE_SIZE
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        XCTAssertFalse(NSFileManager().fileExistsAtPath(pathToFile))

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
        let reason = e.reason!
        let errorMessage = "Uncaught Exception: \(e.name)." + " Reason: \(reason)."
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        let exceptionMessage = jsonDict![0]
        XCTAssertTrue(exceptionMessage[TAG_MSG] == errorMessage) //TODO: Figure out why this string is not what is expected
        XCTAssertTrue(exceptionMessage[TAG_PKG] == MFP_LOGGER_PACKAGE)
        XCTAssertTrue(exceptionMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(exceptionMessage[TAG_LEVEL] == "FATAL")
        
    }
    
    func testGetLogs(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        let pathToBuffer = Logger.logsDocumentPath + FILE_LOGGER_SEND
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
          
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
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
        
        let logs: String! =  try! Logger.getLogs(fileName: FILE_LOGGER_LOGS, overflowFileName: FILE_LOGGER_OVERFLOW, bufferFileName: FILE_LOGGER_SEND)
        
        let bufferFile = NSFileManager().fileExistsAtPath(pathToBuffer)
        
        XCTAssertTrue(bufferFile)
        
        let fileContents = "[\(logs)]"
        
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
        XCTAssertTrue(fatalMessage[TAG_LEVEL] == "FATAL")
        
    }
    
    func testGetLogWithAnalytics(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + FILE_ANALYTICS_LOGS
        let pathToBuffer = Logger.logsDocumentPath + FILE_ANALYTICS_SEND
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Analytics.enabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = DEFAULT_MAX_STORE_SIZE
        let meta = ["hello": 1]
        
        loggerInstance.analytics(meta)
        
        let logs: String! =  try! Logger.getLogs(fileName: FILE_ANALYTICS_LOGS, overflowFileName: FILE_ANALYTICS_OVERFLOW, bufferFileName: FILE_ANALYTICS_SEND)
        
        let bufferFile = NSFileManager().fileExistsAtPath(pathToBuffer)
        
        XCTAssertTrue(bufferFile)
        
        let fileContents = "[\(logs)]"
        
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        let analyticsMessage = jsonDict![0]
        XCTAssertTrue(analyticsMessage[TAG_MSG] == "")
        XCTAssertTrue(analyticsMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(analyticsMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(analyticsMessage[TAG_LEVEL] == "ANALYTICS")
        XCTAssertTrue(analyticsMessage[TAG_META_DATA] == meta)

    }
    
    func testOverFlowLogging(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        let pathToOverflow = Logger.logsDocumentPath + FILE_LOGGER_OVERFLOW
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToOverflow)
        } catch {
            
        }
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let path = bundle.pathForResource("largeData", ofType: "txt")
        let largeData = try! String(contentsOfFile: path!)
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.internalSDKLoggingEnabled = false
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = DEFAULT_MAX_STORE_SIZE
        
        loggerInstance.debug(largeData)
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToOverflow))
        
        var formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        var fileContents = "[\(formattedContents)]"
        var logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        var jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        let infoMessage = jsonDict![0]
        XCTAssertTrue(infoMessage[TAG_MSG] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(infoMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(infoMessage[TAG_LEVEL] == "INFO")
        
        let warnMessage = jsonDict![1]
        XCTAssertTrue(warnMessage[TAG_MSG] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(warnMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(warnMessage[TAG_LEVEL] == "WARN")
        
        let errorMessage = jsonDict![2]
        XCTAssertTrue(errorMessage[TAG_MSG] == "1 2 3 4")
        XCTAssertTrue(errorMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(errorMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[TAG_LEVEL] == "ERROR")
        
        let fatalMessage = jsonDict![3]
        XCTAssertTrue(fatalMessage[TAG_MSG] == "StephenColbert")
        XCTAssertTrue(fatalMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(fatalMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(fatalMessage[TAG_LEVEL] == "FATAL")
        
        formattedContents = try! String(contentsOfFile: pathToOverflow, encoding: NSUTF8StringEncoding)
        fileContents = "[\(formattedContents)]"
        logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        jsonDict = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        
        let overflowMessage = jsonDict![0]
        XCTAssertTrue(overflowMessage[TAG_MSG] == largeData)
        XCTAssertTrue(overflowMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(overflowMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(overflowMessage[TAG_LEVEL] == "DEBUG")
        
    }
    
    func testExistingOverflowFile(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        let pathToOverflow = Logger.logsDocumentPath + FILE_LOGGER_OVERFLOW
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToOverflow)
        } catch {
            
        }
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let path = bundle.pathForResource("largeData", ofType: "txt")
        let largeData = try! String(contentsOfFile: path!)
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.internalSDKLoggingEnabled = false
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = DEFAULT_MAX_STORE_SIZE
        
        loggerInstance.debug(largeData)
        loggerInstance.info(largeData)
        loggerInstance.warn(largeData)
        loggerInstance.error(largeData)
        loggerInstance.fatal(largeData)
        
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToOverflow))
        
        var formattedContents = try! String(contentsOfFile: pathToOverflow, encoding: NSUTF8StringEncoding)
        var fileContents = "[\(formattedContents)]"
        var logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        var jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        XCTAssertTrue(jsonDict!.count == 1)
        
        loggerInstance.debug(largeData)
        
     
        formattedContents = try! String(contentsOfFile: pathToOverflow, encoding: NSUTF8StringEncoding)
        fileContents = "[\(formattedContents)]"
        logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        jsonDict = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        
        XCTAssertTrue(jsonDict!.count == 1)

    }
    
    
    func testUpdateLogProfile(){
        //TODO:
    }
    
    func testLogSendRequest(){
        let fakePKG = "MYPKG"
        let REWRITE_DOMAIN_HEADER_NAME = "X-REWRITE-DOMAIN"
        let UPLOAD_PATH = "/imfmobileanalytics/v1/receiver/apps/"
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        let pathToBuffer = Logger.logsDocumentPath + FILE_LOGGER_SEND
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1")
        let url = bmsClient.bluemixAppRoute! + UPLOAD_PATH + bmsClient.bluemixAppGUID!
        
        let headers = ["Content-Type": "application/json", REWRITE_DOMAIN_HEADER_NAME : bmsClient.rewriteDomain!]

        

        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
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
        
        let logs: String! =  try! Logger.getLogs(fileName: FILE_LOGGER_LOGS, overflowFileName: FILE_LOGGER_OVERFLOW, bufferFileName: FILE_LOGGER_SEND)
        
        let formattedLogs = "[\(logs)]"
        
        let bufferFile = NSFileManager().fileExistsAtPath(pathToBuffer)
        
        XCTAssertTrue(bufferFile)
        
        let (request, payload) = Logger.buildLogSendRequest(logs) { (response, error) -> Void in
        }!
        
        XCTAssertTrue(request.resourceUrl == url)
        XCTAssertTrue(request.headers! == headers)
        XCTAssertNil(request.queryParameters)
        XCTAssertTrue(request.httpMethod == HttpMethod.POST)
        
        XCTAssertTrue(payload == formattedLogs)
    }
    
    func testBuildLogSendRequestFail(){
        let fakePKG = MFP_LOGGER_PACKAGE
        let missingValue = "bluemixAppRoute"
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1")
        bmsClient.uninitializeBluemixAppRoute()
        let msg = "No value found for the BMSClient \(missingValue) property."
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        let pathToBuffer = Logger.logsDocumentPath + FILE_LOGGER_SEND
        let pathToOverflow = Logger.logsDocumentPath + FILE_LOGGER_OVERFLOW
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToOverflow)
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
        
        let logs: String! = try! Logger.getLogs(fileName: FILE_LOGGER_LOGS, overflowFileName: FILE_LOGGER_OVERFLOW, bufferFileName: FILE_LOGGER_SEND)
        let bufferFile = NSFileManager().fileExistsAtPath(pathToBuffer)
        
        XCTAssertTrue(bufferFile)
        
        let request = Logger.buildLogSendRequest(logs) { (response, error) -> Void in
                XCTAssertNil(response)
                XCTAssertNotNil(error)
        }
        
        XCTAssertNil(request)
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        
        let errorMessage = jsonDict[0]
        XCTAssertTrue(errorMessage[TAG_MSG] == msg)
        XCTAssertTrue(errorMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(errorMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[TAG_LEVEL] == "ERROR")
        
    }
    
    func testBuildLogSendRequestGUIDFail(){
        let fakePKG = MFP_LOGGER_PACKAGE
        let missingValue = "bluemixAppGUID"
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1")
        bmsClient.uninitalizeBluemixAppGUID()
        let msg = "No value found for the BMSClient \(missingValue) property."
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        let pathToBuffer = Logger.logsDocumentPath + FILE_LOGGER_SEND
        let pathToOverflow = Logger.logsDocumentPath + FILE_LOGGER_OVERFLOW
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToOverflow)
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
        
        let logs: String! = try! Logger.getLogs(fileName: FILE_LOGGER_LOGS, overflowFileName: FILE_LOGGER_OVERFLOW, bufferFileName: FILE_LOGGER_SEND)
        let bufferFile = NSFileManager().fileExistsAtPath(pathToBuffer)
        
        XCTAssertTrue(bufferFile)
        
        let request = Logger.buildLogSendRequest(logs) { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
        }
        
        XCTAssertNil(request)
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        
        let errorMessage = jsonDict[0]
        XCTAssertTrue(errorMessage[TAG_MSG] == msg)
        XCTAssertTrue(errorMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(errorMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[TAG_LEVEL] == "ERROR")
        
    }
    
    func testReturnClientInitializationError(){
        let errorMessage = "Error"
        Logger.returnClientInitializationError(errorMessage) { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
        }
    }
    
    func testDeleteBufferFileFail(){
        let fakePKG = "mfpsdk.logger"
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        let pathToBuffer = Logger.logsDocumentPath + FILE_LOGGER_SEND
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = DEFAULT_MAX_STORE_SIZE
        
        loggerInstance.debug("Hello world")
    
        let logs: String! =  try! Logger.getLogs(fileName: FILE_LOGGER_LOGS, overflowFileName: FILE_LOGGER_OVERFLOW, bufferFileName: FILE_LOGGER_SEND)
        
        let bufferFile = NSFileManager().fileExistsAtPath(pathToBuffer)
        
        XCTAssertTrue(bufferFile)
        XCTAssertNotNil(logs)
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
        } catch {
            
        }
        
        Logger.deleteBufferFile(pathToBuffer)
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
    
        let errorMessage = jsonDict![0]
        XCTAssertNotNil(errorMessage[TAG_MSG])
        XCTAssertTrue(errorMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(errorMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[TAG_LEVEL] == "ERROR")
        
    }
    
    
    
//TODO: need to figure out how to throw exception when trying to read file size
//    func testFailOverflowLogging(){
//        let fakePKG = "MYPKG"
//        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
//        let pathToOverflow = Logger.logsDocumentPath + FILE_LOGGER_OVERFLOW
//        
//        do {
//            try NSFileManager().removeItemAtPath(pathToFile)
//            
//        } catch {
//            
//        }
//        
//        let bundle = NSBundle(forClass: self.dynamicType)
//        let path = bundle.pathForResource("largeData", ofType: "txt")
//        let largeData = try! String(contentsOfFile: path!)
//        
//        let loggerInstance = Logger.getLoggerForName(fakePKG)
//        Logger.logStoreEnabled = true
//        Logger.internalSDKLoggingEnabled = false
//        Logger.logLevelFilter = LogLevel.Debug
//        Logger.maxLogStoreSize = DEFAULT_MAX_STORE_SIZE
//        
//        loggerInstance.debug(largeData)
//        loggerInstance.info("1242342342343243242342")
//        loggerInstance.warn("Str: heyoooooo")
//        loggerInstance.error("1 2 3 4")
//        loggerInstance.fatal("StephenColbert")
//        
//        
//        let overflowFile = NSFileManager().fileExistsAtPath(pathToOverflow)
//        
//        XCTAssertTrue(overflowFile)
//        
//        let permission: Int16 = 0o000
//        
//        let attributes: [String:AnyObject] = [NSFilePosixPermissions: NSNumber(short: permission)]
//        try! NSFileManager().setAttributes(attributes, ofItemAtPath: pathToFile)
//        
//        loggerInstance.debug(largeData)
//        
//
//        
//        
//        
//    }
    


    
    func testDeleteBufferFile(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + FILE_LOGGER_LOGS
        let pathToBuffer = Logger.logsDocumentPath + FILE_LOGGER_SEND
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
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
        
        try! Logger.getLogs(fileName: FILE_LOGGER_LOGS, overflowFileName: FILE_LOGGER_OVERFLOW, bufferFileName: FILE_LOGGER_SEND)
        
        var bufferFile = NSFileManager().fileExistsAtPath(pathToBuffer)
        
        XCTAssertTrue(bufferFile)
        
        Logger.deleteBufferFile(pathToBuffer)
        
        bufferFile = NSFileManager().fileExistsAtPath(pathToBuffer)
        
        XCTAssertFalse(bufferFile)
    }
    
}
