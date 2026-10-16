# Janus SDK 
## iOS Implementation Guide

### Requirements

- iOS 15 or later
- Xcode 26.0 or later. We build each release with Xcode 26.0.1, the oldest Xcode 26 available to our build machines, and it uses the same Swift 6.2 compiler as Xcode 26.0, so any Xcode from 26.0 on can read it.

### Installation

#### Swift Package Manager

Open Xcode > File > Add Packages… and add "https://github.com/ethyca/janus-sdk-ios.git", or modify `Package.swift` as follows:

```swift
dependencies: [
    .package(url: "https://github.com/ethyca/janus-sdk-ios.git", from: "1.2.0")
]
```

#### CocoaPods

JanusSDK isn't published to the CocoaPods trunk, so point CocoaPods at its podspec directly. No `source` line is needed:

```ruby
target 'YourApp' do
  pod 'JanusSDK', :podspec => 'https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.2.0/JanusSDK.podspec'
end
```

To upgrade, change the version in the URL.

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

`error.localizedDescription` describes the case (for example `Authentication failed with the API`, which means the privacy-experience endpoint returned 401/403 — usually `apiHost` pointing at an authenticated API host rather than the Privacy Center), and `(error as? JanusError)?.caseName` gives the case as a stable string for logging.

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
                    region: selectedRegion,
                    consentFlagType: config.consentFlagType,
                    consentNonApplicableFlagMode: config.consentNonApplicableFlagMode
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
    autoShowExperience: true,                                 // 🚀 Automatically show privacy experience after initialization (default true)
    saveUserPreferencesToFides: true,                         // 💾 Save user preferences to Fides via privacy-preferences API (default true)
    saveNoticesServedToFides: true,                           // 💾 Save notices served to Fides via notices-served API (default true)
    consentFlagType: .boolean,                                // 🎯 Format for consent values (default boolean)
    consentNonApplicableFlagMode: .omit,                      // 🔄 Handle non-applicable notices (default omit)
    enableATT: true,                                          // 📲 Request Apple ATT permission before showing the privacy experience (default false, iOS 14+)
    enableBannerMode: true                                    // 🪧 Show banner_and_modal experiences as a compact banner first (default false)
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

// Fides string in format TC_STRING,AC_STRING,GPP_STRING,NC_STRING
// TC_STRING: IAB TCF string, AC_STRING: Google Additional Consent, 
// GPP_STRING: IAB GPP string, NC_STRING: Base64 Notice Consent preferences
let fides_string = Janus.fides_string
```

### Programmatic Consent Updates

Use `setConsent()` to write consent values directly to the SDK from native code — without showing the privacy experience UI. This is intended for two scenarios:

1. **Bidirectional WebView sync** — your app hosts a FidesJS page in a custom `WKWebView` and needs to push web-originated consent into native storage via a JS bridge.
2. **Legacy consent migration** — users already consented through an older flow; carry their choice into the SDK so they aren't re-prompted. Call `setConsent()` after `initialize` completes and before the experience shows, with `autoShowExperience` turned off. `setConsent()` only saves to Fides when an experience is loaded, so a call made before then stores consent on the device and never sends it to Fides. Pass the external provider consent method so Fides records the consent as carried over.

```swift
// Minimal call — local persist only, no server sync
Janus.setConsent(values: ["analytics": true, "marketing": false])

// With a fides string (e.g. from a FidesJS FidesUpdated event)
Janus.setConsent(
    values: ["analytics": true],
    fidesString: "CPz4OMAP...",
    consentMethod: .fidesJsUpdate
)

// With server sync — requires an experience to be loaded
// Silently no-ops the network call if no experience is available
Janus.setConsent(
    values: ["analytics": true],
    consentMethod: .save,
    saveToFides: true
)

// Migrating consent recorded before Janus. Call after initialize completes: the Fides save needs a loaded experience
// The method lets Fides tell it apart from a choice made in the experience
Janus.setConsent(
    values: ["data_sales_and_sharing": false],
    consentMethod: .externalProvider,
    saveToFides: true
)
```

A `JanusEvent` (`.EXPERIENCE_SELECTION_UPDATED`) is fired to all registered listeners after consent is written, identical to the event fired when a user submits the privacy experience UI.

**With `enableATT` on and tracking denied or restricted,** `setConsent()` stores `false` for every non-exempt notice, even if you pass `true`, and saves that to Fides when `saveToFides` is set. Janus logs a warning naming the notices it switched off. ATT-exempt and notice-only notices keep the values you pass.

`clearConsent()` resets all stored consent values and optionally clears metadata timestamps:

```swift
Janus.clearConsent()                     // clear values, keep timestamps
Janus.clearConsent(clearMetadata: true)  // clear everything
```

### External User ID

Use `setExternalId()` to attach your application's own user identifier (e.g. an Auth0 `sub` or database UUID) to every consent and notices-served request the SDK sends to Fides. Fides stores this on the `BrowserIdentity` of each request, letting it link consent records to a known user — which enables DSR (data subject request) correlation and consent merging across a user's devices.

Call it after the user logs in. Pass `nil` to clear the identifier on logout. The value is held in memory for the lifetime of the SDK and applied to all *subsequent* API calls; it does not retroactively update records already sent.

```swift
// After login — associate consent with your app's user ID
Janus.setExternalId("auth0|abc123")

// On logout — stop associating consent with the user
Janus.setExternalId(nil)
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
    autoShowExperience: true, // Default behavior
    consentFlagType: .boolean,
    consentNonApplicableFlagMode: .omit
)
```

#### Option 2: Manual control

```swift
// Disable automatic display by setting autoShowExperience to false
let config = JanusConfiguration(
    apiHost: "https://privacy-plus.yourhost.com",
    // Other parameters...
    autoShowExperience: false, // Prevent automatic display
    consentFlagType: .boolean,
    consentNonApplicableFlagMode: .omit
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

### TCF Experience Detection

The Janus SDK provides a property to check if the current privacy experience is a TCF (Transparency and Consent Framework) experience:

```swift
// Check if the current experience is a TCF experience
let isTCF = Janus.isTCFExperience

if isTCF {
    // Handle TCF-specific logic
    print("This is a TCF experience")
} else {
    // Handle non-TCF experience
    print("This is a standard privacy experience")
}
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

#### Bidirectional Consent Sync & Loop Prevention

Janus WebViews are **bidirectional**: consent changes flow both ways between native storage and any FidesJS-powered page.

- **Native → Web**: When consent changes in native code (via the privacy experience, `clearConsent()`, or `setConsent()`), Janus injects an `UpdateConsent` message into all managed WebViews so FidesJS reflects the new state.
- **Web → Native**: When a user interacts with a FidesJS UI inside a managed WebView, the JS bridge (`window.JanusSDKBridge`) forwards the consent values back to native storage and fires a `JanusEvent` to all registered listeners.

**How loops are prevented:**

1. **Source exclusion** — When a consent update originates *from* a WebView, Janus propagates the change to all *other* managed WebViews but skips the source WebView. Programmatic calls (e.g. `setConsent()`) have no source WebView and propagate to all.
2. **FidesJS idempotency** — FidesJS does not re-dispatch a `FidesUpdated` event when the incoming consent values are identical to the current state. This prevents an echo from triggering a second round-trip back to native.

These two layers work together so that a WebView-initiated consent change does not bounce indefinitely between FidesJS and native code.

### Banner Mode

By default, Janus shows every non-TCF experience as a full-screen modal. Set `enableBannerMode: true` to show `banner_and_modal` experiences as a compact banner first, matching the layered banner on the web. The banner offers Reject All, Accept All, and a Manage preferences button that opens the full modal.

```swift
let config = JanusConfiguration(
    apiHost: "https://privacy-plus.yourhost.com",
    propertyId: "FDS-A0B1C2",
    enableBannerMode: true
)
```

When banner mode is on:

1. **The banner appears only while consent is still needed**, i.e. when `shouldShowExperience` is true. Once the user has made a choice, `showExperience` opens the full modal directly, so a "Privacy settings" link in your app skips the banner. Dismissing the banner with the close button saves each notice's default as implied consent (consent method `dismiss`) when the user has no saved consent yet. Implied consent doesn't count as a choice, so the banner resurfaces on the next `showExperience`, as it does on the web.
2. **Text and labels come from the experience config.** The banner uses `banner_title` and `banner_description`, falling back to `title` and `description`, and the button labels from the same translation.
3. **`layer1_button_options` picks the buttons.** `acknowledge`, or an experience whose notices are all notice-only, shows a single Acknowledge button. `opt_in_opt_out` and `gpc_conditional` show Reject All and Accept All (apps have no GPC signal).
4. **Notices served are recorded with `serving_component: banner`**, and the modal opened from the banner records `modal`.
5. **The close button dismisses only when the experience is dismissable.** A non-dismissable banner stays until the user makes a choice.

Other component types, including `modal` and TCF experiences, are unaffected by this flag.

### Apple App Tracking Transparency (ATT)

On iOS 14+, Apple requires apps to request permission before tracking users across apps and websites. Janus can handle the ATT dialog natively, automatically enforcing consent based on the user's response.

#### Enabling ATT

Set `enableATT: true` in `JanusConfiguration`. When enabled, Janus will present the system ATT permission dialog before showing the privacy experience. If the user denies or restricts tracking, all non-exempt privacy notices are pre-populated to opt-out and their toggles are locked.

```swift
let config = JanusConfiguration(
    apiHost: "https://privacy-plus.yourhost.com",
    propertyId: "FDS-A0B1C2",
    enableATT: true
)
```

Janus also re-checks the current ATT status on its own, so a user who changes tracking in the iOS Settings app doesn't have to wait for the next prompt:

1. **When Janus initializes and when the app returns to the foreground,** it reads the live status. If tracking is now denied or restricted, it switches non-exempt notices off in stored consent and in any open consent screen.
2. **When tracking is later allowed,** the toggles unlock, but Janus doesn't switch anything back on. The user opts in again themselves.

#### Required Info.plist Key

The system ATT dialog requires `NSUserTrackingUsageDescription` in your **app's** `Info.plist`. Janus cannot add this for you — the host app must include it:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use this to deliver personalized content and measure ad performance.</string>
```

Without this key, calling `ATTrackingManager.requestTrackingAuthorization` will cause a crash at runtime.

#### ATT-Exempt Notices

By default, nearly all notices apply to ATT, meaning they are automatically opted-out when ATT is denied. The exception would be notices meant for informative purposes only, e.g. an "Essential" notice, which cannot be opted out of.

Aside from essential notices, a standard notice can be configured with `att_exempt` so that the notice is unaffected when ATT is denied, and the toggles remain interactive. This is configured within the Admin-UI.
