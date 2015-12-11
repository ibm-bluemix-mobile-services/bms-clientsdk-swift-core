/*
*     Copyright 2015 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http://www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/

import UIKit
import BMSCore

class LogController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource{
    
    @IBOutlet weak var storeLogEnabled: UISwitch!
    @IBOutlet weak var crashButton: UIButton!
    let logArray = ["none", "debug", "info", "warn", "error", "fatal"]
    var level = "debug"
    var type = "debug"
    @IBOutlet weak var packageName: UITextField!
    @IBOutlet weak var levelPicker: UIPickerView!
    @IBOutlet weak var typePicker: UIPickerView!
    @IBOutlet weak var maxLogStoreSize: UITextField!
    @IBOutlet weak var isUncaughtExceptionDetection: UISwitch!
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
    
    @IBAction func clearLogButton(sender: AnyObject) {
        
        Analytics.log(["buttonPressed": "clearLog"])
        Analytics.send()
        
        let FILE = "mfpsdk.logger.log"
        let PATH = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/"
        let pathToFile = PATH + FILE
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
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
        
        Analytics.log(["buttonPressed": "sendLog"])
        Analytics.send()
        
        var logger = Logger.getLoggerForName("SampleLogger")
        if(!packageName.text!.isEmpty){
            logger = Logger.getLoggerForName(packageName.text!)
        }
        
        if(capture.on){
                Logger.sdkDebugLoggingEnabled = true
        } else {
            Logger.sdkDebugLoggingEnabled = false
        }
        
        // TODO: This should not be a toggle - Should instead be a text field that displays true or false
        
        if(isUncaughtExceptionDetection.on){
            Logger.isUncaughtExceptionDetected = true
        } else {
            Logger.isUncaughtExceptionDetected = false
        }
        
        if(!maxLogStoreSize.text!.isEmpty){
            Logger.maxLogStoreSize = UInt64(maxLogStoreSize.text!)!
        }
        
        
        if(storeLogEnabled.on){
                Logger.logStoreEnabled = true
        } else {
            Logger.logStoreEnabled = false
        }

        switch level {
            case "none":
                Logger.logLevelFilter = LogLevel.None
            case "debug":
                Logger.logLevelFilter = LogLevel.Debug
            case "info":
                Logger.logLevelFilter = LogLevel.Info
            case "warn":
                Logger.logLevelFilter = LogLevel.Warn
            case "error":
                Logger.logLevelFilter = LogLevel.Error
            case "fatal":
                Logger.logLevelFilter = LogLevel.Fatal
            default:
                Logger.logLevelFilter = LogLevel.Debug
        }
        
        switch type {
            case "none":
             print("Do nothing")
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

class TextController : UIViewController{

    
  
    @IBOutlet weak var logText: UITextView!

    override func viewDidLoad(){
        super.viewDidLoad()
          }
    
    @IBAction func dismiss(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            print("Dismissing Text Controller")
        }
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        let FILE = "mfpsdk.logger.log"
        let PATH = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/"
        let pathToFile = PATH + FILE
        var formattedContents:String
        
        do {
            formattedContents = try String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
            let fileContents = "[\(formattedContents)]"
            logText.text = fileContents
        } catch {
            logText.text = "Empty Log"
        }
        

    }

    
    
}

