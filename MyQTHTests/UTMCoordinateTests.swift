import CoreLocation
import Testing

@testable import MyQTH

@Suite("UTM Coordinate Tests") struct UTMCoordinateTests {
    // MARK: - Coordinate Conversion Tests
    
    @Suite("Coordinate Conversion Tests") struct CoordinateConversionTests {
        @Test("Projection Tests", arguments: [
            (
                latitude: 41.714775,
                longitude: -72.727260,
                expected: UTMCoordinate(
                    zone: 18,
                    hemisphere: .north,
                    easting: 689_067,
                    northing: 4_620_605
                )
            ),
            (
                latitude: -33.8688,
                longitude: 151.2093,
                expected: UTMCoordinate(
                    zone: 56,
                    hemisphere: .south,
                    easting: 334_369,
                    northing: 6_250_948
                )
            ),
            (
                latitude: 0.0,
                longitude: 3.0,
                expected: UTMCoordinate(
                    zone: 31,
                    hemisphere: .north,
                    easting: 500_000,
                    northing: 0
                )
            ),
            (
                latitude: -0.0001,
                longitude: 3.0,
                expected: UTMCoordinate(
                    zone: 31,
                    hemisphere: .south,
                    easting: 500_000,
                    northing: 9_999_989
                )
            ),
            (
                latitude: 0.0,
                longitude: 180.0,
                expected: UTMCoordinate(
                    zone: 60,
                    hemisphere: .north,
                    easting: 833_979,
                    northing: 0
                )
            ),
            (
                latitude: 0.0,
                longitude: -180.0,
                expected: UTMCoordinate(
                    zone: 1,
                    hemisphere: .north,
                    easting: 166_021,
                    northing: 0
                )
            )
        ])
        func projectionTests(
            latitude: CLLocationDegrees,
            longitude: CLLocationDegrees,
            expected: UTMCoordinate
        ) throws {
            let utm = try UTMCoordinate(from: .init(latitude: latitude, longitude: longitude))
            
            #expect(utm == expected)
        }
        
        @Suite("Zone Exceptions") struct ZoneExceptionTests {
            @Test("Norway Exception") func norwayExceptionUsesZone32() throws {
                let utm = try UTMCoordinate(from: .init(latitude: 60.0, longitude: 6.0))
                let expected = UTMCoordinate(
                    zone: 32,
                    hemisphere: .north,
                    easting: 332_705,
                    northing: 6_655_205
                )
                
                #expect(utm == expected)
            }
            
            @Test("Svalbard Exceptions", arguments: [
                (
                    latitude: 75.0,
                    longitude: 5.0,
                    expected: UTMCoordinate(
                        zone: 31,
                        hemisphere: .north,
                        easting: 557_771,
                        northing: 8_324_581
                    )
                ),
                (
                    latitude: 75.0,
                    longitude: 15.0,
                    expected: UTMCoordinate(
                        zone: 33,
                        hemisphere: .north,
                        easting: 500_000,
                        northing: 8_323_607
                    )
                ),
                (
                    latitude: 75.0,
                    longitude: 25.0,
                    expected: UTMCoordinate(
                        zone: 35,
                        hemisphere: .north,
                        easting: 442_229,
                        northing: 8_324_581
                    )
                ),
                (
                    latitude: 75.0,
                    longitude: 35.0,
                    expected: UTMCoordinate(
                        zone: 37,
                        hemisphere: .north,
                        easting: 384_520,
                        northing: 8_327_502
                    )
                )
            ])
            func svalbardExceptions(
                latitude: CLLocationDegrees,
                longitude: CLLocationDegrees,
                expected: UTMCoordinate
            ) throws {
                let utm = try UTMCoordinate(from: .init(latitude: latitude, longitude: longitude))
                
                #expect(utm == expected)
            }
        }
        
        @Suite("UTM Limits and Validation") struct UTMLimitsAndValidation {
            @Test("UTM Limits", arguments: [
                (latitude: 84.0, longitude: 0.0),
                (latitude: -80.0, longitude: 0.0)
            ])
            func utmLimits(latitude: CLLocationDegrees, longitude: CLLocationDegrees) throws {
                #expect(throws: Never.self) {
                    try UTMCoordinate(from: .init(latitude: latitude, longitude: longitude))
                }
            }
            
            @Test("Latitude Validation", arguments: [
                (latitude: 84.0001, longitude: 0.0),
                (latitude: -80.0001, longitude: 0.0)
            ])
            func latitudeValidation(
                latitude: CLLocationDegrees,
                longitude: CLLocationDegrees
            ) throws {
                let error = #expect(throws: UTMCoordinate.Error.self) {
                    try UTMCoordinate(from: .init(latitude: latitude, longitude: longitude))
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
                let error = #expect(throws: UTMCoordinate.Error.self) {
                    try UTMCoordinate(from: .init(latitude: latitude, longitude: longitude))
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
            let utm = UTMCoordinate(
                zone: 43,
                hemisphere: .north,
                easting: 247_679,
                northing: 4_543_093
            )
            
            #expect(utm.formatted() == "43N 247679 4543093")
            #expect(utm.formatted(precision: .tenMeter) == "43N 24767 454309")
            #expect(utm.formatted(precision: .hundredMeter) == "43N 2476 45430")
            #expect(utm.formatted(precision: .kilometer) == "43N 247 4543")
        }
        
        @Test("Leading Zero Preservation") func leadingZeroPreservation() {
            let utm = UTMCoordinate(
                zone: 43,
                hemisphere: .north,
                easting: 500_000,
                northing: 552_664
            )
            
            #expect(utm.formatted() == "43N 500000 0552664")
            #expect(utm.formatted(precision: .tenMeter) == "43N 50000 055266")
            #expect(utm.formatted(precision: .hundredMeter) == "43N 5000 05526")
            #expect(utm.formatted(precision: .kilometer) == "43N 500 0552")
        }
    }
}
