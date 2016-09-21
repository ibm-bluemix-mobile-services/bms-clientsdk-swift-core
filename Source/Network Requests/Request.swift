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


/**
    Sends HTTP network requests to access resources protected by the Bluemix Mobile Client Access. 
 
    Analytics data is automatically gathered for all requests initiated by this class.

    When building a Request object, all components of the HTTP request must be provided in the initializer, except for the `requestBody`, which can be supplied as either Data or plain text when sending the request via one of the following methods:

        sendString(requestBody: String, withCompletionHandler callback: BMSCompletionHandler?)
        sendData(requestBody: Data, withCompletionHandler callback: BMSCompletionHandler?)
 */
public class Request: BaseRequest {
    
    
    // MARK: Properties (internal)
    
    internal var oauthFailCounter = 0
    
#if swift(>=3.0)
    internal var savedRequestBody: Data?
#else
    internal var savedRequestBody: NSData?
#endif
    
    
    
    // MARK: Method overrides
    
    
#if swift(>=3.0)
    
    
    public override func send(requestBody: Data? = nil, completionHandler: BMSCompletionHandler?) {
        
        let authManager: AuthorizationManager = BMSClient.sharedInstance.authorizationManager
        
        if let authHeader: String = authManager.cachedAuthorizationHeader {
            self.headers["Authorization"] = authHeader
        }
        
        savedRequestBody = requestBody
        
        let sendCompletionHandler : BMSCompletionHandler = {(response: Response?, error: Error?) in
            
            guard error == nil else {
				if let completionHandler = completionHandler{
					completionHandler(response, error)
				}
                return
            }
			
			let authManager = BMSClient.sharedInstance.authorizationManager
            guard let unWrappedResponse = response,
					authManager.isAuthorizationRequired(for: unWrappedResponse) &&
                    self.oauthFailCounter < 2
			else {
                self.oauthFailCounter += 1
                if (response?.statusCode)! >= 400 {
                    completionHandler?(response, BMSCoreError.serverRespondedWithError)
                }
                else {
                    completionHandler?(response, nil)
                }
                return
            }
            
            self.oauthFailCounter += 1
            
            let authCallback: BMSCompletionHandler = {(response: Response?, error:Error?) in
                if error == nil {
                    if let myRequestBody = self.requestBody {
                        self.send(requestBody: myRequestBody, completionHandler: completionHandler)
                    }
                    else {
                        self.send(completionHandler: completionHandler)
                    }
                } else {
                    completionHandler?(response, error)
                }
            }
			authManager.obtainAuthorization(completionHandler: authCallback)
        }
        
        super.send(completionHandler: sendCompletionHandler)
    }
    
    
#else
    
    
    public override func send(requestBody requestBody: NSData? = nil, completionHandler: BMSCompletionHandler?) {
        
        let authManager: AuthorizationManager = BMSClient.sharedInstance.authorizationManager
        
        if let authHeader: String = authManager.cachedAuthorizationHeader {
            self.headers["Authorization"] = authHeader
        }
        
        savedRequestBody = requestBody
        
        let myCallback : BMSCompletionHandler = {(response: Response?, error: NSError?) in
            
            guard error == nil else {
                if let callback = completionHandler{
                    callback(response, error)
                }
                return
            }
            
            let authManager = BMSClient.sharedInstance.authorizationManager
            guard let unWrappedResponse = response where
                authManager.isAuthorizationRequired(for: unWrappedResponse) &&
                    self.oauthFailCounter < 2
                else {
                    self.oauthFailCounter += 1
                    if (response?.statusCode)! >= 400 {
                        completionHandler?(response, NSError(domain: BMSCoreError.domain, code: BMSCoreError.serverRespondedWithError.rawValue, userInfo: nil))
                    }
                    else {
                        completionHandler?(response, nil)
                    }
                    return
            }
            
            self.oauthFailCounter += 1
            
            let authCallback: BMSCompletionHandler = {(response: Response?, error:NSError?) in
                if error == nil {
                    if let myRequestBody = self.requestBody {
                        self.send(requestBody: myRequestBody, completionHandler: completionHandler)
                    }
                    else {
                        self.send(completionHandler: completionHandler)
                    }
                } else {
                    completionHandler?(response, error)
                }
            }
            authManager.obtainAuthorization(completionHandler: authCallback)
        }
        
        super.send(completionHandler: myCallback)
    }
    
    
#endif
    
    
}
