import Foundation

/// This extension provides convenience accessors for values commonly read from an app's Info.plist.These properties return a fallback
/// placeholder ("?") if the corresponding Info.plist keys are missing.
extension Bundle {
    /// The marketing version of the bundle.
    ///
    /// This value corresponds to the Info.plist key `CFBundleShortVersionString`, which is the human-facing version number
    /// you display to users (for example, "1.2.3").
    ///
    /// - Returns: The marketing version string, or "?" if unavailable.
    /// - SeeAlso: `CFBundleShortVersionString`
    var marketingVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    /// The build number of the bundle.
    ///
    /// This value corresponds to the Info.plist key `CFBundleVersion`, which is typically incremented with each build you submit for
    ///  testing or release (for example, "45").
    ///
    /// - Returns: The build number string, or "?" if unavailable.
    /// - SeeAlso: `CFBundleVersion`
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    /// A composed version string in the form "<marketing> (<build>)".
    ///
    /// Combines `marketingVersion` and `buildNumber` into a single user-facing string, such as "1.2.3 (45)". This is useful for
    /// settings screens and diagnostic reporting.
    ///
    /// - Returns: A string combining the marketing version and build number.
    /// - Example: `"1.2.3 (45)"`
    var versionString: String {
        "\(marketingVersion) (\(buildNumber))"
    }
    
    /// The bundle's human-readable copyright.
    ///
    /// This value corresponds to the Info.plist key `NSHumanReadableCopyright`. It is typically shown on an About screen or in
    /// Settings.
    ///
    /// - Returns: The copyright string, or "?" if unavailable.
    /// - SeeAlso: `NSHumanReadableCopyright`
    var copyright: String {
        infoDictionary?["NSHumanReadableCopyright"] as? String ?? "?"
    }
}
