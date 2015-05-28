//
//  MKGPX.swift
//  Trax
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import MapKit

class EditableWaypoint: GPX.Waypoint
{
    // make coordinate get & set (for draggable annotations)
    override var coordinate: CLLocationCoordinate2D {
        get { return super.coordinate }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    override var thumbnailURL: NSURL? { return imageURL }
    override var imageURL: NSURL? { return links.first?.url }
}

extension GPX.Waypoint: MKAnnotation
{
    // MARK: - MKAnnotation

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var title: String! { return name }
    
    var subtitle: String! { return info }
    
    // MARK: - Links to Images

    var thumbnailURL: NSURL? { return getImageURLofType("thumbnail") }
    var imageURL: NSURL? { return getImageURLofType("large") }
    
    private func getImageURLofType(type: String) -> NSURL? {
        for link in links {
            if link.type == type {
                return link.url
            }
        }
        return nil
    }
}
