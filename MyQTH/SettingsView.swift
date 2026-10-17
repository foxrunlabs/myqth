import SwiftUI

struct SettingsView: View {
    @Bindable var locationManager: LocationManager
    
    @AppStorage("net.thefoxrun.labs.MyQTH.callsign") private var callsign = ""
    @AppStorage("net.thefoxrun.labs.MyQTH.displayGrid") private var displayGrid = true
    @Environment(\.dismiss) private var dismiss
    private let contactURL = URL(string: "mailto:labs@thefoxrun.net")!
    private let supportURL = URL(string: "https://labs.thefoxrun.net/myqth/")!
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
                }
                
                Section("Support and Legal") {
                    Label("Version \(Bundle.main.versionString)", systemImage: "tag")
                    Link(destination: contactURL) { Label("Contact", systemImage: "envelope") }
                    Link(destination: supportURL) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                    
                    Link(destination: privacyURL) { Label("Privacy Policy", systemImage: "lock") }
                    NavigationLink {
                        LicenseView()
                    } label: {
                        Label("License", systemImage: "text.page")
                    }
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
