//
//  ViewController.swift
//  BackgroundTaskDemo
//
//  Created by Marco Alonso on 30/09/24.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupGeofencing()
    }
    
    private func setupGeofencing() {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            print("Debug: Geofencing is not supported on this device")
            showAlert(message: "Geofencing is not supported on this device")
            return
        }
        
        guard LocationManager.shared.authorizationStatus == .authorizedAlways else {
            print("Debug: App does not have correct location authorization")
            showAlert(message: "App does not have correct location authorization")
            return
        }
        
        startMonitoring()
    }

    private func startMonitoring() {
        
        let regionCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.33154242, longitude: -122.0307334)
        let geofenceRegion: CLCircularRegion = CLCircularRegion(
            center: regionCoordinate,
            radius: 100,
            identifier: "apple_park"
        )
        
        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = true
        
        // Start monitoring
        LocationManager.shared.startMonitoring(geofenceRegion: geofenceRegion)
    }
        
        private func showAlert(message: String) {
            let alertController = UIAlertController(title: "Information", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alertController, animated: true, completion: nil)
        }


}
