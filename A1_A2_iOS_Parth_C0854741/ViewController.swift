//
//  ViewController.swift
//  A1_A2_iOS_Parth_C0854741
//
//  Created by parth on 2022-05-24.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    var destinationCoordinate: CLLocationCoordinate2D!

    @IBOutlet weak var mapView: MKMapView!
    
    var selectedMarkers = [CLLocationCoordinate2D]()
    override func viewDidLoad() {
        super.viewDidLoad()
        addDoubleTapPin()
        configureLocationServices()
        mapView.delegate = self
        mapView.isZoomEnabled = false
        // Do any additional setup after loading the view, typically from a nib.
        
        let uiLongPressEvent = UILongPressGestureRecognizer(target: self, action: #selector(addLongPressAnnotattion))
        mapView.addGestureRecognizer(uiLongPressEvent)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    private func configureLocationServices() {
        locationManager.delegate = self
        let status = CLLocationManager()
        
        if status.authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else if status.authorizationStatus == .authorizedAlways || status.authorizationStatus == .authorizedWhenInUse {
           beginLocationUpdates(locationManager: locationManager)
        }
    }
    
    private func beginLocationUpdates(locationManager: CLLocationManager) {
        mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    private func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D) {
        let zoomRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(zoomRegion, animated: true)
    }
    
    @IBAction func directionBtnTap(_ sender: UIButton) {
        mapView.removeOverlays(mapView.overlays)
        for annotation in mapView.annotations {
            if (annotation.title != "Destination Place") {
                mapView.removeAnnotation(annotation)
            }
        }
        
        if ((destinationCoordinate) != nil) {
            let sourcePlaceMark = MKPlacemark(coordinate: locationManager.location!.coordinate)
            let destinationPlaceMark = MKPlacemark(coordinate: destinationCoordinate)
            
            // direction request
            let directionRequest = MKDirections.Request()
            directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
            directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
           directionRequest.transportType = .automobile
            
            // set line for direction
            let directions = MKDirections(request: directionRequest)
            directions.calculate { (response, error) in
                guard let directionResponse = response else {return}
                let route = directionResponse.routes[0]
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                
               let rect = route.polyline.boundingMapRect
                self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
            }
        }
        
    }
    
    //double tap gesture
    func addDoubleTapPin() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropDestinationPin))
        doubleTap.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTap)
    }
    
    @objc func dropDestinationPin(sender: UITapGestureRecognizer) {
        //remove other annotaions
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
        
        //set destination annotation
        let touchPoint = sender.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.title = "Destination Place"
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        destinationCoordinate = coordinate
    }
    
    //long press recognizer
    @objc func addLongPressAnnotattion(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let currentData = MarkerData(title: "Title", coordinate: coordinate)
        if (selectedMarkers.count < 3) {
            selectedMarkers.append(coordinate)
        } else {
            selectedMarkers.remove(at: 0)
            selectedMarkers.append(coordinate)
            selectedMarkers.append(selectedMarkers[0])
            addPolygon()
        }
        
        // add annotation for the coordinatet
        let annotation = MKPointAnnotation()
        annotation.title = currentData.title
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    
    //polygon function
    func addPolygon() {
        let coordinates = selectedMarkers.map {$0}
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polygon)
    }
    
}


extension ViewController: MKMapViewDelegate {
    
    //annotation delegate method
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        switch annotation.title {
        case "Destination Place":
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
            annotationView.animatesDrop = true
            return annotationView
        case "Title":
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "customPin") ?? MKPinAnnotationView()
            annotationView.image = UIImage(named: "ic_location")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        default:
            return nil
        }
    }
    
    //draw polygon 
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let rendrer = MKPolylineRenderer(overlay: overlay)
            rendrer.strokeColor = UIColor.blue
            rendrer.lineWidth = 2
            return rendrer
        } else if overlay is MKPolygon {
            let rendrer = MKPolygonRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.4)
            rendrer.strokeColor = UIColor.green
            rendrer.lineWidth = 2
            return rendrer
        }
        return MKOverlayRenderer()
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did get latest location")
        
        guard let latestLocation = locations.first else { return }
        
        if currentCoordinate == nil {
            zoomToLatestLocation(with: latestLocation.coordinate)
        }
    
        currentCoordinate = latestLocation.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
       print("The status changed")
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: manager)
        }
    }
}

