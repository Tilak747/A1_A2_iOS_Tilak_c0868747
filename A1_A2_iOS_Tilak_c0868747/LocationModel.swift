//
//  LocationModel.swift
//  A1_A2_iOS_Tilak_c0868747
//
//  Created by Tilak Acharya on 2023-01-20.
//

import Foundation
import MapKit

class LocationModel:NSObject{
    
    var locationName:String
    var location : CLLocationCoordinate2D
    
    init(locationName: String, location: CLLocationCoordinate2D) {
        self.locationName = locationName
        self.location = location
    }
    
}
