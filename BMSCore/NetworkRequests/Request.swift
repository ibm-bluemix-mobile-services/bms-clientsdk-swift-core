//
//  Request.swift
//  BMSCore
//
//  Created by Vitaly Meytin on 12/21/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import Foundation

public class Request: MFPRequest {
    public override func sendWithCompletionHandler(callback: MfpCompletionHandler?) {
        
        let authManager: AuthorizationManager = BMSClient.sharedInstance.sharedAuthorizationManager
        
        if let authHeader: String = authManager.getCachedAuthorizationHeader() {
            self.headers["Authorization"] = authHeader
        }
        
        func processResponse(response: Response?, error: NSError?) {
            if (authManager.isOAuthError(response)) {
                authManager.obtainAuthorizationHeader({
                    (response: Response?, error: NSError?) in (response != nil) ? self.sendWithCompletionHandler(callback) : callback?(response, error)
                });
            } else {
                callback?(response, error)
            }
        }
        
        super.sendWithCompletionHandler(processResponse)
    }
}