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
    
    // CODE REVIEW: Add checks for unwrapping headers and status code (print error if they are nil)
    @IBAction func getRequestButtonPressed(sender: AnyObject) {
        
        let getRequest = Request(url: "http://httpbin.org/get", headers: nil, queryParameters: nil, method: HttpMethod.GET, timeout: 10.0)
        getRequest.sendWithCompletionHandler( { (response: Response, error: ErrorType?) in
            
            var responseLabelText = ""
            
            if let responseError = error {
                responseLabelText = "ERROR: \(responseError)"
            }
            else {
                responseLabelText = "Status Code: \(response.statusCode!) \n\n"
                responseLabelText += "Headers: \(response.headers!) \n\n"
                responseLabelText += "Response Text: \(response.responseText!) \n\n"
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.responseLabel.text = responseLabelText
            })
        } )
    }
    

    @IBAction func postRequestButtonPressed(sender: AnyObject) {
        
        let getRequest = Request(url: "http://httpbin.org/post", headers: nil, queryParameters: nil, method: HttpMethod.POST, timeout: 10.0)
        getRequest.sendWithCompletionHandler( { (response: Response, error: ErrorType?) in
            
            var responseLabelText = ""
            
            if let responseError = error {
                responseLabelText = "ERROR: \(responseError)"
            }
            else {
                responseLabelText = "Status Code: \(response.statusCode!) \n\n"
                responseLabelText += "Headers: \(response.headers!) \n\n"
                responseLabelText += "Response Text: \(response.responseText!) \n\n"
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

