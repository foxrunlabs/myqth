import CoreLocation
import Foundation

/// Represents a generic Universal Transverse Mercator (UTM) grid reference on WGS 84.
///
/// This type stores a UTM coordinate comprising:
/// - `zone`: the longitudinal zone number (1–60),
/// - `hemisphere`: the north or south hemisphere indicator,
/// - `easting`: the easting value in meters,
/// - `northing`: the northing value in meters.
///
/// Coordinates are stored at meter precision, and the type does not enforce display formatting.
struct UTMCoordinate {
    typealias Zone = Int
    typealias Meters = Int
    
    enum Hemisphere: String, CaseIterable, CustomStringConvertible {
        case north = "N"
        case south = "S"
        
        var description: String { self.rawValue }
    }
    
    // MARK: - Properties
    
    var zone: Zone
    var hemisphere: Hemisphere
    var easting: Meters
    var northing: Meters
    
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
    
    // MARK: - Initializers
    
    /// Initializes to the UTM coordinate corresponding to 0°N, 0°E.
    init() {
        self.zone = 31
        self.hemisphere = .north
        self.easting = 166021
        self.northing = 0
    }
    
    /// Creates a UTM coordinate from its components.
    ///
    /// - Parameters:
    ///   - zone: The longitudinal UTM zone number (1–60).
    ///   - hemisphere: The northern or southern hemisphere.
    ///   - easting: The easting value in meters within the zone.
    ///   - northing: The northing value in meters within the zone.
    init(zone: Zone, hemisphere: Hemisphere, easting: Meters, northing: Meters) {
        self.zone = zone
        self.hemisphere = hemisphere
        self.easting = easting
        self.northing = northing
    }
    
    /// Creates a UTM coordinate from a WGS 84 latitude/longitude.
    ///
    /// - Note:
    ///   - The supported latitude range is −80° to 84°. Coordinates outside this range return `nil`.
    ///   - Special-case handling is applied for southwest Norway and Svalbard zones.
    ///   - Easting and northing values are rounded to the nearest meter.
    ///   - No input normalization is performed; the result reflects the raw input coordinate.
    ///
    /// - Parameter coordinate: The WGS 84 latitude and longitude coordinate.
    /// - Returns: A UTM coordinate if the coordinate is valid and within the supported range; otherwise, `nil`.
    init?(from coordinate: CLLocationCoordinate2D) {
        guard
            CLLocationCoordinate2DIsValid(coordinate),
            (-80.0...84.0).contains(coordinate.latitude)
        else {
            return nil
        }
        
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        
        // compute longitudinal zone
        var zone = min(Int(floor((longitude + 180.0) / 6.0) + 1.0), 60)
        
        // Southwest Norway
        if latitude >= 56.0, latitude < 64.0, longitude >= 3.0, longitude < 12.0 { zone = 32 }

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
        
        self.zone = zone
        let zoneMeridian = 6.0 * Double(zone) - 183.0
        let lambdaMeridian = degreesToRadians(zoneMeridian)
        
        // compute hemisphere
        self.hemisphere = latitude >= 0.0 ? .north : .south
        
        // formula values and cached results
        let phi = degreesToRadians(latitude)
        let lambda = degreesToRadians(longitude)
        
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
        
        // compute easting
        let computedEasting = Self.k0 * N * (
            A +
            (1.0 - T + C) * A3 / 6.0 +
            (5.0 - (18.0 * T) + T2 + (72.0 * C) - (58.0 * Self.ep2)) * A5 / 120.0
        ) + Self.falseEasting
        
        self.easting = Int(computedEasting.rounded())
        
        // compute northing
        let computedNorthing = Self.k0 * (
            M +
            N * tanPhi * (
                A2 / 2.0 +
                (5.0 - T + (9.0 * C) + (4.0 * C2)) * A4 / 24.0 +
                (61.0 - (58.0 * T) + T2 + (600.0 * C) - (330.0 * Self.ep2)) * A6 / 720.0
            )
        ) + (latitude < 0.0 ? Self.falseNorthing : 0.0)
        
        self.northing = Int(computedNorthing.rounded())
    }
    
    // MARK: - Methods
    
    /// Formats the coordinate as "<zone><hemisphere> <easting> <northing>" using the default meter precision.
    ///
    /// The output uses fixed-width integers, and values are rounded to the nearest meter (as stored).
    ///
    /// - Returns: The formatted UTM string.
    func formatted() -> String { UTMFormatStyle().format(self) }
    
    /// Formats the coordinate with the specified display precision, snapping easting and northing to the nearest multiple of that
    /// precision.
    ///
    /// - Parameter precision: The desired display precision (meters, 10 m, 100 m, or 1 km).
    /// - Returns: The formatted UTM string.
    func formatted(precision: UTMFormatStyle.Precision) -> String {
        UTMFormatStyle().precision(precision).format(self)
    }
}


extension UTMCoordinate {
    /// A formatting style for `UTMCoordinate` values that outputs the coordinate as
    /// "<zone><hemisphere> <easting> <northing>" strings with fixed-width integers.
    /// Supports configurable precision (meters, 10 m, 100 m, 1 km) via the `Precision` enumeration.
    struct UTMFormatStyle: FormatStyle {
        typealias FormatInput = UTMCoordinate
        typealias FormatOutput = String
        
        /// Controls display precision by snapping easting and northing to the nearest multiple, and adjusting minimum digit widths
        /// accordingly.
        enum Precision: Int, Codable {
            /// Precision at the meter level.
            case meters = 1
            /// Precision at 10 meters.
            case tenMeters = 10
            /// Precision at 100 meters.
            case hundredMeters = 100
            /// Precision at 1 kilometer.
            case kilometers = 1000
            
            var snapFactor: Int { rawValue }
            
            var minimumEastingDigits: Int {
                switch self {
                case .meters: 6
                case .tenMeters: 5
                case .hundredMeters: 4
                case .kilometers: 3
                }
            }
            
            var minimumNorthingDigits: Int {
                switch self {
                case .meters: 7
                case .tenMeters: 6
                case .hundredMeters: 5
                case .kilometers: 4
                }
            }
        }
        
        // MARK: - Properties
        
        /// The current precision used when formatting (default is `.meters`).
        var precision: Precision = .meters
        
        // MARK: - Methods
        
        /// Formats a `UTMCoordinate` into the string format "<zone><hemisphere> <easting> <northing>".
        /// Easting and northing values are snapped to the selected precision before formatting.
        func format(_ value: FormatInput) -> FormatOutput {
            let factor = precision.snapFactor
            
            let snappedEasting = Int((Double(value.easting) / Double(factor)).rounded()) * factor
            let snappedNorthing = Int((Double(value.northing) / Double(factor)).rounded()) * factor
            
            let eastingFormatter = Self.makeFormatter(minDigits: precision.minimumEastingDigits)
            let northingFormatter = Self.makeFormatter(minDigits: precision.minimumNorthingDigits)
            
            let easting = eastingFormatter.string(from: snappedEasting as NSNumber) ?? String(snappedEasting)
            let northing = northingFormatter.string(from: snappedNorthing as NSNumber) ?? String(snappedNorthing)
            
            return "\(value.zone)\(value.hemisphere) \(easting) \(northing)"
        }
        
        /// Returns a copy of this style configured with the given precision.
        func precision(_ p: Precision) -> Self {
            var copy = self
            copy.precision = p
            return copy
        }
        
        // MARK: - Helper Methods
        
        /// Creates a POSIX locale number formatter with no grouping separator and the specified minimum integer digits.
        private static func makeFormatter(minDigits: Int) -> NumberFormatter {
            let f = NumberFormatter()
            f.minimumIntegerDigits = minDigits
            f.usesGroupingSeparator = false
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }
    }
}

