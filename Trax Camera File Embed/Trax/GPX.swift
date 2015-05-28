//
//  GPX.swift
//  Trax
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//
//  Very simple GPX file parser.
//  Only verified to work for CS193p demo purposes!

import Foundation

class GPX: NSObject, Printable, NSXMLParserDelegate
{
    // MARK: - Public API

    var waypoints = [Waypoint]()
    var tracks = [Track]()
    var routes = [Track]()
    
    typealias GPXCompletionHandler = (GPX?) -> Void
    
    class func parse(url: NSURL, completionHandler: GPXCompletionHandler) {
        GPX(url: url, completionHandler: completionHandler).parse()
    }
    
    // MARK: - Public Classes
    
    class Track: Entry, Printable
    {
        var fixes = [Waypoint]()
        
        override var description: String {
            let waypointDescription = "fixes=[\n" + "\n".join(fixes.map { $0.description }) + "\n]"
            return " ".join([super.description, waypointDescription])
        }
    }
    
    class Waypoint: Entry, Printable
    {
        var latitude: Double
        var longitude: Double
        
        init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
            super.init()
        }
        
        var info: String? {
            set { attributes["desc"] = newValue }
            get { return attributes["desc"] }
        }
        lazy var date: NSDate? = self.attributes["time"]?.asGpxDate
        
        override var description: String {
            return " ".join(["lat=\(latitude)", "lon=\(longitude)", super.description])
        }
    }
    
    class Entry: NSObject, Printable
    {
        var links = [Link]()
        var attributes = [String:String]()
        
        var name: String? {
            set { attributes["name"] = newValue }
            get { return attributes["name"] }
        }
        
        override var description: String {
            var descriptions = [String]()
            if attributes.count > 0 { descriptions.append("attributes=\(attributes)") }
            if links.count > 0 { descriptions.append("links=\(links)") }
            return " ".join(descriptions)
        }
    }
    
    class Link: Printable
    {
        var href: String
        var linkattributes = [String:String]()
        
        init(href: String) { self.href = href }
        
        var url: NSURL? { return NSURL(string: href) }
        var text: String? { return linkattributes["text"] }
        var type: String? { return linkattributes["type"] }
        
        var description: String {
            var descriptions = [String]()
            descriptions.append("href=\(href)")
            if linkattributes.count > 0 { descriptions.append("linkattributes=\(linkattributes)") }
            return "[" + " ".join(descriptions) + "]"
        }
    }

    // MARK: - Printable
    
    override var description: String {
        var descriptions = [String]()
        if waypoints.count > 0 { descriptions.append("waypoints = \(waypoints)") }
        if tracks.count > 0 { descriptions.append("tracks = \(tracks)") }
        if routes.count > 0 { descriptions.append("routes = \(routes)") }
        return "\n".join(descriptions)
    }

    // MARK: - Private Implementation

    private let url: NSURL
    private let completionHandler: GPXCompletionHandler
    
    private init(url: NSURL, completionHandler: GPXCompletionHandler) {
        self.url = url
        self.completionHandler = completionHandler
    }
    
    private func complete(#success: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            self.completionHandler(success ? self : nil)
        }
    }
    
    private func fail() { complete(success: false) }
    private func succeed() { complete(success: true) }
    
    private func parse() {
        let qos = Int(QOS_CLASS_USER_INITIATED.value)
        dispatch_async(dispatch_get_global_queue(qos, 0)) {
            if let data = NSData(contentsOfURL: self.url) {
                let parser = NSXMLParser(data: data)
                parser.delegate = self
                parser.shouldProcessNamespaces = false
                parser.shouldReportNamespacePrefixes = false
                parser.shouldResolveExternalEntities = false
                parser.parse()
            } else {
                self.fail()
            }
        }
    }

    func parserDidEndDocument(parser: NSXMLParser!) { succeed() }
    func parser(parser: NSXMLParser!, parseErrorOccurred parseError: NSError!) { fail() }
    func parser(parser: NSXMLParser!, validationErrorOccurred validationError: NSError!) { fail() }
    
    private var input = ""

    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        input += string
    }
    
    private var waypoint: Waypoint?
    private var track: Track?
    private var link: Link?

    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!) {
        switch elementName {
            case "trkseg":
                if track == nil { fallthrough }
            case "trk":
                tracks.append(Track())
                track = tracks.last
            case "rte":
                routes.append(Track())
                track = routes.last
            case "rtept", "trkpt", "wpt":
                let latitude = (attributeDict["lat"] as NSString).doubleValue
                let longitude = (attributeDict["lon"] as NSString).doubleValue
                waypoint = Waypoint(latitude: latitude, longitude: longitude)
            case "link":
                link = Link(href: attributeDict["href"] as String)
            default: break
        }
    }
    
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        switch elementName {
            case "wpt":
                if waypoint != nil { waypoints.append(waypoint!); waypoint = nil }
            case "trkpt", "rtept":
                if waypoint != nil { track?.fixes.append(waypoint!); waypoint = nil }
            case "trk", "trkseg", "rte":
                track = nil
            case "link":
                if link != nil {
                    if waypoint != nil {
                        waypoint!.links.append(link!)
                    } else if track != nil {
                        track!.links.append(link!)
                    }
                }
                link = nil
            default:
                if link != nil {
                    link!.linkattributes[elementName] = input.trimmed
                } else if waypoint != nil {
                    waypoint!.attributes[elementName] = input.trimmed
                } else if track != nil {
                    track!.attributes[elementName] = input.trimmed
                }
                input = ""
        }
    }
}

// MARK: - Extensions

private extension String {
    var trimmed: String {
        return (self as NSString).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
}

extension String {
    var asGpxDate: NSDate? {
        get {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z"
            return dateFormatter.dateFromString(self)
        }
    }
}
