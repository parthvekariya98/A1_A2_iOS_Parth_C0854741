//
//  MarkerData.swift
//  A1_A2_iOS_Parth_C0854741
//
//  Created by parth on 2022-05-25.
//

import Foundation
import MapKit

struct MarkerData {
    var title:String = ""
    var coordinate: CLLocationCoordinate2D
    
    init(title: String, coordinate: CLLocationCoordinate2D){
        self.title = title
        self.coordinate = coordinate
    }
}
