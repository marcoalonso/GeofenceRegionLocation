//
//  LocationManageB.swift
//  BackgroundTaskDemo
//
//  Created by Marco Alonso on 03/10/24.
//

import CoreLocation
import UserNotifications
import BackgroundTasks

class LocationManagerB: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManagerB()
    
    private let locationManager = CLLocationManager()
    private let openWeatherAPIKey = "43c02b88939bc65afefdef7ff3b31822" 
    
    private let backgroundTaskIdentifier = "com.rotadevsolutions.BackgroundTaskDemo"
    
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    private override init() {
        super.init()
        setupLocationManager()
        requestNotificationAuthorization()
        registerBackgroundTask()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = kCLDistanceFilterNone
    }
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permiso de notificaciones concedido")
            } else if let error = error {
                print("Error al solicitar permiso de notificaciones: \(error.localizedDescription)")
            }
        }
    }
    
    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startBackgroundLocationUpdates() {
        locationManager.startUpdatingLocation()
        print("Iniciando actualizaciones de ubicación en segundo plano")
        scheduleBackgroundTask()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        print("Deteniendo actualizaciones de ubicación")
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
    }
    
    func startMonitoring(geofenceRegion: CLCircularRegion) {
        locationManager.startMonitoring(for: geofenceRegion)
        print("Iniciando monitoreo para la región geográfica: \(geofenceRegion.identifier)")
    }
    
    private func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutos desde ahora
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Tarea en segundo plano programada")
        } catch {
            print("No se pudo programar la tarea en segundo plano: \(error.localizedDescription)")
        }
    }
    
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        scheduleBackgroundTask() // Programa la próxima ejecución
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Obtener la ubicación actual y el clima
        if let location = locationManager.location {
            getWeatherData(for: location) { success in
                task.setTaskCompleted(success: success)
            }
        } else {
            task.setTaskCompleted(success: false)
        }
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
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Saliste de la región geográfica: \(region.identifier)")
        
        // Obtener la ubicación actual
        if let location = manager.location {
            // Consumir la API de OpenWeather
            getWeatherData(for: location) { _ in }
        }
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
    
    // MARK: - OpenWeather API
    
    private func getWeatherData(for location: CLLocation, completion: @escaping (Bool) -> Void) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(openWeatherAPIKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            print("URL inválida")
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let error = error {
                print("Error al obtener datos del clima: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let data = data else {
                print("No se recibieron datos")
                completion(false)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    self?.handleWeatherData(json)
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                print("Error al parsear JSON: \(error.localizedDescription)")
                completion(false)
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
            
            // Mostrar notificación local
            showLocalNotification(message: message)
        }
    }
    
    // MARK: - Notifications
    
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
}
