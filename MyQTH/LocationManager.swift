import CoreLocation
import Foundation
import Observation

/// Manages one-shot access to the user’s current location with SwiftUI-friendly observation.
///
/// `LocationManager` wraps `CLLocationManager` to request authorization and a single location fix on demand. It exposes the
/// latest `CLLocation`, the current authorization status, and a user-presentable `LocationError` for display in the UI.
@MainActor
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    /// A user-presentable error describing why location could not be obtained.
    ///
    /// - permissionDenied: The app lacks permission to access location.
    /// - underlying: An underlying Core Location or system error occurred.
    /// - unknown: An unspecified error occurred.
    enum LocationError: LocalizedError {
        case permissionDenied
        case underlying(Error)
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                "Location access has been denied."
            case .underlying(let error):
                error.localizedDescription
            case .unknown:
                "Unknown error."
            }
        }
    }
    
    /// The underlying Core Location manager.
    private let manager = CLLocationManager()
    
    /// The authorization status.
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
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
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    // MARK: - Methods
    
    /// Requests a single location update.
    ///
    /// This method calls `CLLocationManager.requestLocation()`. The result is delivered via
    /// `locationManager(_:didUpdateLocations:)` or `locationManager(_:didFailWithError:)`.
    func requestLocation() {
        manager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    /// Handles changes to authorization.
    ///
    /// - Authorized (.authorizedAlways / .authorizedWhenInUse): Clears errors and requests a
    ///   one-shot location update.
    /// - Not determined: Clears location and prompts for when-in-use authorization.
    /// - Restricted/Denied: Clears location and surfaces a `.permissionDenied` error.
    /// - Unknown: Surfaces an `.unknown` error.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        error = nil
        
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            requestLocation()
        case .notDetermined:
            location = nil
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            location = nil
            error = .permissionDenied
        @unknown default:
            location = nil
            error = .unknown
        }
    }
    
    /// Receives successful location updates and clears any previous error.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        error = nil
    }
    
    /// Receives location errors and wraps them in `LocationError.underlying`.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        self.error = .underlying(error)
    }
}
