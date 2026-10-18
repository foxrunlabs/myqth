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
            (latitude: 83.9999, band: "X")
        ])
        func latitudeBands(latitude: CLLocationDegrees, band: Character) throws {
            let mgrs = try MGRSCoordinate(from: .init(latitude: latitude, longitude: 0.0))
            
            #expect(mgrs.gridZone == .utm(zone: 31, band: band))
        }
        
        // Independent MGRS reference values (WGS 84, five digits per axis).
        @Test("Polar coordinates", arguments: [
            (85.0, -45.0, "Y UD 07232 07232"),
            (85.0, 45.0, "Z FD 92767 07232"),
            (-85.0, -45.0, "A UR 07232 92767"),
            (-85.0, 45.0, "B FR 92767 92767"),
            (85.0, 0.0, "Z AB 00000 44542"),
            (-85.0, 0.0, "B AT 00000 55457"),
            (90.0, 0.0, "Z AH 00000 00000"),
            (-90.0, 0.0, "B AN 00000 00000")
        ])
        func polarCoordinates(latitude: Double, longitude: Double, expected: String) throws {
            let result = try MGRSCoordinate(from: .init(latitude: latitude, longitude: longitude))
            #expect(result.formatted() == expected)
        }

        @Test("Dividing meridians use eastern zones", arguments: [85.0, -85.0, 90.0, -90.0])
        func dividingMeridians(latitude: Double) throws {
            let west = try MGRSCoordinate(from: .init(latitude: latitude, longitude: -180))
            let east = try MGRSCoordinate(from: .init(latitude: latitude, longitude: 180))
            #expect(west == east)
            #expect(east.gridZone == .ups(zone: latitude > 0 ? .z : .b))
        }

        @Test("Southern equator limit") func southernEquatorLimit() throws {
            let result = try MGRSCoordinate(from: .init(latitude: -1e-15, longitude: 3))
            #expect(result.gridZone == .utm(zone: 31, band: "M"))
            #expect(result.gridSquare == "EV")
            #expect(result.northing == 99_999)
        }

        @Suite("MGRS Limits and Validation") struct MGRSLimitsAndValidation {
            @Test("Projection boundaries", arguments: [
                (-80.0001, MGRSCoordinate.GridZone.ups(zone: .b)),
                (-80.0, .utm(zone: 31, band: "C")),
                (83.9999, .utm(zone: 31, band: "X")),
                (84.0, .ups(zone: .z)),
                (84.0001, .ups(zone: .z))
            ])
            func projectionBoundaries(latitude: Double, expected: MGRSCoordinate.GridZone) throws {
                let result = try MGRSCoordinate(from: .init(latitude: latitude, longitude: 0))
                #expect(result.gridZone == expected)
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
                gridZone: .utm(zone: 18, band: "T"),
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
        
        @Test("Polar formatting") func polarFormatting() {
            let result = MGRSCoordinate(
                gridZone: .ups(zone: .y),
                gridSquare: "UD",
                easting: 7232,
                northing: 7232
            )
            #expect(result.formatted() == "Y UD 07232 07232")
            #expect(result.formatted(precision: .tenMeter) == "Y UD 0723 0723")
            #expect(result.formatted(precision: .hundredMeter) == "Y UD 072 072")
            #expect(result.formatted(precision: .kilometer) == "Y UD 07 07")
            #expect(result.formatted(precision: .tenKilometer) == "Y UD 0 0")
        }

        @Test("Leading Zero Preservation") func leadingZeroPreservation() {
            let mgrs = MGRSCoordinate(
                gridZone: .utm(zone: 18, band: "T"),
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
