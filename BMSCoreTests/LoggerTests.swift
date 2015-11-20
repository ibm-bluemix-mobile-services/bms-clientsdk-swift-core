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
    func testSetGetLevel(){
        
        let level1 = Logger.logLevel
    
        if Logger.internalSDKLoggingEnabled{
            XCTAssertTrue(level1 == LogLevel.Info)
        } else {
            XCTAssertTrue(level1 == LogLevel.Debug)
        }
    }
    
    func testGetLoggerForName(){
        let name = "sample"
        
        let logger = Logger.getLoggerForName(name)
        
        XCTAssertTrue(logger.name == Logger.loggerInstances[name]?.name)
    }

    func testSetGetMaxLogStoreSize(){
    
        let size1 = Logger.maxLogStoreSize
        XCTAssertTrue(size1 == DEFAULT_MAX_FILE_SIZE)

        Logger.maxLogStoreSize = 12345678
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

    
    func testLogMethods(){
        let fakePKG = "MYPKG"
        let documentDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let pathToFile = "\(documentDirPath)/hello.txt"
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        //Not sure why we are mocking getDoumentPath; revisit later
        // id OCLoggerMock = [OCMockObject mockForClass:[OCLogger class]];
        // [[[OCLoggerMock stub] andReturn:pathToFile] getDocumentPath:@"wl.log"];

        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevel = LogLevel.Debug
        Logger.maxLogStoreSize = DEFAULT_MAX_FILE_SIZE

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
        XCTAssertTrue(debugMessage[TAG_META_DATA]!!.count == 0)

        let logMessage = jsonDict![1]
        XCTAssertTrue(logMessage[TAG_MSG] == "Hello world 2")
        XCTAssertTrue(logMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(logMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(logMessage[TAG_LEVEL] == "LOG")
        XCTAssertTrue(logMessage[TAG_META_DATA]!!.count == 0)

        let infoMessage = jsonDict![2]
        XCTAssertTrue(infoMessage[TAG_MSG] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(infoMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(infoMessage[TAG_LEVEL] == "LOG")
        XCTAssertTrue(infoMessage[TAG_META_DATA]!!.count == 0)

        let warnMessage = jsonDict![3]
        XCTAssertTrue(warnMessage[TAG_MSG] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(warnMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(warnMessage[TAG_LEVEL] == "WARN")
        XCTAssertTrue(warnMessage[TAG_META_DATA]!!.count == 0)

        let errorMessage = jsonDict![4]
        XCTAssertTrue(errorMessage[TAG_MSG] == "1 2 3 4")
        XCTAssertTrue(errorMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(errorMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[TAG_LEVEL] == "ERROR")
        XCTAssertTrue(errorMessage[TAG_META_DATA]!!.count == 0)

        let fatalMessage = jsonDict![5]
        XCTAssertTrue(fatalMessage[TAG_MSG] == "StephenColbert")
        XCTAssertTrue(fatalMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(fatalMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(fatalMessage[TAG_META_DATA]!!.count == 0)
    }

    
    func testProcessResponseFromServer(){
        let level = "DEBUG"
        let filters = ["package": "WARN"]
        let serverResponse = ["wllogger": ["level": level]]

        Logger.processConfigResponseFromServer(serverResponse)

        let newCapture = Logger.logStoreEnabled
        let newLevel = Logger.logLevel

        XCTAssertTrue(newCapture)
        XCTAssertTrue(newLevel == LogLevel.Debug)
    }
        
    func testServerConfigOverridesLocalConfig(){
        let serverLevel = "ERROR"
        let serverFilters = ["JSONStore": "INFO"]
        let serverResponse = ["wllogger": ["level": serverLevel]]

        Logger.logStoreEnabled = false
        Logger.logLevel = LogLevel.Warn
        
        XCTAssertFalse(Logger.logStoreEnabled)
        XCTAssertTrue(Logger.logLevel == LogLevel.Warn)

        Logger.processConfigResponseFromServer(serverResponse)

        let newCapture = Logger.logStoreEnabled
        let newLevel = Logger.logLevel

        XCTAssertTrue(newCapture)
        XCTAssertTrue(newLevel == LogLevel.Error)
    }
    
    func testLocalSettingsRestoredOnClear(){
        let serverLevel = "ERROR"
        let serverFilters = ["JSONStore": "INFO"]
        let serverResponse = ["wllogger": ["filters": serverFilters, "level": serverLevel]]

        Logger.logStoreEnabled = false
        Logger.logLevel = LogLevel.Warn

        XCTAssertFalse(Logger.logStoreEnabled)
        XCTAssertTrue(Logger.logLevel == LogLevel.Warn)

        Logger.processConfigResponseFromServer(serverResponse);
    
        let newCapture = Logger.logStoreEnabled
        let newLevel = Logger.logLevel
        
        XCTAssertTrue(newCapture)
        XCTAssertTrue(newLevel == LogLevel.Error)

        Logger.clearServerConfig()

        XCTAssertFalse(Logger.logStoreEnabled)
        XCTAssertTrue(Logger.logLevel == LogLevel.Warn)
    }
    
}
