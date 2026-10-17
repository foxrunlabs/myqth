import CoreLocation
import MapKit
import SwiftUI
import UIKit

struct ContentView: View {
    /// A map zoom preset corresponding to a Maidenhead grid subdivision.
    ///
    /// String raw values support persisting the selected preset with `AppStorage`. All cases are available in the zoom picker,
    /// where each case identifies itself.
    private enum ZoomLevel: String, CaseIterable, Identifiable {
        /// The zoom preset for viewing Maidenhead fields.
        case field

        /// The zoom preset for viewing Maidenhead squares.
        case square

        /// The zoom preset for viewing Maidenhead subsquares.
        case subsquare

        /// The coordinate span used when centering the map at this zoom level.
        var span: MKCoordinateSpan {
            switch self {
            case .field: .field
            case .square: .square
            case .subsquare: .subsquare
            }
        }
        
        /// The case itself, used as its stable identifier in the zoom picker.
        var id: Self { self }

        /// The user-facing name displayed in the zoom picker.
        var displayName: String {
            switch self {
            case .field: "Field"
            case .square: "Square"
            case .subsquare: "Subsquare"
            }
        }
    }
    
    // MARK: - Properties
    
    @Environment(\.openURL) private var openURL

    @AppStorage("net.thefoxrun.labs.MyQTH.callsign") private var callsign = ""
    @AppStorage("net.thefoxrun.labs.MyQTH.displayGrid") private var displayGrid = true
    @AppStorage("net.thefoxrun.labs.MyQTH.zoom") private var zoom = ZoomLevel.subsquare
    
    @State private var locationManager = LocationManager()
    
    @State private var cameraPosition: MapCameraPosition = .region(
        .init(center: CLLocationCoordinate2D(), span: .subsquare)
    )
    
    @State private var gridCells = MaidenheadGrid(
        region: .init(center: CLLocationCoordinate2D(), span: .subsquare)
    ).cells
    
    @State private var showAlert = false
    @State private var showSettings = false
    @State private var showDetails = false

    // MARK: - Computed Properties
    
    private var location: CLLocation? { locationManager.location }
    
    private var roundedCoordinate: CLLocationCoordinate2D? {
        guard let location else { return nil }
        
        let places = CLLocationCoordinate2D.FormatStyle.Precision.tenMeter.ddMinimumPlaces
        let latitude = location.coordinate.latitude.rounded(places: places)
        let longitude = location.coordinate.longitude.rounded(places: places)
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    private var maidenheadLocator: MaidenheadLocator? {
        guard let roundedCoordinate else { return nil }
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

                if let roundedCoordinate {
                    Marker(
                        callsign,
                        systemImage: "antenna.radiowaves.left.and.right",
                        coordinate: roundedCoordinate
                    )
                }
            }
            .onMapCameraChange(frequency: .continuous) { context in
                let cells = MaidenheadGrid(region: context.region).cells
                if cells.map(\.id) != gridCells.map(\.id) { gridCells = cells }
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
                if case .permissionDenied? = locationManager.error {
                    Button("Open Settings") {
                        locationManager.error = nil

                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                }

                Button("OK", role: .cancel) { locationManager.error = nil }
            } message: {
                Text(
                    locationManager.error?.localizedDescription
                        ?? "An unknown location error occurred."
                )
            }
            .sheet(isPresented: $showSettings) { SettingsView(locationManager: locationManager) }
            .sheet(isPresented: $showDetails) {
                if let location { DetailsView(location: location) }
            }
        }
        .onChange(of: locationManager.error != nil, initial: true) { _, hasError in
            showAlert = hasError
        }
        .onChange(of: location, initial: true) { oldLocation, _ in
            if oldLocation == nil || !locationManager.autoUpdate {
                updateCameraPosition(span: zoom.span)
            }
        }
    }

    // MARK: - Methods
    
    private func updateCameraPosition(span: MKCoordinateSpan) {
        guard let roundedCoordinate else { return }
        withAnimation(.easeInOut) {
            cameraPosition = .region(.init(center: roundedCoordinate, span: span))
        }
    }
}


// MARK: - Preview

#Preview {
    ContentView()
}
