import CoreLocation
import Foundation

/// Represents a Military Grid Reference System (MGRS) coordinate, used for specifying locations on the Earth's surface
/// using a combination of grid zones, latitude bands, grid squares, and metric easting/northing values.
struct MGRSCoordinate {
    /// The zone number of the MGRS coordinate, representing one of the 60 longitudinal UTM zones.
    typealias Zone = Int
    
    /// The easting and northing values are measured in meters within a given grid square.
    typealias Meters = Int
    
    // MARK: - Properties
    
    /// The UTM zone number (1-60) of the coordinate.
    let zone: Zone
    
    /// The latitude band character ('C' through 'X' excluding 'I' and 'O') indicating the latitude range for the coordinate.
    let latitudeBand: Character
    
    /// The 100km grid square identifier consisting of two letters.
    let gridSquare: String
    
    /// The easting value within the 100km grid square, measured in meters.
    let easting: Meters
    
    /// The northing value within the 100km grid square, measured in meters.
    let northing: Meters
    
    /// Array of valid latitude band characters used in MGRS.
    private static let latitudeBands = Array("CDEFGHJKLMNPQRSTUVWX")
    
    /// Sets of letters used to identify columns in the 100km grid square, cycling by zone.
    private static let columnLettersSets = [
        Array("ABCDEFGH"),
        Array("JKLMNPQR"),
        Array("STUVWXYZ")
    ]
    
    /// Letters used to identify rows in the 100km grid square.
    private static let rowLetters = Array("ABCDEFGHJKLMNPQRSTUV")
    
    // MARK: - Initializers
    
    /// Creates an `MGRSCoordinate` with default values equating to 0° N, 0° E:
    /// zone 31, latitude band 'N', grid square "AA", easting 66021 meters, and northing 0 meters.
    init() {
        self.zone = 31
        self.latitudeBand = "N"
        self.gridSquare = "AA"
        self.easting = 66021
        self.northing = 0
    }
    
    /// Creates an `MGRSCoordinate` with the specified values.
    ///
    /// - Parameters:
    ///   - zone: The UTM zone number.
    ///   - latitudeBand: The MGRS latitude band character.
    ///   - gridSquare: The 100km grid square identifier.
    ///   - easting: The easting value in meters within the grid square.
    ///   - northing: The northing value in meters within the grid square.
    init(zone: Zone, latitudeBand: Character, gridSquare: String, easting: Meters, northing: Meters) {
        self.zone = zone
        self.latitudeBand = latitudeBand
        self.gridSquare = gridSquare
        self.easting = easting
        self.northing = northing
    }
    
    /// Initializes an `MGRSCoordinate` from a valid geographic coordinate.
    ///
    /// - Parameter coordinate: A valid `CLLocationCoordinate2D` representing latitude and longitude.
    /// - Throws: `MGRSCoordinate.Error.invalidCoordinate` if the coordinate is invalid.
    ///           `MGRSCoordinate.Error.invalidLatitude` if the latitude is outside the valid MGRS range (-80 to 84 degrees).
    init(from coordinate: CLLocationCoordinate2D) throws {
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            throw Error.invalidCoordinate(coordinate)
        }
        
        guard (-80.0...84.0).contains(coordinate.latitude) else {
            throw Error.invalidLatitude(coordinate.latitude)
        }
        
        // zone
        let utm = try UTMCoordinate(from: coordinate)
        self.zone = utm.zone
        
        // latitude band
        let index = min(Int((coordinate.latitude + 80.0) / 8.0), 19)
        self.latitudeBand = Self.latitudeBands[index]
        
        // 100km grid square
        let setNumber = (utm.zone - 1) % 3
        let columnLetters = Self.columnLettersSets[setNumber]
        let columnIndex = utm.easting / 100_000 - 1
        let columnLetter = columnLetters[columnIndex]
        
        let row = (utm.northing / 100_000) % 20
        let rowIndex = zone.isMultiple(of: 2) ? (row + 5) % 20 : row
        let rowLetter = Self.rowLetters[rowIndex]
        
        self.gridSquare = "\(columnLetter)\(rowLetter)"
        
        // easting and northing
        self.easting = utm.easting % 100_000
        self.northing = utm.northing % 100_000
    }
    
    // MARK: - Methods
    
    /// Returns a formatted string representation of the MGRS coordinate with default precision.
    ///
    /// - Returns: A string formatted MGRS coordinate.
    func formatted() -> String { FormatStyle().format(self) }
    
    /// Returns a formatted string representation of the MGRS coordinate with the specified precision.
    ///
    /// - Parameter precision: The desired precision level for the coordinate.
    /// - Returns: A string formatted MGRS coordinate with the requested precision.
    func formatted(precision: FormatStyle.Precision) -> String {
        FormatStyle().precision(precision).format(self)
    }
}


extension MGRSCoordinate {
    /// Defines errors that can occur when creating or using an `MGRSCoordinate`.
    enum Error: LocalizedError {
        /// Indicates the provided geographic coordinate is invalid.
        case invalidCoordinate(CLLocationCoordinate2D)
        
        /// Indicates the latitude value is outside the valid range for MGRS coordinates (-80 to 84 degrees).
        case invalidLatitude(CLLocationDegrees)
        
        /// Provides a localized description of the error.
        var errorDescription: String? {
            switch self {
            case .invalidCoordinate:
                return "Invalid coordinate"
            case .invalidLatitude:
                return "Invalid latitude"
            }
        }
        
        /// Provides a detailed failure reason description for the error.
        var failureReason: String? {
            switch self {
            case .invalidCoordinate(let coordinate):
                return "\(coordinate) is invalid."
            case .invalidLatitude(let latitude):
                return "\(latitude) is invalid. Latitude must be between -80 and 84 degrees."
            }
        }
    }
}


extension MGRSCoordinate {
    /// A `FormatStyle` implementation for `MGRSCoordinate` that provides formatting functionality
    /// for converting an MGRS coordinate into a string representation with configurable precision.
    struct FormatStyle: Foundation.FormatStyle {
        typealias FormatInput = MGRSCoordinate
        typealias FormatOutput = String
        
        /// Represents the precision levels available for formatting an MGRS coordinate.
        enum Precision: Int, Codable {
            /// Precision at 1 meter.
            case meters = 1
            /// Precision at 10 meters.
            case tenMeters = 10
            /// Precision at 100 meters.
            case hundredMeters = 100
            /// Precision at 1 kilometer.
            case kilometers = 1000
            /// Precision at 10 kilometers.
            case tenKilometers = 10_000
            
            /// The snap factor to use when reducing precision; corresponds to the raw integer value.
            var snapFactor: Int { rawValue }
            
            /// The minimum number of integer digits to display for this precision.
            var minimumDigits: Int {
                switch self {
                case .meters: 5
                case .tenMeters: 4
                case .hundredMeters: 3
                case .kilometers: 2
                case .tenKilometers: 1
                }
            }
        }
        
        // MARK: - Properties
        
        /// The precision level to use for formatting.
        private var precision: Precision = .meters
        
        // MARK: - Methods
        
        /// Formats the given `MGRSCoordinate` into a string using the configured precision.
        ///
        /// - Parameter value: The `MGRSCoordinate` to format.
        /// - Returns: A string representing the formatted MGRS coordinate.
        func format(_ value: FormatInput) -> FormatOutput {
            let snappedEasting = value.easting / precision.snapFactor
            let snappedNorthing = value.northing / precision.snapFactor
            
            let formatter = Self.makeFormatter(minDigits: precision.minimumDigits)
            
            let easting = formatter.string(from: snappedEasting as NSNumber) ?? String(snappedEasting)
            let northing = formatter.string(from: snappedNorthing as NSNumber) ?? String(snappedNorthing)
            
            return "\(value.zone)\(value.latitudeBand) \(value.gridSquare) \(easting) \(northing)"
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
        
        // MARK: - Helper Methods
        
        /// Creates and returns a `NumberFormatter` configured for formatting MGRS coordinate components.
        ///
        /// - Parameter minDigits: The minimum number of integer digits the formatter should use.
        /// - Returns: A configured `NumberFormatter` instance.
        private static func makeFormatter(minDigits: Int) -> NumberFormatter {
            let f = NumberFormatter()
            f.minimumIntegerDigits = minDigits
            f.usesGroupingSeparator = false
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }
    }
}

