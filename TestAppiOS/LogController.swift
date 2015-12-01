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
    
    @IBOutlet weak var crashButton: UIButton!

    let logArray = ["none", "debug", "info", "warn", "error", "fatal"]
    var level = "debug"
    var type = "debug"
    @IBOutlet weak var packageName: UITextField!
    @IBOutlet weak var levelPicker: UIPickerView!
    @IBOutlet weak var typePicker: UIPickerView!
    @IBOutlet weak var logText: UITextView!
    @IBOutlet weak var maxLogStoreSize: UITextField!

  
    @IBOutlet weak var storeLogEnabled: UITextField!
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
        let FILE = "mfpsdk.logger.log"
        let PATH = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/"
        let pathToFile = PATH + FILE
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
    }
    @IBAction func updateLogText(sender: AnyObject) {
        let FILE = "mfpsdk.logger.log"
        let PATH = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/"
        let pathToFile = PATH + FILE
        var formattedContents:String
        
        do {
            formattedContents = try String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
            let fileContents = "[\(formattedContents)]"
            logText.text = fileContents.stringByReplacingOccurrencesOfString("\\\"", withString: "\"")
        } catch {
                logText.text = "Empty Log"
        }
//        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        
//        let fileContents = "[\(formattedContents)]"
  //      logText.text = fileContents
        
    }
    // The data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return logArray[row]
    }
    
    func JSONString(var str: String) -> String {
        // \b = \u{8}
        // \f = \u{12}
        let insensitive = NSStringCompareOptions.CaseInsensitiveSearch
        str = str
            .stringByReplacingOccurrencesOfString("\"", withString: "\\\"", options: insensitive)
            .stringByReplacingOccurrencesOfString("/", withString: "\\/", options: insensitive)
            .stringByReplacingOccurrencesOfString("\n", withString: "\\n", options: insensitive)
            .stringByReplacingOccurrencesOfString("\u{8}", withString: "\\b", options: insensitive)
            .stringByReplacingOccurrencesOfString("\u{12}", withString: "\\f", options: insensitive)
            .stringByReplacingOccurrencesOfString("\r", withString: "\\r", options: insensitive)
            .stringByReplacingOccurrencesOfString("\t", withString: "\\t", options: insensitive)
        return str;
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
        
        if(isUncaughtExceptionDetection.enabled){
            Logger.isUncaughtExceptionDetected = true
        } else {
            Logger.isUncaughtExceptionDetected = false
        }
        
        if(!maxLogStoreSize.text!.isEmpty){
            Logger.maxLogStoreSize = Int(maxLogStoreSize.text)
        }
        
        
        if(storeLogEnabled.enabled){
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

