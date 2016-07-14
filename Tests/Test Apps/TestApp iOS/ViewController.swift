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


import UIKit
import BMSCore


class ViewController: UIViewController, UITextFieldDelegate {

    
    @IBOutlet var responseLabel: UITextView!
    @IBOutlet var resourceUrl: UITextField!
    @IBOutlet var httpMethod: UITextField!
    
    
	let logger = Logger.logger(forName: "TestAppiOS")
    
    // Ignore the warning on the extraneous underscore in Swift 2. It is there for Swift 3.
    @IBAction func sendRequestButtonPressed(_ sender: AnyObject) {
        
        logSendButtonPressedEvent()
        
        var method: HttpMethod

        #if swift(>=3.0)
            
            switch httpMethod.text!.lowercased() {
            case "post":
                method = HttpMethod.POST
            case "put":
                method = HttpMethod.PUT
            case "delete":
                method = HttpMethod.DELETE
            case "trace":
                method = HttpMethod.TRACE
            case "head":
                method = HttpMethod.HEAD
            case "options":
                method = HttpMethod.OPTIONS
            case "connect":
                method = HttpMethod.CONNECT
            case "patch":
                method = HttpMethod.PATCH
            default:
                method = HttpMethod.GET
            }
            
        #else
            
            switch httpMethod.text!.lowercaseString {
            case "post":
            method = HttpMethod.POST
            case "put":
            method = HttpMethod.PUT
            case "delete":
            method = HttpMethod.DELETE
            case "trace":
            method = HttpMethod.TRACE
            case "head":
            method = HttpMethod.HEAD
            case "options":
            method = HttpMethod.OPTIONS
            case "connect":
            method = HttpMethod.CONNECT
            case "patch":
            method = HttpMethod.PATCH
            default:
            method = HttpMethod.GET
            }

        #endif
        
        let getRequest = Request(url: resourceUrl.text!, headers: nil, queryParameters: nil, method: method, timeout: 5.0)
        #if swift(>=3.0)
            getRequest.send(completionHandler: populateInterfaceWithResponseData)
        #else
            getRequest.sendWithCompletionHandler(populateInterfaceWithResponseData)
        #endif
    }
    
    
    private func populateInterfaceWithResponseData(response: Response?, error: NSError?) {
        
        var responseLabelText = ""
        
        if let responseError = error {
            responseLabelText = "ERROR: \(responseError.localizedDescription)"
            #if swift(>=3.0)
                logger.error(message: responseLabelText)
            #else
                logger.error(responseLabelText)
            #endif
        }
        else if response != nil {
            let status = response!.statusCode ?? 0
            let headers = response!.headers ?? [:]
            let responseText = response!.responseText ?? ""
            
            responseLabelText = "Status Code: \(status) \n\n"
            responseLabelText += "Headers: \(headers) \n\n"
            responseLabelText += "Response Text: \(responseText) \n\n"
        }
        
        #if swift(>=3.0)
            DispatchQueue.main.async(execute: {
                self.responseLabel.text = responseLabelText
            })
        #else
            dispatch_async(dispatch_get_main_queue(), {
                self.responseLabel.text = responseLabelText
            })
        #endif
    }
    
    
    private func logSendButtonPressedEvent() {
        
        #if swift(>=3.0)
            logger.debug(message: "Sending Request button pressed")
        #else
            logger.debug("Sending Request button pressed")
        #endif
        
        // NOTE: All of the methods below do nothing since the implementation (the BMSAnalytics framework) is not provided
        // These method calls are just to confirm the existence of the APIs
        
        let eventMetadata = ["buttonPressed": "send"]
        
        #if swift(>=3.0)
            Analytics.log(metadata: eventMetadata)
        #else
            Analytics.log(eventMetadata)
        #endif
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        responseLabel.layer.borderWidth = 1
    }
    
    // Ignore the warning on the extraneous underscore in Swift 2. It is there for Swift 3.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

}

