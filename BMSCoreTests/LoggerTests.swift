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

    func testSetGetLevel(){
        Logger.registerDefaultConfigurationValues()
        
        level1 = Logger.level
    
        if Logger.internalSDKLoggingEnabled{
            XCTAssertTrue(level1 == LOGGER_INFO)
        } else {
            XCTAssertTrue(level1 == LOGGER_DEBUG)
        }
    }

    func testSetGetMaxFileSize(){
        Logger.registerDefaultConfigurationValues()
    
        let size1 = Logger.maxFileSize
        XCTAssertTrue(size1 == DEFAULT_MAX_FILE_SIZE)

        Logger.maxFileSize = 12 //Try to set to invalid max file size
        let size2 = Logger.maxFileSize
        XCTAssertTrue(size2 == DEFAULT_MAX_FILE_SIZE, "Max should still be the default when using invalid size")

        Logger.maxFileSize = 12345678
        let size3 = Logger.maxFileSize
        XCTAssertTrue(size3 == 12345678)
    }
    
    func testSetGetCapture(){
        Logger.registerDefaultConfigurationValues()   
        let capture2 = Logger.capture
        XCTAssertTrue(capture2, "should default to true");

        Logger.capture = false
    
        let capture3 = Logger.capture
        XCTAssertFalse(capture3)
    }
    
    func testSetFilters(){
        Logger.registerDefaultConfigurationValues()
        XCTAssertTrue(Logger.filters.isEmpty)
    
        filters = ["myPackage": LOGGER_DEBUG, "megaPackage": LOGGER_ERROR] 
        Logger.filters = filters    
        XCTAssertTrue(Logger.filters.count == 2)
    }
    
    func testLogWithPackageFilter(){
        let packageOne = "package1"
        let packageTwo = "package2"
        let documentDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let pathToFile = "\(documentDirPath)/hello.txt"

        NSFileManager.removeItemAtPath(pathToFile)
    
        //Not sure why we are mocking getDoumentPath; revisit later
        // id OCLoggerMock = [OCMockObject mockForClass:[OCLogger class]];
        // [[[OCLoggerMock stub] andReturn:pathToFile] getDocumentPath:@"wl.log"];
    
        var packageOneInstance = Logger.getInstanceWithPackage(packageOne)
        var packageTwoInstance = Logger.getInstanceWithPackage(packageTwo)
    
        let filters =  ["packageOne": "DEBUG"]

        Logger.filters = filters
        Logger.capture = true
        Logger.maxFileSize = DEFAULT_MAX_FILE_SIZE

        packageOneInstance.debug("Hello World")
        packageOneInstance.log("Hello world")
        packageOneInstance.info("1242342342343243242342")
        packageOneInstance.warn("Str: heyoooooo")
        packageOneInstance.error("1 2 3 4")

        packageTwoInstance.debug("Hello Word")
        packageTwoInstance.log("Hello Word 2")
        packageTwoInstance.info("1242342342343243242342")
        packageTwoInstance.warn("Str: heyoooooo")
        packageTwoInstance.error("1 2 3 4")

        var error:NSError?
        let formattedContents = String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding, error : &error)
        let fileContents = "[\formattedContents]"
        let data = fileContents.dataUsingEncoding(NSUTF8StringEncoding)
        let jsonDict = NSJSONSerialization.dataWithJSONObject(data, options: nil, error: &error)
    
        XCTAssertTrue(jsonDict.count == 5);
    }
    
    func testLogWithLevelFilter(){
        let packageOne = "package1"
        let documentDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let pathToFile = "\(documentDirPath)/hello.txt"

        NSFileManager.removeItemAtPath(pathToFile)
    
        //Not sure why we are mocking getDoumentPath; revisit later
        // id OCLoggerMock = [OCMockObject mockForClass:[OCLogger class]];
        // [[[OCLoggerMock stub] andReturn:pathToFile] getDocumentPath:@"wl.log"];

        packageOneInstance = Logger.getInstanceWithPackage(packageOne)
        filters = ["packageOne": "WARN"]
    
        Logger.filters = filters
        Logger.capture = true
        Logger.maxFileSize = DEFAULT_MAX_FILE_SIZE

        packageOneInstance.debug("Hello World")
        packageOneInstance.log("Hello World 2")
        packageOneInstance.info("1242342342343243242342")
        packageOneInstance.warn("Str: heyoooooo")
        packageOneInstance.error("1 2 3 4")

        var error:NSError?
        let formattedContents = String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding, error : &error)
        let fileContents = "[\formattedContents]"
        let data = fileContents.dataUsingEncoding(NSUTF8StringEncoding)
        let jsonDict = NSJSONSerialization.dataWithJSONObject(data, options: nil, error: &error)
        
        XCTAssertTrue(jsonDict.count == 2)
    }
    
    func testLogMethods(){
        let fakePKG = "MYPKG"
        let documentDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let pathToFile = "\(documentDirPath)/hello.txt"

        NSFileManager.removeItemAtPath(pathToFile)

        //Not sure why we are mocking getDoumentPath; revisit later
        // id OCLoggerMock = [OCMockObject mockForClass:[OCLogger class]];
        // [[[OCLoggerMock stub] andReturn:pathToFile] getDocumentPath:@"wl.log"];

        var loggerInstance = Logger.getInstanceWithPackage(fakePKG)
        Logger.filters = nil
        Logger.capture = true
        Logger.level = LOGGER_TRACE
        Logger.maxFileSize = DEFAULT_MAX_FILE_SIZE

        loggerInstance.trace("Herpderp")
        loggerInstance.debug("Hello word")
        loggerInstance.log("Hello word 2")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        var error:NSError?
        let formattedContents = String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding, error : &error)
        let fileContents = "[\formattedContents]"
        let data = fileContents.dataUsingEncoding(NSUTF8StringEncoding)
        let jsonDict = NSJSONSerialization.dataWithJSONObject(data, options: nil, error: &error)

        let traceMessage = jsonDict[0] 
        XCTAssertTrue(traceMessage[TAG_MSG] == "Herpderp")
        XCTAssertTrue(traceMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(traceMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(traceMessage[TAG_LEVEL] == "TRACE")
        XCTAssertTrue(traceMessage[TAG_META_DATA].count == 0)

        let debugMessage = jsonDict[1]
        XCTAssertTrue(debugMessage[TAG_MSG] == "Hello world")
        XCTAssertTrue(debugMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(debugMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(debugMessage[TAG_LEVEL] == "DEBUG")
        XCTAssertTrue(debugMessage[TAG_META_DATA].count == 0)

        let logMessage = jsonDict[2]
        XCTAssertTrue(logMessage[TAG_MSG] == "Hello world 2")
        XCTAssertTrue(logMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(logMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(logMessage[TAG_LEVEL] == "LOG")
        XCTAssertTrue(logMessage[TAG_META_DATA].count == 0)

        let infoMessage = jsonDict[3]
        XCTAssertTrue(infoMessage[TAG_MSG] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(infoMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(infoMessage[TAG_LEVEL] == "LOG")
        XCTAssertTrue(infoMessage[TAG_META_DATA].count == 0)

        let warnMessage = jsonDict[4]
        XCTAssertTrue(warnMessage[TAG_MSG] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(warnMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(warnMessage[TAG_LEVEL] == "WARN")
        XCTAssertTrue(warnMessage[TAG_META_DATA].count == 0)

        let errorMessage = jsonDict[5]
        XCTAssertTrue(errorMessage[TAG_MSG] == "1 2 3 4")
        XCTAssertTrue(errorMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(errorMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[TAG_LEVEL] == "ERROR")
        XCTAssertTrue(errorMessage[TAG_META_DATA].count == 0)

        let fatalMessage = jsonDict[6]
        XCTAssertTrue(fatalMessage[TAG_MSG] == "StephenColbert")
        XCTAssertTrue(fatalMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(fatalMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(fatalMessage[TAG_META_DATA].count == 0)
    }
    
    func testLogMethodsWithMetadata(){
        let fakePKG = "MYPKG"
        let fakeMetadata0 = ["hello": "world"]
        let fakeMetadata1 = ["hello": "world"]
        let fakeMetadata2 = ["hello": "world"]
        let fakeMetadata3 = ["hello": "world"]
        let fakeMetadata4 = ["hello": "world"]
        let fakeMetadata5 = ["hello": "world"]
        let fakeMetadata6 = ["hello": "world"]

        let documentDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let pathToFile = "\(documentDirPath)/hello.txt"

        NSFileManager.removeItemAtPath(pathToFile)

        //Not sure why we are mocking getDoumentPath; revisit later
        // id OCLoggerMock = [OCMockObject mockForClass:[OCLogger class]];
        // [[[OCLoggerMock stub] andReturn:pathToFile] getDocumentPath:@"wl.log"];

        loggerInstance = Logger.getInstanceWithPackage(fakePKG)
        Logger.filters = nil
        Logger.capture = true
        Logger.level = LOGGER_TRACE
        Logger.maxFileSize = DEFAULT_MAX_FILE_SIZE

        loggerInstance.metadata(fakeMetadata0).trace("Herpderp")
        loggerInstance.metadata(fakeMetadata1).debug("Hello world")
        loggerInstance.metadata(fakeMetadata2).log("Hello world 2")
        loggerInstance.metadata(fakeMetadata3).info("1242342342343243242342")
        loggerInstance.metadata(fakeMetadata4).warn("Str: heyoooooo")
        loggerInstance.metadata(fakeMetadata5).error("1 2 3 4")
        loggerInstance.metadata(fakeMetadata6).fatal("StephenColbert")

        var error:NSError?
        let formattedContents = String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding, error : &error)
        let fileContents = "[\formattedContents]"
        let data = fileContents.dataUsingEncoding(NSUTF8StringEncoding)
        let jsonDict = NSJSONSerialization.dataWithJSONObject(data, options: nil, error: &error)


        
    
        let traceMessage = jsonDict[0]
        let metadata0  = String(data: traceMessage[TAG_META_DATA]!, encoding: NSASCIIStringEncoding)
        let traceMetaData = String(data: fakeMetadata0!, encoding: NSASCIIStringEncoding)
        XCTAssertTrue(traceMessage[TAG_MSG] == "Herpderp")
        XCTAssertTrue(traceMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(traceMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(traceMessage[TAG_LEVEL] == "TRACE")
        XCTAssertTrue(traceMetaData == metadata0)


        let debugMessage = jsonDict[1]
        let metadata1 = String(data: debugMessage[TAG_META_DATA]!, encoding: NSASCIIStringEncoding)
        let debugMetaData = String(data: fakeMetadata1!, encoding: NSASCIIStringEncoding)
        XCTAssertTrue(debugMessage[TAG_MSG] == "Hello world")
        XCTAssertTrue(debugMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(debugMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(debugMessage[TAG_LEVEL] == "DEBUG")
        XCTAssertTrue(debugMetaData == metadata1)

        let logMessage = jsonDict[2]
        let metadata2 = String(data: logMessage[TAG_META_DATA]!, encoding: NSASCIIStringEncoding)
        let logMetaData = String(data: fakeMetadata2!, encoding: NSASCIIStringEncoding)
        XCTAssertTrue(logMessage[TAG_MSG] == "Hello world 2")
        XCTAssertTrue(logMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(logMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(logMessage[TAG_LEVEL] == "LOG")
        XCTAssertTrue(logMetaData == metadata2)

        let infoMessage = jsonDict[3]
        let metadata3 = String(data: infoMessage[TAG_META_DATA]!, encoding: NSASCIIStringEncoding)
        let infoMetaData = String(data: fakeMetadata3!, encoding: NSASCIIStringEncoding)
        XCTAssertTrue(infoMessage[TAG_MSG] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(infoMessage[TAG_TIMESTAMP] != nil)
        XCTAssertTrue(infoMessage[TAG_LEVEL] == "INFO")
        XCTAssertTrue(infoMetaData == metadata3)

        let warnMessage = jsonDict[4]
        let metadata4 = String(data: warnMessage[TAG_META_DATA]!, encoding: NSASCIIStringEncoding)
        let warnMetaData = String(data: fakeMetadata4!, encoding: NSASCIIStringEncoding)
        XCTAssertTrue(warnMessage[TAG_MSG] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(warnMessage[TAG_LEVEL] == "WARN")
        XCTAssertTrue(warnMetaData == metadata4)

        let errorMessage = jsonDict[5]
        let metadata5 = String(data: errorMessage[TAG_META_DATA]!, encoding: NSASCIIStringEncoding)
        let errorMetaData = String(data: fakeMetadata5!, encoding: NSASCIIStringEncoding)
        XCTAssertTrue(errorMessage[TAG_MSG] == "1 2 3 4")
        XCTAssertTrue(errorMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(errorMessage[TAG_LEVEL] == "ERROR")
        XCTAssertTrue(errorMetaData == metadata5)

        let fatalMessage = jsonDict[6]
        let metadata6 = String(data: fatalMessage[TAG_META_DATA]!, encoding: NSASCIIStringEncoding)
        let fatalMetaData = String(data: fakeMetadata6!, encoding: NSASCIIStringEncoding)
        XCTAssertTrue(fatalMessage[TAG_MSG] == "StephenColbert")
        XCTAssertTrue(fatalMessage[TAG_PKG] == fakePKG)
        XCTAssertTrue(fatalMessage[TAG_LEVEL] == "FATAL")
        XCTAssertTrue(fatalMetaData == metadata6)
    }
    
    func testSwapFileCreated(){
        let fakePKG = "MYPKG"
        let fakeMetadata1 = ["hello": "world"]
        let documentDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let pathToLogFile = "\(documentDirPath)/hello.txt"
        let pathToSwapFile = "\(documentDirPath)/hello.txt.swap"

        NSFileManager.removeItemAtPath(pathToFile)
        NSFileManager.removeItemAtPath(pathToSwapFile)
    
        //Not sure why we are mocking getDoumentPath; revisit later
        // id OCLoggerMock = [OCMockObject mockForClass:[OCLogger class]];
        // [[[OCLoggerMock stub] andReturn:pathToLogFile] getDocumentPath:@"wl.log"];
        // [[[OCLoggerMock stub] andReturn:pathToSwapFile] getDocumentPath:@"wl.log.swap"];

        let loggerInstance = Logger.getInstanceWithPackage(fakePKG)
        Logger.filters = nil
        Logger.capture = true
        Logger.setLevel = LOGGER_DEBUG
        Logger.maxFileSize = DEFAULT_LOW_BOUND_FILE_SIZE

        for i in  0..<100 {
            loggerInstance.metadata(fakeMetadata1).debug("Hello world")
        }

        let swapFileExists = NSFileManager.fileExistsAtPath(pathToFile, isDirectory: false)
        XCTAssertTrue(swapFileExists)
    }
    
    func testProcessResponseFromServer(){
        let level = "DEBUG"
        let filters = ["package": "WARN"]
        let serverResponse = ["wllogger": ["filters": filters, "level": level]]

        Logger.processConfigResponseFromServer(serverResponse)

        let newCapture = Logger.capture
        let newLevel = Logger.level
        let newFilters = Logger.filters

        let filterJSON = String(data: filters!, encoding: NSASCIIStringEncoding)
        let filterNewJSON = String(data: newFilters!, encoding: NSASCIIStringEncoding)

        XCTAssertTrue(newCapture)
        XCTAssertTrue(newType == LOGGER_DEBUG)
        XCTAssertTrue(filterJSON == filterNewJSON)
        
    func testServerConfigOverridesLocalConfig(){
        let serverLevel = "ERROR"
        let serverFilters = ["JSONStore": "INFO"]
        let serverResponse = ["wllogger": ["filters": serverFilters, "level": serverLevel]]

        Logger.capture = false
        Logger.level = LOGGER_WARN
        Logger.filters = ["MegaPackage": "DEBUG"]

        var filterJSON = String(data: Logger.filters!, encoding: NSASCIIStringEncoding)
        var filterNewJSON = String(data: ["MegaPackage": "DEBUG"]!, encoding: NSASCIIStringEncoding)

        XCTAssertFalse(Logger.capture)
        XCTAssertTrue(Logger.level == LOGGER_WARN)
        XCTAssertTrue(filterJSON == filterNewJSON)

        Logger.processConfigResponseFromServer(serverResponse)

        let newCapture = Logger.capture
        let newLevel = Logger.level
        let newFilters = Logger.filters

        filterJSON = String(data: Logger.filters!, encoding: NSASCIIStringEncoding)
        filterNewJSON = String(data: newFilters!, encoding: NSASCIIStringEncoding)


        XCTAssertTrue(newCapture)
        XCTAssertTrue(newType == LOGGER_ERROR)
        XCTAssertTrue(filterJSON == filterNewJSON)
    }
    
    func testLocalSettingsRestoredOnClear(){
        let serverLevel = "ERROR"
        let serverFilters = ["JSONStore": "INFO"]
        let serverResponse = ["wllogger": ["filters": serverFilters, "level": serverLevel]]

        Logger.capture = false
        Logger.level = LOGGER_WARN
        Logger.filters = ["MegaPackage": "DEBUG"]

        var filterJSON = String(data: Logger.filters!, encoding: NSASCIIStringEncoding)
        var filterNewJSON = String(data: ["MegaPackage": "DEBUG"]!, encoding: NSASCIIStringEncoding)


        XCTAssertFalse(Logger.capture)
        XCTAssertTrue(Logger.level == LOGGER_WARN)
        XCTAssertTrue(filterJSON == filterNewJSON)

        Logger.processConfigResponseFromServer(serverResponse);
    
        let newCapture = Logger.capture
        let newLevel = Logger.level
        let newFilters = Logger.filters

        filterJSON = String(data: Logger.filters!, encoding: NSASCIIStringEncoding)
        filterNewJSON = String(data: newFilters!, encoding: NSASCIIStringEncoding)
        
        XCTAssertTrue(newCapture)
        XCTAssertTrue(newLevel == LOGGER_ERROR)
        XCTAssertTrue(filterJSON == filterNewJSON)

        Logger.clearServerConfig()

        XCTAssertFalse(Logger.capture)
        XCTAssertTrue(Logger.level == LOGGER_WARN)
        XCTAssertTrue(filterJSON == filterNewJSON)
    }
    
}

