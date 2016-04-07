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
    
    
    @IBAction func sendRequestButtonPressed(sender: AnyObject) {
        
        logSendButtonPressedEvent()
        
        var method: HttpMethod

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
        
        let getRequest = Request(url: resourceUrl.text!, headers: nil, queryParameters: nil, method: method, timeout: 5.0)
        getRequest.sendWithCompletionHandler(populateInterfaceWithResponseData)
    }
    
    
    private func populateInterfaceWithResponseData(response: Response?, error: NSError?) {
        
        var responseLabelText = ""
        
        if let responseError = error {
            responseLabelText = "ERROR: \(responseError.localizedDescription)"
            logger.error(responseLabelText)
        }
        else if response != nil {
            let status = response!.statusCode ?? 0
            let headers = response!.headers ?? [:]
            let responseText = response!.responseText ?? ""
            
            responseLabelText = "Status Code: \(status) \n\n"
            responseLabelText += "Headers: \(headers) \n\n"
            responseLabelText += "Response Text: \(responseText) \n\n"
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.responseLabel.text = responseLabelText
        })
    }
    
    
    private func logSendButtonPressedEvent() {
        
        logger.debug("Sending Request button pressed")
        
        // NOTE: All of the methods below do nothing since the implementation (the BMSAnalytics framework) is not provided
        // These method calls are just to confirm the existence of the APIs
        
        let eventMetadata = ["buttonPressed": "send"]
        Analytics.log(eventMetadata)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        responseLabel.layer.borderWidth = 1
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

}

