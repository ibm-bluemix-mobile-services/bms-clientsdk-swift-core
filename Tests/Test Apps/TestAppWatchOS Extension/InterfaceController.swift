/*
*     Copyright 2016 IBM Corp.
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


import WatchKit
import Foundation
import BMSCoreWatchOS


class InterfaceController: WKInterfaceController {

    
    @IBOutlet var responseLabel: WKInterfaceLabel!
    
    
    @IBAction func getRequestButtonPressed() {
        
        testLoggerAndAnalytics()
        
        let getRequest = MFPRequest(url: "http://httpbin.org/get", headers: nil, queryParameters: nil, method: HttpMethod.GET, timeout: 10.0)
        getRequest.sendWithCompletionHandler( { (response: Response?, error: NSError?) in
            
            var responseLabelText = ""
            
            if let responseError = error {
                responseLabelText = "ERROR: \(responseError.localizedDescription)"
            }
            else if response != nil {
                let status = response!.statusCode ?? 0
                responseLabelText = "Status: \(status) \n\n"
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.responseLabel.setText(responseLabelText)
            })
        } )
    }
    
    
    func testLoggerAndAnalytics() {
        
        Analytics.enabled = true
        
        Analytics.log(["buttonPressed": "getRequest"])
        Analytics.send { (response: Response?, error: NSError?) -> Void in
            if let response = response {
                print("\nAnalytics sent successfully: " + String(response.isSuccessful))
                print("Status Code: " + String(response.statusCode))
                if let responseText = response.responseText {
                    print("Response text: " + responseText)
                }
                print("")
            }
        }
        
        Logger.logLevelFilter = LogLevel.Debug
        Logger.logStoreEnabled = true
        
        let testLogger = Logger.getLoggerForName("Test")
        testLogger.debug("Sending GET request")
        Logger.send { (response: Response?, error: NSError?) -> Void in
            if let response = response {
                print("\nLogs sent successfully: " + String(response.isSuccessful))
                print("Status Code: " + String(response.statusCode))
                if let responseText = response.responseText {
                    print("Response text: " + responseText)
                }
                print("")
            }
        }
    }
    
}
