import CoreLocation
import MapKit
import SwiftUI

struct DetailsView: View {
    let location: CLLocation
    @Environment(\.dismiss) private var dismiss
    
    private var coordinate: CLLocationCoordinate2D { location.coordinate }
    private var utm: UTMCoordinate? { UTMCoordinate(from: location.coordinate) }    
    private var accuracy: String {
        if location.horizontalAccuracy >= 0 {
            location.horizontalAccuracy.formatted(.number.precision(.fractionLength(1))) + " meters"
        } else {
            "Invalid Coordinate"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                ListRow(
                    value: accuracy,
                    label: "Horizontal Accuracy"
                )
                
                ListRow(
                    value: coordinate.maidenheadLocator ?? "Invalid Coordinate",
                    label: "Maidenhead Locator"
                )
                
                ListRow(
                    value: coordinate.formatted(),
                    label: "Decimal Degrees"
                )
                
                ListRow(
                    value: coordinate.formatted(notation: .ddm),
                    label: "Degrees Decimal Minutes"
                )
                
                ListRow(
                    value: coordinate.formatted(notation: .dms),
                    label: "Degrees Minutes Seconds"
                )
                
                ListRow(
                    value: utm?.formatted(precision: .tenMeters) ?? "Invalid Coordinate",
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
