//
//  HappinessViewController.swift
//  Happiness
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class HappinessViewController: UIViewController, FaceViewDataSource
{
    // a property to access our Model
    // incredibly simplistic Model
    // most MVCs would have more complicated Models (e.g. CalculatorBrain)
    var happiness: Int = 25 { // 0 = very sad, 100 = ecstatic
        didSet {
            // validate (actually, enforce validity of) modifications to the Model
            happiness = min(max(happiness, 0), 100)
            println("happiness = \(happiness)")
            // any time the Model changes, we need to update our View
            updateUI()
        }
    }
    
    func updateUI() {
        // to update our UI, we just need to ask the FaceView to redraw
        faceView.setNeedsDisplay()
    }
    
    // FaceViewDataSource
    func smilinessForFaceView(sender: FaceView) -> Double? {
        // interpret the Model for the View
        return Double(happiness-50)/50
    }

    @IBOutlet weak var faceView: FaceView! {
        // the property observer didSet gets called when this outlet gets set
        // (i.e. when iOS makes the connection to the FaceView in the storyboard)
        // this is a perfect time to configure the FaceView with its delegate and recognizers
        didSet {
            faceView.dataSource = self
            // this pinch gesture can be handled by the View, so just "turn it on" here in the Controller
            faceView.addGestureRecognizer(UIPinchGestureRecognizer(target: faceView, action: "scale:"))
            // this pan gesture recognizer modifies the Model so it must be handled by the Controller
            // we could add it in code like below, but instead, we added it directly in the storyboard
            // and wired it up with ctrl-drag
            // faceView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "changeHappiness:"))
        }
    }
    
    private struct Constants {
        static let HappinessGestureScale: CGFloat = 4
    }
    
    // handler for a pan gesture recognized by our FaceView
    @IBAction func changeHappiness(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            let translation = gesture.translationInView(faceView)
            // here we are basically interpreting input from the View for our Model
            let happinessChange = -Int(translation.y / Constants.HappinessGestureScale)
            if happinessChange != 0 {
                happiness += happinessChange
                // normally the translation of a pan gesture
                // is relative to the point at which it was first recognized
                // but we can reset that point so that we are getting "incremental" pan data ...
                gesture.setTranslation(CGPointZero, inView: faceView)
            }
        default: break
        }
    }
}
