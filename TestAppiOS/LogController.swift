//
//  LogController.swift
//  BMSCore
//
//  Created by Nana on 11/17/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit
import BMSCore

class LogController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource{

    @IBOutlet weak var crashButton: UIButton!
    
    
    let logArray = ["debug", "info", "warn", "error", "fatal"]
    var level = "debug"
    var type = "debug"
    @IBOutlet weak var packageName: UITextField!
    @IBOutlet weak var levelPicker: UIPickerView!
    @IBOutlet weak var typePicker: UIPickerView!
    
    @IBOutlet weak var capture: UISwitch!

    @IBOutlet weak var logMessage: UITextField!
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // The number of columns of data
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return logArray.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return logArray[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch pickerView.tag{
            case 0:
                print("Selecting log type " + logArray[row])
                type = logArray[row]
            case 1:
                print("Selected log level " + logArray[row])
                level = logArray[row]
            default:
                print("should not happen")
            
        }
    }
    
    @IBAction func sendLogButton(sender: AnyObject) {
        var logger = Logger.getLoggerForName("SampleLogger")
        if(!packageName.text!.isEmpty){
            logger = Logger.getLoggerForName(packageName.text!)
        }
        
        if(capture.enabled){
                Logger.internalSDKLoggingEnabled = true
        } else {
            Logger.internalSDKLoggingEnabled = false
        }
        

//        switch level {
//            case "debug":
//                Logger.logLevel = LogLevel.Debug
//            
//        }
        
        switch type {
            case "debug":
                logger.debug(logMessage.text!)
            case "info":
                logger.info(logMessage.text!)
            case "warn":
                logger.warn(logMessage.text!)
            case "error":
                logger.error(logMessage.text!)
            case "fatal":
                logger.fatal(logMessage.text!)
            default:
                logger.debug(logMessage.text!)
            
        }
      
    }
    
    @IBAction func crashAppButton(sender: AnyObject){
        let e = NSException(name:"crashApp", reason:"No reason at all just doing it for fun", userInfo:["user":"nana"])
        e.raise()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.typePicker.delegate = self
        self.typePicker.dataSource = self
        self.typePicker.tag = 0
        
        self.levelPicker.delegate = self
        self.levelPicker.tag = 1
        self.levelPicker.dataSource = self
    }
    
    

}

