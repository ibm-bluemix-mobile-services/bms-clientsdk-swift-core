//
//  AppDelegate.swift
//  TestAppiOS
//
//  Created by Anthony Oliveri on 10/5/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit
import BMSCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let myBMSClient = BMSClient.sharedInstance
        myBMSClient.initializeWithBluemixAppRoute("", bluemixAppGUID: "", bluemixRegionSuffix: REGION_US_SOUTH)
        myBMSClient.defaultRequestTimeout = 10.0 // seconds
        
        // TODO: Get a real apiKey from Bluemix app
        Analytics.initializeWithAppName("TestAppiOS", apiKey: "REPLACE WITH ACTUAL API KEY")
        
        Analytics.startRecordingApplicationLifecycle()
        
        return true
    }

}

