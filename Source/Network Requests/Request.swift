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


public class Request: MFPRequest {
    
    private var oauthFailCounter = 0
    private var savedRequestBody: NSData?
    private var domainName = "com.ibm.bms.mca.client"
    public init(url: String, method: HttpMethod) {
        super.init(url: url, headers: nil, queryParameters:nil, method: method)
    }
    
    public override func sendWithCompletionHandler(callback: MfpCompletionHandler?) {
        
        let authManager: AuthorizationManager = BMSClient.sharedInstance.sharedAuthorizationManager
        
        if let authHeader: String = authManager.getCachedAuthorizationHeader() {
            self.headers["Authorization"] = authHeader
        }
        
        savedRequestBody = requestBody
        
        let myCallback : MfpCompletionHandler = {(response: Response?, error:NSError?) in
            
            guard error == nil else {
                callback?(response, error)
                return
            }
            
            guard let unWrappedResponse = response where
                BMSClient.sharedInstance.sharedAuthorizationManager.isAuthorizationRequired(unWrappedResponse) &&
                    self.oauthFailCounter++ < 2
                else {
                if (response?.statusCode)! >= 400 {
                        callback?(response, NSError(domain: self.domainName, code: -1, userInfo: nil))
                    } else {
                        callback?(response, nil)
                    }
                    return
                }
            
            let authCallback: MfpCompletionHandler = {(response: Response?, error:NSError?) in
                if error == nil {
                    if let myRequestBody = self.requestBody {
                        self.sendData(myRequestBody, withCompletionHandler: nil)
                    }
                    else {
                        self.sendWithCompletionHandler(callback)
                    }
                } else {
                    callback?(response, error)
                }
            }
            authManager.obtainAuthorization(authCallback)
        }
        
        super.sendWithCompletionHandler(myCallback)
    }
}