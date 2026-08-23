import SwiftUI

struct SettingsView: View {
    @Bindable var locationManager: LocationManager
    
    @AppStorage("net.thefoxrun.MyQTH.callsign") private var callsign = ""
    @Environment(\.dismiss) private var dismiss
    private let contactURL = URL(string: "mailto:foxrunlabs@icloud.com")!
    
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
                
                Section("About") {
                    Text(Bundle.main.copyright)
                    Text("Version " + Bundle.main.versionString)
                    Link(destination: contactURL) { Label("Contact", systemImage: "envelope") }
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
