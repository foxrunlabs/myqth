import MapKit
import SwiftUI

struct DetailsView: View {
    let coordinate: CLLocationCoordinate2D
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                ListRow(
                    coordinate: coordinate.maidenheadLocator ?? "Invalid Coordinate",
                    label: "Maidenhead Locator"
                )
                
                ListRow(
                    coordinate: coordinate.formatted(.coordinate(format: .dd)),
                    label: "Decimal Degrees"
                )
                
                ListRow(
                    coordinate: coordinate.formatted(.coordinate(format: .ddm)),
                    label: "Degrees Decimal Minutes"
                )
                
                ListRow(
                    coordinate: coordinate.formatted(.coordinate(format: .dms)),
                    label: "Degrees Minutes Seconds"
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
    let coordinate: String
    let label: String
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(coordinate)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var showDetails = true
    
    VStack {
        Button("Show Coordinate Details") {
            showDetails = true
        }
    }
    .sheet(isPresented: $showDetails) {
        DetailsView(coordinate: .w1aw)
    }
}
