**Current Version:** 1.4.0 - (2026-01-01)

---
## Version 1.4.0 - (2026-01-01)
### Added

- **Unified Settings & Permissions (New Property System)**
    - Implemented a comprehensive set of Read/Write properties to control WebView2 behavior directly from AutoIt.
    - **Properties** (DispIds 170-179):
        - `AreDevToolsEnabled`: Toggle Developer Tools.
        - `AreDefaultContextMenusEnabled`: Control native context menus.
        - `AreDefaultScriptDialogsEnabled`: Suppress or allow alerts/prompts.
        - `AreBrowserAcceleratorKeysEnabled`: Manage browser shortcuts.
        - `IsStatusBarEnabled`: Toggle the status bar.
        - `ZoomFactor`: Direct access to zoom level.
        - `BackColor`: Set background color using Hex strings (e.g., "0xFFFFFF").
        - `AreHostObjectsAllowed`: Control JS bridge access.
        - `Anchor`: Manage control resizing behavior.
    - **Methods** (DispIds 180-184):
        - `SetZoomFactor`: Helper method for zoom.
        - `OpenDevToolsWindow`: Programmatically open DevTools.
        - `WebViewSetFocus`: Force focus to the WebView control.
        - **`AddInitializationScript`**: (New) Injects and manages persistent JS logic.

- **Custom Context Menu System**
    - Implemented `OnContextMenu` COM event (DispId 6) to intercept user right-clicks.
    - Added data payload support providing context metadata (Coordinates, Kind, Selection, Source URL, Link URL) via JSON.
    - Sent as raw JSON string (prefixed with "JSON:") to avoid Base64 overhead.

- **Focus Management Overhaul**
    - `OnBrowserGotFocus` (DispId 11): Native event triggering when WebView gains focus.
    - `OnBrowserLostFocus` (DispId 12): Native event triggering when focus leaves the WebView hierarchy.
    - Refactored logic to use `AreDevToolsEnabled` style properties instead of legacy timers for cleaner integration.

- **Utilities**
    - `EncodeURI` (DispId 165): Native UTF-8 encoding for safe URL parameter generation.
    - `DecodeURI` (DispId 166): Native decoding to convert percent-encoded strings.
    - `EncodeB64` (DispId 167): Native encoding (UTF-8) -> Base64.
    - `DecodeB64` (DispId 168): Native decoding  Base64 -> String (UTF8).

- **Navigation Lifecycle Events**
    - `OnNavigationStarting` (DispId 2): Intercepts and validates URLs before loading.
    - `OnNavigationCompleted` (DispId 3): Detailed navigation status and `WebErrorStatus`.

- **State Synchronization**
    - `OnTitleChanged` (DispId 4): Real-time synchronization of document title.
    - `OnURLChanged` (DispId 13): Real-time tracking of URL changes.
    - `OnZoomChanged` (DispId 10): Event fired when zoom level changes.

- **Property Getters**
    - `GetSource` (DispId 160) & `GetDocumentTitle` (DispId 161).
    - `GetCanGoBack` (DispId 162) & `GetCanGoForward` (DispId 163).
    - `GetBrowserProcessId` (DispId 164).

- **Permanent JavaScript Injection System**
    
    - Implemented `AddInitializationScript` (DispId 184): Allows permanent injection of JavaScript libraries (like `bridge.js`) that persist across navigations and page refreshes.
        
    - Added automated script lifecycle management using `AddScriptToExecuteOnDocumentCreatedAsync`.
        
    - Integrated **Script ID Tracking**: The library now remembers the last injected script ID to allow clean replacement or removal, preventing memory leaks and script duplication.
        

---
### Fixed

- **Focus Bounce Issue** Resolved where internal focus changes triggered false "LostFocus" events. Implemented robust checks using `BeginInvoke` and `ContainsFocus`.
- **CS1061 Compile Error** Corrected `TitleChanged` to standard `DocumentTitleChanged` event mapping.
- **Context Menu JSON** Fixed JSON escaping for special characters in selection text and URLs.

### Changed

- **Refactored Event Registration** Cleaned up `RegisterEvents` to remove legacy AdBlock/Context Menu duplication while preserving functionality.
- **DispId Standardization** Re-mapped `OnURLChanged` to DispId 13 to avoid conflicts.
- **Extension Management**
    - `AddExtension` (DispId 150) now returns the internal ID for better lifecycle management via `RemoveExtension` (DispId 151).

---
## Version 1.3.0  - (2025-12-25)

### Added

- **Multi-Instance Support**: Added the ability to create and manage multiple independent WebView2 instances within the same AutoIt application.
    
- **Extension Support**: Introduced the `AddExtension` method, allowing the loading of unpacked browser extensions (Manifest V2 and V3) per instance.
    
- **Independent User Profiles**: Each instance now supports a unique `UserDataFolder`, enabling isolated cookies, cache, and browser history (e.g., `Profile_1`, `Profile_2`).
    
- **Context Menu Control**: Added `SetContextMenuEnabled` to programmatically enable or disable the right-click menu.
    
- **DevTools Management**: Added `SetDevToolsEnabled` to toggle access to the browser's developer tools.
    

### Fixed

- **Event Routing**: Resolved an issue where JavaScript bridge messages were cross-talking between instances; messages are now correctly routed via unique prefixes (e.g., `Web1_`, `Web2_`).
    
- **Resource Locking**: Improved the `Cleanup()` method to ensure all WebView2 processes and profile files are properly released upon closing.
    
- **Initialization Sequence**: Fixed a race condition where calling methods before the engine was fully ready caused crashes; events now properly wait for the `INIT_READY` signal.
    

### Changed

- **Event-Driven Architecture**: Refactored the communication layer to be 100% event-driven, eliminating the need for `Sleep()` or polling loops.
    
- **Bridge Logic**: Optimized the `.NET` to `AutoIt` bridge to handle high-frequency messaging without UI blocking.
    
- **Resizing Logic**: Updated the recommended implementation to use `WM_SIZE` for smoother synchronization between AutoIt GUI containers and the WebView2 engine.


- ---
## Version 1.2.0 - 2024-11-15

### Added

- **JavaScript Bridge**: Initial implementation of `postMessage` communication from JavaScript to AutoIt.
    
- **ExecuteScript Method**: Added ability to run custom JS code from AutoIt directly into the WebView.
    
- **Navigation Events**: Introduced `NAV_STARTING` and `NAV_COMPLETED` events for better page load tracking.
    

### Changed

- **DLL Optimization**: Migrated core logic to a dedicated .NET DLL to handle complex COM interop.
    
- **Stability**: Improved memory management when reloading large websites.
    

---

## Version 1.1.0 - 2024-09-10

### Added

- **Custom Profile Path**: Introduced the ability to set a custom `UserDataFolder` for basic data persistence.
    
- **UserAgent Override**: Added method to change the browser's User-Agent string.
    
- **Zoom Factor**: Added support for manual zoom control (`SetZoomFactor`).
    

### Fixed

- **Object Cleanup**: Fixed a bug where `msedgewebview2.exe` processes remained active after AutoIt script exited.
    

---

## Version 1.0.0 - 2024-06-20 (Initial Release)

### Added

- **Core Engine**: Basic integration of WebView2 control into AutoIt GUI via COM.
    
- **Basic Navigation**: Implemented `Maps` and `MapsToString` methods.
    
- **Resize Support**: Fundamental resizing of the browser window relative to the parent GUI.

---
