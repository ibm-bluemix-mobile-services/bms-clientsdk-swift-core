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
//        myBMSClient.initializeForBluemixApp(route: "", GUID: "")
//        myBMSClient.defaultRequestTimeout = 10.0 // seconds
        
        return true
    }

}

