/*
*     Copyright 2016 IBM Corp.
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


class ViewController: UIViewController, UITextFieldDelegate {

    
    @IBOutlet var resourceUrl: UITextField!
    @IBOutlet var httpMethodPicker: UIPickerView!
    @IBOutlet var callbackPicker: UIPickerView!
    @IBOutlet var progressBar: UIProgressView!
    @IBOutlet var responseLabel: UITextView!
    
    let callbackViewController = CallbackPickerViewController()
    let httpMethodViewController = HttpMethodPickerViewController()
    
    let logger = Logger.logger(name: "TestAppiOS")

#if swift(>=3.0)
    let imageFile = Bundle.main.url(forResource: "Andromeda", withExtension: "jpg")!
#else
    let imageFile = NSBundle.mainBundle().URLForResource("Andromeda", withExtension: "jpg")!
#endif
    
    
    var bmsUrlSession: BMSURLSession {
        
        switch callbackViewController.callbackType {
            
        case .delegate:
            #if swift(>=3.0)
                return BMSURLSession(configuration: .default, delegate: URLSessionDelegateExample(viewController: self), delegateQueue: nil)
            #else
                return BMSURLSession(configuration: .defaultSessionConfiguration(), delegate: URLSessionDelegateExample(viewController: self), delegateQueue: nil)
            #endif
            
        case .completionHandler:
            #if swift(>=3.0)
                return BMSURLSession(configuration: .default, delegate: nil, delegateQueue: nil)
            #else
                return BMSURLSession(configuration: .defaultSessionConfiguration(), delegate: nil, delegateQueue: nil)
            #endif
        }
    }
    
    
#if swift(>=3.0)
    
    var request: URLRequest? {
        
        guard let requestUrl = URL(string: resourceUrl.text!) else {
            logger.error(message: "Invalid URL")
            return nil
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = httpMethodViewController.httpMethod.rawValue
        return request
    }
    
#else
    
    var request: NSURLRequest? {

        guard let requestUrl = NSURL(string: resourceUrl.text!) else {
            logger.error(message: "Invalid URL")
            return nil
        }
        
        let request = NSMutableURLRequest(URL: requestUrl)
        request.HTTPMethod = httpMethodViewController.httpMethod.rawValue
        return request
    }
    
#endif
    
    
    
    @IBAction func sendDataTaskRequest(sender button: UIButton) {
        
        guard request != nil else {
            return
        }
        
        #if swift(>=3.0)
        
            switch callbackViewController.callbackType {
            case .delegate:
                bmsUrlSession.dataTask(with: request!).resume()
            case .completionHandler:
                bmsUrlSession.dataTask(with: request!, completionHandler: displayData).resume()
            }
        
        #else
        
            switch callbackViewController.callbackType {
            case .delegate:
                bmsUrlSession.dataTaskWithRequest(request!).resume()
            case .completionHandler:
                bmsUrlSession.dataTaskWithRequest(request!, completionHandler: displayData).resume()
            }
        
        #endif
    }
    
    
    @IBAction func sendUploadTaskRequest(sender button: UIButton) {
        
        guard request != nil else {
            return
        }
        
        #if swift(>=3.0)
        
            switch callbackViewController.callbackType {
            case .delegate:
                bmsUrlSession.uploadTask(with: request!, fromFile: imageFile).resume()
            case .completionHandler:
                bmsUrlSession.uploadTask(with: request!, fromFile: imageFile, completionHandler: displayData).resume()
            }
        
        #else
        
            switch callbackViewController.callbackType {
            case .delegate:
                bmsUrlSession.uploadTaskWithRequest(request!, fromFile: imageFile).resume()
            case .completionHandler:
                bmsUrlSession.uploadTaskWithRequest(request!, fromFile: imageFile, completionHandler: displayData).resume()
            }
        
        #endif
    }
    
    
#if swift(>=3.0)
    
    func displayData(_ data: Data?, response: URLResponse?, error: Error?) {
        
        var answer = ""
        if let response = response as? HTTPURLResponse {
            answer += "Status code: \(response.statusCode)\n\n"
        }
        if data != nil {
            answer += "Response Data: \(String(data: data!, encoding: .utf8)!))\n\n"
        }
        if error != nil {
            answer += "Error:  \(error!)"
        }
        DispatchQueue.main.async {
            self.responseLabel.text = answer
        }
    }
    
#else
    
    func displayData(data: NSData?, response: NSURLResponse?, error: NSError?) {
        
        var answer = ""
        if let response = response as? NSHTTPURLResponse {
            answer += "Status code: \(response.statusCode)\n\n"
        }
        if data != nil {
            answer += "Response Data: \(String(data: data!, encoding: NSUTF8StringEncoding)!))\n\n"
        }
        if error != nil {
            answer += "Error:  \(error!)"
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.responseLabel.text = answer
        })
    }
    
#endif
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.callbackPicker.dataSource = callbackViewController
        self.callbackPicker.delegate = callbackViewController
        
        self.httpMethodPicker.dataSource = httpMethodViewController
        self.httpMethodPicker.delegate = httpMethodViewController
        
        #if swift(>=3.0)
            self.progressBar.transform = CGAffineTransform(scaleX: 1, y: 2)
        #else
            self.progressBar.transform = CGAffineTransformMakeScale(1, 2)
        #endif
        responseLabel.layer.borderWidth = 1
    }
    
    
    
#if swift(>=3.0)
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
#else
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
#endif
}
