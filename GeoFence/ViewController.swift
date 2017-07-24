//
//  ViewController.swift
//  Geo Fence
//
//  Created by Julian Jans on 13/07/2016.
//  Copyright © 2016 Julian Jans. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AudioToolbox

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var lastKnownPosition: CLLocation?
    
    var fences = Array<Fence>()
    var tracking: Bool = false
    var track = Array<CLLocation>()
    var trackLines = Array<MKPolyline>()
    
    @IBOutlet var mapView: MKMapView?
    @IBOutlet var trackCount: UILabel?
    @IBOutlet var labels: [UIView]!
    @IBOutlet var colorView: UIView?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var messageLabel: UILabel?
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = CLActivityType.fitness
        locationManager.delegate = self
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
        
        mapView!.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
        
        clearMapOverlays()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        alert("Geo Fence", message: "Tap to add fences...", color: nil)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    
    // MARK: Track
    
    @IBAction func trackLog() {
        tracking = true
        alert("Track", message: "Estimated file size:", color: nil)
    }
    
    func updateTrackLine(_ from: CLLocation, to:CLLocation) {
        var pointsToUse: [CLLocationCoordinate2D] = [to.coordinate, from.coordinate]
        let polyLine = MKPolyline(coordinates: &pointsToUse, count: pointsToUse.count)
        mapView!.add(polyLine)
        trackLines.append(polyLine)
    }
    
    
    // MARK: Fences
    
    @IBAction func didTapMapView(_ gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == .ended) {
            addFence(coordinateFromGesture(gestureRecognizer))
        }
    }
    
    func addFence(_ center: CLLocationCoordinate2D) {
     
        let fence = Fence(coordinate:center, radius: max((mapView?.region.span.latitudeDelta)! * 7500.0, 100))
        fences.append(fence)
        
        if let circle = fence.circle {
            mapView!.add(circle)
        }
        if let region = fence.region {
            locationManager.startMonitoring(for: region)
        }
    }

    
    // MARK: Overlays
    
    @IBAction func clearMapOverlays() {
        
        tracking = false
        track = Array<CLLocation>()
        trackCount?.text = ""
        
        for polyline in trackLines {
            mapView!.remove(polyline)
        }
        
        for fence in fences {
            if let circle = fence.circle {
                mapView!.remove(circle)
            }
            if let region = fence.region {
                locationManager.stopMonitoring(for: region)
            }
        }
        
        alert("Geo Fence", message: "Cleared overlays", color: nil)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if (overlay is MKCircle) {
            let renderer = GradientCircleRenderer(overlay: overlay)
            
            let color = UIColor.randomColor(0.8)
            
            // FIXME: Improve on this bit of code
            for fence in fences where fence.circle == (overlay as! MKCircle) {
                fence.color = color
            }
            
            renderer.fillColor = color
            return renderer
            
        } else if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.randomColor(0.8)
            renderer.lineWidth = 6.0
            return renderer
        } else {
            return MKOverlayRenderer()
        }
    }
    
 
    // MARK: Location Manager Delegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        if (tracking) {
            if let currentLocation = location {
                track.append(currentLocation)
                trackCount?.text = "\(ByteCountFormatter.string(fromByteCount: (Int64(track.count * 108)), countStyle: .file))"
                if (lastKnownPosition != nil) {
                    updateTrackLine(lastKnownPosition!, to: currentLocation)
                }
            }
        }
        lastKnownPosition = location!
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        alert("Entered Region", message: region.identifier, color: fenceColor(region))
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        alert("Exited Region", message: region.identifier, color:  fenceColor(region))
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        alert("Monitoring Region", message: region.identifier, color:  fenceColor(region))
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        alert("Failed Monitoring Region", message: error.localizedDescription, color: nil)
    }
    
    
    // MARK: Helpers
    
    func coordinateFromGesture(_ gestureRecognizer: UIGestureRecognizer) -> CLLocationCoordinate2D {
        let touchPoint = gestureRecognizer.location(in: gestureRecognizer.view)
        let coordinate = self.mapView!.convert(touchPoint, toCoordinateFrom: self.mapView)
        return coordinate
    }
    
    func alert(_ title: String, message: String, color: UIColor?) {
        
        func setAlpha(_ alpha: CGFloat) {
            for view in labels {
                view.alpha = alpha
            }
        }
        colorView?.backgroundColor = (color != nil) ? color?.withAlphaComponent(0.2) : UIColor.clear
    
        setAlpha(0.0)
        titleLabel?.text = title
        messageLabel?.text = message
        UIView.animate(withDuration: 0.2, animations: {
            setAlpha(1.0)
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }, completion: { (bool) in
            UIView.animate(withDuration: 0.6, delay: 1.0, options: UIViewAnimationOptions(), animations: { setAlpha(0.0) }, completion: nil)
        }) 
    }
    
    func fenceColor(_ region: CLRegion) -> UIColor? {
        for fence in fences where fence.region!.identifier == region.identifier {
            return fence.color
        }
        return nil
    }
    
}
