//
//  JanusExampleApp.swift
//  JanusExample
//
//  Created by Thabo Fletcher on 3/5/25.
//

import SwiftUI
import JanusSDK
import WebKit
import UIKit

// Only import the specific event we added that's not part of the public API
import class JanusSDK.ConsentUpdatedFromWebViewEvent

@main
struct JanusExampleApp: App {
    @StateObject private var janusManager = JanusManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(janusManager)
        }
    }
}

class JanusManager: ObservableObject {
    @Published var isInitialized: Bool = false
    @Published var initializationError: String?
    @Published var listenerId: String?
    @Published var consentValues: [String: Bool] = [:]
    @Published var consentMetadata: ConsentMetadata = Janus.consentMetadata
    @Published var events: [String] = []
    @Published var isListening: Bool = false
    @Published var isInitializing: Bool = false
    
    // Add hasExperience property
    @Published var hasExperience: Bool = false
    
    // Configuration
    private var config: JanusConfig?
    
    // Track background WebViews
    @Published var backgroundWebViews: [(id: Int, webView: WKWebView, eventCount: Int)] = []
    private var nextWebViewId: Int = 1
    
    // WebView event trackers
    public var webViewEventTrackers: [Int: WebViewEventTracker] = [:]
    
    // Track events for specific WebViews
    @Published var webViewEvents: [Int: [String]] = [:]
    
    // Track FidesJS consent values for each WebView
    @Published var webViewConsent: [Int: [String: Bool]] = [:]
    
    // Track which WebViews are expanded in the UI
    @Published var expandedWebViews: Set<Int> = []
    
    // Track currently selected WebView for event display
    @Published var selectedWebViewId: Int? = nil
    
    func setConfig(_ config: JanusConfig) {
        self.config = config
        setupJanus()
    }
    
    func setupJanus() {
        guard let config = config else { return }
        
        isInitializing = true
        isInitialized = false
        initializationError = nil
        hasExperience = false
        
        let janusConfig = JanusConfiguration(
            apiHost: config.apiHost,
            propertyId: config.propertyId,
            ipLocation: config.region == nil, // Only use IP location if no region is provided
            region: config.region
        )
        
        Janus.initialize(config: janusConfig) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isInitializing = false
                self?.isInitialized = success
                if let error = error {
                    self?.initializationError = error.localizedDescription
                } else if success {
                    self?.refreshConsentValues()
                    self?.addEventListeners()
                    self?.hasExperience = Janus.hasExperience
                }
            }
        }
    }
    
    // Helper to get the configured website URL
    var websiteURL: String {
        config?.website ?? "https://ethyca.com"
    }
    
    func refreshConsentValues() {
        consentValues = Janus.consent
        consentMetadata = Janus.consentMetadata
        hasExperience = Janus.hasExperience
    }
    
    func showPrivacyExperience() {
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Error: Unable to find root view controller")
            return
        }
        
        // Find the topmost presented view controller
        var topmostViewController = rootViewController
        while let presentedViewController = topmostViewController.presentedViewController {
            topmostViewController = presentedViewController
        }
        
        // Call showExperience with the topmost view controller
        Janus.showExperience(from: topmostViewController)
    }
    
    func addEventListeners() {
        // Set hasExperience value
        hasExperience = Janus.hasExperience
        
        listenerId = Janus.addConsentEventListener { [weak self] event in
            DispatchQueue.main.async {
                // Base event description
                var eventDescription = "Event: \(event.type)"
                
                // Add event data information if available based on event type
                
                // WebView events
                if let uiChangedEvent = event as? WebViewFidesUIChangedEvent {
                    if let interaction = Mirror(reflecting: uiChangedEvent).children.first(where: { $0.label == "interaction" })?.value as? [String: Bool] {
                        let dataString = interaction.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                        eventDescription += "\nData: \(dataString)"
                    }
                } else if let updatingEvent = event as? WebViewFidesUpdatingEvent {
                    if let consentIntended = Mirror(reflecting: updatingEvent).children.first(where: { $0.label == "consentIntended" })?.value as? [String: Bool] {
                        let dataString = consentIntended.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                        eventDescription += "\nData: \(dataString)"
                    }
                } else if let initializedEvent = event as? WebViewFidesInitializedEvent {
                    eventDescription += "\nData: shouldShowExperience: \(initializedEvent.shouldShowExperience)"
                } else if let modalClosedEvent = event as? WebViewFidesModalClosedEvent {
                    if let consentMethod = Mirror(reflecting: modalClosedEvent).children.first(where: { $0.label == "consentMethod" })?.value as? String {
                        eventDescription += "\nData: consentMethod: \(consentMethod)"
                    }
                } 
                // Standard experience events
                else if let interactionEvent = event as? ExperienceInteractionEvent {
                    if let interaction = Mirror(reflecting: interactionEvent).children.first(where: { $0.label == "interaction" })?.value as? [String: Bool] {
                        let dataString = interaction.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                        eventDescription += "\nData: \(dataString)"
                    }
                } else if let closedEvent = event as? ExperienceClosedEvent {
                    if let closeMethod = Mirror(reflecting: closedEvent).children.first(where: { $0.label == "closeMethod" })?.value as? String {
                        eventDescription += "\nData: closeMethod: \(closeMethod)"
                    }
                } else if let updatingEvent = event as? ExperienceSelectionUpdatingEvent {
                    if let consentIntended = Mirror(reflecting: updatingEvent).children.first(where: { $0.label == "consentIntended" })?.value as? [String: Bool] {
                        let dataString = consentIntended.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                        eventDescription += "\nData: \(dataString)"
                    }
                }
                
                self?.events.append(eventDescription)
                // Refresh consent values for ConsentUpdatedFromWebViewEvent and ExperienceSelectionUpdatedEvent
                if event is ConsentUpdatedFromWebViewEvent || event is ExperienceSelectionUpdatedEvent {
                    self?.refreshConsentValues()
                }
                
                // Update hasExperience for any event that might affect the privacy experience
                if event.type == "experienceLoaded" || event.type == "experienceUpdated" {
                    self?.hasExperience = Janus.hasExperience
                }
            }
        }
        
        isListening = (listenerId != nil)
    }
    
    func removeEventListeners() {
        if let id = listenerId {
            Janus.removeConsentEventListener(listenerId: id)
            listenerId = nil
            isListening = false
        }
    }
    
    // Clean up resources when the app is closing
    deinit {
        removeEventListeners()
    }
    
    func clearEventLog() {
        events.removeAll()
    }
    
    func clearLocalStorage() {
        // Clear HTTP cookies
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        print("All HTTP cookies deleted")
        
        // Clear WebView storage
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                dataStore.removeData(ofTypes: record.dataTypes, for: [record]) {
                    print("WebView storage record deleted: \(record)")
                }
            }
        }
        
        // Clear Janus SDK storage
        Janus.clearConsent(clearMetadata: true)
        
        // Reset consent values
        consentValues.removeAll()
        
        // Clear events
        events.removeAll()
        
        // Clear WebView events
        webViewEvents.removeAll()
        
        // Clear WebView consent
        webViewConsent.removeAll()
    }
    
    // Add a background WebView to the manager
    func addBackgroundWebView(autoSyncOnStart: Bool = true) {
        let consentWebView = Janus.createConsentWebView(autoSyncOnStart: autoSyncOnStart)
        
        // Enable debugging for WebView
        if #available(iOS 16.4, *) {
            consentWebView.isInspectable = true
        }
        
        // Create webview entry with unique ID
        let webViewId = nextWebViewId
        nextWebViewId += 1
        
        // Create a tuple with the WebView and initial event count
        let webViewEntry = (id: webViewId, webView: consentWebView, eventCount: 0)
        backgroundWebViews.append(webViewEntry)
        
        // Initialize empty event array for this WebView
        webViewEvents[webViewId] = []
        
        // Initialize empty consent values for this WebView
        webViewConsent[webViewId] = [:]
        
        // Create and store a tracker for this WebView
        let tracker = WebViewEventTracker(webView: consentWebView, webViewId: webViewId)
        
        // Set callbacks
        tracker.onEventCountChanged = { [weak self] id, count in
            self?.updateWebViewEventCount(id: id, count: count)
            if let events = self?.webViewEventTrackers[id]?.events {
                self?.webViewEvents[id] = events
            }
        }
        
        tracker.onConsentValuesChanged = { [weak self] id, consent in
            self?.webViewConsent[id] = consent
        }
        
        webViewEventTrackers[webViewId] = tracker
        
        // Load the configured website
        if let url = URL(string: websiteURL) {
            let request = URLRequest(url: url)
            consentWebView.load(request)
        }
    }
    
    // Remove a background WebView by ID
    func removeBackgroundWebView(id: Int) {
        if let index = backgroundWebViews.firstIndex(where: { $0.id == id }),
           index < backgroundWebViews.count {
            // Get the WebView to release
            let webView = backgroundWebViews[index].webView
            
            // Remove from our managed array
            backgroundWebViews.remove(at: index)
            
            // Remove the event tracker
            webViewEventTrackers.removeValue(forKey: id)
            
            // Remove events for this WebView
            webViewEvents.removeValue(forKey: id)
            
            // Remove consent values for this WebView
            webViewConsent.removeValue(forKey: id)
            
            // Remove from expanded set if needed
            expandedWebViews.remove(id)
            
            // If this was the selected WebView, clear the selection
            if selectedWebViewId == id {
                selectedWebViewId = nil
            }
            
            // Tell Janus to release it
            Janus.releaseConsentWebView(webView)
        }
    }
    
    // Update the event count for a specific WebView
    private func updateWebViewEventCount(id: Int, count: Int) {
        if let index = backgroundWebViews.firstIndex(where: { $0.id == id }) {
            var webView = backgroundWebViews[index]
            webView.eventCount = count
            backgroundWebViews[index] = webView
        }
    }
    
    // Select a WebView to view its events
    func selectWebView(id: Int) {
        selectedWebViewId = id
    }
    
    // Toggle the expanded state of a WebView
    func toggleExpandWebView(id: Int) {
        if expandedWebViews.contains(id) {
            expandedWebViews.remove(id)
        } else {
            expandedWebViews.insert(id)
            // Fetch the latest consent values when expanding
            webViewEventTrackers[id]?.fetchCurrentConsentValues()
        }
    }
    
    // Check if a WebView is expanded
    func isWebViewExpanded(id: Int) -> Bool {
        return expandedWebViews.contains(id)
    }
    
    // Remove all background WebViews at once
    func removeAllBackgroundWebViews() {
        // Release all WebViews in a single pass
        for entry in backgroundWebViews {
            let webView = entry.webView
            // Tell Janus to release it
            Janus.releaseConsentWebView(webView)
        }
        
        // Clear all data structures at once instead of one by one
        backgroundWebViews.removeAll()
        webViewEventTrackers.removeAll()
        webViewEvents.removeAll()
        webViewConsent.removeAll()
        expandedWebViews.removeAll()
        selectedWebViewId = nil
        
        print("Removed all background WebViews and cleared associated data")
    }
    
    // Copy current experience to clipboard with enhanced encoding
    func copyExperienceJSON() {
        guard let experience = Janus.currentExperience else { return }
        
        // Create a JSON encoder with the same custom date handling as the decoder
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        // Use a custom ISO8601 date encoding strategy to match the decoder
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            
            // Create a formatter that handles fractional seconds
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            let dateString = formatter.string(from: date)
            try container.encode(dateString)
        }
        
        do {
            let data = try encoder.encode(experience)
            if let jsonString = String(data: data, encoding: .utf8) {
                UIPasteboard.general.string = jsonString
                print("Experience JSON copied to clipboard")
            }
        } catch {
            print("Error encoding experience: \(error)")
        }
    }
}
