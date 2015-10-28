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


public enum LogLevel: Int {
    
    case Analytics, Fatal, Error, Warn, Info, Debug, None
}


public class Logger {
    
    
    // MARK: Properties
    
    private static var loggerInstances: [String: Logger] = [:]
    
    public let name: String
    
    public static var logStoreEnabled: Bool = true
    
    public static var logLevel: LogLevel {
        get {
            return LogLevel.Debug
        }
        set {
            
        }
    }
    
    public static var maxLogStoreSize: Int {
        get {
            return 1
        }
        set {
            
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
    
    
    
    // MARK: Methods
    
    public func getLoggerForName(loggerName: String) -> Logger {
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
        Logger.captureUncaughtExceptions()
    }
    
    public func debug(message: String, error: ErrorType? = nil) { }
    
    public func info(message: String, error: ErrorType? = nil) { }
    
    public func warn(message: String, error: ErrorType? = nil) { }
    
    public func error(message: String, error: ErrorType? = nil) { }
    
    public func fatal(message: String, error: ErrorType? = nil) { }
    
    public func send(completionHandler callback: MfpCompletionHandler? = nil) { }
    
    public func updateLogProfile(withCompletionHandler callback: MfpCompletionHandler? = nil) { }
    
    // In documentation, explain that developer needs to call this method if they set their own uncaught exception handler
    public static func captureUncaughtExceptions() { }
    
}
