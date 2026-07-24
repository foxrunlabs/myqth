import CoreLocation
import MapKit
import SwiftUI

struct ContentView: View {
    private enum ZoomLevel: String, CaseIterable, CustomStringConvertible, Identifiable {
        case field
        case square
        case subsquare

        var span: MKCoordinateSpan {
            switch self {
            case .field: .field
            case .square: .square
            case .subsquare: .subsquare
            }
        }
        
        var id: Self { self }

        var description: String {
            switch self {
            case .field: "Field"
            case .square: "Square"
            case .subsquare: "Subsquare"
            }
        }
    }
    
    // MARK: - Properties

    @State private var locationManager = LocationManager()
    
    @State private var showAlert = false
    @State private var showSettings = false
    @State private var showDetails = false
    
    @AppStorage("net.thefoxrun.MyQTH.zoom") private var zoom = ZoomLevel.subsquare
    @State private var cameraPosition: MapCameraPosition = .region(
        .init(center: .w1aw, span: .subsquare)
    )

    // MARK: - Computed Properties
    
    private var coordinate: CLLocationCoordinate2D? { locationManager.location?.coordinate }

    private var isUpdateDisabled: Bool {
        locationManager.authorizationStatus == .denied ||
            locationManager.authorizationStatus == .restricted
    }

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                UserAnnotation(anchor: .center) {
                    Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue)
                        .font(.system(size: 48.0))
                }
            }
            .onMapCameraChange { context in cameraPosition = .region(context.region) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gear") { showSettings = true }
                        .accessibilityLabel("App settings")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Zoom", systemImage: "square.arrowtriangle.4.outward") {
                        Picker("Zoom", selection: $zoom) {
                            ForEach(ZoomLevel.allCases) { zoomLevel in
                                Text(String(describing: zoomLevel))
                                    .tag(zoomLevel)
                            }
                        }
                        .onChange(of: zoom) { _, newZoom in
                            updateCameraPosition(span: newZoom.span)
                        }
                    }
                    .accessibilityLabel("Update zoom level and recenter map")
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
                    showDetails = true
                }
                .font(.title)
                .buttonStyle(.glass)
                .disabled(coordinate == nil)
                .accessibilityLabel("Opens details with coordinates in multiple formats")
            }
            .alert("Location Error", isPresented: $showAlert) {
                Button("OK") { locationManager.error = nil }
            } message: {
                Text(locationManager.error?.localizedDescription ?? "An unknown error occurred.")
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showDetails) {
                if let coordinate { DetailsView(coordinate: coordinate) }
            }
        }
        .onChange(of: locationManager.error != nil) { _, hasError in showAlert = hasError }
        .onChange(of: locationManager.location) { _, _ in updateCameraPosition(span: zoom.span) }
    }

    // MARK: - Methods
    
    private func updateCameraPosition(span: MKCoordinateSpan) {
        guard let coordinate else { return }
        withAnimation(.easeInOut) {
            cameraPosition = .region(.init(center: coordinate, span: span))
        }
    }
}


// MARK: - Preview

#Preview {
    ContentView()
}
