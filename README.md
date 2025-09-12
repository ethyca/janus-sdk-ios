# Janus SDK Overview

The Janus SDK provides a comprehensive solution for implementing privacy-first consent management in your mobile applications. Built on Fides' privacy engineering principles, our SDK helps you:

- Serve appropriate privacy notices based on user location
- Collect and manage user consent preferences
- Enforce consent across your mobile application
- Synchronize consent state with your backend systems

## Available SDKs & Requirements

- **iOS SDK** (13.0+)
- **Android SDK** (API 21+)
- **Flutter SDK** (Flutter 3.3.0+, Dart 3.7.2+, iOS 13.0+, Android API 21+)
- **Fides Privacy Center** (2.59.1+)

## Key Features

- Location and property-aware notice serving
- Support for banner experience
- Configurable consent types (opt-in, opt-out, notice-only)
- Support for granular purpose-based consent
- Compliance with major privacy regulations (GDPR, CCPA, etc.)
- Consent preference persistence
- Real-time consent state checking
- WebView consent synchronization
- Integrations synchronization through FidesJS (GTM, Shopify, etc.)

## Getting Started

- [iOS Implementation Guide](https://github.com/ethyca/janus-sdk-ios/blob/main/iOSImplementationGuide.md)
- [Android Implementation Guide](https://github.com/ethyca/janus-sdk-android/blob/main/AndroidImplementationGuide.md)
- [Flutter Implementation Guide](https://github.com/ethyca/janus-sdk-flutter/blob/main/FlutterImplementationGuide.md)

## Best Practices

1. **Initialization**
   - Initialize the SDK at app launch
   - Handle initialization errors appropriately
   - Ensure that the callback from `initialize()` has executed with a "success" condition before attempting to use Janus

2. **Privacy Experience**
   - Initialization will automatically show any applicable privacy experience, but your application should include privacy settings that allow this to be recalled with `showExperience()`
   - Check `hasExperience` is true before showing any buttons or UI components that call `showExperience()`

3. **Error Handling**
   - Implement proper error handling for network issues
   - Provide fallback user experiences when needed

4. **Region Handling**
   - Region codes are mapped to experiences in Fides by ISO-3166-2. The region provided to the `initialize()` call should adhere to this standard.
   - Set `ipLocation` to true to use IP-based location detection, which avoids device permission requests.
   - If using `ipLocation`, initialize first with defaults, and provide `region` on a secondary initialization if ip location fails (see `JanusError.noRegionProvided` below)
   - **Upcoming:**
     - If `gpsGeolocation` is set to true, JanusSDK will automatically attempt to use GPS-based geolocation from the device to determine the region. If this permission is not allowed and no region was provided, JanusSDK will return `JanusError.noRegionProvided`.
     - On-device GPS geolocation subdivisions may not adhere to ISO-3166-2. JanusSDK will translate these into ISO-3166-2 for regions with applicable legal constraints.
     - If automatic regional detection is not available, provide a manual region override capability and call `initialize()` again after that has completed.

5. **WebView Management**
   - Always call `releaseConsentWebView()` when you're done with a WebView created using `createConsentWebView()`
   - Failure to release WebViews properly can cause memory leaks, as script message handlers need explicit cleanup
   - A good pattern is to call `releaseConsentWebView()` in your view controller's `deinit` method or whenever the WebView is no longer needed
   - For single-page applications, retain the WebView for the app's lifetime; for multi-page applications, release and recreate as needed

## Core Components

### JanusSDK

The main entry point for integrating consent management capabilities is the JanusSDK object.

**Key Methods/Properties:**
- `initialize(config, callback)`: Configures the SDK and provides platform-specific callbacks for when Janus is initialized or a `JanusError`. After inititialization, any privacy experience that matches the region and property ID will automatically be shown.
- `currentExperience`: Gets the current privacy experience.
- `hasExperience`: True when there is an experience available for the current region and propertyId.
- `shouldShowExperience`: A boolean indicating whether the privacy experience should be shown to the user. Returns true if a valid experience exists and the users consent is not present or not valid.
- `showExperience()`: Display the consent management interface to the user if `hasExperience` is true.
- `getLocationByIPAddress(callback)`: Performs IP-based location detection and provides the resulting location data through the callback.
- `region`: Returns the region code currently being used by the SDK after initialization.
- `listenerId = addConsentEventListener(listener)`: Attaches to events emitted during key user interactions.
- `removeConsentEventListener(listenerId)`: Removes an event listener.
- `createConsentWebView()`: Creates a platform-specific webview that synchronizes consent state with your mobile application as well as bidirectional support of Events with FidesJS.
- `releaseConsentWebView(webView)`: Properly releases a WebView created with `createConsentWebView()` to prevent memory leaks. Always call this when you're done with a WebView.
- `consent`: Provides the current state of the user's current consent preferences.
- `consentMetadata`: An object containing metadata about the consent, including:
  - `createdAt`: A timestamp indicating when the consent was created.
  - `updatedAt`: A timestamp indicating when the consent was last updated.
  - `consentMethod`: A string indicating how the consent was provided (e.g., "save", "dismiss").
- `fides_string`: The user's current consent string(s) combined into a single value.
- `clearConsent(clearMetadata)`: Clears all consent data. The optional `clearMetadata` parameter (default: false) determines whether to also clear consent metadata.
- `setLogger(logger)`: Sets a custom logger implementation for debugging and monitoring SDK operations. Accepts any object that implements the JanusLogger interface (see below). If used, setLogger should be called prior to initialize, in order to obtain logs during init.

**Janus Logger Interface:**
A protocol/interface for implementing custom logging functionality. Custom loggers must implement:
- `log(level, message, metadata, error)`: Main logging method that receives:
  - `level`: Log level (verbose, debug, info, warn, error)
  - `message`: The log message string
  - `metadata`: Optional key-value pairs for additional context (constrained to `[String: String]`)
  - `error`: Optional error object for error-level logs (Throwable on Android, Error on iOS)

**Janus Configuration Options:**
- `apiHost`:  🌎 FidesPlus API server base URL (REQUIRED)
- `privacyCenterHost`: 🏢 Privacy Center host URL - defaults to empty, if not provided Janus will assume the privacy center is hosted on the FidesPlus API server (apiHost)
- `propertyId`:  🏢 Property identifier for this app (i.e. "FDS-A0B1C2") - defaults to empty
- `ipLocation`: 📍 Use IP-based location detection - defaults to true
- `region`: ISO-3166-2 region code (overrides location detection if set) - defaults to empty
- `fidesEvents`: Whether or not to map JanusEvents to FidesJS events in managed Consent WebViews - defaults to true
- `autoShowExperience`: 🚀 Automatically show privacy experience after initialization if shouldShowExperience is true - defaults to true
- `saveUserPreferencesToFides`: 💾 Save user preferences to Fides via privacy-preferences API - defaults to true
- `saveNoticesServedToFides`: 💾 Save notices served to Fides via notices-served API - defaults to true
- `consentFlagType`: 🎯 The format for consent values returned by external interfaces - defaults to boolean (options: "boolean", "consentMechanism")
- `consentNonApplicableFlagMode`: 🔄 Controls how non-applicable privacy notices are handled in consent objects - defaults to omit (options: "omit", "include")

> **Note:** For full TCF support, the JanusSDK requires a minimum version of 2.59.1 for the Fides privacy-center image

### Integrations Support

Integrations such as Shopify, GTM, and BlueConic are managed through webviews. Events are fired from Janus to Fides in any open webviews created by `createConsentWebView`, allowing integrations to work intrinsically as configured by FidesJS in the webview.

`fidesEvents` must be set to true for JanusEvents to fire integrations in managed Consent WebViews, however, FidesJS events *will* propagate between managed Consent WebViews regardless of this setting.

## Bidirectional Event Binding

When using a WebView created with `createConsentWebView()`, the JanusSDK establishes a bidirectional event binding between your native app and the FidesJS running in the WebView:

1. **Events from JanusSDK to FidesJS:**
   - When consent values are updated in the native app, the changes are automatically propagated to FidesJS in the WebView.
   - FidesJS in the WebView receives these events and updates its own state accordingly, triggering any FidesJS event listeners in the web content.
   - This ensures that web content in your WebViews always reflects the current consent state managed by JanusSDK.

2. **Events from FidesJS to JanusSDK:**
   - When a user interacts with FidesJS UI components in the WebView (accepting cookies, changing preferences, etc.), FidesJS dispatches events.
   - The JanusSDK listens for these FidesJS events and converts them to corresponding JanusEvents.
   - These JanusEvents are then dispatched to all registered event listeners in your native app through `Janus.addConsentEventListener()`.
   - When consent values are updated in FidesJS, JanusSDK automatically captures these changes and updates its internal consent storage.

This bidirectional binding ensures that consent state remains synchronized between your native app and any WebViews, regardless of where the user manages their consent preferences.

## Events

### JanusSDK Event Lifecycle

The following events are dispatched by JanusSDK as part of its native lifecycle, independent of any WebView interaction:

| JanusSDK Lifecycle          | JanusEvent Type               | Description                                                    |
|-----------------------------|-------------------------------|----------------------------------------------------------------|
| `showExperience()`          | `experienceShown`             | The native consent experience is displayed                     |
| Native UI interaction       | `experienceInteraction`       | User interacts with elements in the native consent UI          |
| Native experience closed    | `experienceClosed`            | The native consent experience is dismissed                     |
| Native consent updating     | `experienceSelectionUpdating` | User's consent selection is being processed                    |
| Native consent updated      | `experienceSelectionUpdated`  | User's consent has been saved and applied                      |
| WebView consent updated     | `consentUpdatedFromWebView`   | Consent selection has been updated in a WebView and saved      |

#### Event Details

- `experienceInteraction`: Contains a `<string,bool>` key-value pair indicating the element clicked and its toggle state.
- `experienceClosed`: Contains a string identifying how the experience was dismissed.
- `experienceSelectionUpdating`: Contains the user's intended consent collection.
- `consentUpdatedFromWebView`: Contains the updated consent values from the WebView.

### Events Propagated From FidesJS to JanusSDK

When a user interacts with FidesJS in a WebView created with `createConsentWebView()`, the following FidesJS events are mapped to JanusEvents and dispatched by JanusSDK:

| FidesJS Event        | Mapped to JanusEvent Type          | Description                                                   |
|----------------------|------------------------------------|---------------------------------------------------------------|
| `FidesInitializing`  | `webviewFidesInitializing`         | FidesJS is beginning to initialize in the WebView             |
| `FidesInitialized`   | `webviewFidesInitialized`          | FidesJS has completed initialization in the WebView           |
| `FidesUIShown`       | `webviewFidesUIShown`              | A FidesJS UI component (banner, modal) is displayed           |
| `FidesUIChanged`     | `webviewFidesUIChanged`            | User changes preferences in the FidesJS UI                    |
| `FidesModalClosed`   | `webviewFidesModalClosed`          | FidesJS modal is closed                                       |
| `FidesUpdating`      | `webviewFidesUpdating`             | FidesJS begins updating user's consent preferences            |
| `FidesUpdated`       | `webviewFidesUpdated`              | FidesJS has updated and saved user's consent preferences      |

### Events Propagated From JanusSDK to FidesJS

If `fidesEvents` is set to true in the configuration (defaults to true), when events are dispatched by the JanusSDK in the native app, they fire these corresponding FidesJS events in active WebViews created with `createConsentWebView()`:

| JanusEvent Type              | Mapped to FidesJS Event    |
|------------------------------|----------------------------|
| `experienceShown`            | `FidesUIShown`             |
| `experienceInteraction`      | `FidesUIChanged`           |
| `experienceClosed`           | `FidesModalClosed`         |
| `experienceSelectionUpdating`| `FidesUpdating`            |
| `experienceSelectionUpdated` | `FidesUpdated`             |

Events propagated from JanusSDK to FidesJS include a `source` attribute with the value `"JanusSDK"`. This allows web components to identify the origin of events and prevent potential event loops. If you have custom event handling logic in your web components, you can check for this attribute to distinguish between events naturally occurring in FidesJS and those propagated from the native JanusSDK.

For example, in JavaScript:
```javascript
window.addEventListener("FidesUpdated", (event) => {
  if (event.detail && event.detail.source === "JanusSDK") {
    // Event was propagated from the native JanusSDK
  } else {
    // Event originated from FidesJS in the WebView
  }
});
```

This ensures that consent state and UI interactions remain synchronized between the native app and any web content in WebViews.

## Error Handling

The SDK provides detailed error types via `JanusError`:
- `invalidConfiguration`: Invalid SDK configuration provided during initialization on the callback
- `notInitialized`: Thrown as an exception if a method is called before the initialize callback completes
- `networkError`: Provided during initialization on the callback, or thrown as an exception during API operations
- `authenticationFailed`: Provided during initialization on the callback if API credentials are invalid
- `apiError`: Provided during initialization on the callback, or thrown as an exception when the API returns an error
- `invalidRegion`: Provided during initialization on the callback if an unsupported region code is provided
- `invalidExperience`: Provided during initialization on the callback if experience data is invalid or missing
- `noRegionProvided`: Provided during initialization on the callback if no region is provided and IP location detection fails or is disabled

These errors are returned through the initialization callback's error parameter, which should be checked and handled appropriately.