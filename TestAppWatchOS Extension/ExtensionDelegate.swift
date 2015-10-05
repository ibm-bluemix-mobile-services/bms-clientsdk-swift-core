//
//  ExtensionDelegate.swift
//  TestAppWatchOS Extension
//
//  Created by Anthony Oliveri on 10/5/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import WatchKit
import BMSCoreWatchOS

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        
        let myBMSClient = BMSClient.sharedInstance
        myBMSClient.initializeForBluemixApp(route: "", GUID: "")
        myBMSClient.defaultRequestTimeout = 10.0 // seconds
    }

}
