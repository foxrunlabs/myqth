import CoreLocation

/// Represents a Maidenhead grid locator with canonical mixed-case representation
/// (e.g., "FN31pr"). Supports construction from strings or geographic coordinates.
struct MaidenheadLocator: CustomStringConvertible, Equatable, Hashable {
    var locator: String
    
    /// ASCII value for the uppercase letter A.
    private static let upperA = Int(Character("A").asciiValue!)
    
    /// ASCII value for the lowercase letter A.
    private static let lowerA = Int(Character("a").asciiValue!)
    
    /// ASCII value for the digit 0.
    private static let zero = Int(Character("0").asciiValue!)
    
    // MARK: - Computed Properties
    
    var field: String { String(locator.prefix(2)) }
    var square: String { String(locator.suffix(4).prefix(2)) }
    var subsquare: String { String(locator.suffix(2)) }
    
    var description: String { locator }
    
    /// Converts the locator to the geographic coordinate at the center of the represented cell.
    ///
    /// - Note:
    ///   - 4-character locators return the center of the 2°×1° square.
    ///   - 6-character locators return the center of the 5′×2.5′ subsquare.
    ///   - Assumes the `locator` is a canonical 4- or 6-character string
    ///     (uppercase field/square, lowercase subsquare).
    ///
    /// - Returns: A `CLLocationCoordinate2D` in WGS 84.
    var coordinate: CLLocationCoordinate2D {
        assert(locator.count == 4 || locator.count == 6)
        
        let chars = Array(locator.utf8)
        let upperA = Character("A").asciiValue!
        let zero = Character("0").asciiValue!
        let lowerA = Character("a").asciiValue!
        
        // Shift to [-180...180] and [-90...90]
        var longitude = -180.0
        var latitude = -90.0
        
        // Field
        longitude += Double(chars[0] - upperA) * 20.0
        latitude += Double(chars[1] - upperA) * 10.0
        
        // Square
        longitude += Double(chars[2] - zero) * 2.0
        latitude += Double(chars[3] - zero)
        
        if chars.count == 4 {
            // Center in square
            longitude += 1.0
            latitude += 0.5
        } else {
            // Subsquare
            longitude += Double(chars[4] - lowerA) * (2.0 / 24.0)
            latitude += Double(chars[5] - lowerA) * (1.0 / 24.0)
            
            // Center in subsquare
            longitude += (2.0 / 24.0) / 2.0
            latitude += (1.0 / 24.0) / 2.0
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - Initializers
    
    /// Initializes to the canonical locator for (0°N, 0°E).
    init() { locator = "JJ00aa" }
    
    /// Trims and normalizes input; accepts 4- or 6-character locators. Stores 6-character locators in canonical mixed-case
    /// (lowercased subsquare).
    ///
    /// - Parameter locator: A Maidenhead locator string.
    /// - Returns: An instance if the input is valid; otherwise, `nil`.
    init?(locator: String) {
        // Trim and normalize
        let trimmedLocator = locator.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Validate the input for 4- or 6-character locators
        let pattern = /[A-R]{2}[0-9]{2}([A-X]{2})?/
        guard let _ = try? pattern.wholeMatch(in: trimmedLocator) else { return nil }
        
        // Format locator appropriately
        if trimmedLocator.count == 4 {
            self.locator = trimmedLocator
        } else {
            let prefix = trimmedLocator.dropLast(4)
            let suffix = trimmedLocator.suffix(2).lowercased()
            self.locator = prefix + suffix
        }
    }
    
    /// Creates a canonical 6-character locator from a WGS 84 coordinate.
    ///
    /// Normalizes latitude and longitudet to positive ranges and handles boundary cases. Maps to field/square/subsquare and returns
    /// the mixed-case locator.
    ///
    /// - Parameter coordinate: A WGS 84 coordinate.
    /// - Returns: An instance if the coordinate is valid; otherwise, `nil`.
    init?(from coordinate: CLLocationCoordinate2D) {
        guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
        
        // Normalize longitude and latitude to the positive ranges used by the Maidenhead grid
        // system.
        let adjLong = min(coordinate.longitude, 179.999999) + 180.0
        let adjLat = min(coordinate.latitude, 89.999999) + 90.0
        
        // Field (20° longitude x 10° latitude)
        let fieldLon = Int(adjLong / 20.0)
        let fieldLat = Int(adjLat / 10.0)
        
        // Square (2° longitude x 1° latitude)
        let squareLon = Int(adjLong / 2.0) % 10
        let squareLat = Int(adjLat) % 10
        
        // Subsquare (5' longitude x 2.5' latitude)
        let subsquareLon = Int((adjLong / 2.0).truncatingRemainder(dividingBy: 1) * 24)
        let subsquareLat = Int(adjLat.truncatingRemainder(dividingBy: 1) * 24)
        
        self.locator = String([
            Self.upperLetter(fieldLon),
            Self.upperLetter(fieldLat),
            Self.digit(squareLon),
            Self.digit(squareLat),
            Self.lowerLetter(subsquareLon),
            Self.lowerLetter(subsquareLat),
        ])
    }
    
    // MARK: - Helper Methods
    
    /// Converts a field index (0–17) to an uppercase Maidenhead field character.
    ///
    /// Examples:
    /// - `0` → `A`
    /// - `17` → `R`
    private static func upperLetter(_ value: Int) -> Character {
        assert((0..<18).contains(value))
        return Character(UnicodeScalar(value + upperA)!)
    }
    
    /// Converts a square index (0–9) to a Maidenhead square digit.
    ///
    /// Examples:
    /// - `0` → `0`
    /// - `9` → `9`
    private static func digit(_ value: Int) -> Character {
        assert((0..<10).contains(value))
        return Character(UnicodeScalar(value + zero)!)
    }
    
    /// Converts a subsquare index (0–23) to a lowercase Maidenhead subsquare character.
    ///
    /// Examples:
    /// - `0` → `a`
    /// - `23` → `x`
    private static func lowerLetter(_ value: Int) -> Character {
        assert((0..<24).contains(value))
        return Character(UnicodeScalar(value + lowerA)!)
    }
}
