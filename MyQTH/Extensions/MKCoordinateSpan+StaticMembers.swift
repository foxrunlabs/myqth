import MapKit

/// This extension defines reusable `MKCoordinateSpan` presets that match Maidenhead grid granularities.
extension MKCoordinateSpan {
    /// Maidenhead field.
    /// - Latitude delta: 10.0°
    /// - Longitude delta: 20.0°
    static let field = Self(latitudeDelta: 10.0, longitudeDelta: 20.0)
    /// Maidenhead square.
    /// - Latitude delta: 1.0°
    /// - Longitude delta: 2.0°
    static let square = Self(latitudeDelta: 1.0, longitudeDelta: 2.0)
    /// Maidenhead subsquare.
    /// - Latitude delta: 2.5′
    /// - Longitude delta: 5.0′
    static let subsquare = Self(latitudeDelta: 2.5 / 60.0, longitudeDelta: 5.0 / 60.0)
}
