//
//  TwitterRequest.swift
//  Twitter
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import Foundation
import Accounts
import Social
import CoreLocation

// Simple Twitter query class
// Create an instance of it using one of the initializers
// Set the requestType and parameters (if not using a convenience init that sets those)
// Call fetch (or fetchTweets if fetching Tweets)
// The handler passed in will be called when the information comes back from Twitter
// Once a successful fetch has happened,
//   a follow-on TwitterRequest to get more Tweets (newer or older) can be created
//   using the requestFor{Newer,Older} methods

private var twitterAccount: ACAccount?

public class TwitterRequest
{
    public let requestType: String
    public let parameters = Dictionary<String, String>()
    
    // designated initializer
    public init(_ requestType: String, _ parameters: Dictionary<String, String> = [:]) {
        self.requestType = requestType
        self.parameters = parameters
    }
    
    // convenience initializer for creating a TwitterRequest that is a search for Tweets
    public convenience init(search: String, count: Int = 0, _ resultType: SearchResultType = .Mixed, _ region: CLCircularRegion? = nil) {
        var parameters = [TwitterKey.Query : search]
        if count > 0 {
            parameters[TwitterKey.Count] = "\(count)"
        }
        switch resultType {
            case .Recent: parameters[TwitterKey.ResultType] = TwitterKey.ResultTypeRecent
            case .Popular: parameters[TwitterKey.ResultType] = TwitterKey.ResultTypePopular
            default: break
        }
        if let geocode = region {
            parameters[TwitterKey.Geocode] = "\(geocode.center.latitude),\(geocode.center.longitude),\(geocode.radius/1000.0)km"
        }
        self.init(TwitterKey.SearchForTweets, parameters)
    }

    public enum SearchResultType {
        case Mixed
        case Recent
        case Popular
    }
    
    // convenience "fetch" for when self is a request that returns Tweet(s)
    // handler is not necessarily invoked on the main queue

    public func fetchTweets(handler: ([Tweet]) -> Void) {
        fetch { results in
            var tweets = [Tweet]()
            var tweetArray: NSArray?
            if let dictionary = results as? NSDictionary {
                if let tweets = dictionary[TwitterKey.Tweets] as? NSArray {
                    tweetArray = tweets
                } else if let tweet = Tweet(data: dictionary) {
                    tweets = [tweet]
                }
            } else if let array = results as? NSArray {
                tweetArray = array
            }
            if tweetArray != nil {
                for tweetData in tweetArray! {
                    if let tweet = Tweet(data: tweetData as? NSDictionary) {
                        tweets.append(tweet)
                    }
                }
            }
            handler(tweets)
        }
    }

    public typealias PropertyList = AnyObject

    // send an arbitrary request off to Twitter
    // calls the handler (not necessarily on the main queue)
    //   with the JSON results converted to a Property List
    
    public func fetch(handler: (results: PropertyList?) -> Void) {
        performTwitterRequest(SLRequestMethod.GET, handler)
    }
    
    // generates a request for older Tweets than were returned by self
    // only makes sense if self has done a fetch already
    // only makes sense for requests for Tweets

    public var requestForOlder: TwitterRequest? {
        return min_id != nil ? modifiedRequest(parametersToChange: [TwitterKey.MaxID : min_id!]) : nil
    }
    
    // generates a request for newer Tweets than were returned by self
    // only makes sense if self has done a fetch already
    // only makes sense for requests for Tweets

    public var requestForNewer: TwitterRequest? {
        return (max_id != nil) ? modifiedRequest(parametersToChange: [TwitterKey.SinceID : max_id!], clearCount: true) : nil
    }
    
    // MARK: - Private Implementation
    
    // creates an appropriate SLRequest using the specified SLRequestMethod
    // then calls the other version of this method that takes an SLRequest
    // handler is not necessarily called on the main queue
    
    func performTwitterRequest(method: SLRequestMethod, handler: (PropertyList?) -> Void) {
        var jsonExtension = (self.requestType.rangeOfString(JSONExtension) == nil) ? JSONExtension : ""
        let request = SLRequest(
            forServiceType: SLServiceTypeTwitter,
            requestMethod: method,
            URL: NSURL(string: "\(TwitterURLPrefix)\(self.requestType)\(jsonExtension)"),
            parameters: self.parameters
        )
        performTwitterRequest(request, handler)
    }
    
    // sends the request to Twitter
    // unpackages the JSON response into a Property List
    // and calls handler (not necessarily on the main queue)

    func performTwitterRequest(request: SLRequest, handler: (PropertyList?) -> Void) {
        if let account = twitterAccount {
            request.account = account
            request.performRequestWithHandler { (jsonResponse, httpResponse, _) in
                var propertyListResponse: PropertyList?
                if jsonResponse != nil {
                    propertyListResponse = NSJSONSerialization.JSONObjectWithData(
                        jsonResponse,
                        options: NSJSONReadingOptions.MutableLeaves,
                        error: nil
                    )
                    if propertyListResponse == nil {
                        let error = "Couldn't parse JSON response."
                        self.log(error)
                        propertyListResponse = error
                    }
                } else {
                    let error = "No response from Twitter."
                    self.log(error)
                    propertyListResponse = error
                }
                self.synchronize {
                    self.captureFollowonRequestInfo(propertyListResponse)
                }
                handler(propertyListResponse)
            }
        } else {
            let accountStore = ACAccountStore()
            let twitterAccountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
            accountStore.requestAccessToAccountsWithType(twitterAccountType, options: nil) { (granted, _) in
                if granted {
                    if let account = accountStore.accountsWithAccountType(twitterAccountType)?.last as? ACAccount {
                        twitterAccount = account
                        self.performTwitterRequest(request, handler: handler)
                    } else {
                        let error = "Couldn't discover Twitter account type."
                        self.log(error)
                        handler(error)
                    }
                } else {
                    let error = "Access to Twitter was not granted."
                    self.log(error)
                    handler(error)
                }
            }
        }
    }
    
    private var min_id: String? = nil
    private var max_id: String? = nil
    
    // modifies parameters in an existing request to create a new one
    
    private func modifiedRequest(#parametersToChange: Dictionary<String,String>, clearCount: Bool = false) -> TwitterRequest {
        var newParameters = parameters
        for (key, value) in parametersToChange {
            newParameters[key] = value
        }
        if clearCount { newParameters[TwitterKey.Count] = nil }
        return TwitterRequest(requestType, newParameters)
    }
    
    // captures the min_id and max_id information
    // to support requestForNewer and requestForOlder

    private func captureFollowonRequestInfo(propertyListResponse: PropertyList?) {
        if let responseDictionary = propertyListResponse as? NSDictionary {
            self.max_id = responseDictionary.valueForKeyPath(TwitterKey.SearchMetadata.MaxID) as? String
            if let next_results = responseDictionary.valueForKeyPath(TwitterKey.SearchMetadata.NextResults) as? String {
                for queryTerm in next_results.componentsSeparatedByString(TwitterKey.SearchMetadata.Separator) {
                    if queryTerm.hasPrefix("?\(TwitterKey.MaxID)=") {
                        let next_id = queryTerm.componentsSeparatedByString("=")
                        if next_id.count == 2 {
                            self.min_id = next_id[1]
                        }
                    }
                }
            }
        }
    }
    
    // debug println with identifying prefix
    
    private func log(whatToLog: AnyObject) {
        debugPrintln("TwitterRequest: \(whatToLog)")
    }
    
    // synchronizes access to self across multiple threads

    private func synchronize(closure: () -> Void) {
        objc_sync_enter(self)
        closure()
        objc_sync_exit(self)
    }
    
    // constants

    let JSONExtension = ".json"
    let TwitterURLPrefix = "https://api.twitter.com/1.1/"
    
    // keys in Twitter responses/queries

    struct TwitterKey {
        static let Count = "count"
        static let Query = "q"
        static let Tweets = "statuses"
        static let ResultType = "result_type"
        static let ResultTypeRecent = "recent"
        static let ResultTypePopular = "popular"
        static let Geocode = "geocode"
        static let SearchForTweets = "search/tweets"
        static let MaxID = "max_id"
        static let SinceID = "since_id"
        struct SearchMetadata {
            static let MaxID = "search_metadata.max_id_str"
            static let NextResults = "search_metadata.next_results"
            static let Separator = "&"
        }
    }
}
