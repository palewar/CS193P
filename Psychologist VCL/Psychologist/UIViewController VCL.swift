//
//  UIViewController VCL.swift
//  Psychologist
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

var accumulatingLogVCLprefix = ""
var lastLogVCLPrefixRequest: NSDate?

extension UIViewController {
    var logVCLprefix: String {
        if let lastRequestDate = lastLogVCLPrefixRequest {
            if lastRequestDate.timeIntervalSinceNow < -2 {
                accumulatingLogVCLprefix += "__"
            }
        }
        lastLogVCLPrefixRequest = NSDate(timeIntervalSinceNow: 0)
        return accumulatingLogVCLprefix
    }
}
