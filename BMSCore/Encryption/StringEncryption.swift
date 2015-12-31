//
//  StringEncryption.swift
//  BMSSecurity
//
//  Created by Oded Betzalel on 12/29/15.
//  Copyright © 2015 IBM. All rights reserved.
//


public protocol StringEncryption {
    func encrypt(str:String)->String;
    func decrypt(str:String)->String;

}
