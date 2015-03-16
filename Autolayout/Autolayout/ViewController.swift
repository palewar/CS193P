//
//  ViewController.swift
//  Autolayout
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    // after the demo, appropriate things were private-ized.
    // including outlets and actions.

    @IBOutlet private weak var loginField: UITextField!
    @IBOutlet private weak var passwordField: UITextField!
    @IBOutlet private weak var passwordLabel: UILabel!
    @IBOutlet private weak var companyLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    
    // our Model, the logged in user
    var loggedInUser: User? { didSet { updateUI() } }
    
    // sets whether the password field is secure or not
    var secure: Bool = false { didSet { updateUI() } }
    
    // update the user-interface
    // by transferring information from the Model to our View
    // and setting up security in the password fields
    //
    // NOTE: After the demo, this method was protected against
    //         crashing if it is called before our outlets are set.
    //       This is nice to do since setting our Model calls this
    //         and our Model might get set while we are being prepared.
    //       It was easy too.  Just added ? after outlets.
    //
    private func updateUI() {
        passwordField?.secureTextEntry = secure
        passwordLabel?.text = secure ? "Secured Password" : "Password"
        nameLabel?.text = loggedInUser?.name
        companyLabel?.text = loggedInUser?.company
        image = loggedInUser?.image
    }
    
    // once we're loaded (outlets set, etc.), update the UI
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    // log in (set our Model)
    @IBAction private func login() {
        loggedInUser = User.login(loginField.text ?? "", password: passwordField.text ?? "")
    }
    
    // toggle whether passwords are secure or not
    @IBAction private func toggleSecurity() {
        secure = !secure
    }
    
    // a convenience property
    // so that we can easily intervene
    // when an image is set in our imageView
    // whenever the image is set in our imageView
    // we add a constraint that the imageView
    // must maintain the aspect ratio of its image
    private var image: UIImage? {
        get {
            return imageView?.image
        }
        set {
            imageView?.image = newValue
            if let constrainedView = imageView {
                if let newImage = newValue {
                    aspectRatioConstraint = NSLayoutConstraint(
                        item: constrainedView,
                        attribute: .Width,
                        relatedBy: .Equal,
                        toItem: constrainedView,
                        attribute: .Height,
                        multiplier: newImage.aspectRatio,
                        constant: 0)
                } else {
                    aspectRatioConstraint = nil
                }
            }
        }
    }
    
    // the imageView aspect ratio constraint
    // when it is set here,
    // we'll remove any existing aspect ratio constraint
    // and then add the new one to our view
    private var aspectRatioConstraint: NSLayoutConstraint? {
        willSet {
            if let existingConstraint = aspectRatioConstraint {
                view.removeConstraint(existingConstraint)
            }
        }
        didSet {
            if let newConstraint = aspectRatioConstraint {
                view.addConstraint(newConstraint)
            }
        }
    }
}

// User is our Model,
// so it can't itself have anything UI-related
// but we can add a UI-specific property
// just for us to use
// because we are the Controller
// note this extension is private

private extension User
{
    var image: UIImage? {
        if let image = UIImage(named: login) {
            return image
        } else {
            return UIImage(named: "unknown_user")
        }
    }
}

// wouldn't it be convenient
// to have an aspectRatio property in UIImage?
// yes, it would, so let's add one!
// why is this not already in UIImage?
// probably because the semantic of returning zero
//   if the height is zero is not perfect
//   (nil might be better, but annoying)

extension UIImage
{
    var aspectRatio: CGFloat {
        return size.height != 0 ? size.width / size.height : 0
    }
}
