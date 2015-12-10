//
//  ViewController.swift
//  TestAppiOS
//
//  Created by Anthony Oliveri on 10/5/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit
import BMSCore

// TODO: Fix the storyboard so that the view fits in all iOS screen sizes

class ViewController: UIViewController, UITextFieldDelegate {

    
    @IBOutlet var responseLabel: UITextView!
    @IBOutlet var resourceUrl: UITextField!
    @IBOutlet var httpMethod: UITextField!
    
    
    @IBAction func sendRequestButtonPressed(sender: AnyObject) {
        
        Analytics.log(["buttonPressed": "sendRequest"])
        Analytics.send()
        
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
        
        let getRequest = Request(url: resourceUrl.text!, headers: nil, queryParameters: nil, method: method, timeout: 10.0)
        getRequest.sendWithCompletionHandler(populateInterfaceWithResponseData)
    }
    
    
    private func populateInterfaceWithResponseData(response: Response?, error: NSError?) {
        
        var responseLabelText = ""
        
        if let responseError = error {
            responseLabelText = "ERROR: \(responseError.localizedDescription)"
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

}

