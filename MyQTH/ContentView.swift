import CoreLocation
import MapKit
import SwiftUI

struct ContentView: View {
    private enum ZoomLevel: String, CaseIterable, Identifiable {
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

        var displayName: String {
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
    
    @AppStorage("net.thefoxrun.labs.MyQTH.callsign") private var callsign = ""
    @AppStorage("net.thefoxrun.labs.MyQTH.displayGrid") private var displayGrid = true
    @AppStorage("net.thefoxrun.labs.MyQTH.zoom") private var zoom = ZoomLevel.subsquare
    
    @State private var cameraPosition: MapCameraPosition = .region(
        .init(center: CLLocationCoordinate2D(), span: .subsquare)
    )
    
    @State private var gridCells = MaidenheadGrid(
        region: .init(center: CLLocationCoordinate2D(), span: .subsquare)
    ).cells

    // MARK: - Computed Properties
    
    private var location: CLLocation? { locationManager.location }
    
    private var maidenheadLocator: MaidenheadLocator? {
        guard let location else { return nil }
        
        let places = CLLocationCoordinate2D.FormatStyle.Precision.tenMeter.ddMinimumPlaces
        let latitude = location.coordinate.latitude.rounded(places: places)
        let longitude = location.coordinate.longitude.rounded(places: places)
        let roundedCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        return try? MaidenheadLocator(from: roundedCoordinate)
    }

    private var isUpdateDisabled: Bool {
        locationManager.authorizationStatus == .denied ||
            locationManager.authorizationStatus == .restricted
    }
    
    private var isDetailDisabled: Bool { location == nil }

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                if displayGrid {
                    MaidenheadGridContent(cells: gridCells)
                }

                Marker(
                    callsign,
                    systemImage: "antenna.radiowaves.left.and.right",
                    coordinate: location?.coordinate ?? CLLocationCoordinate2D()
                )
            }
            .onMapCameraChange(frequency: .continuous) { context in
                let cells = MaidenheadGrid(region: context.region).cells
                
                if cells.map(\.id) != gridCells.map(\.id) {
                    gridCells = cells
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gear") { showSettings = true }
                        .accessibilityLabel("App settings")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Zoom", systemImage: "square.arrowtriangle.4.outward") {
                        Picker("Zoom", selection: $zoom) {
                            ForEach(ZoomLevel.allCases) { zoomLevel in
                                Text(zoomLevel.displayName)
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
                        if locationManager.autoUpdate {
                            updateCameraPosition(span: zoom.span)
                        } else {
                            locationManager.requestLocation()
                        }
                    } label: {
                        Image(systemName: "location")
                    }
                    .disabled(isUpdateDisabled)
                    .accessibilityLabel("Update location and recenter map")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    showDetails = true
                } label: {
                    if let maidenheadLocator {
                        HStack {
                            Image(systemName: "globe")
                            
                            Text(maidenheadLocator.formatted())
                                .font(.title)
                            
                            Image(systemName: "info")
                                .symbolVariant(.circle)
                        }
                    } else {
                        Text("Locating...")
                            .font(.title)
                    }
                }
                .buttonStyle(.glass)
                .disabled(isDetailDisabled)
                .accessibilityLabel("Opens details with coordinates in multiple formats")
            }
            .alert("Location Error", isPresented: $showAlert) {
                Button("OK") { locationManager.error = nil }
            } message: {
                Text(locationManager.error?.localizedDescription ?? "An unknown error occurred.")
            }
            .sheet(isPresented: $showSettings) { SettingsView(locationManager: locationManager) }
            .sheet(isPresented: $showDetails) {
                if let location { DetailsView(location: location) }
            }
        }
        .onChange(of: locationManager.error != nil) { _, hasError in showAlert = hasError }
        .onChange(of: location, initial: true) { oldLocation, _ in
            if oldLocation == nil || !locationManager.autoUpdate {
                updateCameraPosition(span: zoom.span)
            }
        }
    }

    // MARK: - Methods
    
    private func updateCameraPosition(span: MKCoordinateSpan) {
        guard let location else { return }
        withAnimation(.easeInOut) {
            cameraPosition = .region(.init(center: location.coordinate, span: span))
        }
    }
}


// MARK: - Preview

#Preview {
    ContentView()
}
