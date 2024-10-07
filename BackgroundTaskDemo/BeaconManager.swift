//
//  BeaconManager.swift
//  BackgroundTaskDemo
//
//  Created by Marco Alonso on 04/10/24.
//

import Foundation
import CoreLocation

/// Esta clase es de prueba para poder trackear balizas, aun no se implementa.
class BeaconManager: NSObject, CLLocationManagerDelegate {
    static let shared = BeaconManager()
    
    private var locationManager: CLLocationManager?
    var beaconDetectedCallback: ((UUID) -> Void)?
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func startScanning(completion: @escaping (UUID) -> Void) {
        beaconDetectedCallback = completion
        
        // Empezamos a monitorizar una región amplia que cubra todos los beacons
        let uuid = UUID(uuidString: "954FBC91-620E-4B5A-86F7-1F31A0054194")!
        
        let beaconRegion = CLBeaconRegion(uuid: uuid, identifier: "MyBeaconRegion")
        
        locationManager?.startMonitoring(for: beaconRegion)
        locationManager?.startRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        if let beacon = beacons.first {
            beaconDetectedCallback?(beacon.uuid)
        }
    }
}
