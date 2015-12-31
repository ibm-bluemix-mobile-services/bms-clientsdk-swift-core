//
//  Queue.swift
//  BMSCore
//
//  Created by Oded Betzalel on 12/29/15.
//  Copyright © 2015 IBM. All rights reserved.
//
// Queue data structure implementation

public class Queue<Element> {
    public var items = [Element]()
    public var size:Int {return items.count}
    
    public init() {}

    //adds element to queue
    public func add(element:Element){
        items.append(element)
    }

    //remove element from queue. if queue empty returns nil
    public func remove()->Element?{
        return isEmpty() ? nil : items.removeFirst()
    }
    
    //returns next element in queue(without removing). if queue empty, returns nil
    public func element()->Element?{
        return isEmpty() ? nil : items[0]
    }
    
    //checks if queue is empty
    public func isEmpty()->Bool {
        return size == 0 ? true : false
    }
}