import CoreLocation
import MapKit
import SwiftUI

struct DetailsView: View {
    let location: CLLocation
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties
    
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
            let maidenhead = try MaidenheadLocator(from: location.coordinate)
            return AttributedString(maidenhead.formatted())
        } catch {
            return attributedError(error)
        }
    }
    
    private var utmCoordinate: AttributedString {
        do {
            let utm = try UTMCoordinate(from: location.coordinate)
            return AttributedString(utm.formatted(precision: .tenMeters))
        } catch {
            return attributedError(error)
        }
    }
    
    private var mgrsCoordinate: AttributedString {
        do {
            let mgrs = try MGRSCoordinate(from: location.coordinate)
            return AttributedString(mgrs.formatted(precision: .tenMeters))
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
                ListRow(location.coordinate.formatted(), label: "Decimal Degrees")
                ListRow(location.coordinate.formatted(notation: .ddm), label: "Degrees Decimal Minutes")
                ListRow(location.coordinate.formatted(notation: .dms), label: "Degrees Minutes Seconds")
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
