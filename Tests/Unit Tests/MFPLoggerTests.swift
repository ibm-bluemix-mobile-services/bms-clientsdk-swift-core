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


// TODO: Update these tests to check if printToConsole was called, rather than checking for file existence
class MFPLoggerTests: XCTestCase {
    
    func testGetLoggerForName(){
        let name = "sample"
        
        let logger = Logger.getLoggerForName(name)
        
        XCTAssertTrue(logger.name == Logger.loggerInstances[name]?.name)
    }
    
    func testNoInternalLogging(){
        let fakePKG = MFP_LOGGER_PACKAGE
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logLevelFilter = LogLevel.Debug
        Logger.sdkDebugLoggingEnabled = false
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        
    }
    
    
    func testLogMethods(){
        let fakePKG = "MYPKG"
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logLevelFilter = LogLevel.Debug
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        
    }
    
    func testLogWithNone(){
        let fakePKG = "MYPKG"
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logLevelFilter = LogLevel.None
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
     
        
    }
    
    func testIncorrectLogLevel(){
        let fakePKG = "MYPKG"
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logLevelFilter = LogLevel.Fatal
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        
        
    }

}
