//
//  LocationManager.swift
//  BackgroundTaskDemo
//
//  Created by Marco Alonso on 30/09/24.
//

import Foundation
import CoreLocation
import BackgroundTasks
import UserNotifications
import UIKit

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let openWeatherAPIKey = "43c02b88939bc65afefdef7ff3b31822"

    private let locationManager = CLLocationManager()
    
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }

    var location: CLLocation {
        return locationManager.location ?? CLLocation(latitude: 0, longitude: 0)
    }
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        // Helps to save battery when device is not moving
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.distanceFilter = 10
        locationManager.startMonitoringSignificantLocationChanges()
        /*
         /// TODO: - Manejar la notificacion push
        locationManager.startMonitoringLocationPushes { data, error in
            if let e = error {
                print("Debug: error getting push \(e.localizedDescription)")
            }
            
            guard let data = data else {
                print("Debug: error data not found!")
                return
            }
            print("Debug: data \(data)")
        }
        */
    }
    
    func requestLocationPermission() {
        // locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }
    
    func startBackgroundLocationUpdates() {
        locationManager.startUpdatingLocation()
        print("Iniciando actualizaciones de ubicación en segundo plano")
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        print("Deteniendo actualizaciones de ubicación")
    }
    
    // Función para monitorear una región geográfica
    func startMonitoring(geofenceRegion: CLCircularRegion) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            print("Debug: MonitoringNotAvailable ******* ")
            return
        }
        locationManager.startMonitoring(for: geofenceRegion)
        print("Iniciando monitoreo para la región geográfica: \(geofenceRegion.identifier)")
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("Nueva ubicación obtenida en segundo plano: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener la ubicación: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entraste en la región geográfica: \(region.identifier)")
        if let location = manager.location {
            getWeatherData(for: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Saliste de la región geográfica: \(region.identifier)")
        if let location = manager.location {
            getWeatherData(for: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Region monitoring failed with error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            print("Permiso de ubicación siempre concedido")
        case .authorizedWhenInUse:
            print("Permiso de ubicación concedido solo en uso")
        case .denied, .restricted:
            print("Permiso de ubicación denegado o restringido")
        case .notDetermined:
            print("Permiso de ubicación no determinado")
        @unknown default:
            print("Estado de autorización desconocido")
        }
    }
    
    //    MARK: - Weather API
    private func getWeatherData(for location: CLLocation) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(openWeatherAPIKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            print("URL inválida")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let error = error {
                print("Error al obtener datos del clima: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No se recibieron datos")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    self?.handleWeatherData(json)
                }
            } catch {
                print("Error al parsear JSON: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    private func handleWeatherData(_ weatherData: [String: Any]) {
        if let main = weatherData["main"] as? [String: Any],
           let temp = main["temp"] as? Double,
           let weather = weatherData["weather"] as? [[String: Any]],
           let firstWeather = weather.first,
           let description = firstWeather["description"] as? String {
            
            let temperatureCelsius = Int(temp.rounded())
            let message = "Temperatura actual: \(temperatureCelsius)°C, \(description)"
            print("Debug:  message  \(message)")
            
            // Mostrar notificación local
            showLocalNotification(message: message)
            
            // Mostrar alerta modal si la app está en primer plano
            showAlertIfInForeground(message: message)
        }
    }
    
    private func showLocalNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Actualización del clima"
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error al mostrar notificación local: \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlertIfInForeground(message: String) {
        DispatchQueue.main.async {
            if let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() {
                let alertController = UIAlertController(title: "Actualización del clima", message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                topViewController.present(alertController, animated: true, completion: nil)
            }
        }
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        }
        
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        
        return self
    }
}
