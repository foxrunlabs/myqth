import CoreLocation
import Foundation

/// Represents a Military Grid Reference System (MGRS) coordinate, used for specifying locations on the Earth's surface
/// using a combination of grid zones, latitude bands, grid squares, and metric easting/northing values.
nonisolated struct MGRSCoordinate: Equatable, Sendable {
    /// MGRS grid-zone designators
    enum GridZone: CustomStringConvertible, Equatable, Sendable {
        /// UTM zone number (1-60) and latitude band ('C' through 'X' excluding 'I' and 'O')
        case utm(zone: Int, band: Character)
        
        /// UPS zone ('A', 'B', 'Y', or 'Z')
        case ups(zone: UPSCoordinate.Zone)
        
        var description: String {
            switch self {
            case .utm(let zone, let band):
                "\(zone)\(band)"

            case .ups(let zone):
                "\(zone)"
            }
        }
    }
    
    /// Defines the zone-specific letters and origins for UPS-based MGRS 100 km grid squares.
    private struct UPSGrid {
        /// The grid square column letters, ordered by increasing easting.
        let columnLetters: [Character]

        /// The grid square row letters, ordered by increasing northing.
        let rowLetters: [Character]

        /// The UPS easting, in meters, at the start of the first column.
        let columnOrigin: Int

        /// The UPS northing, in meters, at the start of the first row.
        let rowOrigin: Int

        // MARK: - Initializers
        
        /// Creates the 100 km grid parameters for the specified UPS zone.
        ///
        /// - Parameter zone: The UPS grid zone whose column letters, row letters, and coordinate origins to use.
        init(zone: UPSCoordinate.Zone) {
            switch zone {
            case .a:
                columnLetters = Array("JKLPQRSTUXYZ")
                rowLetters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")
                columnOrigin = 800_000
                rowOrigin = 800_000

            case .b:
                columnLetters = Array("ABCFGHJKLPQR")
                rowLetters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")
                columnOrigin = 2_000_000
                rowOrigin = 800_000

            case .y:
                columnLetters = Array("RSTUXYZ")
                rowLetters = Array("ABCDEFGHJKLMNP")
                columnOrigin = 1_300_000
                rowOrigin = 1_300_000

            case .z:
                columnLetters = Array("ABCFGHJ")
                rowLetters = Array("ABCDEFGHJKLMNP")
                columnOrigin = 2_000_000
                rowOrigin = 1_300_000
            }
        }
    }
    
    /// The easting and northing values are measured in meters within a given grid square.
    typealias Meters = Int
    
    // MARK: - Properties
    
    /// The grid-zone of the coordinate.
    let gridZone: GridZone
    
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
        self.gridZone = .utm(zone: 31, band: "N")
        self.gridSquare = "AA"
        self.easting = 66021
        self.northing = 0
    }
    
    /// Creates an `MGRSCoordinate` from already-validated components without checking them.
    /// Grid-zone and square letters must be valid together; offsets must be in `0..<100_000`.
    ///
    /// - Parameters:
    ///   - gridZone: MGRS grid-zone.
    ///   - gridSquare: The 100km grid square identifier.
    ///   - easting: The easting value in meters within the grid square.
    ///   - northing: The northing value in meters within the grid square.
    init(gridZone: GridZone, gridSquare: String, easting: Meters, northing: Meters) {
        self.gridZone = gridZone
        self.gridSquare = gridSquare
        self.easting = easting
        self.northing = northing
    }
    
    /// Initializes an `MGRSCoordinate` from a valid WGS 84 geographic coordinate.
    /// Uses UTM for −80° ≤ latitude < 84° and UPS elsewhere, including both poles.
    /// Projected coordinates are rounded down to whole meters before selecting the grid square.
    ///
    /// - Parameter coordinate: A valid `CLLocationCoordinate2D` representing latitude and longitude.
    /// - Throws: `MGRSCoordinate.Error.invalidCoordinate` if the coordinate is invalid.
    ///           `MGRSCoordinate.Error.invalidProjectedCoordinate` if the projection is invalid.
    init(from coordinate: CLLocationCoordinate2D) throws {
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            throw Error.invalidCoordinate(coordinate)
        }
        
        if (-80.0..<84.0).contains(coordinate.latitude) {
            // UTM-based MGRS
            let utm = try UTMCoordinate(from: coordinate)
            
            // grid-zone designator
            let index = max(0, min(Int(floor(coordinate.latitude / 8.0)) + 10, 19))
            let band = Self.latitudeBands[index]
            self.gridZone = .utm(zone: utm.zone, band: band)
            
            // 100 km grid square
            guard (1...60).contains(utm.zone),
                  (100_000..<900_000).contains(utm.easting),
                  (0..<10_000_000).contains(utm.northing)
            else {
                throw Error.invalidProjectedCoordinate
            }
            
            let setNumber = (utm.zone - 1) % 3
            let columnLetters = Self.columnLettersSets[setNumber]
            let columnIndex = utm.easting / 100_000 - 1
            let columnLetter = columnLetters[columnIndex]
            
            let row = (utm.northing / 100_000) % 20
            let rowIndex = utm.zone.isMultiple(of: 2) ? (row + 5) % 20 : row
            let rowLetter = Self.rowLetters[rowIndex]
            
            self.gridSquare = "\(columnLetter)\(rowLetter)"
            
            // easting and northing
            self.easting = utm.easting % 100_000
            self.northing = utm.northing % 100_000
        } else {
            // UPS-based MGRS
            let ups = try UPSCoordinate(from: coordinate)
            
            // grid-zone designator
            self.gridZone = .ups(zone: ups.zone)

            // 100 km grid square
            let grid = UPSGrid(zone: ups.zone)

            let columnIndex = (ups.easting - grid.columnOrigin) / 100_000
            let rowIndex = (ups.northing - grid.rowOrigin) / 100_000
            
            guard ups.easting >= grid.columnOrigin,
                  ups.northing >= grid.rowOrigin,
                  grid.columnLetters.indices.contains(columnIndex),
                  grid.rowLetters.indices.contains(rowIndex)
            else {
                throw Error.invalidProjectedCoordinate
            }

            let columnLetter = grid.columnLetters[columnIndex]
            let rowLetter = grid.rowLetters[rowIndex]

            self.gridSquare = "\(columnLetter)\(rowLetter)"

            // Position within 100 km grid square
            self.easting = ups.easting % 100_000
            self.northing = ups.northing % 100_000
        }
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
        
        /// Indicates the projected coordinate is invalid.
        case invalidProjectedCoordinate
        
        /// Provides a localized description of the error.
        var errorDescription: String? {
            switch self {
            case .invalidCoordinate:
                "Invalid coordinate"
            case .invalidProjectedCoordinate:
                "Invalid projected coordinate"
            }
        }
        
        /// Provides a detailed failure reason description for the error.
        var failureReason: String? {
            switch self {
            case .invalidCoordinate(let coordinate):
                "\(coordinate) is invalid."
            case .invalidProjectedCoordinate:
                "The projected coordinate is outside the supported MGRS grid."
            }
        }
    }
}


extension MGRSCoordinate {
    /// A `FormatStyle` implementation for `MGRSCoordinate` that provides formatting functionality
    /// for converting an MGRS coordinate into a string representation with configurable precision.
    nonisolated struct FormatStyle: Foundation.FormatStyle {
        typealias FormatInput = MGRSCoordinate
        typealias FormatOutput = String
        
        /// Represents the precision levels available for formatting an MGRS coordinate.
        enum Precision: Int, Codable {
            /// Precision at 1 meter.
            case meter = 1
            /// Precision at 10 meters.
            case tenMeter = 10
            /// Precision at 100 meters.
            case hundredMeter = 100
            /// Precision at 1 kilometer.
            case kilometer = 1000
            /// Precision at 10 kilometers.
            case tenKilometer = 10_000
            
            /// The snap factor to use when reducing precision; corresponds to the raw integer value.
            var snapFactor: Int { rawValue }
            
            /// The minimum number of integer digits to display for this precision.
            var minimumDigits: Int {
                switch self {
                case .meter: 5
                case .tenMeter: 4
                case .hundredMeter: 3
                case .kilometer: 2
                case .tenKilometer: 1
                }
            }
        }
        
        // MARK: - Properties
        
        /// The precision level to use for formatting.
        private var precision: Precision = .meter
        
        // MARK: - Methods
        
        /// Formats the given `MGRSCoordinate` into a string using the configured precision.
        ///
        /// - Parameter value: The `MGRSCoordinate` to format.
        /// - Returns: A string representing the formatted MGRS coordinate.
        func format(_ value: FormatInput) -> FormatOutput {
            let snappedEasting = value.easting / precision.snapFactor
            let snappedNorthing = value.northing / precision.snapFactor
            
            let formatter = NumberFormatter()
            formatter.minimumIntegerDigits = precision.minimumDigits
            formatter.usesGroupingSeparator = false
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            let easting = formatter.string(from: snappedEasting as NSNumber) ?? String(snappedEasting)
            let northing = formatter.string(from: snappedNorthing as NSNumber) ?? String(snappedNorthing)
            
            return "\(value.gridZone) \(value.gridSquare) \(easting) \(northing)"
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

