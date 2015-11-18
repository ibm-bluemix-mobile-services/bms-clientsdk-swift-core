//
//  LogController.swift
//  BMSCore
//
//  Created by Nana on 11/17/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit
import BMSCore

class LogController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource{
    
    
    let logArray = ["debug", "info", "warn", "error", "fatal"]
    
    @IBOutlet weak var picker: UIPickerView!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // The number of columns of data
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return logArray.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return logArray[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.picker.delegate = self
        self.picker.dataSource = self
    }
    
    

}

