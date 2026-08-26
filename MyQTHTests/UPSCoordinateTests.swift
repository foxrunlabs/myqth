import CoreLocation
import Testing

@testable import MyQTH

struct UPSCoordinateTests {
    // MARK: - Projection Tests
    
    struct ProjectionTests {
        @Test("North Pole") func northPole() throws {
            let ups = try UPSCoordinate(from: CLLocationCoordinate2D(latitude: 90, longitude: 0))
            
            #expect(ups.zone == .z)
            #expect(ups.easting == 2_000_000)
            #expect(ups.northing == 2_000_000)
        }
        
        @Test("South Pole") func southPole() throws {
            let ups = try UPSCoordinate(from: CLLocationCoordinate2D(latitude: -90, longitude: 0))
            
            #expect(ups.zone == .b)
            #expect(ups.easting == 2_000_000)
            #expect(ups.northing == 2_000_000)
        }
        
        @Test("North at 0° E") func northAtZeroLongitude() throws {
            let ups = try UPSCoordinate(from: CLLocationCoordinate2D(latitude: 85, longitude: 0))
            
            #expect(ups.zone == .z)
            #expect(ups.easting == 2_000_000)
            #expect(ups.northing == 1_444_543)
        }
        
        @Test("South at 0° E") func southAtZeroLongitude() throws {
            let ups = try UPSCoordinate(from: CLLocationCoordinate2D(latitude: -85, longitude: 0))
            
            #expect(ups.zone == .b)
            #expect(ups.easting == 2_000_000)
            #expect(ups.northing == 2_555_457)
        }
    }
    
    // MARK: - Zone Tests
    
    struct ZoneTests {
        @Test("Zone Y") func zoneY() throws {
            let ups = try UPSCoordinate(from: CLLocationCoordinate2D(latitude: 85, longitude: -45))
            
            #expect(ups.zone == .y)
            #expect(ups.easting == 1_607_232)
            #expect(ups.northing == 1_607_232)
        }
        
        @Test("Zone Z") func zoneZ() throws {
            let ups = try UPSCoordinate(from: CLLocationCoordinate2D(latitude: 85, longitude: 45))
            
            #expect(ups.zone == .z)
            #expect(ups.easting == 2_392_768)
            #expect(ups.northing == 1_607_232)
        }
        
        @Test("Zone A") func zoneA() throws {
            let ups = try UPSCoordinate(from: CLLocationCoordinate2D(latitude: -85, longitude: -45))
            
            #expect(ups.zone == .a)
            #expect(ups.easting == 1_607_232)
            #expect(ups.northing == 2_392_768)
        }
        
        @Test("Zone B") func zoneB() throws {
            let ups = try UPSCoordinate(from: CLLocationCoordinate2D(latitude: -85, longitude: 45))
            
            #expect(ups.zone == .b)
            #expect(ups.easting == 2_392_768)
            #expect(ups.northing == 2_392_768)
        }
    }
    
    // MARK: - Quadrant Tests
    
    struct QuadrantTests {
        @Test("Northwest hemisphere past 90° W") func northwestHemispherePast90Degrees() throws {
            let ups = try UPSCoordinate(from: CLLocationCoordinate2D(latitude: 85, longitude: -135))
            
            #expect(ups.zone == .y)
            #expect(ups.easting == 1_607_232)
            #expect(ups.northing == 2_392_768)
        }
        
        @Test("Northeast hemisphere past 90° E") func northeastHemispherePast90Degrees() throws {
            let ups = try UPSCoordinate(from: CLLocationCoordinate2D(latitude: 85, longitude: 135))
            
            #expect(ups.zone == .z)
            #expect(ups.easting == 2_392_768)
            #expect(ups.northing == 2_392_768)
        }
        
        @Test("Southwest hemisphere past 90° W") func southwestHemispherePast90Degrees() throws {
            let ups = try UPSCoordinate(from: CLLocationCoordinate2D(latitude: -85, longitude: -135))
            
            #expect(ups.zone == .a)
            #expect(ups.easting == 1_607_232)
            #expect(ups.northing == 1_607_232)
        }
        
        @Test("Southeast hemisphere past 90° E") func southeastHemispherePast90Degrees() throws {
            let ups = try UPSCoordinate(from: CLLocationCoordinate2D(latitude: -85, longitude: 135))
            
            #expect(ups.zone == .b)
            #expect(ups.easting == 2_392_768)
            #expect(ups.northing == 1_607_232)
        }
    }
    
    // MARK: - Latitude Validation Tests
    
    @Test("Latitude Validation Tests", arguments: [
        (84, 0),     // northern UTM boundary
        (-80, 0),    // southern UTM boundary
        (45, -71),   // latitude inside UTM range
        (91, 0)      // invalid lat/long
    ])
    func invalidCoordinates(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        #expect(throws: UPSCoordinate.Error.self) {
            try UPSCoordinate(from: coordinate)
        }
    }
    
    // MARK: - Initializer Tests
    
    struct InitializerTests {
        @Test("Default Initializer") func defaultInitializer() throws {
            let ups = UPSCoordinate()
            
            #expect(ups.zone == .z)
            #expect(ups.easting == 2_000_000)
            #expect(ups.northing == 2_000_000)
        }
        
        @Test("Component Initializer") func componentInitializer() throws {
            let ups = UPSCoordinate(zone: .z, easting: 2_392_768, northing: 1_607_232)
            
            #expect(ups.zone == .z)
            #expect(ups.easting == 2_392_768)
            #expect(ups.northing == 1_607_232)
        }
    }
    
    // MARK: - Formatting Tests
    
    struct FormattingTests {
        @Test("Formatting") func defaultFormatting() {
            let ups = UPSCoordinate(zone: .z, easting: 2_392_768, northing: 1_607_232)
            
            #expect(ups.formatted() == "Z 2392768 1607232")
            #expect(ups.formatted(precision: .tenMeter) == "Z 239276 160723")
            #expect(ups.formatted(precision: .hundredMeter) == "Z 23927 16072")
            #expect(ups.formatted(precision: .kilometer) == "Z 2392 1607")
        }
        
        @Test("Formatting preserves leading zeros") func formattingPreserverLeadingZeros() {
            let ups = UPSCoordinate(zone: .y, easting: 123_456, northing: 987_654)
            
            #expect(ups.formatted() == "Y 0123456 0987654")
            #expect(ups.formatted(precision: .tenMeter) == "Y 012345 098765")
            #expect(ups.formatted(precision: .hundredMeter) == "Y 01234 09876")
            #expect(ups.formatted(precision: .kilometer) == "Y 0123 0987")
        }
    }
}
