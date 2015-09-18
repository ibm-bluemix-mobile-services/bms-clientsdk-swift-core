//
//  BMSResponse.swift
//  BMSCore
//
//  Created by Anthony Oliveri on 9/17/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import Foundation


// TODO: Documentation
public struct BMSResponse: Response {
    
    
    // MARK: Properties (public)
    
    public let statusCode: Int?
    
    // TODO: Change from [NSObject: AnyObject] to [String: String]?
    public let headers: [NSObject: AnyObject]?
    
    public let responseText: String?
    
    // TODO: Change from AnyObject to [String: AnyObject]?
    public let responseJSON: AnyObject?
    
    public let responseData: NSData?
    
    public let error: ErrorType?
    
    
    
    // MARK: Properties (internal/private)
    
    let alamoFireResponse: NSHTTPURLResponse?
    
    let isSuccessful: Bool?
    
    let isRedirect: Bool
    
    
    
    // MARK: Initializer
    
    init(responseText: String?, responseJSON: AnyObject?, responseData: NSData?, error: ErrorType?, alamoFireResponse: NSHTTPURLResponse?, isRedirect: Bool) {
        
        self.responseText = responseText
        self.responseJSON = responseJSON
        self.responseData = responseData
        self.error = error
        self.alamoFireResponse = alamoFireResponse
        self.isRedirect = isRedirect
        
        self.statusCode = alamoFireResponse?.statusCode
        
        if let status = statusCode {
            isSuccessful = (200..<300 ~= status)
        }
        else {
            isSuccessful = false
        }
        
        self.headers = alamoFireResponse?.allHeaderFields
    }
    
}
