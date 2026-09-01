import CoreLocation
import Testing

@testable import MyQTH

@Suite("MGRS Coordinate Tests") struct MGRSCoordinateTests {
    // MARK: - Coordinate Conversion Tests
    
    @Suite("Coordinate Conversion Tests") struct CoordinateConversionTests {
        @Test("Known Coordinate") func projectionTests() throws {
            let expected = MGRSCoordinate()
            let mgrs = try MGRSCoordinate(from: .init(latitude: 0.0, longitude: 0.0))
            
            #expect(mgrs == expected)
        }
        
        @Test("Latitude Bands", arguments: [
            (latitude: -80.0, band: "C"),
            (latitude: -72.0, band: "D"),
            (latitude: -64.0, band: "E"),
            (latitude: -56.0, band: "F"),
            (latitude: -48.0, band: "G"),
            (latitude: -40.0, band: "H"),
            (latitude: -32.0, band: "J"),
            (latitude: -24.0, band: "K"),
            (latitude: -16.0, band: "L"),
            (latitude: -8.0, band: "M"),
            (latitude: -0.0001, band: "M"),
            (latitude: 0.0, band: "N"),
            (latitude: 8.0, band: "P"),
            (latitude: 16.0, band: "Q"),
            (latitude: 24.0, band: "R"),
            (latitude: 32.0, band: "S"),
            (latitude: 40.0, band: "T"),
            (latitude: 48.0, band: "U"),
            (latitude: 56.0, band: "V"),
            (latitude: 64.0, band: "W"),
            (latitude: 72.0, band: "X"),
            (latitude: 84.0, band: "X")
        ])
        func latitudeBands(latitude: CLLocationDegrees, band: Character) throws {
            let mgrs = try MGRSCoordinate(from: .init(latitude: latitude, longitude: 0.0))
            
            #expect(mgrs.latitudeBand == band)
        }
        
        @Suite("MGRS Limits and Validation") struct MGRSLimitsAndValidation {
            @Test("MGRS Limits", arguments: [
                (latitude: 84.0001, longitude: 0.0),
                (latitude: -80.0001, longitude: 0.0)
            ])
            func mgrsLimits(latitude: CLLocationDegrees, longitude: CLLocationDegrees) throws {
                let error = #expect(throws: MGRSCoordinate.Error.self) {
                    try MGRSCoordinate(from: .init(latitude: latitude, longitude: longitude))
                }
                
                guard case .invalidLatitude(_) = error else {
                    Issue.record("Expected invalidLatitude error")
                    return
                }
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
                let error = #expect(throws: MGRSCoordinate.Error.self) {
                    try MGRSCoordinate(from: .init(latitude: latitude, longitude: longitude))
                }
                
                guard case .invalidCoordinate(_) = error else {
                    Issue.record("Expected invalidCoordinate error")
                    return
                }
            }
        }
    }
    
    // MARK: - Formatting Tests
    
    @Suite("Formatting Tests") struct FormattingTests {
        @Test("Full Coordinate") func fullCoordinateFormatting() {
            let mgrs = MGRSCoordinate(
                zone: 18,
                latitudeBand: "T",
                gridSquare: "XM",
                easting: 89066,
                northing: 20604
            )
            
            #expect(mgrs.formatted() == "18T XM 89066 20604")
            #expect(mgrs.formatted(precision: .tenMeter) == "18T XM 8906 2060")
            #expect(mgrs.formatted(precision: .hundredMeter) == "18T XM 890 206")
            #expect(mgrs.formatted(precision: .kilometer) == "18T XM 89 20")
            #expect(mgrs.formatted(precision: .tenKilometer) == "18T XM 8 2")
        }
        
        @Test("Leading Zero Preservation") func leadingZeroPreservation() {
            let mgrs = MGRSCoordinate(
                zone: 18,
                latitudeBand: "T",
                gridSquare: "WL",
                easting: 123,
                northing: 7
            )
            
            #expect(mgrs.formatted() == "18T WL 00123 00007")
            #expect(mgrs.formatted(precision: .tenMeter) == "18T WL 0012 0000")
            #expect(mgrs.formatted(precision: .hundredMeter) == "18T WL 001 000")
            #expect(mgrs.formatted(precision: .kilometer) == "18T WL 00 00")
            #expect(mgrs.formatted(precision: .tenKilometer) == "18T WL 0 0")
        }
    }
}
