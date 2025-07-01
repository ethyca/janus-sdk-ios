# Janus SDK 
## iOS Implementation Guide

### Installation

#### Swift Package Manager

Open Xcode > File > Add Packages… and add "https://github.com/ethyca/janus-sdk-ios.git", or modify `Package.swift` as follows:

```swift
dependencies: [
    .package(url: "https://github.com/ethyca/janus-sdk-ios.git", from: "1.0.17")
]
```

#### CocoaPods

```ruby
source 'https://github.com/ethyca/janus-sdk-ios.git'

target 'YourApp' do
  pod 'JanusSDK', '1.0.17'
end
```

### Custom Logging

The Janus SDK supports custom logging implementations through the `JanusLogger` protocol. This is useful for debugging, monitoring, and integrating with your app's existing logging infrastructure.

#### JanusLogger Protocol

```swift
protocol JanusLogger {
    func log(
        level: JanusLogLevel,
        message: String,
        metadata: [String: String]?,
        error: Error?
    )
}

enum JanusLogLevel {
    case verbose, debug, info, warn, error
}
```

#### Setting a Custom Logger

If you have implemented your own custom logger implementation, be sure to call setLogger() prior to initialize() in order to receive logs that occur during the initialization of the SDK.

```swift
// Set custom logger BEFORE initializing Janus
let myCustomLogger = MyCustomJanusLogger()
Janus.setLogger(myCustomLogger)

// Now initialize Janus - logs during initialization will use your custom logger
let config = JanusConfiguration(
    apiHost: "https://privacy-plus.yourhost.com",
    propertyId: "FDS-A0B1C2"
)

Janus.initialize(config: config) { success, error in
    // Handle initialization result
}
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
                    privacyCenterHost: config.privacyCenterHost,
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
    apiHost: "https://privacy-plus.yourhost.com",             // 🌎 FidesPlus API server base URL (REQUIRED)
    privacyCenterHost: "https://privacy-center.yourhost.com", // 🏢 Privacy Center host URL - if not provided, Janus will use the apiHost
    propertyId: "FDS-A0B1C2",                                 // 🏢 Property identifier for this app
    ipLocation: true,                                         // 📍 Use IP-based geolocation (default true)
    region: "US-CA",                                          // 🌎 Provide if geolocation is false or fails
    fidesEvents: true,                                        // 🔄 Map JanusEvents to FidesJS events in WebViews (default true)
    autoShowExperience: true                                  // 🚀 Automatically show privacy experience after initialization (default true)
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

### Controlling Privacy Experience Display

By default, Janus will automatically show the privacy experience after successful initialization if `shouldShowExperience` returns true. You can control this behavior with the `autoShowExperience` configuration parameter.

#### Option 1: Automatic display (default)

```swift
// With autoShowExperience set to true (default), Janus will automatically
// show the privacy experience after initialization if shouldShowExperience is true
let config = JanusConfiguration(
    apiHost: "https://privacy-plus.yourhost.com",
    // Other parameters...
    autoShowExperience: true // Default behavior
)
```

#### Option 2: Manual control

```swift
// Disable automatic display by setting autoShowExperience to false
let config = JanusConfiguration(
    apiHost: "https://privacy-plus.yourhost.com",
    // Other parameters...
    autoShowExperience: false // Prevent automatic display
)

// Initialize Janus without showing the privacy experience immediately
Janus.initialize(config: config) { success, error in
    if success {
        // You can now decide when to show the experience
        
        // Check if the experience should be shown (based on consent status, etc.)
        if Janus.shouldShowExperience {
            // Show at the appropriate time in your app flow
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                    Janus.showExperience(from: rootVC)
                }
            }
        }
    }
}
```

### Region Detection and Access

JanusSDK provides methods to work directly with region detection and access the current region:

```swift
// Get the user's region by IP geolocation
Janus.getLocationByIPAddress { success, locationData, error in
    if success, let locationData = locationData {
        // Use the full location data
        let isoRegion = locationData.location // Format: "US-CA"
        let country = locationData.country    // Format: "US"
        let subRegion = locationData.region   // Format: "CA"
        let ipAddress = locationData.ip       // Format: "192.168.1.1"
        
        // Update UI with region information
        updateRegionUI(region: isoRegion ?? "")
    } else if let error = error {
        // Handle specific errors
        switch error {
        case let networkError as APIError.networkError:
            showNetworkError(networkError)
        case JanusError.invalidRegion:
            showLocationDetectionFailed()
        default:
            showGenericError()
        }
    }
}

// Access the current region being used by the SDK (after initialization)
let currentRegion = Janus.region
regionLabel.text = "Current Region: \(currentRegion)"
```

The `getLocationByIPAddress` method is particularly useful when:
- You want to show region information to users before showing a privacy experience
- You need to implement custom region selection UI based on detected region
- You want to give users the option to correct their detected region

The `region` property returns the region code that the SDK is currently using, which may come from:
- The region specified in the configuration during initialization
- The region detected via IP geolocation
- Empty string if no region has been determined yet

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
