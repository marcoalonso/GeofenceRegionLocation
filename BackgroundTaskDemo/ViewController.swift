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
        
        /// Escanear balizas, aun no se prueba
        BeaconManager.shared.startScanning { uuid in
            print("Detected beacon UUID: \(uuid.uuidString)")
        }
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
            showLocationPermissionAlert()
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
    
    func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "Location Access Required",
            message: "Please enable location access in Settings.",
            preferredStyle: .alert
        )
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }


}
