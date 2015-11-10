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


public class Analytics {
    
    
    // MARK: Properties (public)

    // TODO: Should this class use a singleton? Static methods/properties seem to work fine.
    public static let sharedInstance = Analytics()
    
    public static var enabled: Bool = true
    
    
    
    // MARK: Properties (internal/private)
    
    internal static let logger = Logger.getLoggerForName(MFP_ANALYTICS_PACKAGE)
    
    
    
    // MARK: Methods (public)
    
    public static func log(metadata: [String: AnyObject]) {
        
        logger.analytics(metadata)
    }
    
    
    public static func send(completionHandler: MfpCompletionHandler? = nil) {
    
        logger.send(completionHandler: completionHandler)
    }
    
    
    // Remove the observers registered in the Analytics+iOS "startRecordingApplicationLifecycleEvents" method
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}



// MARK: Constants

private let MFP_ANALYTICS_PACKAGE = "mfpsdk.analytics"
