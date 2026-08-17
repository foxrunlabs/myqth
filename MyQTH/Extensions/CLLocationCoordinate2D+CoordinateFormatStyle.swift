import CoreLocation
import Foundation

extension CLLocationCoordinate2D {
    /// Formats the coordinate using the default notation (decimal degrees) and precision (meter).
    /// - Returns: A string in the form "<latitude>, <longitude>" with five fractional digits per component.
    func formatted() -> String { FormatStyle().format(self) }
    
    /// Formats the coordinate using the specified notation.
    /// - Parameter notation: The coordinate notation to apply (.dd, .ddm, or .dms).
    /// - Returns: A formatted string representation of the coordinate.
    func formatted(notation: FormatStyle.Notation, precision: FormatStyle.Precision) -> String {
        FormatStyle().notation(notation).precision(precision).format(self)
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
    struct FormatStyle: Foundation.FormatStyle {
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
        
        /// Represents the precision levels available for formatting a coordinate.
        enum Precision: Int, Codable {
            /// Precision at 1 meter.
            case meter
            /// Precision at 10 meters.
            case tenMeter
            /// Precision at 100 meters.
            case hundredMeter
            /// Precision at 1 kilometer.
            case kilometer
            /// Precision at 10 kilometers.
            case tenKilometer
            
            /// The minimum number of decimal places for this precision using DD notation.
            var ddMinimumPlaces: Int {
                switch self {
                case .meter: 5
                case .tenMeter: 4
                case .hundredMeter: 3
                case .kilometer: 2
                case .tenKilometer: 1
                }
            }
            
            /// The minimum number of decimal places for this precision using DDM notation.
            var ddmMinimumPlaces: Int {
                switch self {
                case .meter: 4
                case .tenMeter: 3
                case .hundredMeter: 2
                case .kilometer: 1
                case .tenKilometer: 0
                }
            }
            
            /// The minimum number of decimal places for this precision using DMS notation.
            var dmsMinimumPlaces: Int {
                switch self {
                case .meter: 3
                case .tenMeter: 2
                case .hundredMeter: 1
                case .kilometer, .tenKilometer: 0
                }
            }
        }

        // MARK: - Properties
        
        /// The coordinate format used by this style.
        var notation: Notation = .dd
        
        /// The precision used by this style.
        var precision: Precision = .meter
        
        // MARK: - Methods
        
        /// Formats a coordinate using this style.
        ///
        /// - Parameter value: The coordinate to format.
        /// - Returns: A string representation of `value` using the selected coordinate format.
        func format(_ value: FormatInput) -> FormatOutput {
            switch notation {
            case .dd:
                "\(dd(value.latitude)), \(dd(value.longitude))"
            case .ddm:
                "\(ddm(value.latitude, positive: "N", negative: "S")), \(ddm(value.longitude, positive: "E", negative: "W"))"
            case .dms:
                "\(dms(value.latitude, positive: "N", negative: "S")), \(dms(value.longitude, positive: "E", negative: "W"))"
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
        
        /// Returns a copy of this `FormatStyle` configured to use the specified precision.
        ///
        /// - Parameter p: The desired precision level.
        /// - Returns: A new `FormatStyle` instance set to the specified precision.
        func precision(_ p: Precision) -> Self {
            var copy = self
            copy.precision = p
            return copy
        }

        // MARK: - Helper Methods
        
        /// Formats a coordinate component as decimal degrees.
        ///
        /// - Parameter value: The coordinate component to format.
        /// - Returns: A formatted DD string.
        private func dd(_ value: CLLocationDegrees) -> String {
            let places = precision.ddMinimumPlaces
            let degrees = value.rounded(places: places).formatted(.number.precision(.fractionLength(places)))
            return "\(degrees)"
        }

        /// Formats a coordinate component as degrees and decimal minutes.
        ///
        /// - Parameters:
        ///   - value: The coordinate component to format.
        ///   - positive: The hemisphere indicator for positive values.
        ///   - negative: The hemisphere indicator for negative values.
        /// - Returns: A formatted DDM string.
        private func ddm(
            _ value: CLLocationDegrees,
            positive: String,
            negative: String
        )
            -> String
        {
            let ddPlaces = precision.ddMinimumPlaces
            let ddmPlaces = precision.ddmMinimumPlaces
            let hemi = value >= 0.0 ? positive : negative
            
            // Normalize to the precision used by DD so all coordinate
            // formats (DD, DDM, DMS) represent the same displayed location.
            let totalDegrees = value.rounded(places: ddPlaces)
            let totalMinutes = (abs(totalDegrees) * 60.0).rounded(places: ddmPlaces)

            let degrees = Int(totalMinutes / 60.0)
            let minutes = totalMinutes.truncatingRemainder(dividingBy: 60.0)
                .formatted(.number.precision(.fractionLength(ddmPlaces)))

            return "\(degrees)° \(minutes)' \(hemi)"
        }

        /// Formats a coordinate component as degrees, minutes, and seconds.
        ///
        /// - Parameters:
        ///   - value: The coordinate component to format.
        ///   - positive: The hemisphere indicator for positive values.
        ///   - negative: The hemisphere indicator for negative values.
        /// - Returns: A formatted DMS string.
        private func dms(
            _ value: CLLocationDegrees,
            positive: String,
            negative: String
        )
            -> String
        {
            let ddPlaces = precision.ddMinimumPlaces
            let dmsPlaces = precision.dmsMinimumPlaces
            let hemi = value >= 0.0 ? positive : negative
            
            // Normalize to the precision used by DD so all coordinate
            // formats (DD, DDM, DMS) represent the same displayed location.
            let totalDegrees = value.rounded(places: ddPlaces)
            let totalSeconds = (abs(totalDegrees) * 3600.0).rounded(places: dmsPlaces)
            let degrees = Int(totalSeconds / 3600.0)
            let minutes = Int(totalSeconds.truncatingRemainder(dividingBy: 3600.0) / 60.0)
            let seconds = totalSeconds.truncatingRemainder(dividingBy: 60.0)
                .formatted(.number.precision(.fractionLength(dmsPlaces)))

            return "\(degrees)° \(minutes)' \(seconds)\" \(hemi)"
        }
    }
}

