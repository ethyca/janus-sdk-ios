//
//  ContentView.swift
//  JanusExample
//
//  Created by Thabo Fletcher on 3/5/25.
//

import SwiftUI
import JanusSDK
import WebKit

// Local file imports
import Foundation // This is imported so we don't need to add it explicitly elsewhere

// Add this enum and struct before ContentView
enum ConfigurationType: String, CaseIterable {
    case ethyca = "Ethyca"
    case ethycaEmpty = "Ethyca (Empty)"
    case cookieHouse = "Cookie House (RC)"
    case cookieHouseNightly = "Cookie House (Nightly)"
    case custom = "Custom"
}

struct JanusConfig {
    var type: ConfigurationType = .ethyca
    var apiHost: String = "https://privacy.ethyca.com"
    var privacyCenterHost: String = ""
    var website: String = "https://ethyca.com"
    var propertyId: String? = "FDS-KSB4MF"
    var region: String? = nil
    var autoShowExperience: Bool = true

    static func forType(_ type: ConfigurationType) -> JanusConfig {
        switch type {
        case .ethyca:
            return JanusConfig()
        case .ethycaEmpty:
            return JanusConfig(
                type: .ethycaEmpty,
                apiHost: "https://privacy.ethyca.com",
                privacyCenterHost: "",
                website: "https://ethyca.com",
                propertyId: nil,
                region: nil,
                autoShowExperience: true
            )
        case .cookieHouse:
            return JanusConfig(
                type: .cookieHouse,
                apiHost: "https://privacy-plus-rc.fides-staging.ethyca.com/",
                privacyCenterHost: "",
                website: "https://cookiehouse-plus-rc.fides-staging.ethyca.com",
                propertyId: nil,
                region: nil,
                autoShowExperience: true
            )
        case .cookieHouseNightly:
            return JanusConfig(
                type: .cookieHouseNightly,
                apiHost: "https://privacy-plus-nightly.fides-staging.ethyca.com/",
                privacyCenterHost: "",
                website: "https://cookiehouse-plus-nightly.fides-staging.ethyca.com",
                propertyId: nil,
                region: nil,
                autoShowExperience: true
            )
        case .custom:
            if let saved = UserDefaults.standard.object(forKey: "CustomJanusConfig") as? [String: Any] {
                return JanusConfig(
                    type: .custom,
                    apiHost: saved["apiHost"] as? String ?? "",
                    privacyCenterHost: saved["privacyCenterHost"] as? String ?? "",
                    website: saved["website"] as? String ?? "",
                    propertyId: (saved["propertyId"] as? String)?.isEmpty == true ? nil : (saved["propertyId"] as? String),
                    region: (saved["region"] as? String)?.isEmpty == true ? nil : (saved["region"] as? String),
                    autoShowExperience: saved["autoShowExperience"] as? Bool ?? true
                )
            }
            return JanusConfig(type: .custom, apiHost: "", privacyCenterHost: "", website: "", propertyId: nil, region: nil, autoShowExperience: true)
        }
    }

    func save() {
        if type == .custom {
            UserDefaults.standard.set([
                "apiHost": apiHost,
                "privacyCenterHost": privacyCenterHost,
                "website": website,
                "propertyId": propertyId ?? "",
                "region": region ?? "",
                "autoShowExperience": autoShowExperience
            ], forKey: "CustomJanusConfig")
        }
    }
}

enum PresentationStyle: String, CaseIterable {
    case fullScreen = "Full Screen"
    case sheet = "Sheet"
}

struct ContentView: View {
    @EnvironmentObject var janusManager: JanusManager
    @State private var showFullExample = false
    @State private var showFullExampleSheet = false
    @State private var config = JanusConfig()
    @State private var selectedRegion = "US-CA"
    @State private var regionInput = ""
    @State private var presentationStyle: PresentationStyle = .fullScreen

    var isLaunchEnabled: Bool {
        if config.type == .custom {
            return !config.apiHost.isEmpty && !config.website.isEmpty
        }
        return true
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.checkerboard")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.blue)
                .padding(.bottom, 8)

            Text("Janus SDK Example")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 20)

            Picker("Configuration", selection: $config.type) {
                ForEach(ConfigurationType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .onChange(of: config.type) { newType in
                print("Config type changed to \(newType)")
                config = JanusConfig.forType(newType)
            }

            VStack(alignment: .leading, spacing: 8) {
                ConfigField(label: "API Host", value: $config.apiHost, isEnabled: config.type == .custom, placeholder: "https://privacy-center.example.com")
                ConfigField(label: "Privacy Center Host", value: $config.privacyCenterHost, isEnabled: config.type == .custom, placeholder: "https://privacy-center.example.com")
                ConfigField(label: "Website", value: $config.website, isEnabled: config.type == .custom, placeholder: "https://example.com")
                ConfigField(label: "Property ID (Optional)", value: Binding(
                    get: { config.propertyId ?? "" },
                    set: { config.propertyId = $0.isEmpty ? nil : $0 }
                ), isEnabled: config.type == .custom, placeholder: "EX-AMPLE123")
                ConfigField(label: "Region (Optional)", value: Binding(
                    get: { config.region ?? "" },
                    set: { config.region = $0.isEmpty ? nil : $0 }
                ), isEnabled: true, placeholder: "Leave empty to use IP location")
                
                Toggle("Auto-Show Experience", isOn: $config.autoShowExperience)
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Presentation Style")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Presentation Style", selection: $presentationStyle) {
                        ForEach(PresentationStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.vertical, 4)
            }
            .padding(.vertical, 20)

            Button(action: {
                config.save()
                janusManager.setConfig(config)
                
                switch presentationStyle {
                case .fullScreen:
                    showFullExample = true
                case .sheet:
                    showFullExampleSheet = true
                }
            }) {
                Text("Launch Full Example")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isLaunchEnabled ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!isLaunchEnabled)
            .padding(.horizontal, 40)

            Button(action: {
                janusManager.clearLocalStorage()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear Example Storage")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .fullScreenCover(isPresented: $showFullExample) {
                FullExampleView()
                    .environmentObject(janusManager)
            }
            .sheet(isPresented: $showFullExampleSheet) {
                FullExampleView()
                    .environmentObject(janusManager)
            }

            Spacer()
        }
        .padding()
    }
}

struct ConfigField: View {
    let label: String
    @Binding var value: String
    let isEnabled: Bool
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(!isEnabled)
                .autocapitalization(.none)
        }
    }
}

struct FullExampleView: View {
    @EnvironmentObject var janusManager: JanusManager
    @State private var showWebView = false
    @State private var showEventLog = false
    @State private var showWebViewEventLog = false
    @State private var primaryWebViewAutoSync = true
    @State private var backgroundWebViewAutoSync = true
    @State private var selectedRegion = "US-CA"
    @State private var regionInput = ""
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            if janusManager.isInitializing {
                VStack {
                    ProgressView()
                        .padding()
                    Text("Initializing Janus SDK...")
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    Section(content: {
                        HStack {
                            Text("Initialization:")
                            Spacer()
                            Text(janusManager.isInitialized ? "Success ✅" : "Not Ready ❌")
                                .foregroundColor(janusManager.isInitialized ? .green : .red)
                        }

                        HStack {
                            Text("Privacy Experience:")
                            Spacer()
                            if janusManager.hasExperience {
                                CopyButton {
                                    janusManager.copyExperienceJSON()
                                }
                            }
                            Text(janusManager.hasExperience ? "Available ✅" : "Not Available ❌")
                                .foregroundColor(janusManager.hasExperience ? .green : .red)
                        }

                        HStack {
                            Text("Region:")
                            Spacer()
                            Text(janusManager.currentRegion.isEmpty ? "Not set" : janusManager.currentRegion)
                                .foregroundColor(.secondary)
                        }

                        // IP Location testing button with inline loading state
                        HStack {
                            Text("IP Location:")
                            Spacer()

                            if janusManager.isInitializing {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 20, height: 20)
                            } else {
                                Button("Test Detection") {
                                    janusManager.testIPLocationDetection()
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .cornerRadius(6)
                                .disabled(janusManager.isInitializing)
                            }
                        }

                        if !janusManager.ipLocationDetails.isEmpty {
                            DisclosureGroup("IP Location Details") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(janusManager.ipLocationDetails.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                        HStack {
                                            Text(key)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text(value)
                                                .font(.caption.monospaced())
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }

                        if let error = janusManager.initializationError {
                            HStack {
                                Text("Error:")
                                Spacer()
                                Text(error)
                                    .foregroundColor(.red)
                            }

                            // Add visual examples for IP location errors
                            if let janusError = janusManager.initializationErrorType {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Error Handling Example:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    VStack(alignment: .leading, spacing: 8) {
                                        if case .noRegionProvidedIPLocationFailed = janusError {
                                            Text("IP Location Detection Failed")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(6)
                                                .background(Color.red)
                                                .cornerRadius(4)

                                            Text("We couldn't detect your region automatically. Please select your region or country to continue.")
                                                .font(.caption)
                                                .padding(.bottom, 4)

                                            // Separate picker and button completely with clear vertical layout
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("Select your region:")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)

                                                // Use a menu-style picker instead
                                                Menu {
                                                    Button("United States (CA)") { selectedRegion = "US-CA" }
                                                    Button("European Union") { selectedRegion = "EU" }
                                                    Button("United Kingdom") { selectedRegion = "GB" }
                                                } label: {
                                                    HStack {
                                                        Text(selectedRegion.isEmpty ? "Select Region" : selectedRegion)
                                                        Spacer()
                                                        Image(systemName: "chevron.down")
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 8)
                                                    .background(Color.gray.opacity(0.1))
                                                    .cornerRadius(8)
                                                    .frame(maxWidth: .infinity)
                                                }

                                                Text("Selected: \(selectedRegion)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .padding(.top, 4)

                                                // Clear separate button
                                                Button(action: {
                                                    janusManager.updateRegion(newRegion: selectedRegion)
                                                }) {
                                                    Text("Apply Region")
                                                        .fontWeight(.medium)
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.vertical, 12)
                                                        .background(Color.blue)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(8)
                                                }
                                                .padding(.top, 8)
                                                .buttonStyle(PlainButtonStyle())
                                                .disabled(selectedRegion.isEmpty)
                                            }
                                            .padding(.vertical, 8)
                                        } else if case .noRegionProvidedIPLocationFalse = janusError {
                                            Text("Region Required")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(6)
                                                .background(Color.orange)
                                                .cornerRadius(4)

                                            Text("A region is required when IP location detection is disabled. Please specify a region.")
                                                .font(.caption)
                                                .padding(.bottom, 4)

                                            // Region field example in a VStack with improved reliability
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("Enter your region:")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)

                                                TextField("Enter Region (e.g., US-CA)", text: $regionInput)
                                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                                    .autocapitalization(.none)
                                                    .disableAutocorrection(true)
                                                    .padding(.bottom, 4)

                                                // Clear separate button
                                                Button(action: {
                                                    janusManager.updateRegion(newRegion: regionInput)
                                                }) {
                                                    Text("Apply Region")
                                                        .fontWeight(.medium)
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.vertical, 12)
                                                        .background(regionInput.isEmpty ? Color.gray : Color.blue)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(8)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .disabled(regionInput.isEmpty)
                                            }
                                            .padding(.vertical, 8)
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        } else {
                            // Display a success message when region is set successfully
                            if !janusManager.currentRegion.isEmpty {
                                HStack {
                                    Text("Region set successfully:")
                                    Spacer()
                                    Text(janusManager.currentRegion)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }, header: {
                        Text("Janus SDK")
                    })

                    Section(content: {
                        if janusManager.hasExperience {
                            Button("Show Privacy Experience") {
                                janusManager.showPrivacyExperience()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(janusManager.isInitialized ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.bottom, 8)
                            .disabled(!janusManager.isInitialized)
                        } else {
                            Text("No Privacy Experience Available")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.secondary)
                                .cornerRadius(8)
                                .padding(.bottom, 8)
                        }

                        // Primary WebView button
                        VStack(alignment: .leading) {
                            Button("Show WebView") {
                                showWebView = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                            Toggle("Start Synced", isOn: $primaryWebViewAutoSync)
                                .font(.caption)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .padding(.bottom, 8)
                        }

                        // Background WebView button
                        VStack(alignment: .leading) {
                            Button("+ BG WebView") {
                                janusManager.addBackgroundWebView(autoSyncOnStart: backgroundWebViewAutoSync)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                            Toggle("Start Synced", isOn: $backgroundWebViewAutoSync)
                                .font(.caption)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                    }, header: {
                        Text("Actions")
                    })

                    Section(content: {
                        let metadata = janusManager.consentMetadata
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(metadata.createdAt?.formatted() ?? "Never")
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(metadata.updatedAt?.formatted() ?? "Never")
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Consent Method")
                            Spacer()
                            Text(janusManager.consentMethod.isEmpty ? "unknown" : janusManager.consentMethod)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Version Hash")
                            Spacer()
                            Text(janusManager.consentMetadata.versionHash.isEmpty ? "Not Available" : janusManager.consentMetadata.versionHash)
                                .foregroundColor(.secondary)
                        }
                    }, header: {
                        Text("Consent Metadata")
                    })

                    if !janusManager.fides_string.isEmpty {
                        Section(content: {
                            Text(janusManager.fides_string)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(3)
                                .truncationMode(.tail)
                        }, header: {
                            Text("Fides String")
                        })
                    }

                    Section(content: {
                        ForEach(janusManager.consentValues.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text(key)
                                Spacer()
                                Text(value ? "Allowed ✓" : "Denied ✗")
                                    .foregroundColor(value ? .green : .red)
                            }
                        }

                        if janusManager.consentValues.isEmpty {
                            Text("No consent values available")
                                .italic()
                                .foregroundColor(.gray)
                        }
                    }, header: {
                        Text("Consent Values")
                    })

                    Section(content: {
                        if !janusManager.events.isEmpty {
                            Button("Show All Events (\(janusManager.events.count))") {
                                showEventLog = true
                            }
                        } else {
                            Text("No events recorded")
                                .italic()
                                .foregroundColor(.gray)
                        }
                    }, header: {
                        HStack {
                            Text("Events")
                            Spacer()

                            // Event listener toggle in the middle of the header
                            Button(janusManager.listenerId == nil ? "Add Event Listener" : "Remove Event Listener") {
                                if janusManager.listenerId == nil {
                                    janusManager.addEventListeners()
                                } else {
                                    janusManager.removeEventListeners()
                                }
                            }
                            .font(.footnote)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            .disabled(!janusManager.isInitialized)

                            Spacer()

                            if janusManager.isListening {
                                Text("Listening")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            } else {
                                Text("Not listening")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    })

                    if !janusManager.backgroundWebViews.isEmpty {
                        Section(content: {
                            ForEach(janusManager.backgroundWebViews, id: \.id) { webViewEntry in
                                VStack {
                                    HStack {
                                        Text("WebView #\(webViewEntry.id)")

                                        Spacer()

                                        Button("Events (\(webViewEntry.eventCount))") {
                                            janusManager.selectWebView(id: webViewEntry.id)
                                            showWebViewEventLog = true
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        .foregroundColor(.blue)

                                        Button {
                                            janusManager.toggleExpandWebView(id: webViewEntry.id)
                                        } label: {
                                            Image(systemName: janusManager.isWebViewExpanded(id: webViewEntry.id) ? "chevron.up" : "chevron.down")
                                                .foregroundColor(.gray)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())

                                        Button {
                                            janusManager.removeBackgroundWebView(id: webViewEntry.id)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }

                                    // Display consent values when expanded
                                    if janusManager.isWebViewExpanded(id: webViewEntry.id) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("FidesJS Consent Values:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)

                                            if let consent = janusManager.webViewConsent[webViewEntry.id], !consent.isEmpty {
                                                ForEach(consent.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                                    HStack {
                                                        Text(key)
                                                            .font(.caption)
                                                        Spacer()
                                                        Text(value ? "Allowed ✓" : "Denied ✗")
                                                            .font(.caption)
                                                            .foregroundColor(value ? .green : .red)
                                                    }
                                                    .padding(.leading, 16)
                                                }
                                            } else {
                                                Text("No consent values available")
                                                    .font(.caption)
                                                    .italic()
                                                    .foregroundColor(.gray)
                                                    .padding(.leading, 16)
                                            }

                                            // Show Fides String if available
                                            if let fidesString = janusManager.webViewFidesString[webViewEntry.id], !fidesString.isEmpty {
                                                Text("Fides String:")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .padding(.top, 4)
                                                    .padding(.leading, 16)

                                                Text(fidesString)
                                                    .font(.caption.monospaced())
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                    .padding(.leading, 16)
                                            }

                                            // Refresh button
                                            Button("Refresh Values") {
                                                janusManager.webViewEventTrackers[webViewEntry.id]?.fetchCurrentConsentValues()
                                            }
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .padding(.top, 4)
                                            .padding(.leading, 16)
                                        }
                                        .padding(.top, 8)
                                        .padding(.bottom, 4)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(8)
                                        .padding(.vertical, 4)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }, header: {
                            Text("Background WebViews")
                        })
                    }
                }
                .sheet(isPresented: $showWebView) {
                    WebViewExample(autoSyncOnStart: primaryWebViewAutoSync)
                }
                .sheet(isPresented: $showEventLog) {
                    EventLogView()
                        .environmentObject(janusManager)
                }
                .sheet(isPresented: $showWebViewEventLog) {
                    WebViewEventLogView(webViewId: janusManager.selectedWebViewId)
                        .environmentObject(janusManager)
                }
            }
        }
        .onDisappear {
            // Only clean up WebViews when the view is actually being dismissed
            // not when it's temporarily covered by a modal presentation
            guard !presentationMode.wrappedValue.isPresented else { return }

            // Clean up all background WebViews when the FullExampleView is closed
            janusManager.removeAllBackgroundWebViews()
        }
    }
}

struct EventLogView: View {
    @EnvironmentObject var janusManager: JanusManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(janusManager.events.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(janusManager.events[index])
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Event Log")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        janusManager.clearEventLog()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WebViewExample: View {
    @State private var webView: WKWebView?
    @EnvironmentObject var janusManager: JanusManager
    @StateObject private var debugHelper = FidesDebugHelper()
    let autoSyncOnStart: Bool

    init(autoSyncOnStart: Bool = true) {
        self.autoSyncOnStart = autoSyncOnStart
    }

    var body: some View {
        VStack {
            HStack {
                Text("Primary Consent WebView")
                    .font(.headline)

                Spacer()

                // Debug button - directly runs Fides debug check when clicked
                // Results are logged to the Safari Web Inspector console
                Button(action: {
                    debugHelper.runFidesDebugCheck()
                }) {
                    Image(systemName: "ladybug")
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                // Modal button - shows the Fides modal
                Button(action: {
                    debugHelper.showFidesModal()
                }) {
                    Image(systemName: "dial.max")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding()

            // WebView takes the full screen
            if let webView = webView {
                WebViewWrapper(webView: webView)
            } else {
                ProgressView()
                    .onAppear {
                        let consentWebView = Janus.createConsentWebView(autoSyncOnStart: autoSyncOnStart)

                        // Enable debugging for WebView - can be removed in production apps
                        if #available(iOS 16.4, *) {
                            consentWebView.isInspectable = true
                        }

                        // Register for debugging
                        debugHelper.registerWebView(consentWebView)

                        webView = consentWebView

                        // Load configured website
                        if let url = URL(string: janusManager.websiteURL) {
                            let request = URLRequest(url: url)
                            consentWebView.load(request)
                        }
                    }
            }
        }
        .onDisappear {
            if let webView = webView {
                // Release the WebView when the view disappears
                Janus.releaseConsentWebView(webView)
                self.webView = nil
            }
        }
    }
}

// WebView wrapper to display a WKWebView in SwiftUI
struct WebViewWrapper: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
}

struct WebViewEventLogView: View {
    @EnvironmentObject var janusManager: JanusManager
    @Environment(\.dismiss) private var dismiss
    let webViewId: Int?

    var body: some View {
        NavigationView {
            Group {
                if let id = webViewId, let events = janusManager.webViewEvents[id] {
                    List {
                        if !events.isEmpty {
                            ForEach(events.indices, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(events[index])
                                        .font(.system(.body, design: .monospaced))
                                }
                                .padding(.vertical, 4)
                            }
                        } else {
                            Text("No FidesJS events recorded")
                                .italic()
                                .foregroundColor(.gray)
                        }
                    }
                    .navigationTitle("WebView #\(id) Events")
                } else {
                    Text("No WebView selected")
                        .italic()
                        .foregroundColor(.gray)
                        .navigationTitle("WebView Events")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Add a CopyButton struct at the end of the file
struct CopyButton: View {
    var action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button {
            action()

            // Visual feedback - briefly change color
            withAnimation {
                isPressed = true
            }

            // Reset after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    isPressed = false
                }
            }
        } label: {
            Image(systemName: isPressed ? "doc.on.doc.fill" : "doc.on.doc")
                .font(.caption)
                .foregroundColor(isPressed ? .green : .blue)
                .scaleEffect(isPressed ? 1.25 : 1.0)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

#Preview {
    ContentView()
        .environmentObject(JanusManager())
}

