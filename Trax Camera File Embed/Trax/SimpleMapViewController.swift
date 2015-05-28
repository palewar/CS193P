//
//  SimpleMapViewController.swift
//  Trax
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit
import MapKit

class SimpleMapViewController: UIViewController
{
    // so simple it doesn't really have a Model
    // it just makes one of it's outlets publicly available
    // making your outlets public is not generally advised
    // usually you want to keep control of them
    // so that people can't "mess your MVC up" by messing with them

    @IBOutlet weak var mapView: MKMapView!
}
