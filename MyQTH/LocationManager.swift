import CoreLocation
import Foundation
import Observation

/// Manages one-shot access to the user’s current location with SwiftUI-friendly observation.
///
/// `LocationManager` wraps `CLLocationManager` to request authorization and a single location fix on demand. It
/// exposes the latest `CLLocation`, the current authorization status, and a user-presentable `LocationError` for display
/// in the UI.
@MainActor
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private enum DefaultsKey {
        static let autoUpdate = "net.thefoxrun.labs.MyQTH.autoUpdate"
        static let latitude = "net.thefoxrun.labs.MyQTH.lastKnownLatitude"
        static let longitude = "net.thefoxrun.labs.MyQTH.lastKnownLongitude"
        static let horizontalAccuracy = "net.thefoxrun.labs.MyQTH.lastKnownHorizontalAccuracy"
        static let timestamp = "net.thefoxrun.labs.MyQTH.lastKnownLocationTimestamp"
    }
    
    /// A user-presentable error describing why location could not be obtained.
    ///
    /// - permissionDenied: Location services are denied.
    /// - permissionRestricted: Location services are restricted.
    /// - underlying: An underlying Core Location or system error occurred.
    /// - unknown: An unspecified error occurred.
    enum LocationError: LocalizedError {
        case permissionDenied
        case permissionRestricted
        case underlying(Error)
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                "Location access is disabled. You can enable it in Settings."
            case .permissionRestricted:
                "Location access is restricted on this device. You may need to contact a parent or device administrator."
            case .underlying(let error):
                error.localizedDescription
            case .unknown:
                "An unknown location error occurred."
            }
        }
    }
    
    /// The underlying Core Location manager.
    private let manager = CLLocationManager()
    
    /// The authorization status.
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Position update mode setting.
    var autoUpdate = false {
        didSet {
            UserDefaults.standard.set(autoUpdate, forKey: DefaultsKey.autoUpdate)
            configureUpdates()
        }
    }
    
    /// The most recent error, suitable for presenting to the user. Set to `nil` when a location is successfully obtained or when
    /// authorization allows requesting location.
    var error: LocationError?
    
    /// The most recently reported location from Core Location.
    ///
    /// Reset to `nil` when authorization is not determined, restricted, or denied. Updated to the last value received in
    /// `didUpdateLocations` when available.
    private(set) var location: CLLocation?
    
    // MARK: - Initializer
    
    /// Initializes the manager, assigns the delegate, sets desired accuracy, and captures the
    /// current authorization status.
    override init() {
        super.init()
        
        autoUpdate = UserDefaults.standard.bool(forKey: DefaultsKey.autoUpdate)
        location = loadLastKnownLocation()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        
        authorizationStatus = manager.authorizationStatus
    }
        
    // MARK: - Methods
    
    /// Requests a single location update.
    ///
    /// This method calls `CLLocationManager.requestLocation()`. The result is delivered via
    /// `locationManager(_:didUpdateLocations:)` or `locationManager(_:didFailWithError:)`.
    func requestLocation() {
        guard !autoUpdate else { return }
        manager.requestLocation()
    }
    
    /// Starts or stops location updates based on `autoUpdate` value and `authorizationStatus`.
    private func configureUpdates() {
        guard
            authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
        else {
            return
        }
        
        if autoUpdate {
            manager.startUpdatingLocation()
        } else {
            manager.stopUpdatingLocation()
        }
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    /// Handles changes to authorization.
    ///
    /// - Authorized (.authorizedAlways / .authorizedWhenInUse): Clears errors and requests either a one-shot location update or
    /// configures continuous location updates.
    /// - Not determined: Clears location and prompts for when-in-use authorization.
    /// - Restricted/Denied: Clears location and surfaces a `.permissionDenied` error.
    /// - Unknown: Surfaces an `.unknown` error.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        error = nil
        
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if autoUpdate {
                configureUpdates()
            } else {
                requestLocation()
            }
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted:
            manager.stopUpdatingLocation()
            error = .permissionRestricted
        case .denied:
            manager.stopUpdatingLocation()
            error = .permissionDenied
        @unknown default:
            manager.stopUpdatingLocation()
            error = .unknown
        }
    }
    
    /// Receives successful location updates and clears any previous error.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        error = nil
        
        if let location { save(location) }
    }
    
    /// Receives location errors and wraps them in `LocationError.underlying`.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        self.error = .underlying(error)
    }
    
    /// Saves the last known location to standard user defaults.
    ///
    /// Stores the latitude, longitude, horizontal accuracy, and timestamp for restoration by `loadLastKnownLocation()`,
    /// replacing any previously saved values.
    ///
    /// - Parameter location: The location whose coordinates, horizontal accuracy, and timestamp to save.
    private func save(_ location: CLLocation) {
        UserDefaults.standard.set(location.coordinate.latitude, forKey: DefaultsKey.latitude)
        UserDefaults.standard.set(location.coordinate.longitude, forKey: DefaultsKey.longitude)
        UserDefaults.standard.set(location.horizontalAccuracy, forKey: DefaultsKey.horizontalAccuracy)
        UserDefaults.standard.set(location.timestamp, forKey: DefaultsKey.timestamp)
    }
    
    /// Restores the last known location from standard user defaults.
    ///
    /// Reads the saved latitude, longitude, horizontal accuracy, and timestamp. If the timestamp is missing or is not a `Date`,
    /// uses `Date.distantPast`. The restored location has an altitude of zero and a vertical accuracy of `-1`, indicating
    /// that altitude information is invalid.
    ///
    /// - Returns: The restored location, or `nil` if the latitude, longitude, or horizontal accuracy entry is missing.
    private func loadLastKnownLocation() -> CLLocation? {
        guard
            UserDefaults.standard.object(forKey: DefaultsKey.latitude) != nil,
            UserDefaults.standard.object(forKey: DefaultsKey.longitude) != nil,
            UserDefaults.standard.object(forKey: DefaultsKey.horizontalAccuracy) != nil
        else {
            return nil
        }
        
        let latitude = UserDefaults.standard.double(forKey: DefaultsKey.latitude)
        let longitude = UserDefaults.standard.double(forKey: DefaultsKey.longitude)
        let horizontalAccuracy = UserDefaults.standard.double(forKey: DefaultsKey.horizontalAccuracy)
        let timestamp = UserDefaults.standard.object(forKey: DefaultsKey.timestamp) as? Date ?? .distantPast
        
        return CLLocation(
            coordinate: .init(
                latitude: latitude,
                longitude: longitude
            ),
            altitude: 0,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: -1,
            timestamp: timestamp
        )
    }
}
