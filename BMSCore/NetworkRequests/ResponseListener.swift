//
//  ResponseListener.swift
//  BMSCore
//
//  Created by Oded Betzalel on 12/29/15.
//  Copyright © 2015 IBM. All rights reserved.
//
import BMSCore
public protocol ResponseListener {
    func onSuccess(response:Response)
    
    //not sure which params onFailure should take. leaving it commented out for now
    //func onFailure()
}