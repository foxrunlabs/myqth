import CoreLocation
import Foundation

extension CLLocationCoordinate2D {
    /// Formats the coordinate using the default notation (decimal degrees).
    /// - Returns: A string in the form "<latitude>, <longitude>" with four fractional digits per component.
    func formatted() -> String { CoordinateFormatStyle().format(self) }
    
    /// Formats the coordinate using the specified notation.
    /// - Parameter notation: The coordinate notation to apply (.dd, .ddm, or .dms).
    /// - Returns: A formatted string representation of the coordinate.
    func formatted(notation: CoordinateFormatStyle.Notation) -> String {
        CoordinateFormatStyle().notation(notation).format(self)
    }
}


extension CLLocationCoordinate2D {
    /// A format style for displaying geographic coordinates.
    ///
    /// `CoordinateFormatStyle` formats a `CLLocationCoordinate2D` using one of the common latitude/longitude
    /// coordinate formats: decimal degrees (DD), degrees and decimal minutes (DDM), or degrees/minutes/seconds (DMS).
    ///
    /// All formats are derived from the same normalized decimal-degree value so that the displayed DD, DDM, and DMS
    /// representations remain consistent with each other.
    struct CoordinateFormatStyle: FormatStyle {
        typealias FormatInput = CLLocationCoordinate2D
        typealias FormatOutput = String

        /// The coordinate display format.
        enum Notation: String, Codable {
            /// Decimal degrees.
            ///
            /// Example: `41.7148, -72.7273`
            case dd = "DD"
            
            /// Degrees and decimal minutes.
            ///
            /// Example: `41° 42.888' N, 72° 43.638' W`
            case ddm = "DDM"
            
            /// Degrees, minutes, and seconds.
            ///
            /// Example: `41° 42' 53.28" N, 72° 43' 38.28" W`
            case dms = "DMS"
        }

        /// The coordinate format used by this style.
        var notation: Notation = .dd
        
        /// Formats a coordinate using this style.
        ///
        /// - Parameter value: The coordinate to format.
        /// - Returns: A string representation of `value` using the selected coordinate format.
        func format(_ value: FormatInput) -> FormatOutput {
            switch notation {
            case .dd:
                "\(Self.dd(value.latitude)), \(Self.dd(value.longitude))"
            case .ddm:
                "\(Self.ddm(value.latitude, positive: "N", negative: "S")), \(Self.ddm(value.longitude, positive: "E", negative: "W"))"
            case .dms:
                "\(Self.dms(value.latitude, positive: "N", negative: "S")), \(Self.dms(value.longitude, positive: "E", negative: "W"))"
            }
        }
        
        /// Returns a copy of this format style configured with the specified coordinate notation.
        ///
        /// - Parameter n: The coordinate notation to apply (.dd, .ddm, or .dms).
        /// - Returns: A `CoordinateFormatStyle` with `notation` set to `n`.
        func notation(_ n: Notation) -> Self {
            var copy = self
            copy.notation = n
            return copy
        }

        // MARK: - Helper Methods
        
        /// Formats a coordinate component as decimal degrees.
        ///
        /// - Parameter value: The coordinate component to format.
        /// - Returns: A formatted DD string.
        private static func dd(_ value: CLLocationDegrees) -> String {
            let degrees = value.rounded(places: 4).formatted(.number.precision(.fractionLength(4)))
            return "\(degrees)"
        }

        /// Formats a coordinate component as degrees and decimal minutes.
        ///
        /// - Parameters:
        ///   - value: The coordinate component to format.
        ///   - positive: The hemisphere indicator for positive values.
        ///   - negative: The hemisphere indicator for negative values.
        /// - Returns: A formatted DDM string.
        private static func ddm(
            _ value: CLLocationDegrees,
            positive: String,
            negative: String
        )
            -> String
        {
            let hemi = value >= 0.0 ? positive : negative
            
            // Normalize to the precision used by DD so all coordinate
            // formats (DD, DDM, DMS) represent the same displayed location.
            let totalDegrees = value.rounded(places: 4)
            let totalMinutes = (abs(totalDegrees) * 60.0).rounded(places: 3)

            let degrees = Int(totalMinutes / 60.0)
            let minutes = totalMinutes.truncatingRemainder(dividingBy: 60.0)
                .formatted(.number.precision(.fractionLength(3)))

            return "\(degrees)° \(minutes)' \(hemi)"
        }

        /// Formats a coordinate component as degrees, minutes, and seconds.
        ///
        /// - Parameters:
        ///   - value: The coordinate component to format.
        ///   - positive: The hemisphere indicator for positive values.
        ///   - negative: The hemisphere indicator for negative values.
        /// - Returns: A formatted DMS string.
        private static func dms(
            _ value: CLLocationDegrees,
            positive: String,
            negative: String
        )
            -> String
        {
            let hemi = value >= 0.0 ? positive : negative
            
            // Normalize to the precision used by DD so all coordinate
            // formats (DD, DDM, DMS) represent the same displayed location.
            let totalDegrees = value.rounded(places: 4)
            let totalSeconds = (abs(totalDegrees) * 3600.0).rounded(places: 2)
            let degrees = Int(totalSeconds / 3600.0)
            let minutes = Int(totalSeconds.truncatingRemainder(dividingBy: 3600.0) / 60.0)
            let seconds = totalSeconds.truncatingRemainder(dividingBy: 60.0)
                .formatted(.number.precision(.fractionLength(2)))

            return "\(degrees)° \(minutes)' \(seconds)\" \(hemi)"
        }
    }
}

