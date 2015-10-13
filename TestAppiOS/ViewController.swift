//
//  ViewController.swift
//  TestAppiOS
//
//  Created by Anthony Oliveri on 10/5/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit
import BMSCore

class ViewController: UIViewController {

    
    @IBOutlet var responseLabel: UITextView!
    
    
    @IBAction func getRequestButtonPressed(sender: AnyObject) {
        
        let getRequest = Request(url: "http://httpbin.org/get", headers: nil, queryParameters: nil, method: HttpMethod.GET, timeout: 10.0)
        getRequest.sendWithCompletionHandler(populateInterfaceWithResponseData)
    }
    

    @IBAction func postRequestButtonPressed(sender: AnyObject) {
        
        let getRequest = Request(url: "http://httpbin.org/post", headers: nil, queryParameters: nil, method: HttpMethod.POST, timeout: 10.0)
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

}

