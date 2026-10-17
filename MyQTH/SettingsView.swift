import SwiftUI

struct SettingsView: View {
    @Bindable var locationManager: LocationManager
    
    @AppStorage("net.thefoxrun.labs.MyQTH.callsign") private var callsign = ""
    @AppStorage("net.thefoxrun.labs.MyQTH.displayGrid") private var displayGrid = true
    @Environment(\.dismiss) private var dismiss
    private let contactURL = URL(string: "mailto:labs@thefoxrun.net")!
    private let privacyURL = URL(string: "https://labs.thefoxrun.net/myqth/privacy.html")!
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    LabeledContent("Callsign") {
                        TextField("Callsign", text: $callsign)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Toggle(isOn: $displayGrid) {
                        Text("Maidenhead Locator Grid")
                    }
                    .sensoryFeedback(.selection, trigger: displayGrid)
                    
                    Toggle(isOn: $locationManager.autoUpdate) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Auto Update Position")
                            Text("May use more battery")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .sensoryFeedback(.selection, trigger: locationManager.autoUpdate)
                }
                
                Section("Support and Legal") {
                    
                    Text("Version " + Bundle.main.versionString)
                    Link(destination: contactURL) { Label("Contact", systemImage: "envelope") }
                    Link(destination: privacyURL) { Label("Privacy Policy", systemImage: "lock") }
                    Text(Bundle.main.copyright)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var showSettings = true
    
    VStack {
        Button("Show Settings") { showSettings = true }
    }
    .sheet(isPresented: $showSettings) {
        SettingsView(locationManager: LocationManager())
    }
}
