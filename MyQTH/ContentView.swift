import CoreLocation
import MapKit
import SwiftUI

struct ContentView: View {
    @State private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .region(.init(center: .w1aw, span: .subsquare))
    @State private var showAlert = false

    // MARK: - Computed Properties
    
    private var coordinate: CLLocationCoordinate2D? { locationManager.location?.coordinate }

    private var isUpdateDisabled: Bool {
        locationManager.authorizationStatus == .denied ||
            locationManager.authorizationStatus == .restricted
    }

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Map(position: $position, interactionModes: [.pan, .zoom]) {
                UserAnnotation(anchor: .center) {
                    Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue)
                        .font(.system(size: 48.0))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gear") {
                    }
                    .disabled(true)
                    .accessibilityLabel("App settings")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zoom", systemImage: "square.arrowtriangle.4.outward") {
                    }
                    .disabled(true)
                    .accessibilityLabel("Adjust default zoom level")
                }

                ToolbarSpacer(.fixed, placement: .topBarTrailing)

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        locationManager.requestLocation()
                    } label: {
                        Image(systemName: "location")
                    }
                    .disabled(isUpdateDisabled)
                    .accessibilityLabel("Update location and recenter map")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(coordinate?.maidenheadLocator ?? "Locating...") {
                }
                .font(.title)
                .buttonStyle(.glass)
                .accessibilityLabel("Opens details with coordinates in multiple formats")
            }
            .alert("Location Error", isPresented: $showAlert) {
                Button("OK") { locationManager.error = nil }
            } message: {
                Text(locationManager.error?.localizedDescription ?? "An unknown error occurred.")
            }
        }
        .onChange(of: locationManager.error != nil) { _, hasError in
            showAlert = hasError
        }
        .onChange(of: locationManager.location) { _, _ in
            recenterOnUser()
        }
    }

    // MARK: - Methods

    private func recenterOnUser() {
        guard let coordinate else { return }
        withAnimation(.easeOut) { position = .region(.init(center: coordinate, span: .subsquare)) }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
