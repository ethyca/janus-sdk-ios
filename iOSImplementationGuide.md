# Janus SDK 
## iOS Implementation Guide

### Installation

#### Swift Package Manager

Open Xcode > File > Add Packages… and add "https://github.com/ethyca/janus-sdk-ios.git", or modify `Package.swift` as follows:

```swift
dependencies: [
    .package(url: "https://github.com/ethyca/janus-sdk-ios.git", from: "1.0.2")
]
```

#### CocoaPods

```ruby
source 'https://github.com/ethyca/janus-sdk-ios.git'

target 'YourApp' do
  pod 'JanusSDK', '1.0.2'
end
```

### Initialization

📌 Initialize the SDK in `AppDelegate` or `SceneDelegate`

Before using Janus, initialize it inside `application(_:didFinishLaunchingWithOptions:)`. Janus must be fully initialized before any of its functions are available for use. All code that interacts with Janus should wait for the callback from `initialize()` to execute.

In addition, most of the errors from initialization will come back on this callback as an error event (see `JanusError` in the main documentation). Errors should be handled gracefully (i.e., if the region could not be determined, presenting a region selector to the user) and `initialize()` should be called again with new configuration data.

### Error Handling

The SDK provides specific error types through the `JanusError` enum that help you understand what went wrong during initialization. Handling these errors appropriately is crucial for a good user experience. For example:

- If `noRegionProvided` occurs, show a region selector to the user and reinitialize
- For `networkError`, provide a retry option
- With `invalidConfiguration`, check your configuration values for correctness

Here's a complete example of initialization with proper error handling:

```swift
import JanusSDK

Janus.initialize(config: config) { success, error in
    if success {
        // ✅ Initialization complete, Janus is now ready to use
    } else if let janusError = error as? JanusError {
        // Handle specific error types
        switch janusError {
        case .noRegionProvided:
            // Show region selector to user, then reinitialize with selected region
            presentRegionSelector { selectedRegion in
                let newConfig = JanusConfiguration(
                    apiHost: config.apiHost,
                    propertyId: config.propertyId,
                    ipLocation: false,
                    region: selectedRegion
                )
                Janus.initialize(config: newConfig) { /* handle result */ }
            }
        case .networkError(let error):
            // Show network error and retry option
            presentNetworkError(error: error) {
                Janus.initialize(config: config) { /* handle result */ }
            }
        case .invalidConfiguration:
            // Log the error and check configuration values
            debugPrint("Invalid configuration provided: \(config)")
        case .apiError(let message):
            // Handle API-specific errors
            debugPrint("API error occurred: \(message)")
        case .invalidRegion:
            // Handle invalid region code
            debugPrint("Invalid region code provided: \(config.region ?? "nil")")
        case .invalidExperience:
            // Handle missing or invalid experience data
            debugPrint("Invalid or missing privacy experience data")
        default:
            // Generic error handling
            debugPrint("An unexpected error occurred: \(janusError.localizedDescription)")
        }
    }
}
```

> Note: The `presentRegionSelector` and `presentNetworkError` functions in the example above are placeholders for your app's UI components and are not part of the JanusSDK.

📌 Sample Configuration

```swift
// Configure Janus with required credentials and settings
let config = JanusConfiguration(
    apiHost: "https://host.com",    // 🌎 Fides base URL
    propertyId: "FDS-A0B1C2",       // 🏢 Property identifier for this app
    ipLocation: true,               // 📍 Use IP-based geolocation
    region: "US-CA",                // 🌎 Provide if geolocation is false or fails, overrides ip location
    fidesEvents: true               // 🔄 Map JanusEvents to FidesJS events in WebViews (defaults to true)
)
```

### Display Privacy Notice

📌 Subscribe to Consent Events

Before showing the privacy notice, listen for consent-related events.

```swift
let listenerId = Janus.addConsentEventListener { event in
    // ✅ Handle consent event by event.type
    // additional properties may be available on event.detail
}

// ✅ Remove the event listener when no longer needed
Janus.removeConsentEventListener(listenerId: listenerId)
```

📌 Show the Privacy Notice

```swift
// Example of conditionally showing a button based on hasExperience
// This might be in your SwiftUI view:
if Janus.hasExperience {
    Button("Show Privacy Experience") {
        // When the button is tapped, show the experience
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            Janus.showExperience(from: viewController)
        }
    }
}

// In UIKit you might do:
privacyButton.isHidden = !Janus.hasExperience

// The showExperience method already checks hasExperience internally,
// so you don't need to check it again before calling the method:
@IBAction func showPrivacyExperience(_ sender: UIButton) {
    Janus.showExperience(from: self) // 'self' should be your UIViewController
}
```

### Check Consent Status

```swift
// Get a single consent value
let analyticsConsent = Janus.consent["analytics"] ?? false

// Get all the user's consent choices
let consent = Janus.consent

// List of IAB strings like CPzHq4APzHq4AAMABBENAUEAALAAAEOAAAAAAEAEACACAAAA,1~61.70
let fides_string = Janus.fides_string
```

### WKWebView Integration

```swift
// Get an auto-syncing WebView instance
let webView = Janus.createConsentWebView()

// Load the WebView with an application that includes FidesJS
let request = URLRequest(url: URL(string: "https://your-fides-enabled-url.com")!)
webView.load(request)

// IMPORTANT: Release the WebView when you're done with it to prevent memory leaks
// This is typically done in deinit or when the view controller is being destroyed
Janus.releaseConsentWebView(webView)
```

⚠️ **Important:** Always call `releaseConsentWebView()` when you're done with a WebView to prevent memory leaks. WebKit's script message handlers require explicit cleanup, and failing to release the WebView properly can lead to resource issues.
