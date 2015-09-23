//
//  BMSResponse.swift
//  BMSCore
//
//  Created by Anthony Oliveri on 9/17/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import Foundation


public struct MFPResponse: Response {
    
    
    // MARK: Properties (public)
    
    public let statusCode: Int?
    
    public let headers: [NSObject: AnyObject]?
    
    public let responseText: String?
    
    public let responseData: NSData?
    
    
    
    // MARK: Properties (internal/private)
    
    let httpResponse: NSHTTPURLResponse?
    
    let isSuccessful: Bool?
    
    let isRedirect: Bool
    
    
    
    // MARK: Initializer
    
    init(responseData: NSData?, httpResponse: NSHTTPURLResponse?, isRedirect: Bool) {
        
        self.isRedirect = isRedirect
        self.httpResponse = httpResponse
        self.headers = httpResponse?.allHeaderFields
        self.statusCode = httpResponse?.statusCode
        
        if let responseData = responseData {
            self.responseData = responseData
            self.responseText = String(NSString(data: responseData, encoding: NSUTF8StringEncoding))
        }
        else {
            self.responseData = nil
            self.responseText = nil
        }
        
        if let status = statusCode {
            isSuccessful = (200..<300 ~= status)
        }
        else {
            isSuccessful = false
        }
    }
    
}
