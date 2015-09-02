//
//  ResponseListener.swift
//  BMSCore
//
//  Created by Anthony Oliveri on 9/1/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import Foundation


/**
 * ResponseListener is the interface that will be called after the ResourceRequest has completed or failed.
 */

public protocol ResponseListener {
    
    /**
     *  This method will be called only when a response from the server has been received with an http status
     *  in the 200 range.
     *  @param response The server response
     */
    func onSuccess (response: Response)
    
    /**
     *  This method will be called either when there is no response from the server or when the status
     *  from the server response is in the 400 or 500 ranges. The FailResponse contains an error code
     *  distinguishing between the different cases.
     *
     *  @param response Contains detail regarding why the request failed
     *  @param error Error that could have caused the request to fail. Null if no error is thrown.
     */
    func onFailure (response: Response, error: NSError)
    
}