import MapKit
import SwiftUI

/// Only generates cells intersecting the viewport, at a readable level of detail.
struct MaidenheadGrid {
    struct Cell: Identifiable {
        let id: String
        let center: CLLocationCoordinate2D
        let boundary: [MKMapPoint]
    }

    let cells: [Cell]

    /// Creates Maidenhead grid cells for the specified map viewport.
    ///
    /// Selects the finest available precision—subsquare, square, or field—whose cell dimensions fit within the viewport span
    /// no more than four times in either direction. Falls back to field precision for larger spans. Partial cells at viewport edges
    /// can increase the number of intersecting cells.
    ///
    /// Latitude coverage is clamped to the poles, and longitude coverage is limited to 360 degrees. Columns wrap across the
    /// international date line without generating duplicate cells. Each cell uses its geographic midpoint for its center and
    /// formatted locator identifier.
    ///
    /// Cell boundaries are closed map-point outlines clipped to latitudes of approximately ±85 degrees for
    /// Mercator projection. Cells entirely outside that range, or whose locator cannot be created, are omitted.
    ///
    /// - Parameter region: The viewport used to select grid precision and coverage. Its center must be a valid
    /// coordinate, and both span components must be finite and greater than zero. Otherwise, `cells` is empty.
    init(region: MKCoordinateRegion) {
        let latitudeSpan = region.span.latitudeDelta
        let longitudeSpan = region.span.longitudeDelta
        
        guard
            latitudeSpan.isFinite,
            longitudeSpan.isFinite,
            latitudeSpan > 0,
            longitudeSpan > 0,
            CLLocationCoordinate2DIsValid(region.center)
        else {
            cells = []
            return
        }

        let levels: [(span: MKCoordinateSpan, precision: MaidenheadLocator.FormatStyle.Precision)] = [
            (.subsquare, .subsquare), (.square, .square), (.field, .field)
        ]
        
        // Limit density in both dimensions, including on wide windows.
        let level = levels.first {
            latitudeSpan / $0.span.latitudeDelta <= 4 &&
            longitudeSpan / $0.span.longitudeDelta <= 4
        } ?? levels[2]
        
        let south = max(-90.0, region.center.latitude - latitudeSpan / 2.0)
        let north = min(90.0, region.center.latitude + latitudeSpan / 2.0)
        let west = region.center.longitude - min(360.0, longitudeSpan) / 2.0
        let east = region.center.longitude + min(360.0, longitudeSpan) / 2.0
        
        let height = level.span.latitudeDelta
        let width = level.span.longitudeDelta
        
        // Worldwide cell counts.
        let columns = Int((360.0 / width).rounded())
        let rows = Int((180.0 / height).rounded())
        
        // Shift latitude to a zero-based index and clamp rows to the world bounds.
        let firstRow = max(0, min(rows - 1, Int(floor((south + 90.0) / height))))
        
        // ceil - 1 excludes the next cell when the edge is exactly on a boundary.
        let lastRow = max(firstRow, min(rows - 1, Int(ceil((north + 90.0) / height)) - 1))

        // Leave columns unbounded here to allow date-line crossings; wrap them below.
        let firstColumn = Int(floor((west + 180.0) / width))
        
        // Include at most one world's worth of columns to avoid duplicate cells.
        let lastColumn = min(firstColumn + columns - 1, Int(ceil((east + 180.0) / width)) - 1)

        var visibleCells: [Cell] = []
        
        // Visit each column and row intersecting the viewport.
        for column in firstColumn...max(firstColumn, lastColumn) {
            // Wrap into 0..<columns; adding columns corrects negative remainders.
            let wrappedColumn = (column % columns + columns) % columns
            
            // Convert the column index to west/east longitude boundaries.
            let left = -180.0 + Double(wrappedColumn) * width
            let right = left + width
            
            for row in firstRow...lastRow {
                // Convert the row index to south/north latitude boundaries.
                let bottom = -90.0 + Double(row) * height
                let top = bottom + height
                
                // Use the cell midpoint for both its locator and label position.
                let center = CLLocationCoordinate2D(
                    latitude: bottom + height / 2.0,
                    longitude: left + width / 2.0
                )
                
                guard let locator = try? MaidenheadLocator(from: center) else { continue }
                
                // MapKit's Mercator projection cannot represent the poles.
                let lowerLatitude = max(-85, bottom)
                let upperLatitude = min(85, top)
                
                guard lowerLatitude < upperLatitude else { continue }
                
                // Repeat the first corner to close the outline, then project to map points.
                let boundary = [
                    CLLocationCoordinate2D(latitude: lowerLatitude, longitude: left),
                    CLLocationCoordinate2D(latitude: upperLatitude, longitude: left),
                    CLLocationCoordinate2D(latitude: upperLatitude, longitude: right),
                    CLLocationCoordinate2D(latitude: lowerLatitude, longitude: right),
                    CLLocationCoordinate2D(latitude: lowerLatitude, longitude: left)
                ].map { MKMapPoint($0) }
                
                visibleCells.append(Cell(
                    id: locator.formatted(precision: level.precision),
                    center: center,
                    boundary: boundary
                ))
            }
        }
        
        cells = visibleCells
    }
}


// MARK: - Maidenhead Grid Content

struct MaidenheadGridContent: MapContent {
    let cells: [MaidenheadGrid.Cell]

    var body: some MapContent {
        ForEach(cells) { cell in
            MapPolyline(points: cell.boundary)
                .stroke(.blue, lineWidth: 2)
        }
        
        ForEach(cells) { cell in
            Annotation(cell.id, coordinate: cell.center, anchor: .center) {
                Text(verbatim: cell.id)
                    .font(.caption.monospaced().weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 4))
                    .fixedSize()
                    .allowsHitTesting(false)
                    .accessibilityLabel("Maidenhead locator \(cell.id)")
            }
            .annotationTitles(.hidden)
        }
    }
}
