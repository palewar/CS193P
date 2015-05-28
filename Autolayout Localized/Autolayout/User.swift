//
//  User.swift
//  Autolayout
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import Foundation

struct User
{
    let name: String
    let company: String
    let login: String
    let password: String
    
    var lastLogin = NSDate.demoRandom()
    
    init(name: String, company: String, login: String, password: String) {
        self.name = name
        self.company = company
        self.login = login
        self.password = password
    }
    
    static func login(login: String, password: String) -> User? {
        if let user = database[login] {
            if user.password == password {
                return user
            }
        }
        return nil
    }

     static let database: Dictionary<String, User> = {
        var theDatabase = Dictionary<String, User>()
        for user in [
            User(name: "John Appleseed", company: "Apple", login: "japple", password: "foo"),
            User(name: "Madison Bumgarner", company: "World Champion San Francisco Giants", login: "madbum", password: "foo"),
            User(name: "John Hennessy", company: "Stanford", login: "hennessy", password: "foo"),
            User(name: "Bad Guy", company: "Criminals, Inc.", login: "baddie", password: "foo")
        ] {
            theDatabase[user.login] = user
        }
        return theDatabase
    }()
}

private extension NSDate {
    class func demoRandom() -> NSDate {
        let randomIntervalIntoThePast = -Double(arc4random() % 60*60*24*20)
        return NSDate(timeIntervalSinceNow: randomIntervalIntoThePast)
    }
}