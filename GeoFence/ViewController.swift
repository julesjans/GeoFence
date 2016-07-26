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
        locationManager.activityType = CLActivityType.Fitness
        locationManager.delegate = self
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
        
        mapView!.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
        
        clearMapOverlays()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        alert("Geo Fence", message: "Tap to add fences...", color: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    // MARK: Track
    
    @IBAction func trackLog() {
        tracking = true
        alert("Track", message: "Estimated file size:", color: nil)
    }
    
    func updateTrackLine(from: CLLocation, to:CLLocation) {
        var pointsToUse: [CLLocationCoordinate2D] = [to.coordinate, from.coordinate]
        let polyLine = MKPolyline(coordinates: &pointsToUse, count: pointsToUse.count)
        mapView!.addOverlay(polyLine)
        trackLines.append(polyLine)
    }
    
    
    // MARK: Fences
    
    @IBAction func didTapMapView(gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == .Ended) {
            addFence(coordinateFromGesture(gestureRecognizer))
        }
    }
    
    func addFence(center: CLLocationCoordinate2D) {
     
        let fence = Fence(coordinate:center, radius: max((mapView?.region.span.latitudeDelta)! * 7500.0, 100))
        fences.append(fence)
        
        if let circle = fence.circle {
            mapView!.addOverlay(circle)
        }
        if let region = fence.region {
            locationManager.startMonitoringForRegion(region)
        }
    }

    
    // MARK: Overlays
    
    @IBAction func clearMapOverlays() {
        
        tracking = false
        track = Array<CLLocation>()
        trackCount?.text = ""
        
        for polyline in trackLines {
            mapView!.removeOverlay(polyline)
        }
        
        for fence in fences {
            if let circle = fence.circle {
                mapView!.removeOverlay(circle)
            }
            if let region = fence.region {
                locationManager.stopMonitoringForRegion(region)
            }
        }
        
        alert("Geo Fence", message: "Cleared overlays", color: nil)
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {

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
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        if (tracking) {
            if let currentLocation = location {
                track.append(currentLocation)
                trackCount?.text = "\(NSByteCountFormatter.stringFromByteCount((Int64(track.count * 108)), countStyle: .File))"
                if (lastKnownPosition != nil) {
                    updateTrackLine(lastKnownPosition!, to: currentLocation)
                }
            }
        }
        lastKnownPosition = location!
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        alert("Entered Region", message: region.identifier, color: fenceColor(region))
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        alert("Exited Region", message: region.identifier, color:  fenceColor(region))
    }
    
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        alert("Monitoring Region", message: region.identifier, color:  fenceColor(region))
    }
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        alert("Failed Monitoring Region", message: error.localizedDescription, color: nil)
    }
    
    
    // MARK: Helpers
    
    func coordinateFromGesture(gestureRecognizer: UIGestureRecognizer) -> CLLocationCoordinate2D {
        let touchPoint = gestureRecognizer.locationInView(gestureRecognizer.view)
        let coordinate = self.mapView!.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
        return coordinate
    }
    
    func alert(title: String, message: String, color: UIColor?) {
        
        func setAlpha(alpha: CGFloat) {
            for view in labels {
                view.alpha = alpha
            }
        }
        colorView?.backgroundColor = (color != nil) ? color?.colorWithAlphaComponent(0.2) : UIColor.clearColor()
    
        setAlpha(0.0)
        titleLabel?.text = title
        messageLabel?.text = message
        UIView.animateWithDuration(0.2, animations: {
            setAlpha(1.0)
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }) { (bool) in
            UIView.animateWithDuration(0.6, delay: 1.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { setAlpha(0.0) }, completion: nil)
        }
    }
    
    func fenceColor(region: CLRegion) -> UIColor? {
        for fence in fences where fence.region!.identifier == region.identifier {
            return fence.color
        }
        return nil
    }
    
}