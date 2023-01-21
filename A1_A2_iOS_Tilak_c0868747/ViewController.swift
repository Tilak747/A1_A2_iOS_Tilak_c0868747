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
    
    @IBOutlet weak var resetBtn: UIButton!
    @IBOutlet weak var searchText: UITextField!
    var locationManager = CLLocationManager()
    
    
    
    @IBOutlet weak var table: UITableView!
    
    @IBOutlet weak var guideBtn: UIButton!
    var mapAnnotations = [MKPointAnnotation]()
    var myCurrentLocationAnnotation:MKPointAnnotation?
    
    var locations = [MKMapItem]()
    var triangleOverlay:MKOverlayRenderer?
    var linesOverlay:MKOverlayRenderer?
    
    var currentGuide = 0
    
    
    @IBAction func resetAll(_ sender: Any) {
        map.removeAnnotations(mapAnnotations)
        
        if let overlays = map?.overlays{
            map.removeOverlays(overlays)
        }
        
        initMap()
    }
    
    @IBAction func guideUserToNextLocation(_ sender: Any) {
        if(mapAnnotations.count != 3){
            return
        }
        switch(currentGuide){
        case 0:
            drawRoute(from: mapAnnotations[0], to:   mapAnnotations[1])
            guideBtn.setTitle("From B To C", for: .normal)
            currentGuide = 1
        case 1:
            drawRoute(from: mapAnnotations[1], to:   mapAnnotations[2])
            guideBtn.setTitle("From C To A", for: .normal)
            currentGuide = 2
        case 2:
            drawRoute(from: mapAnnotations[2], to:   mapAnnotations[0])
            guideBtn.setTitle("From A To B", for: .normal)
            currentGuide = 0
        default:
            drawRoute(from: mapAnnotations[0], to:   mapAnnotations[1])
            guideBtn.setTitle("From B To C", for: .normal)
            currentGuide = 0
        }
    }
    
    func drawRoute(from:MKPointAnnotation,to:MKPointAnnotation) {
        map.removeOverlays(map.overlays)
        
        let sourcePlaceMark = MKPlacemark(coordinate: from.coordinate)
        let destinationPlaceMark = MKPlacemark(coordinate: to.coordinate)
        
        
        let directionRequest = MKDirections.Request()
        
        
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        
        directionRequest.transportType = .walking
        
        // calculate the direction
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResponse = response else {return}
            let route = directionResponse.routes[0]
            
            self.map.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
            
            self.map.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    func drawPolylineWithRouteDistance(from:MKAnnotation,to:MKAnnotation){
        let sourcePlaceMark = MKPlacemark(coordinate: from.coordinate)
        let destinationPlaceMark = MKPlacemark(coordinate: to.coordinate)
        
        let directionRequest = MKDirections.Request()
        
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        
        directionRequest.transportType = .walking
        
        // calculate the direction
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResponse = response else {return}
            let route = directionResponse.routes[0]
            
            self.map.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)

        }
    }
    
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
    
        
        if((text ?? "").isEmpty){
            locations.removeAll()
            table.isHidden = true
            table.reloadData()
            return
        }
        
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
                
                self.table.isHidden = false
                self.locations = response.mapItems
                
                self.table.reloadData()
            }
        
    }
    
    func initMap(){
        
        triangleOverlay = nil
        linesOverlay = nil
        
        table.isHidden = true
        resetBtn.isHidden = true
        guideBtn.isHidden = true
        
        mapAnnotations = [MKPointAnnotation]()
        locations.removeAll()
        
        map.isZoomEnabled = false
        map.showsUserLocation = true
    
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        addDoubleTap()
        
        map.delegate = self
    
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress))
        map.addGestureRecognizer(longPressGesture)
    }

    func addDoubleTap(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(addAnnotationOnDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        map.addGestureRecognizer(doubleTap)
    }
    
    func removeAllAnnotations(){
        map.removeAnnotations(mapAnnotations)
        map.removeOverlays(map.overlays)
        mapAnnotations.removeAll()
        triangleOverlay = nil
    }
    
    
    @objc func addAnnotationOnDoubleTap(sender: UITapGestureRecognizer){
        
        func addIt(){
            let touchPoint = sender.location(in: map)
            let coordinate = map.convert(touchPoint, toCoordinateFrom: map)
            let annotation = MKPointAnnotation()
            
            let title = getAnnotationTitle()
            
            annotation.title = title
            annotation.coordinate = coordinate
            
            mapAnnotations.append(annotation)
            
            map.addAnnotation(annotation)
        }
        
        if(checkAnnotationsCount()){
            addIt()
        }
        else{
            removeAllAnnotations()
            addIt()
        }
        createAllPolylines()
    }
    
    func getAnnotationTitle() -> String{
        var title = ""
        switch(mapAnnotations.count){
            case 0 :
                title = "A"
            case 1 :
                title = "B"
            case 2 :
                title = "C"
        default:
            return ""
        }
        return title
    }
    
    
    func addLocationFromSearch(location:MKMapItem){
        
        locations.removeAll()
        
        func addIt(){

            
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.placemark.coordinate
            annotation.title = getAnnotationTitle()
            
//            if(checkIfAlreadyMarkerExistsNearby(annotation: annotation)){
//
//            }
            
            mapAnnotations.append(annotation)
            map.addAnnotation(annotation)
        }
        
        if(checkAnnotationsCount()){
            
            addIt()
        }
        else{
            removeAllAnnotations()
            
            addIt()
            
        }
        
        createAllPolylines()
        
        table.isHidden = true
        
        
    }
    
    @objc func addAnnotationOnLongPress(gestureRecognizer:UIGestureRecognizer){
        
        func addIt(){
            let touchPoint = gestureRecognizer.location(in: map)
            let newCoordinates = map.convert(touchPoint, toCoordinateFrom: map)
           
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            annotation.title = getAnnotationTitle()
            
            mapAnnotations.append(annotation)
            
            map.addAnnotation(annotation)
        }
        
        if (checkAnnotationsCount()){
            addIt()
        }
        else{
            removeAllAnnotations()
           addIt()
        }
        createAllPolylines()

    }
    
    
    
    func createAllPolylines(){
        if(triangleOverlay != nil){
            return
        }
        
        var coordinates = mapAnnotations.map {$0.coordinate}
        
        if(mapAnnotations.count == 3) {
            
            
            let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
            map.addOverlay(polygon)
            
            resetBtn.isHidden = false
            guideBtn.isHidden = false
            
            guideBtn.setTitle("From A To B", for: .normal)
            currentGuide = 0
        }
        else{
            return
        }
        
        //to create lines among two markers
        if(linesOverlay != nil){
            return
        }
        coordinates.append(mapAnnotations[0].coordinate)
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        map.addOverlay(polyline)
        
        //to create center marker among two annotations
//        for i in 0...(mapAnnotations.count-2){
//            var location = mapAnnotations[i].coordinate
//            var centerlocation = location.middleLocationWith(location: mapAnnotations[i+1].coordinate)
//
//            let annotation = MKPointAnnotation()
//            annotation.coordinate = centerlocation
//            annotation.title = "center"
//            map.addAnnotation(annotation)
//
//        }
    }
    
    
    func checkIfAlreadyMarkerExistsNearby(annotation:MKAnnotation) -> Bool{
        for marker in mapAnnotations{
            
            let location = CLLocation(latitude: marker.coordinate.latitude, longitude: marker.coordinate.longitude)
            let toChecklocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            
            var hasNearby  = toChecklocation.checkIfLocationNearby(loc: location)
            
            if(hasNearby){
                return true
            }
            
            
        }
        return false
            
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
        return mapAnnotations.count < 3
    }
    
    func distanceFromMyLocation(from:MKAnnotation,to:MKAnnotation) -> String {
        
        let sourcePlaceMark = MKPlacemark(coordinate: from.coordinate)
        let destinationPlaceMark = MKPlacemark(coordinate: to.coordinate)
        
        let directionRequest = MKDirections.Request()
        
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        
        directionRequest.transportType = .walking
        
        // calculate the direction
        var distance = ".. km"
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResponse = response else {return}
            let route = directionResponse.routes[0]
            
            distance =  "\(route.distance) km"
        }
        
        print(distance)
        
        return distance
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
            
            let distanceFromCurrentLocation = distanceFromMyLocation(from: myCurrentLocationAnnotation!, to: annotation)
            
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
            annotationView.image = UIImage(named: "marker")
            annotationView.canShowCallout = true
            
            let subtitleView = UILabel()
            var subTitle = "current location -> \(distanceFromCurrentLocation) away\n"
            annotationView.markerTintColor = UIColor.blue
            
        
            if(mapAnnotations.count == 3){

                switch(annotation.title){
                case "B":
                    let distancetoA = distanceFromMyLocation(from: annotation, to: mapAnnotations[0])
                    let distancetoC = distanceFromMyLocation(from: annotation, to: mapAnnotations[2])
                    subTitle.append("Distance to A -> \(distancetoA) \n Distance to C -> \(distancetoC)")
                case "C":
                    let distancetoA = distanceFromMyLocation(from: annotation, to: mapAnnotations[0])
                    let distancetoB = distanceFromMyLocation(from: annotation, to: mapAnnotations[1])
                    subTitle.append("Distance to A -> \(distancetoA) \n Distance to B -> \(distancetoB)")
                default:
                    let distancetoB = distanceFromMyLocation(from: annotation, to: mapAnnotations[1])
                    let distancetoC = distanceFromMyLocation(from: annotation, to: mapAnnotations[2])
                    subTitle.append("Distance to B -> \(distancetoB) \n Distance to C -> \(distancetoC)")
                }
            }
            subtitleView.text = subTitle
            annotationView.detailCalloutAccessoryView = subtitleView
            
            
            
            
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
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.9)
            rendrer.lineWidth = 1
            
            return rendrer
        } else if overlay is MKPolygon {
            
            let rendrer = MKPolygonRenderer(overlay: overlay)
            rendrer.strokeColor = UIColor.green
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.5)
            rendrer.lineWidth = 3
            
            triangleOverlay = rendrer
            
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


extension CLLocationCoordinate2D {
    // MARK: CLLocationCoordinate2D+MidPoint
    func middleLocationWith(location:CLLocationCoordinate2D) -> CLLocationCoordinate2D {

        let lon1 = longitude * M_PI / 180
        let lon2 = location.longitude * M_PI / 180
        let lat1 = latitude * M_PI / 180
        let lat2 = location.latitude * M_PI / 180
        let dLon = lon2 - lon1
        let x = cos(lat2) * cos(dLon)
        let y = cos(lat2) * sin(dLon)

        let lat3 = atan2( sin(lat1) + sin(lat2), sqrt((cos(lat1) + x) * (cos(lat1) + x) + y * y) )
        let lon3 = lon1 + atan2(y, cos(lat1) + x)

        let center:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat3 * 180 / M_PI, lon3 * 180 / M_PI)
        return center
    }
    
    
}

extension CLLocation{
    func checkIfLocationNearby(loc:CLLocation) -> Bool{
        let distance = distance(from: loc) / 1000
        return distance < 500
        //500 metres
    }
}
