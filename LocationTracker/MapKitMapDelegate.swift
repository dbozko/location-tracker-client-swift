//
//  MapKitMapDelegate.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/12/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import MapKit

class MapKitMapDelegate: NSObject, MapDelegate, MKMapViewDelegate {

    var mapView: MKMapView
    var polyline: MKPolyline? = nil
    var circle: MKCircle? = nil
    
    static let mapDefaultStyleId = "Standard"
    static let mapStyleIds = ["Standard","Satellite","Satellite Flyover","Hybrid","Hybrid Flyover"]
    static let mapStyleTypes: [String:MKMapType] = ["Standard":MKMapType.standard,
                                                    "Satellite":MKMapType.satellite,
                                                    "Satellite Flyover":MKMapType.satelliteFlyover,
                                                    "Hybrid":MKMapType.hybrid,
                                                    "Hybrid Flyover":MKMapType.hybridFlyover]
    
    init(mapView: MKMapView) {
        self.mapView = mapView
        self.mapView.showsUserLocation = true
        super.init()
        self.mapView.delegate = self;
    }
    
    // MARK: LocationMapViewDelegate Members
    
    func providerId() -> String {
        return "MapKit"
    }
    
    func setStyle(styleId: String) {
        if let mapType = MapKitMapDelegate.mapStyleTypes[styleId] {
            self.mapView.mapType = mapType;
        }
    }
    
    func getPin(coordinate: CLLocationCoordinate2D, title: String, color: UIColor) -> MapPin {
        return MapKitMapPin(
            coordinate: coordinate,
            title: title,
            color: color
        )
    }
    
    func addPin(pin: MapPin) {
        self.mapView.addAnnotation(pin as! MapKitMapPin)
    }
    
    func removePins(pins: [MapPin]) {
        self.mapView.removeAnnotations(pins as! [MapKitMapPin])
    }
    
    func drawPath(coordinates: [CLLocationCoordinate2D]) {
        // remove polyline if one exists
        if (self.polyline != nil) {
            self.mapView.remove(self.polyline!)
        }
        // create and add new polyline
        var mutableCoordinates = coordinates;
        self.polyline = MKPolyline(coordinates: &mutableCoordinates, count: coordinates.count)
        self.mapView.add(self.polyline!)
    }
    
    func erasePath() {
        // remove polyline if one exists
        if (self.polyline != nil) {
            self.mapView.remove(self.polyline!)
            self.polyline = nil
        }
    }
    
    func drawRadius(centerCoordinate coordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance) {
        // remove circle if one exists
        if (self.circle != nil) {
            self.mapView.remove(self.circle!)
        }
        // create and add new polyline
        self.circle = MKCircle(center: coordinate, radius: radiusMeters)
        self.mapView.add(self.circle!)
    }
    
    func eraseRadius() {
        // remove circle if one exists
        if (self.circle != nil) {
            self.mapView.remove(self.circle!)
            self.circle = nil
        }
    }
    
    func centerAndZoom(centerCoordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance, animated: Bool) {
        let region = MKCoordinateRegionMakeWithDistance(centerCoordinate, radiusMeters, radiusMeters)
        self.mapView.setRegion(region, animated: animated)
    }
    
    // MARK: MKMapViewDelegate Members
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if (overlay === self.polyline) {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blue
            polylineRenderer.lineWidth = 2
            return polylineRenderer
        }
        else {
            let cirlceRenderer = MKCircleRenderer(overlay: overlay)
            cirlceRenderer.strokeColor = UIColor.green
            cirlceRenderer.fillColor = UIColor.green.withAlphaComponent(0.15)
            cirlceRenderer.lineWidth = 2
            return cirlceRenderer
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseIdentifier = "PinAnnotation"
        var pinAnnotation: MKPinAnnotationView? = self.mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MKPinAnnotationView
        if(pinAnnotation == nil) {
            pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        }
        else {
            pinAnnotation?.annotation = annotation
        }
        if let pin = annotation as? MapPin {
            pinAnnotation!.pinTintColor = pin.color
        }
        pinAnnotation?.canShowCallout = true
        return pinAnnotation;
    }
    
}
