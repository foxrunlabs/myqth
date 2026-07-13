import CoreLocation

/// Convenience APIs for converting between geographic coordinates and Maidenhead grid locators.
///
/// Supports generation of 6-character Maidenhead locators and conversion from 4- and 6-character locators back to geographic
/// coordinates.
extension CLLocationCoordinate2D {
    /// ASCII value for the uppercase letter A.
    private static let upperA = Int(Character("A").asciiValue!)
    
    /// ASCII value for the lowercase letter A.
    private static let lowerA = Int(Character("a").asciiValue!)
    
    /// ASCII value for the digit 0.
    private static let zero = Int(Character("0").asciiValue!)
    
    // MARK: - Computed Properties
    
    /// The 6-character Maidenhead grid locator corresponding to this coordinate.
    ///
    /// The Maidenhead Locator System divides the Earth into progressively smaller regions called fields, squares, and subsquares.
    /// This property returns the locator for the coordinate centered within its containing subsquare.
    ///
    /// Examples:
    /// - `FN41pr`
    /// - `EM13ab`
    ///
    /// - Returns: A 6-character Maidenhead locator, or `nil` if the coordinate is invalid.
    var maidenheadLocator: String? {
        guard CLLocationCoordinate2DIsValid(self) else { return nil }
        
        // Normalize longitude and latitude to the positive ranges used by the Maidenhead grid
        // system.
        let adjLong = min(longitude, 179.999999) + 180.0
        let adjLat = min(latitude, 89.999999) + 90.0
        
        // Field (20° longitude x 10° latitude)
        let fieldLon = Int(adjLong / 20.0)
        let fieldLat = Int(adjLat / 10.0)
        
        // Square (2° longitude x 1° latitude)
        let squareLon = Int(adjLong / 2.0) % 10
        let squareLat = Int(adjLat) % 10
        
        // Subsquare (5' longitude x 2.5' latitude)
        let subsquareLon = Int((adjLong / 2.0).truncatingRemainder(dividingBy: 1) * 24)
        let subsquareLat = Int(adjLat.truncatingRemainder(dividingBy: 1) * 24)
        
        return String([
            Self.upperLetter(fieldLon),
            Self.upperLetter(fieldLat),
            Self.digit(squareLon),
            Self.digit(squareLat),
            Self.lowerLetter(subsquareLon),
            Self.lowerLetter(subsquareLat),
        ])
    }
    
    // MARK: - Initializer
    
    /// Creates a coordinate from a Maidenhead grid locator.
    ///
    /// The initializer accepts either a 4-character locator representing a square or a 6-character locator representing a subsquare.
    ///
    /// Examples:
    /// - `FN41`
    /// - `FN41pr`
    ///
    /// The resulting coordinate is positioned at the geographic center of the represented square or subsquare.
    ///
    /// - Parameter maidenhead: A 4- or 6-character Maidenhead locator.
    /// - Returns: A coordinate corresponding to the center of the locator, or `nil` if the locator is invalid.
    init?(maidenhead: String) {
        // Trim and normalize
        let locator = maidenhead.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Validate the input for 4- or 6-character locators
        let pattern = /[A-R]{2}[0-9]{2}([A-X]{2})?/
        guard let _ = try? pattern.wholeMatch(in: locator) else { return nil }
        
        let chars = Array(locator.utf8)
        let upperA = Character("A").asciiValue!
        let zero = Character("0").asciiValue!
        
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
            longitude += Double(chars[4] - upperA) * (2.0 / 24.0)
            latitude += Double(chars[5] - upperA) * (1.0 / 24.0)
            
            // Center in subsquare
            longitude += (2.0 / 24.0) / 2.0
            latitude += (1.0 / 24.0) / 2.0
        }
        
        self.init(latitude: latitude, longitude: longitude)
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
