import Foundation

/// Extension to provide rounding methods on `Double` values to a specified number of decimal places.
///
/// - The `places` parameter is limited to the range `0...15` because `Double` precision typically provides about 15-17
///   decimal digits of precision, and rounding beyond this can lead to meaningless results.
extension Double {
    /// Rounds the value to a specified number of decimal places using the provided rounding rule.
    ///
    /// - Parameters:
    ///   - places: The number of decimal places to round to. Must be between 0 and 15 inclusive.
    ///   - rule: The rounding rule to apply. Defaults to `.toNearestOrAwayFromZero`.
    ///
    /// - Returns: A new `Double` value rounded to the specified number of decimal places.
    ///
    /// - Discussion:
    ///   Examples of rounding rules include `.toNearestOrAwayFromZero`, `.down`, `.up`, `.towardZero`, and `.awayFromZero`.
    ///   The typical range for `places` is 0 through 15 to maintain meaningful precision with `Double`.
    func rounded(places: Int, rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> Double {
        precondition(places >= 0 && places <= 15, "Places must be in the range 0...15")
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded(rule) / divisor
    }
    
    /// Rounds this value in place to a specified number of decimal places using the provided rule.
    ///
    /// - Parameters:
    ///   - places: The number of decimal places to round to. Must be between 0 and 15 inclusive.
    ///   - rule: The rounding rule to apply. Defaults to `.toNearestOrAwayFromZero`.
    ///
    /// - Discussion:
    ///   This is the mutating counterpart of `rounded(places:rule:)`, modifying the value in place.
    mutating func round(places: Int, rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) {
        precondition(places >= 0 && places <= 15, "Places must be in the range 0...15")
        self = rounded(places: places, rule: rule)
    }
}
