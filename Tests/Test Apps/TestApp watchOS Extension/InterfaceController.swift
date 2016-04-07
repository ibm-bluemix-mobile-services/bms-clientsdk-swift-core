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
import BMSCore


class InterfaceController: WKInterfaceController {

    
    @IBOutlet var responseLabel: WKInterfaceLabel!
    
    
    @IBAction func getRequestButtonPressed() {
        
        let getRequest = Request(url: "http://httpbin.org/get", headers: nil, queryParameters: nil, method: HttpMethod.GET, timeout: 10.0)
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
    
    private func logSendButtonPressedEvent() {
        
        Logger.logLevelFilter = LogLevel.Debug
        
		let logger = Logger.logger(forName: "TestAppWatchOS")
        logger.debug("GET request button pressed")
        
        
        // NOTE: All of the methods below do nothing since the implementation (the BMSAnalytics framework) is not provided
        // These method calls are just to confirm the existence of the APIs
        
        let eventMetadata = ["buttonPressed": "GET Request"]
        Analytics.log(eventMetadata)
    }
}
