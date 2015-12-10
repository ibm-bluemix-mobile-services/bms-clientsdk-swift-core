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
        myBMSClient.initializeWithBluemixAppRoute("", bluemixAppGUID: "", bluemixRegionSuffix: REGION_US_SOUTH)
        myBMSClient.defaultRequestTimeout = 10.0 // seconds
        
        // TODO: Get a real apiKey from Bluemix app
        Analytics.initializeWithAppName("TestAppWatchOS", apiKey: "REPLACE WITH ACTUAL API KEY")
    }
    
    func applicationDidBecomeActive() {
        Analytics.recordApplicationDidBecomeActive()
    }
    
    func applicationWillResignActive() {
        Analytics.recordApplicationWillResignActive()
    }

}
