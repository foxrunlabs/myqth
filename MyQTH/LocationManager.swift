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
    /// The status of a one-shot location request.
    enum RequestState {
        /// No location fix is in progress, including before a request or after a successful update.
        case idle

        /// Core Location is obtaining a location fix.
        case locating

        /// Authorization prevented the request or a location update failed; see the manager’s `error` for details.
        case failed
    }

    /// Persists independently of alert presentation so dismissing an error does not hide a failure.
    private(set) var requestState: RequestState = .idle

    /// A user-presentable error describing why location could not be obtained.
    enum LocationError: LocalizedError {
        /// Location services are denied.
        case permissionDenied
        
        /// Location services are restricted.
        case permissionRestricted
        
        /// An underlying Core Location or system error occurred.
        case underlying(Error)
        
        /// An unspecified error occurred.
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
    
    /// UserDefaults keys for AppStorage.
    private enum DefaultsKey {
        static let latitude = "net.thefoxrun.labs.MyQTH.lastKnownLatitude"
        static let longitude = "net.thefoxrun.labs.MyQTH.lastKnownLongitude"
        static let horizontalAccuracy = "net.thefoxrun.labs.MyQTH.lastKnownHorizontalAccuracy"
        static let timestamp = "net.thefoxrun.labs.MyQTH.lastKnownLocationTimestamp"
    }
    
    /// The underlying Core Location manager.
    private let manager = CLLocationManager()
    
    /// The authorization status.
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// The most recent error, suitable for presenting to the user. Set to `nil` when a location is successfully obtained or
    /// when a new request starts. Dismissing an alert leaves this error available for recovery.
    private(set) var error: LocationError?
    
    /// The most recently reported location from Core Location. Updated to the last value received in `didUpdateLocations`
    /// when available.
    private(set) var location: CLLocation?
    
    // MARK: - Initializer
    
    /// Initializes the manager, recalls the last known location, and captures the current authorization status.
    override init() {
        super.init()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        
        location = loadLastKnownLocation()
        authorizationStatus = manager.authorizationStatus
    }
    
    // MARK: - Methods
    
    /// Requests a single fix or explains why authorization prevents it. Duplicate requests are ignored.
    func requestLocation() {
        guard requestState != .locating else { return }

        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            error = nil
            requestState = .locating
            manager.requestLocation()
        case .notDetermined:
            error = nil
            manager.requestWhenInUseAuthorization()
        case .denied:
            error = .permissionDenied
            requestState = .failed
        case .restricted:
            error = .permissionRestricted
            requestState = .failed
        @unknown default:
            error = .unknown
            requestState = .failed
        }
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    /// Handles changes to authorization.
    ///
    /// - Authorized: Clears errors and requests a one-shot location update.
    /// - Not determined: Clears errors and prompts for when-in-use authorization.
    /// - Restricted: Stops updating location and surfaces a `.permissionRestricted` error.
    /// - Denied: Stops updating location and surfaces a `.permissionDenied` error.
    /// - Unknown: Surfaces an `.unknown` error.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        // Cancel any in-flight request before applying the new authorization state.
        manager.stopUpdatingLocation()
        requestState = .idle
        requestLocation()
    }

    /// Receives successful location updates, clears any previous error, and saves the last valid location.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard authorizationStatus == .authorizedAlways ||
                authorizationStatus == .authorizedWhenInUse
        else {
            return
        }

        guard let latest = locations.last(where: {
            $0.horizontalAccuracy >= 0 && CLLocationCoordinate2DIsValid($0.coordinate)
        }) else {
            error = .unknown
            requestState = .failed
            return
        }

        location = latest
        error = nil
        requestState = .idle
        save(latest)
    }
    
    /// Receives location errors and wraps them in `LocationError.underlying`.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // Preserve the actionable permission error if a late callback arrives after revocation.
        guard
            authorizationStatus == .authorizedAlways ||
                authorizationStatus == .authorizedWhenInUse
        else {
            return
        }
        
        self.error = .underlying(error)
        requestState = .failed
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
    /// uses `Date.distantPast`. The restored location has an altitude of `0` and a vertical accuracy of `-1`, indicating
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
