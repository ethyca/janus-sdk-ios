//
//  FidesDebugHelper.swift
//  JanusExample
//
//  Created by Thabo Fletcher on 3/7/25.
//

import Foundation
import WebKit
import Combine
// No need to import JanusSDK as we don't directly use any of its functionality

// MARK: - Debug Helper (Optional)
// This class contains debugging utilities that are not required for a production implementation
// Developers can remove this entire class and related UI elements in their own apps
class FidesDebugHelper: NSObject, WKScriptMessageHandler, ObservableObject {
    // Store a reference to the WebView for debugging purposes
    private var currentWebView: WKWebView?
    
    // Register a WebView for debugging functionality
    func registerWebView(_ webView: WKWebView) {
        self.currentWebView = webView
        
        // Setup message handlers for debugging
        webView.configuration.userContentController.add(self, name: "fidesDebug")
        
        print("WebView registered for debugging")
    }
    
    // Cleanup when the helper is deinitialized
    deinit {
        if let webView = currentWebView {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "fidesDebug")
        }
    }
    
    // WKScriptMessageHandler implementation
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let messageBody = message.body as? [String: Any], 
           let type = messageBody["type"] as? String {
            if type == "FidesEvent" && messageBody["eventType"] != nil {
                let eventType = messageBody["eventType"] as! String
                print("📣 FIDES EVENT: \(eventType)")
                if let detail = messageBody["detail"] as? [String: Any] {
                    print("📝 Detail: \(detail)")
                }
            } else if type == "debug" {
                if let message = messageBody["message"] as? String {
                    print("🔍 DEBUG: \(message)")
                    if let data = messageBody["data"], !(data is NSNull) {
                        print("📊 Data: \(data)")
                    }
                }
            } else {
                print("JS Message: \(message.name) - \(messageBody)")
            }
        } else {
            print("JS Message: \(message.name) - \(message.body)")
        }
    }
    
    // Method to show the Fides modal
    func showFidesModal() {
        guard let webView = currentWebView else {
            print("Error: No WebView registered")
            return
        }
        
        print("Attempting to show Fides modal...")
        
        let script = """
        (function() {
            if (window.Fides && typeof window.Fides.showModal === 'function') {
                // Log using window.Janus.log from JavaScript
                window.Janus.log('Attempting to show Fides modal...', null, 'info');
                window.Fides.showModal();
                window.Janus.log('Fides.showModal() called successfully', null, 'info');
                return true;
            } else {
                window.Janus.log('Error: Fides.showModal not available', null, 'error');
                return false;
            }
        })();
        """
        
        webView.evaluateJavaScript(script) { (result: Any?, error: Error?) in
            if let error = error {
                print("Error showing Fides modal: \(error.localizedDescription)")
            } else if let success = result as? Bool, success {
                print("Fides modal shown")
            } else {
                print("Failed to show Fides modal")
            }
        }
    }
    
    // Method to run debug checks directly in the console
    // This is triggered by the ladybug button in the UI
    // To view results In Safari:
    // Enable Develop menu in Preferences > Advanced
    // Go to Develop > [Your Device/Simulator] > [WebView]
    // Logs should also appear in Xcode console
    func runFidesDebugCheck() {
        guard let webView = currentWebView else {
            print("Error: No WebView registered")
            return
        }
        
        // Log to console directly - don't use JSLogger from Swift
        print("Starting Fides debug check...")
        
        let script = """
        (function() {
            // Use window.Janus.log for all logging within JavaScript
            window.Janus.log('Starting Fides debug check...');
            
            // Check for Fides object
            if (window.Fides) {
                const version = window.Fides.fides_meta?.version || 'unknown';
                window.Janus.log(`Fides object found! Version: ${version}`);
                
                // List available methods on Fides
                const methods = [];
                for (const key in window.Fides) {
                    if (typeof window.Fides[key] === 'function') {
                        methods.push(key);
                    }
                }
                window.Janus.log(`Available Fides methods: ${methods.join(', ')}`);
                
                // Check consent state
                if (window.Fides.consent) {
                    window.Janus.log('Current consent values: ', window.Fides.consent);
                }
                
                // Register event listeners for all Fides events
                const fidesEvents = [
                    'FidesInitializing', 
                    'FidesInitialized',
                    'FidesUpdating',
                    'FidesUpdated',
                    'FidesUIShown',
                    'FidesUIChanged',
                    'FidesModalClosed'
                ];
                
                // Function to handle and log Fides events
                function handleFidesEvent(event) {
                    const eventType = event.type;
                    let eventDetail = {
                        consent: event.detail?.consent,
                        fides_string: event.detail?.fides_string
                    };
                    
                    if (event.detail?.extraDetails) {
                        eventDetail.extraDetails = {
                            servingComponent: event.detail.extraDetails.servingComponent,
                            shouldShowExperience: event.detail.extraDetails.shouldShowExperience,
                            consentMethod: event.detail.extraDetails.consentMethod
                        };
                    }
                    
                    // Send to both consoles using the Janus log function
                    window.webkit.messageHandlers.fidesDebug.postMessage({
                        type: 'FidesEvent',
                        eventType: eventType,
                        detail: eventDetail
                    });
                    
                    // Log Fides events with Janus logger
                    window.Janus.log(`FIDES EVENT: ${eventType}`, eventDetail, 'FidesEvent');
                }
                
                // Add listeners for all events
                fidesEvents.forEach(eventType => {
                    window.addEventListener(eventType, handleFidesEvent);
                    window.Janus.log(`Registered listener for ${eventType}`);
                });
                
                window.Janus.log('Debug check complete. Fides event listeners registered. Event info will appear in both Safari and Xcode console.');
                return true;
            } else {
                window.Janus.log('Error: Fides object not found!', null, 'error');
                return false;
            }
        })();
        """
        
        webView.evaluateJavaScript(script) { (result: Any?, error: Error?) in
            if let error = error {
                print("Error executing debug script: \(error.localizedDescription)")
            } else {
                print("Debug script executed in Safari console")
            }
        }
    }
} 
