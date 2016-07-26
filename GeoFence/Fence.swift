//
//  Fence.swift
//  Geo Fence
//
//  Created by Julian Jans on 13/07/2016.
//  Copyright © 2016 Julian Jans. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class Fence: NSObject {
    
    var color: UIColor?
    
    var coordinate: CLLocationCoordinate2D?
    
    var circle: MKCircle?
    
    var region: CLCircularRegion?
    
    convenience init(coordinate: CLLocationCoordinate2D, radius: Double) {
        self.init()
        self.coordinate = coordinate
        self.circle = MKCircle(centerCoordinate: coordinate, radius: radius)
        self.region = CLCircularRegion(center: coordinate, radius: radius, identifier: "\(coordinate.latitude.roundToPlaces(6)), \(coordinate.longitude.roundToPlaces(6)), \(radius)")
    }

}