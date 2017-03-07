//
//  DropitViewController.swift
//  Dropit
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class DropitViewController: UIViewController, UIDynamicAnimatorDelegate
{
    // MARK: - Outlets

    @IBOutlet weak var gameView: BezierPathsView!   //gameView is the main area that the game is displayed on
    
    // MARK: - Animation
    
    /*animator cannot be created at start time, must be initialized lazily */

    lazy var animator: UIDynamicAnimator = {
        let lazilyCreatedDynamicAnimator = UIDynamicAnimator(referenceView: self.gameView)
        lazilyCreatedDynamicAnimator.delegate = self
        return lazilyCreatedDynamicAnimator
    }()
    
    let dropitBehavior = DropitBehavior()
    
    var attachment: UIAttachmentBehavior? {
        // setting the UIAttachmentBehavior removes the previous instance
        willSet {
            animator.removeBehavior(attachment)
            gameView.setPath(nil, named: PathNames.Attachment)
        }
        didSet {
            if attachment != nil { //check against empty optional, otherwise program could crash
                animator.addBehavior(attachment) //add the attachment to the animator
                attachment?.action = { [unowned self] in //prevent reference cycle by declaring unowned self
                    if let attachedView = self.attachment?.items.first as? UIView {
                        let path = UIBezierPath()
                        path.moveToPoint(self.attachment!.anchorPoint)
                        path.addLineToPoint(attachedView.center)    //draws a line between the object and its anchorPoint
                        self.gameView.setPath(path, named: PathNames.Attachment)
                    }
                }
            }
        }
    }
    
    // MARK: - View Controller Lifecycle
    /* upon view loading, the animator adds the behaviour */
    override func viewDidLoad() {
        super.viewDidLoad()
        animator.addBehavior(dropitBehavior)
    }
    
    // creates a circular barrier in the center of the gameView
    // the barrier is currently sized to be the same as the size of a drop
    
    override func viewDidLayoutSubviews() { //called after view loading stage
        super.viewDidLayoutSubviews()       //must call function of superclass when overriding
        let barrierSize = dropSize
        //origin point is the bottom left corner of barrier
        let barrierOrigin = CGPoint(x: gameView.bounds.midX-barrierSize.width/2, y: gameView.bounds.midY-barrierSize.height/2)
        let path = UIBezierPath(ovalInRect: CGRect(origin: barrierOrigin, size: barrierSize))
        dropitBehavior.addBarrier(path, named: PathNames.MiddleBarrier)
        gameView.setPath(path, named: PathNames.MiddleBarrier)
    }
    
    // MARK: - UIDynamicAnimatorDelegate
    //will remove rows whenever all drops are stationary
    func dynamicAnimatorDidPause(animator: UIDynamicAnimator) {
        removeCompletedRow()
    }
    
    // MARK: - Gestures
    //outlet that connects a tap gesture to the drop() function
    @IBAction func drop(sender: UITapGestureRecognizer) {
        drop()
    }
    //when a user makes a pan gesture grab the drop
    @IBAction func grabDrop(sender: UIPanGestureRecognizer) {
        let gesturePoint = sender.locationInView(gameView)  //the original point of the drag motion
        
        
        switch sender.state {
        case .Began:    //add a behaviour that anchors the drop to the gesture point
            if let viewToAttachTo = lastDroppedView {
                attachment = UIAttachmentBehavior(item: viewToAttachTo, attachedToAnchor: gesturePoint)
                lastDroppedView = nil
            }
        case .Changed:  //move the anchor to the new gesturepoint
            attachment?.anchorPoint = gesturePoint
        case .Ended:    //remove the attachment
            attachment = nil
        default: break
        }
    }
    
    // MARK: - Dropping

    var dropsPerRow = 10    //determines the width of each drop
    
    var dropSize: CGSize {
        let size = gameView.bounds.size.width / CGFloat(dropsPerRow)
        return CGSize(width: size, height: size)    //drops are squares
    }
    
    var lastDroppedView: UIView?    //keep track of the last drop for anchoring
    
    func drop() {
        var frame = CGRect(origin: CGPointZero, size: dropSize)
        frame.origin.x = CGFloat.random(dropsPerRow) * dropSize.width
        
        let dropView = UIView(frame: frame)
        dropView.backgroundColor = UIColor.random
        
        lastDroppedView = dropView
    
        dropitBehavior.addDrop(dropView)
    }
    
    // removes a single, completed row
    // allows for a little "wiggle room" for mostly complete rows
    // in the end, does nothing more than call removeDrop() in DropitBehavior

    func removeCompletedRow()
    {   //keep track of all the drops we are removing
        var dropsToRemove = [UIView]()
        var dropFrame = CGRect(x: 0, y: gameView.frame.maxY, width: dropSize.width, height: dropSize.height)
        
        do {
            dropFrame.origin.y -= dropSize.height
            dropFrame.origin.x = 0
            var dropsFound = [UIView]()
            var rowIsComplete = true
            //finds all the drop along the bottom row using a hit test
            for _ in 0 ..< dropsPerRow {
                if let hitView = gameView.hitTest(CGPoint(x: dropFrame.midX, y: dropFrame.midY), withEvent: nil) {
                    if hitView.superview == gameView {
                        dropsFound.append(hitView)  //if hittest is successful, add the drop to the list for removal
                    } else {
                        rowIsComplete = false
                    }
                }
                dropFrame.origin.x += dropSize.width
            }
            if rowIsComplete {
                dropsToRemove += dropsFound
            }
        } while dropsToRemove.count == 0 && dropFrame.origin.y > 0  //remove all rows above the bottom of the screen
        
        for drop in dropsToRemove {
            dropitBehavior.removeDrop(drop)
        }
    }
    
    // MARK: - Constants
    //good programming practice to use structs rather than strings
    struct PathNames {
        static let MiddleBarrier = "Middle Barrier"
        static let Attachment = "Attachment"
    }
}

// MARK: - Extensions
//allows easy access to a random CGFloat
private extension CGFloat {
    static func random(max: Int) -> CGFloat {
        return CGFloat(arc4random() % UInt32(max))
    }
}
//allows easy access to several basic UIColors
private extension UIColor {
    class var random: UIColor {
        switch arc4random()%5 {
        case 0: return UIColor.greenColor()
        case 1: return UIColor.blueColor()
        case 2: return UIColor.orangeColor()
        case 3: return UIColor.redColor()
        case 4: return UIColor.purpleColor()
        default: return UIColor.blackColor()
        }
    }
}
