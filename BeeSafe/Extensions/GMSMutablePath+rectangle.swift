//
//  GMSMutablePath+rectangle.swift
//  BeeSafe
//
//  Created by Artem Goncharov on 19/1/19.
//  Copyright © 2019 hakathon. All rights reserved.
//

import Foundation
import GoogleMaps

extension GMSPath {
    static func rectangle(southWest: CLLocationCoordinate2D, northenEast: CLLocationCoordinate2D) -> GMSPath {
        let path = GMSMutablePath()
        path.add(southWest)
        path.add(CLLocationCoordinate2D(latitude: northenEast.latitude, longitude: southWest.longitude))
        path.add(CLLocationCoordinate2D(latitude: northenEast.latitude, longitude: northenEast.longitude))
        path.add(CLLocationCoordinate2D(latitude: southWest.latitude, longitude: northenEast.longitude))
        path.add(southWest)
        
        return path
    }
    
    static func rectangle(point1: CLLocationCoordinate2D,
                          point2: CLLocationCoordinate2D,
                          point3: CLLocationCoordinate2D,
                          point4: CLLocationCoordinate2D) -> GMSPath {
        let path = GMSMutablePath()
        path.add(point1)
        path.add(point2)
        path.add(point3)
        path.add(point4)
        path.add(point1)

        return path
    }
}
