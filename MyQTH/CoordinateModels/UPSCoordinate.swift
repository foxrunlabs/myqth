import CoreLocation
import Foundation

struct UPSCoordinate {
    typealias Meters = Int
    
    enum Zone: Character, CustomStringConvertible {
        case a = "A"
        case b = "B"
        case y = "Y"
        case z = "Z"
        
        var description: String { String(rawValue) }
    }
    
    let zone: Zone
    let easting: Meters
    let northing: Meters
    
    /// Semi‑major axis of the WGS 84 ellipsoid, in meters.
    private static let a = 6_378_137.0
    
    /// Flattening of the WGS 84 ellipsoid.
    private static let f = 1.0 / 298.257223563
    
    /// First eccentricity of the WGS 84 ellipsoid.
    private static let e = sqrt(f * (2 - f))
    
    /// Polar stereographic constant derived from the WGS 84 eccentricity.
    private static let c = sqrt(pow(1 + e, 1 + e) * pow(1 - e, 1 - e))
    
    /// Scale factor at natural origin used by UPS.
    private static let k0 = 0.994
    
    /// False easting applied by UPS, in meters.
    private static let falseEasting = 2_000_000.0
    
    /// False northing applied by UPS, in meters.
    private static let falseNorthing = 2_000_000.0
    
    // MARK: - Initializers
    
    /// Initializes to the UPS coordinate corresponding to 90°N, 0°E
    init() {
        self.zone = .z
        self.easting = 2_000_000
        self.northing = 2_000_000
    }
    
    /// Creates a UPS coordinate from its components.
    ///
    /// - Parameters:
    ///   - zone: UPS zone letter.
    ///   - easting: The easting value in meters within the zone.
    ///   - northing: The northing value in meters within the zone.
    init(zone: Zone, easting: Meters, northing: Meters) {
        self.zone = zone
        self.easting = easting
        self.northing = northing
    }
    
    /// Creates a UPS coordinate from a WGS 84 latitude/longitude.
    ///
    /// - Note:
    ///   - The supported latitude range is above 84° N and below 80° S.
    ///   - Easting and northing values are truncated to the nearest meter.
    ///   - No input normalization is performed; the result reflects the raw input coordinate.
    ///
    /// - Parameter coordinate: The WGS 84 latitude and longitude coordinate.
    /// - Throws: `UTMCoordinate.Error.invalidCoordinate` if the coordinate is invalid.
    ///           `UTMCoordinate.Error.invalidLatitude` if the latitude is outside the supported range.
    init(from coordinate: CLLocationCoordinate2D) throws {
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            throw Error.invalidCoordinate(coordinate)
        }
        
        guard coordinate.latitude > 84 || coordinate.latitude < -80 else {
            throw Error.invalidLatitude(coordinate.latitude)
        }
        
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        
        // compute zone
        self.zone = if latitude >= 0.0 {
            (longitude >= 0.0) ? .z : .y
        } else {
            (longitude >= 0.0) ? .b : .a
        }
        
        // formula values and cached results
        let phi = degreesToRadians(latitude)
        let lambda = degreesToRadians(longitude)
        
        let absPhi = abs(phi)
        let sinAbsPhi = sin(absPhi)
        
        let t = tan(
            (CLLocationDegrees.pi / 4.0) - (absPhi / 2.0)
        ) * pow(
            (1 + Self.e * sinAbsPhi) / (1 - Self.e * sinAbsPhi),
            Self.e / 2.0
        )
        
        let rho = 2.0 * Self.a * Self.k0 * t / Self.c
        
        self.easting = Meters((Self.falseEasting + rho * sin(lambda)).rounded())
        
        let hemisphereSign = (latitude >= 0.0) ? -1.0 : 1.0
        self.northing = Meters((Self.falseNorthing + hemisphereSign * rho * cos(lambda)).rounded())
    }
    
    // MARK: - Methods
    
    /// Returns a formatted string representation of the UPS coordinate with default precision.
    ///
    /// - Returns: A string formatted UPS coordinate.
    func formatted() -> String { FormatStyle().format(self) }
    
    /// Returns a formatted string representation of the UPS coordinate with the specified precision.
    ///
    /// - Parameter precision: The desired precision level for the coordinate.
    /// - Returns: A string formatted UPS coordinate with the requested precision.
    func formatted(precision: FormatStyle.Precision) -> String {
        FormatStyle().precision(precision).format(self)
    }
}


extension UPSCoordinate {
    /// Defines domain-specific errors that can arise during UPS coordinate creation and validation.
    enum Error: LocalizedError {
        /// The provided coordinate failed validation.
        case invalidCoordinate(CLLocationCoordinate2D)
        /// The latitude is outside the supported UPS range.
        case invalidLatitude(CLLocationDegrees)
        
        /// Provides a short, user-presentable description of the error.
        var errorDescription: String? {
            switch self {
            case .invalidCoordinate:
                "Invalid coordinate"
            case .invalidLatitude:
                "Invalid latitude"
            }
        }
        
        /// Provides more detailed context about the error, including the offending value and range when applicable.
        var failureReason: String? {
            switch self {
            case .invalidCoordinate(let coordinate):
                "\(coordinate) is invalid."
            case .invalidLatitude(let latitude):
                "\(latitude) is invalid. Latitude must be above 84 or below -80 degrees."
            }
        }
    }
}


extension UPSCoordinate {
    /// A `FormatStyle` implementation for `UPSCoordinate` that provides formatting functionality
    /// for converting a UPS coordinate into a string representation with configurable precision.
    struct FormatStyle: Foundation.FormatStyle {
        typealias FormatInput = UPSCoordinate
        typealias FormatOutput = String
        
        /// Represents the precision levels available for formatting a UPS coordinate.
        enum Precision: Int, Codable {
            /// Precision at 1 meter.
            case meter = 1
            /// Precision at 10 meters.
            case tenMeter = 10
            /// Precision at 100 meters.
            case hundredMeter = 100
            /// Precision at 1 kilometer.
            case kilometer = 1000
            
            /// The snap factor to use when reducing precision; corresponds to the raw integer value.
            var snapFactor: Int { rawValue }
            
            /// The minimum number of integer digits to display for this precision.
            var minimumDigits: Int {
                switch self {
                case .meter: 7
                case .tenMeter: 6
                case .hundredMeter: 5
                case .kilometer: 4
                }
            }
        }
        
        // MARK: - Properties
        
        /// The precision level to use for formatting.
        private var precision: Precision = .meter
        
        // MARK: - Methods
        
        /// Formats the given `UPSCoordinate` into a string using the configured precision.
        ///
        /// - Parameter value: The `UPSCoordinate` to format.
        /// - Returns: A string representing the formatted UPS coordinate.
        func format(_ value: FormatInput) -> FormatOutput {
            let snappedEasting = value.easting / precision.snapFactor
            let snappedNorthing = value.northing / precision.snapFactor
            
            let formatter = NumberFormatter()
            formatter.minimumIntegerDigits = precision.minimumDigits
            formatter.usesGroupingSeparator = false
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            let easting = formatter.string(from: snappedEasting as NSNumber) ?? String(snappedEasting)
            let northing = formatter.string(from: snappedNorthing as NSNumber) ?? String(snappedNorthing)
            
            return "\(value.zone) \(easting) \(northing)"
        }
        
        /// Returns a copy of this `FormatStyle` configured to use the specified precision.
        ///
        /// - Parameter p: The desired precision level.
        /// - Returns: A new `FormatStyle` instance set to the specified precision.
        func precision(_ p: Precision) -> Self {
            var copy = self
            copy.precision = p
            return copy
        }
    }
}
