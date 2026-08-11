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
            return AttributedString(try MaidenheadLocator(from: location.coordinate).formatted())
        } catch {
            return attributedError(error)
        }
    }
    
    private var utmCoordinate: AttributedString {
        do {
            return AttributedString(
                try UTMCoordinate(from: location.coordinate).formatted(precision: .tenMeters)
            )
        } catch {
            return attributedError(error)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                ListRow(
                    value: horizontalAccuracy,
                    label: "Horizontal Accuracy"
                )
                
                AttributedListRow(
                    value: maidenheadLocator,
                    label: "Maidenhead Locator"
                )
                
                ListRow(
                    value: location.coordinate.formatted(),
                    label: "Decimal Degrees"
                )
                
                ListRow(
                    value: location.coordinate.formatted(notation: .ddm),
                    label: "Degrees Decimal Minutes"
                )
                
                ListRow(
                    value: location.coordinate.formatted(notation: .dms),
                    label: "Degrees Minutes Seconds"
                )
                
                AttributedListRow(
                    value: utmCoordinate,
                    label: "UTM"
                )
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
    let value: String
    let label: String
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(value)
                .textSelection(.enabled)
            
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}


// MARK: - Attributed List Row

fileprivate struct AttributedListRow: View {
    let value: AttributedString
    let label: String
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(value)
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
