import SwiftUI

struct SettingsView: View {
    @AppStorage("net.thefoxrun.MyQTH.autoUpdate") private var autoUpdate = false
    @Environment(\.dismiss) private var dismiss
    private let contactURL = URL(string: "mailto:foxrunlabs@icloud.com")!
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle(isOn: $autoUpdate) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Auto Update Position")
                            Text("May use more battery")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .sensoryFeedback(.selection, trigger: autoUpdate)
                    .disabled(true)
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
        SettingsView()
    }
}
