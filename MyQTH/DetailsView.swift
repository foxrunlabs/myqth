import CoreLocation
import MapKit
import SwiftUI

struct DetailsView: View {
    let location: CLLocation
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties
    
    private var coordinate: CLLocationCoordinate2D {
        let places = CLLocationCoordinate2D.FormatStyle.Precision.tenMeter.ddMinimumPlaces
        let latitude = location.coordinate.latitude.rounded(places: places)
        let longitude = location.coordinate.longitude.rounded(places: places)
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    private var horizontalAccuracy: String {
        let accuracy = Measurement(
            value: location.horizontalAccuracy,
            unit: UnitLength.meters
        )
        
        return accuracy.formatted(.measurement(
            width: .wide,
            usage: .asProvided,
            numberFormatStyle: .number.precision(.fractionLength(1))
        ))
    }
    
    private var maidenheadLocator: AttributedString {
        do {
            let maidenhead = try MaidenheadLocator(from: coordinate)
            return AttributedString(maidenhead.formatted())
        } catch {
            return attributedError(error)
        }
    }
    
    private var utmCoordinate: AttributedString {
        do {
            let utm = try UTMCoordinate(from: coordinate)
            return AttributedString(utm.formatted(precision: .tenMeter))
        } catch {
            return attributedError(error)
        }
    }
    
    private var mgrsCoordinate: AttributedString {
        do {
            let mgrs = try MGRSCoordinate(from: coordinate)
            return AttributedString(mgrs.formatted(precision: .tenMeter))
        } catch {
            return attributedError(error)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                ListRow(horizontalAccuracy, label: "Horizontal Accuracy")
                ListRow(maidenheadLocator, label: "Maidenhead Locator")
                ListRow(coordinate.formatted(notation: .dd, precision: .tenMeter), label: "Decimal Degrees")
                ListRow(coordinate.formatted(notation: .ddm, precision: .tenMeter), label: "Degrees Decimal Minutes")
                ListRow(coordinate.formatted(notation: .dms, precision: .tenMeter), label: "Degrees Minutes Seconds")
                ListRow(utmCoordinate, label: "UTM")
                ListRow(mgrsCoordinate, label: "MGRS")
            }
            .navigationTitle("Position Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func attributedError(_ error: Error) -> AttributedString {
        var s = AttributedString(error.localizedDescription)
        s[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] = .red
        return s
    }
}


// MARK: - List Row

fileprivate struct ListRow: View {
    let title: AttributedString
    let label: String
    
    // MARK: - Initializers
    
    init(_ title: String, label: String) {
        self.title = AttributedString(title)
        self.label = label
    }
    
    init(_ title: AttributedString, label: String) {
        self.title = title
        self.label = label
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .textSelection(.enabled)
            
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var showDetails = true
    let location = CLLocation(
        latitude: CLLocationCoordinate2D.w1aw.latitude,
        longitude: CLLocationCoordinate2D.w1aw.longitude
    )
    
    VStack {
        Button("Show Coordinate Details") {
            showDetails = true
        }
    }
    .sheet(isPresented: $showDetails) {
        DetailsView(location: location)
    }
}
