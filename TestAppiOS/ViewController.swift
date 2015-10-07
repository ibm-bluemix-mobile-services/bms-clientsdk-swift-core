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
        
        let getRequest = Request(url: NSURL(string: "http://httpbin.org/get")!, method: HttpMethod.GET, timeout: 10.0)
        getRequest.sendWithCompletionHandler( { (response: MFPResponse, error: ErrorType?) in
            
            var responseLabelText = ""
            
            if let responseError = error {
                responseLabelText = "ERROR: \(responseError)"
            }
            else {
                responseLabelText = "Status Code: \(response.statusCode!) \n\n"
                responseLabelText += "Headers: \(response.headers) \n\n"
                responseLabelText += "Response Text: \(response.responseText) \n\n"
                responseLabelText += "Response JSON: \(response.responseJSON) \n\n"
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.responseLabel.text = responseLabelText
            })
        } )
    }
    

    @IBAction func postRequestButtonPressed(sender: AnyObject) {
        
        let getRequest = Request(url: NSURL(string: "http://httpbin.org/post")!, method: HttpMethod.POST, timeout: 10.0)
        getRequest.sendWithCompletionHandler( { (response: MFPResponse, error: ErrorType?) in
            
            var responseLabelText = ""
            
            if let responseError = error {
                responseLabelText = "ERROR: \(responseError)"
            }
            else {
                responseLabelText = "Status Code: \(response.statusCode!) \n\n"
                responseLabelText += "Headers: \(response.headers) \n\n"
                responseLabelText += "Response Text: \(response.responseText) \n\n"
                responseLabelText += "Response JSON: \(response.responseJSON) \n\n"
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.responseLabel.text = responseLabelText
            })
        } )
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

