import CoreLocation

/// Utilities for converting WGS 84 geographic coordinates (latitude/longitude) to
/// UTM (Universal Transverse Mercator) grid references.
extension CLLocationCoordinate2D {
    /// Semi‑major axis of the WGS 84 ellipsoid, in meters.
    private static let a = 6_378_137.0
    
    /// Flattening of the WGS 84 ellipsoid.
    private static let f = 1.0 / 298.257223563
    
    /// First eccentricity squared (e²) of the WGS 84 ellipsoid.
    private static let e2 = f * (2 - f)
    
    /// Second eccentricity squared (e′²) derived from e².
    private static let ep2 = e2 / (1 - e2)
    
    /// Central meridian scale factor used by UTM.
    private static let k0 = 0.9996
    
    /// False easting applied by UTM, in meters.
    private static let falseEasting = 500_000.0
    
    /// False northing applied for southern hemisphere UTM zones, in meters.
    private static let falseNorthing = 10_000_000.0
    
    /// Returns the UTM (Universal Transverse Mercator) grid reference for this coordinate.
    ///
    /// The result is a string in the form "<zone><hemisphere> <easting> <northing>", for example
    /// "33N 500000 4649776". Values are rounded to the nearest meter. If the coordinate is invalid
    /// or outside the latitude range supported by UTM (−80° to 84°), this property returns `nil`.
    ///
    /// The calculation uses the WGS 84 ellipsoid and the standard Transverse Mercator projection with
    /// a central meridian scale factor of 0.9996, including special‑case handling for southwest Norway
    /// and Svalbard zone assignments.
    ///
    /// - Returns: A UTM string containing zone/hemisphere and integer easting/northing, or `nil` if the
    ///   coordinate cannot be represented in UTM.
    var utm: String? {
        guard
            CLLocationCoordinate2DIsValid(self),
            (-80.0...84.0).contains(latitude)
        else {
            return nil
        }
        
        let normalizedLatitude = (latitude * 10_000.0).rounded() / 10_000.0
        let normalizedLongitude = (longitude * 10_000.0).rounded() / 10_000.0
        
        // work in radians
        let phi = Self.degreesToRadians(normalizedLatitude)
        let lambda = Self.degreesToRadians(normalizedLongitude)
        
        // longitudinal zone
        let zone = utmZone
        let zoneMeridian = 6.0 * Double(zone) - 183.0
        let lambdaMeridian = Self.degreesToRadians(zoneMeridian)
        
        // hemisphere
        let hemisphere = latitude >= 0.0 ? "N" : "S"
        
        // formula values and cached results
        let sinPhi = sin(phi)
        let tanPhi = tan(phi)
        let cosPhi = cos(phi)
        
        let N = Self.a / sqrt(1.0 - Self.e2 * sinPhi * sinPhi)
        let T = tanPhi * tanPhi
        let C = Self.ep2 * cosPhi * cosPhi
        let A = (lambda - lambdaMeridian) * cosPhi
        
        let e4 = Self.e2 * Self.e2
        let e6 = e4 * Self.e2
        
        let M = Self.a * (
            (1 - (Self.e2 / 4.0) - (3.0 * e4 / 64.0) - (5.0 * e6 / 256.0)) * phi -
            ((3.0 * Self.e2 / 8.0) + (3.0 * e4 / 32.0) + (45.0 * e6 / 1024.0)) * sin(2.0 * phi) +
            ((15.0 * e4 / 256.0) + (45.0 * e6 / 1024.0)) * sin(4.0 * phi) -
            (35.0 * e6 / 3072.0) * sin(6.0 * phi)
        )
        
        let A2 = A * A
        let A3 = A2 * A
        let A4 = A2 * A2
        let A5 = A4 * A
        let A6 = A3 * A3
        let T2 = T * T
        let C2 = C * C
        
        // easting
        let easting = Self.k0 * N * (
            A +
            (1.0 - T + C) * A3 / 6.0 +
            (5.0 - (18.0 * T) + T2 + (72.0 * C) - (58.0 * Self.ep2)) * A5 / 120.0
        ) + Self.falseEasting
        
        // northing
        let northing = Self.k0 * (
            M +
            N * tanPhi * (
                A2 / 2.0 +
                (5.0 - T + (9.0 * C) + (4.0 * C2)) * A4 / 24.0 +
                (61.0 - (58.0 * T) + T2 + (600.0 * C) - (330.0 * Self.ep2)) * A6 / 720.0
            )
        ) + (latitude < 0.0 ? Self.falseNorthing : 0.0)
        
        return "\(zone)\(hemisphere) \(Int(easting.rounded())) \(Int(northing.rounded()))"
    }
    
    /// Computes the longitudinal UTM zone number for this coordinate, including special cases
    /// for southwest Norway (zone 32V) and Svalbard (zones 31X, 33X, 35X, 37X) to reduce distortion.
    ///
    /// - Returns: An integer from 1 to 60 representing the UTM zone.
    private var utmZone: Int {
        var zone = min(Int(floor((longitude + 180.0) / 6.0) + 1.0), 60)
        
        // Southwest Norway
        if latitude >= 56.0, latitude < 64.0, longitude >= 3.0, longitude < 12.0 {
            zone = 32
        }

        // Svalbard
        if latitude >= 72.0, latitude <= 84.0 {
            switch longitude {
            case 0.0..<9.0:
                zone = 31
            case 9.0..<21.0:
                zone = 33
            case 21.0..<33.0:
                zone = 35
            case 33.0..<42.0:
                zone = 37
            default:
                break
            }
        }

        return zone
    }
    
    /// Converts degrees to radians.
    ///
    /// - Parameter degrees: An angle in degrees.
    /// - Returns: The angle converted to radians.
    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180.0
    }
}

