import CoreLocation
import Foundation

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
        enum Format: Codable {
            /// Decimal degrees.
            ///
            /// Example: `41.7148, -72.7273`
            case dd
            
            /// Degrees and decimal minutes.
            ///
            /// Example: `41° 42.888' N, 72° 43.638' W`
            case ddm
            
            /// Degrees, minutes, and seconds.
            ///
            /// Example: `41° 42' 53.28" N, 72° 43' 38.28" W`
            case dms
        }

        /// The coordinate format used by this style.
        var format: Format
        
        /// Formats a coordinate using this style.
        ///
        /// - Parameter value: The coordinate to format.
        /// - Returns: A string representation of `value` using the selected coordinate format.
        func format(_ value: FormatInput) -> FormatOutput {
            switch format {
            case .dd:
                "\(Self.dd(value.latitude)), \(Self.dd(value.longitude))"
            case .ddm:
                "\(Self.ddm(value.latitude, positive: "N", negative: "S")), \(Self.ddm(value.longitude, positive: "E", negative: "W"))"
            case .dms:
                "\(Self.dms(value.latitude, positive: "N", negative: "S")), \(Self.dms(value.longitude, positive: "E", negative: "W"))"
            }
        }

        // MARK: - Helper Methods
        /// Rounds a coordinate component to the decimal degree precision used for display.
        ///
        /// - Parameter value: The coordinate component to round.
        /// - Returns: A rounded coordinate component.
        ///
        /// This normalized value is used as the source for DD, DDM, and DMS output so that each format represents the same
        /// displayed location.
        private static func normalizedDegrees(_ value: CLLocationDegrees) -> CLLocationDegrees {
            (value * 10_000.0).rounded() / 10_000.0
        }
        
        /// Formats a coordinate component as decimal degrees.
        ///
        /// - Parameter value: The coordinate component to format.
        /// - Returns: A formatted DD string.
        private static func dd(_ value: CLLocationDegrees) -> String {
            let degrees = normalizedDegrees(value).formatted(.number.precision(.fractionLength(4)))
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
            let totalDegrees = normalizedDegrees(value)
            let totalMinutes = (abs(totalDegrees) * 60.0 * 1000.0).rounded() / 1000.0

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
            let totalDegrees = normalizedDegrees(value)
            let totalSeconds = (abs(totalDegrees) * 3600.0 * 100).rounded() / 100.0
            let degrees = Int(totalSeconds / 3600.0)
            let minutes = Int(totalSeconds.truncatingRemainder(dividingBy: 3600.0) / 60.0)
            let seconds = totalSeconds.truncatingRemainder(dividingBy: 60.0)
                .formatted(.number.precision(.fractionLength(2)))

            return "\(degrees)° \(minutes)' \(seconds)\" \(hemi)"
        }
    }

    /// Formats the  coordinate using the provided coordinate format style.
    /// - Parameter format: The coordinate format style to apply. The default is decimal degrees.
    /// - Returns: A formatted string representation of the coordinate.
    func formatted(_ format: CoordinateFormatStyle = .coordinate(format: .dd)) -> String {
        format.format(self)
    }
}


// MARK: - FormatStyle Extension
extension FormatStyle where Self == CLLocationCoordinate2D.CoordinateFormatStyle {
    /// Creates a coordinate format style.
    ///
    /// - Parameter format: The coordinate format to use.
    /// - Returns: A coordinate format style configured with `format`.
    static func coordinate(format: Self.Format) -> Self {
        Self(format: format)
    }
}
