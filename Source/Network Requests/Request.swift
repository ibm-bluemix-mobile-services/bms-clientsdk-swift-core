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


import Foundation

public class Request: MFPRequest {
    
    public init(url: String, method: HttpMethod) {
        super.init(url: url, headers: nil, queryParameters:nil, method: method)
    }
    
    public override func sendWithCompletionHandler(callback: MfpCompletionHandler?) {
        
        let authManager: AuthorizationManager = BMSClient.sharedInstance.sharedAuthorizationManager
        
        if let authHeader: String = authManager.getCachedAuthorizationHeader() {
            self.headers["Authorization"] = authHeader
        }
        
        let myCallback : MfpCompletionHandler = {(response: Response?, error:NSError?) in
            if error == nil {
                print (2)
                if let unWrappedResponse = response {
                    if BMSClient.sharedInstance.sharedAuthorizationManager.isAuthorizationRequired(unWrappedResponse) {
                        let authCallback: MfpCompletionHandler = {(response: Response?, error:NSError?) in
                            if error != nil {
                                print(1)
                            }
                        }
                        
                        authManager.obtainAuthorization(authCallback)
                    }
                    
                } else {
                    
                }
                
            }
            else {
                callback?(response, error)
            }
            
            
        }
        
        
//        
//        //TODO: ilan - fix
//        func processResponse(response: Response?, error: NSError?) {
////            if (authManager.isOAuthError(response)) {
////                authManager.obtainAuthorizationHeader({
////                    (response: Response?, error: NSError?) in (response != nil) ? self.sendWithCompletionHandler(callback) : callback?(response, error)
////                });
////            } else {
////                callback?(response, error)
////            }
//        }
        
        super.sendWithCompletionHandler(myCallback)
    }
}