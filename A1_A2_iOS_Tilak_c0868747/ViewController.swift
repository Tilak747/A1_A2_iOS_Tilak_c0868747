//
//  ViewController.swift
//  A1_A2_iOS_Tilak_c0868747
//
//  Created by Tilak Acharya on 2023-01-20.
//

import UIKit
import MapKit

class ViewController: UIViewController,CLLocationManagerDelegate {

    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var searchText: UITextField!
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var table: UITableView!
    
    var mapAnnotations = [MKPointAnnotation]()
    var myCurrentLocationAnnotation:MKPointAnnotation?
    
    var locations = [MKMapItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initMap()
        
        table.delegate = self
        table.dataSource = self
        
        searchText.addTarget(self, action: #selector(ViewController.textFieldDidChange(_:)), for: .editingChanged)
    }
    
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        let text = textField.text
        
        self.locations.removeAll()
        
        guard let mapView = map,
              let searchBarText = textField.text else {
            return
        }
        
                let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchBarText
            request.region = mapView.region
            let search = MKLocalSearch(request: request)
            search.start { response, _ in
                guard let response = response else {
                    return
                }
                
                self.locations = response.mapItems
                
                print("\(text) \(response.mapItems.count)")
                
                self.table.reloadData()
            }
        
    }
    
    func initMap(){
        
        mapAnnotations = [MKPointAnnotation]()
        
        map.isZoomEnabled = false
        map.showsUserLocation = true
    
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        addDoubleTap()
        
        map.delegate = self
        
//        addDoubleTap()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress))
        map.addGestureRecognizer(longPressGesture)
    }

    func addDoubleTap(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(addAnnotationOnDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        map.addGestureRecognizer(doubleTap)
    }
    
    @objc func addAnnotationOnDoubleTap(sender: UITapGestureRecognizer){
        if(checkAnnotationsCount()){
            let touchPoint = sender.location(in: map)
            let coordinate = map.convert(touchPoint, toCoordinateFrom: map)
            let annotation = MKPointAnnotation()
            annotation.title = getAnnotationTitle()
            annotation.coordinate = coordinate
            
            mapAnnotations.append(annotation)
            
            map.addAnnotation(annotation)
        }
        else{
            createAllPolylines()
        }
    }
    
    func getAnnotationTitle() -> String{
        var title = ""
        switch(mapAnnotations.count){
            case 1 :
                title = "A"
            case 2 :
                title = "B"
            case 3 :
                title = "C"
        default:
            return ""
        }
        return title
    }
    
    func addLocationFromSearch(location:MKMapItem){
        if(checkAnnotationsCount()){
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.placemark.coordinate
            annotation.title = getAnnotationTitle()
            mapAnnotations.append(annotation)
            map.addAnnotation(annotation)
        }
        else{
            createAllPolylines()
        }
        
        locations.removeAll()
    }
    
    @objc func addAnnotationOnLongPress(gestureRecognizer:UIGestureRecognizer){
        
        if (checkAnnotationsCount()){
            let touchPoint = gestureRecognizer.location(in: map)
            let newCoordinates = map.convert(touchPoint, toCoordinateFrom: map)
            let location = CLLocationCoordinate2D(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            annotation.title = getAnnotationTitle()
            
            mapAnnotations.append(annotation)
            
            map.addAnnotation(annotation)
        }
        else{
            createAllPolylines()
        }
    }
    
    func createAllPolylines(){
        
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        removeMyCurrentLocation()

        let userLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        displayLocation(latitude: latitude, longitude: longitude, title: "My location", subtitle: "you are here")
    }
    func removeMyCurrentLocation(){
        if let annotation = myCurrentLocationAnnotation {
            map.removeAnnotation(annotation)
        }
    }
    func displayLocation(latitude: CLLocationDegrees,
                         longitude: CLLocationDegrees,
                         title: String,
                         subtitle: String) {
        // 2nd step - define span
        let latDelta: CLLocationDegrees = 0.05
        let lngDelta: CLLocationDegrees = 0.05
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        // 3rd step is to define the location
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        // 4th step is to define the region
        let region = MKCoordinateRegion(center: location, span: span)
        
        // 5th step is to set the region for the map
        map.setRegion(region, animated: true)
        
        // 6th step is to define annotation
        
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.subtitle = subtitle
        annotation.coordinate = location
        
        myCurrentLocationAnnotation = annotation
        
        map.addAnnotation(annotation)
    }
    
    func checkAnnotationsCount() -> Bool{
        return mapAnnotations.count <  4
    }
    
}

extension ViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        switch annotation.title {
        case "My location":
            let annotationView = map.dequeueReusableAnnotationView(withIdentifier: "customPin") ?? MKPinAnnotationView()
            annotationView.image = UIImage(named: "ic_place_2x")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        default:
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
            annotationView.markerTintColor = UIColor.blue
            return annotationView
        }
        
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let rendrer = MKCircleRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.black.withAlphaComponent(0.5)
            rendrer.strokeColor = UIColor.green
            rendrer.lineWidth = 2
            return rendrer
        } else if overlay is MKPolyline {
            let rendrer = MKPolylineRenderer(overlay: overlay)
            rendrer.strokeColor = UIColor.blue
            rendrer.lineWidth = 3
            return rendrer
        } else if overlay is MKPolygon {
            let rendrer = MKPolygonRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.6)
            rendrer.strokeColor = UIColor.yellow
            rendrer.lineWidth = 2
            return rendrer
        }
        return MKOverlayRenderer()
    }

}


extension ViewController: UITableViewDelegate,UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath)
        let location = locations[indexPath.row]
        cell.textLabel?.text = location.placemark.name
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let location = locations[indexPath.row]
        addLocationFromSearch(location: location)

    }
}
