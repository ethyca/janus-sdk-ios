//
//  WebViewEventTracker.swift
//  JanusExample
//
//  Created to track FidesJS events in WebViews
//

import Foundation
import WebKit
import Combine

/// A class to track FidesJS events from a specific WebView
class WebViewEventTracker: NSObject, WKScriptMessageHandler, ObservableObject {
    // The WebView this tracker is observing
    private weak var webView: WKWebView?
    
    // The ID of the WebView (for UI display purposes)
    private let webViewId: Int
    
    // List of events received from this WebView
    @Published var events: [String] = []
    
    // Count of events received from this WebView
    @Published var eventCount: Int = 0
    
    // FidesJS consent values from the WebView
    @Published var fidesConsent: [String: Bool] = [:]
    
    // Callback to notify parent when event count changes
    var onEventCountChanged: ((Int, Int) -> Void)?
    
    // Callback to notify parent when consent values change
    var onConsentValuesChanged: ((Int, [String: Bool]) -> Void)?
    
    /// Initialize with a WebView and its ID
    /// - Parameters:
    ///   - webView: The WebView to track
    ///   - webViewId: The ID to identify this WebView
    init(webView: WKWebView, webViewId: Int) {
        self.webView = webView
        self.webViewId = webViewId
        super.init()
        setupWebView()
    }
    
    /// Set up the WebView with a message handler and inject the event listening script
    private func setupWebView() {
        guard let webView = webView else { return }
        
        // Add this class as a message handler for the WebView
        webView.configuration.userContentController.add(self, name: "janusEventTracker")
        
        // Inject JavaScript to listen for FidesJS events
        injectEventListeningScript()
    }
    
    /// Inject JavaScript to listen for FidesJS events
    private func injectEventListeningScript() {
        let script = """
        (function() {
            // Map of all FidesJS events we want to listen for
            const fidesEvents = [
                'FidesInitializing',
                'FidesInitialized',
                'FidesUIShown',
                'FidesUIChanged', 
                'FidesModalClosed',
                'FidesUpdating',
                'FidesUpdated'
            ];
            
            // Add listeners for each FidesJS event
            fidesEvents.forEach(eventType => {
                window.addEventListener(eventType, event => {
                    // Create message to send to native code
                    const message = {
                        type: eventType,
                        data: event.detail || {}
                    };
                    
                    // Send to native through webkit message handler
                    window.webkit.messageHandlers.janusEventTracker.postMessage(message);
                    
                    // Also send current consent values when consent-related events occur
                    if (['FidesInitialized', 'FidesUpdated', 'FidesModalClosed'].includes(eventType)) {
                        if (window.Fides && window.Fides.consent) {
                            window.webkit.messageHandlers.janusEventTracker.postMessage({
                                type: 'ConsentValues',
                                data: { consent: window.Fides.consent }
                            });
                        }
                    }
                });
            });
            
            console.log('Janus WebView Event Tracker initialized');
        })();
        """
        
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView?.configuration.userContentController.addUserScript(userScript)
    }
    
    /// Fetch the current FidesJS consent values from the WebView
    func fetchCurrentConsentValues() {
        let script = """
        (function() {
            if (window.Fides && window.Fides.consent) {
                return window.Fides.consent;
            }
            return {};
        })();
        """
        
        webView?.evaluateJavaScript(script) { [weak self] (result, error) in
            if let error = error {
                print("Error fetching FidesJS consent: \(error.localizedDescription)")
                return
            }
            
            if let consentDict = result as? [String: Bool] {
                DispatchQueue.main.async {
                    self?.fidesConsent = consentDict
                    if let id = self?.webViewId {
                        self?.onConsentValuesChanged?(id, consentDict)
                    }
                }
            }
        }
    }
    
    /// Handle messages from the WebView
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "janusEventTracker",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            return
        }
        
        if type == "ConsentValues", let data = body["data"] as? [String: Any], let consent = data["consent"] as? [String: Bool] {
            // Update consent values
            DispatchQueue.main.async {
                self.fidesConsent = consent
                self.onConsentValuesChanged?(self.webViewId, consent)
            }
            return
        }
        
        // Add event data if available
        if let data = body["data"] as? [String: Any] {            
            // Check for consent values in event data
            if let consent = data["consent"] as? [String: Bool] {
                DispatchQueue.main.async {
                    self.fidesConsent = consent
                    self.onConsentValuesChanged?(self.webViewId, consent)
                }
            }
            
            // Create a description of the event
            var eventDescription = "FidesJS Event: \(type)"
            let dataString = formatEventData(data)
            if !dataString.isEmpty {
                eventDescription += "\nData: \(dataString)"
            }
            
            // Add the event to our list
            DispatchQueue.main.async {
                self.events.append(eventDescription)
                self.eventCount += 1
                self.onEventCountChanged?(self.webViewId, self.eventCount)
            }
        } else {
            // Handle events without data
            let eventDescription = "FidesJS Event: \(type)"
            
            // Add the event to our list
            DispatchQueue.main.async {
                self.events.append(eventDescription)
                self.eventCount += 1
                self.onEventCountChanged?(self.webViewId, self.eventCount)
            }
        }
        
        // Fetch updated consent values after certain events
        if ["FidesInitialized", "FidesUpdated", "FidesModalClosed"].contains(type) {
            fetchCurrentConsentValues()
        }
    }
    
    /// Format event data for display
    private func formatEventData(_ data: [String: Any]) -> String {
        var formattedParts: [String] = []
        
        // Format source if present
        if let source = data["source"] as? String {
            formattedParts.append("source: \(source)")
        }
        
        // Format consent values
        if let consent = data["consent"] as? [String: Bool] {
            let consentString = consent.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            formattedParts.append("consent: {\(consentString)}")
        }
        
        // Format fides_string
        if let fidesString = data["fides_string"] as? String {
            formattedParts.append("fides_string: \(fidesString)")
        }
        
        // Format extraDetails
        if let extraDetails = data["extraDetails"] as? [String: Any] {
            var extraDetailsParts: [String] = []
            
            if let servingComponent = extraDetails["servingComponent"] as? String {
                extraDetailsParts.append("servingComponent: \(servingComponent)")
            }
            
            if let shouldShowExperience = extraDetails["shouldShowExperience"] as? Bool {
                extraDetailsParts.append("shouldShowExperience: \(shouldShowExperience)")
            }
            
            if let consentMethod = extraDetails["consentMethod"] as? String {
                extraDetailsParts.append("consentMethod: \(consentMethod)")
            }
            
            if !extraDetailsParts.isEmpty {
                formattedParts.append("extraDetails: {\(extraDetailsParts.joined(separator: ", "))}")
            }
        }
        
        return formattedParts.joined(separator: ", ")
    }
    
    /// Clean up when this tracker is no longer needed
    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "janusEventTracker")
    }
} 
