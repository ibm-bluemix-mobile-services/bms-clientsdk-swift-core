//
//  InterfaceController.swift
//  TestAppWatchOS Extension
//
//  Created by Anthony Oliveri on 10/5/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import WatchKit
import Foundation
import BMSCoreWatchOS


class InterfaceController: WKInterfaceController {

    
    @IBOutlet var responseLabel: WKInterfaceLabel!
    
    
    @IBAction func getRequestButtonPressed() {
        
        Analytics.log(["buttonPressed": "getRequest"])
        Analytics.send()
        
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
    
}
