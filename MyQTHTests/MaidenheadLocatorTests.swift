import CoreLocation
import Testing

@testable import MyQTH

@Suite("Maidenhead Locator Tests") struct MaidenheadLocatorTests {
    // MARK: - Locator Initializer Tests
    
    @Suite("Locator Initializer Tests") struct LocatorInitializerTests {
        @Test("Valid Locator Normalization", arguments: [
            (input: "FN31pr", expected: "FN31pr"),
            (input: "fn31pr", expected: "FN31pr"),
            (input: "FN31PR", expected: "FN31pr"),
            (input: "fN31pR", expected: "FN31pr"),
            (input: " FN31pr ", expected: "FN31pr"),
            (input: "\nFN31PR\n", expected: "FN31pr"),
            (input: "FN31", expected: "FN31"),
            (input: "fn31", expected: "FN31"),
        ])
        func validLocatorNormalization(input: String, expected: String) throws {
            let locator = try MaidenheadLocator(locator: input)
            
            #expect(locator.locator == expected)
        }
        
        @Test("Invalid Locators", arguments: [
            "",
            "FN",
            "FN3",
            "FN311",
            "FN31p",
            "FN31prx",
            "SN31pr",
            "FN31yr",
            "FN3Apr",
            "1N31pr",
            "FN-1pr",
        ])
        func invalidLocators(input: String) throws {
            let error = #expect(throws: MaidenheadLocator.Error.self) {
                try MaidenheadLocator(locator: input)
            }
            
            guard case .invalidLocator(_) = error else {
                Issue.record("Expected invalidLocator error")
                return
            }
        }
    }
    
    // MARK: - Component Tests
    
    @Suite("Component Tests") struct componentTests {
        @Test("Six Characters") func sixCharacters() throws {
            let locator = try MaidenheadLocator(locator: "FN31pr")
            
            #expect(locator.field == "FN")
            #expect(locator.square == "31")
            #expect(locator.subsquare == "pr")
        }
        
        @Test("Four Characters") func fourCharacters() throws {
            let locator = try MaidenheadLocator(locator: "FN31")
            
            #expect(locator.field == "FN")
            #expect(locator.square == "31")
            #expect(locator.subsquare.isEmpty)
        }
    }
    
    // MARK: - Coordinate Conversion Tests
    
    @Suite("Coordinate Conversion Tests") struct CoordinateConversionTests {
        @Test("Known Coordinates", arguments: [
            (latitude: 0.0, longitude: 0.0, expected: "JJ00aa"),
            (latitude: 41.714775, longitude: -72.727260, expected: "FN31pr")
        ])
        func knownCoordinates(
            latitude: CLLocationDegrees,
            longitude: CLLocationDegrees,
            expected: String
        ) throws {
            let locator = try MaidenheadLocator(
                from: .init(latitude: latitude, longitude: longitude)
            )
            
            #expect(locator.formatted() == expected)
        }
        
        @Test("Invalid Coordinate", arguments: [
            (latitude: 91.0, longitude: 0.0),
            (latitude: -91.0, longitude: 0.0),
            (latitude: 0.0, longitude: 181.0),
            (latitude: 0.0, longitude: -181.0)
        ])
        func invalidCoordinate(
            latitude: CLLocationDegrees,
            longitude: CLLocationDegrees
        ) throws {
            let error = #expect(throws: MaidenheadLocator.Error.self) {
                try MaidenheadLocator(from: .init(latitude: latitude, longitude: longitude))
            }
            
            guard case .invalidCoordinate(_) = error else {
                Issue.record("Expected invalidCoordinate error")
                return
            }
        }
    }
    
    // MARK: - Locator Conversion Tests
    
    @Suite("Locator Conversion Tests") struct LocatorConversionTests {
        @Test("Four Character") func fourCharacterLocator() throws {
            let locator = try MaidenheadLocator(locator: "JJ00")
            let coordinate = locator.coordinate
            
            #expect(coordinate.latitude == 0.5)
            #expect(coordinate.longitude == 1.0)
        }
        
        @Test("Six Character") func sixCharacter() throws {
            let locator = try MaidenheadLocator(locator: "JJ00aa")
            let coordinate = locator.coordinate
            
            #expect(coordinate.latitude == 1.0 / 48.0)
            #expect(coordinate.longitude == 1.0 / 24.0)
        }
    }
    
    // MARK: - Round Trip Conversion (Coordinate to Locator to Coordinate)
    
    @Test("Round Trip Conversion Tests", arguments: [
        (latitude: 41.714775, longitude: -72.727260),
        (latitude: 0.0, longitude: 0.0),
        (latitude: 51.5074, longitude: -0.1278),
        (latitude: -33.8688, longitude: 151.2093),
        (latitude: 35.6762, longitude: 139.6503),
    ])
    func roundTripCoversions(latitude: CLLocationDegrees, longitude: CLLocationDegrees) throws {
        let original = try MaidenheadLocator(from: .init(latitude: latitude, longitude: longitude))
        let center = original.coordinate
        let roundtrip = try MaidenheadLocator(from: center)
        
        #expect(roundtrip == original)
    }
    
    // MARK: - Formatting Tests
    
    @Test("Formatting Tests") func FormattingTests() throws {
        let maidenhead = try MaidenheadLocator(locator: "FN31pr")
        
        #expect(maidenhead.formatted(precision: .field) == "FN")
        #expect(maidenhead.formatted(precision: .square) == "FN31")
        #expect(maidenhead.formatted() == "FN31pr")
    }
}
