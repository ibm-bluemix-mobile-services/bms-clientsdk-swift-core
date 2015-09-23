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
    
    public let responseJSON: AnyObject?
    
    
    
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
            
            do {
                self.responseJSON = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers)
            }
            catch {
                self.responseJSON = nil
                // Log a warning/error
            }
        }
        else {
            self.responseData = nil
            self.responseText = nil
            self.responseJSON = nil
        }
        
        if let status = statusCode {
            isSuccessful = (200..<300 ~= status)
        }
        else {
            isSuccessful = false
        }
    }
    
}
