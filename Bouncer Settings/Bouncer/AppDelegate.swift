//
//  AppDelegate.swift
//  Bouncer
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit
import CoreMotion

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    // motion is done using hardware that must be shared
    // so anyone in this app using CoreMotion must use this
    struct Motion {
        static let Manager = CMMotionManager()
    }
}
