import CoreLocation
import Testing

@testable import MyQTH

@Suite("UPS Coordinate Tests") struct UPSCoordinateTests {
    // MARK: - Coordinate Conversion Tests
    
    @Suite("Coordinate Conversion Tests") struct CoordinateConversionTests {
        @Test("Projection Tests", arguments: [
            (
                latitude: 90.0,
                longitude: 0.0,
                expected: UPSCoordinate(zone: .z, easting: 2_000_000, northing: 2_000_000)
            ),
            (
                latitude: -90.0,
                longitude: 0.0,
                expected: UPSCoordinate(zone: .b, easting: 2_000_000, northing: 2_000_000)
            ),
            (
                latitude: 85.0,
                longitude: 0.0,
                expected: UPSCoordinate(zone: .z, easting: 2_000_000, northing: 1_444_543)
            ),
            (
                latitude: -85.0,
                longitude: 0.0,
                expected: UPSCoordinate(zone: .b, easting: 2_000_000, northing: 2_555_457)
            ),
            (
                latitude: 85.0,
                longitude: -45.0,
                expected: UPSCoordinate(zone: .y, easting: 1_607_232, northing: 1_607_232)
            ),
            (
                latitude: 85.0,
                longitude: -45.0,
                expected: UPSCoordinate(zone: .y, easting: 1_607_232, northing: 1_607_232)
            ),
            (
                latitude: 85.0,
                longitude: 45.0,
                expected: UPSCoordinate(zone: .z, easting: 2_392_768, northing: 1_607_232)
            ),
            (
                latitude: -85.0,
                longitude: -45.0,
                expected: UPSCoordinate(zone: .a, easting: 1_607_232, northing: 2_392_768)
            ),
            (
                latitude: -85.0,
                longitude: 45.0,
                expected: UPSCoordinate(zone: .b, easting: 2_392_768, northing: 2_392_768)
            ),
            (
                latitude: 85.0,
                longitude: -135.0,
                expected: UPSCoordinate(zone: .y, easting: 1_607_232, northing: 2_392_768)
            ),
            (
                latitude: 85.0,
                longitude: 135.0,
                expected: UPSCoordinate(zone: .z, easting: 2_392_768, northing: 2_392_768)
            ),
            (
                latitude: -85.0,
                longitude: -135.0,
                expected: UPSCoordinate(zone: .a, easting: 1_607_232, northing: 1_607_232)
            ),
            (
                latitude: -85.0,
                longitude: 135.0,
                expected: UPSCoordinate(zone: .b, easting: 2_392_768, northing: 1_607_232)
            ),
        ])
        func projectionTests(
            latitude: CLLocationDegrees,
            longitude: CLLocationDegrees,
            expected: UPSCoordinate
        ) throws {
            let ups = try UPSCoordinate(from: .init(latitude: latitude, longitude: longitude))
            
            #expect(ups == expected)
        }
        
        @Suite("UPS Validation") struct UPSLimitsAndValidation {
            @Test("Latitude Validation", arguments: [
                (latitude: 84.0, longitude: 0.0),
                (latitude: -80.0, longitude: 0.0)
            ])
            func latitudeValidation(
                latitude: CLLocationDegrees,
                longitude: CLLocationDegrees
            ) throws {
                let error = #expect(throws: UPSCoordinate.Error.self) {
                    try UPSCoordinate(from: .init(latitude: latitude, longitude: longitude))
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
                let error = #expect(throws: UPSCoordinate.Error.self) {
                    try UPSCoordinate(from: .init(latitude: latitude, longitude: longitude))
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
            let ups = UPSCoordinate(zone: .z, easting: 2_392_768, northing: 1_607_232)
            
            #expect(ups.formatted() == "Z 2392768 1607232")
            #expect(ups.formatted(precision: .tenMeter) == "Z 239276 160723")
            #expect(ups.formatted(precision: .hundredMeter) == "Z 23927 16072")
            #expect(ups.formatted(precision: .kilometer) == "Z 2392 1607")
        }
        
        @Test("Leading Zero Preservation") func leadingZeroPreservation() {
            let ups = UPSCoordinate(zone: .y, easting: 123_456, northing: 987_654)
            
            #expect(ups.formatted() == "Y 0123456 0987654")
            #expect(ups.formatted(precision: .tenMeter) == "Y 012345 098765")
            #expect(ups.formatted(precision: .hundredMeter) == "Y 01234 09876")
            #expect(ups.formatted(precision: .kilometer) == "Y 0123 0987")
        }
    }
}
