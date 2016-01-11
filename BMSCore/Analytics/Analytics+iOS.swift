///*
//*     Copyright 2015 IBM Corp.
//*     Licensed under the Apache License, Version 2.0 (the "License");
//*     you may not use this file except in compliance with the License.
//*     You may obtain a copy of the License at
//*     http://www.apache.org/licenses/LICENSE-2.0
//*     Unless required by applicable law or agreed to in writing, software
//*     distributed under the License is distributed on an "AS IS" BASIS,
//*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//*     See the License for the specific language governing permissions and
//*     limitations under the License.
//*/
//
//
//import UIKit
//
//
//public extension Analytics {
//    
//    /**
//        Records the duration of the app's lifecycle from when it enters the foreground to when it goes to the background.
//        This data will be sent to the Analytics server, provided that the `Analytics.enabled` property is set to `true`.
//        
//        This method should be called in the `AppDelegate didFinishLaunchingWithOptions` method.
//    */
//    public static func startRecordingApplicationLifecycle() {
//        
//        // By now, the app will have already passed the "will enter foreground" event. Therefore, we must manually start the timer for the current session.
//        logSessionStart()
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "logSessionStart", name: UIApplicationWillEnterForegroundNotification, object: nil)
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "logSessionEnd", name: UIApplicationDidEnterBackgroundNotification, object: nil)
//    }
//    
//    
//    /**
//        Cease recording app lifecycle events.
//    */
//    public static func stopRecordingApplicationLifecycle() {
//        
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
//        
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
//    }
//    
//}
