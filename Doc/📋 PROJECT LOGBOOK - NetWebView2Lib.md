**Current Version:** Version 1.4.1 - (2026-01-03)

---
## Version 1.4.1 - (2026-01-03)

### 🚀 Data Intelligence & JSON Manipulation

This update transforms the `NetJson.Parser` into a full-featured JSON management suite, allowing for complex data merging and structure inspection directly from AutoIt.

#### **Added**

- **Advanced JSON Methods** (DispIds 214 - 221):
    
    - `Merge(string jsonContent)`: **(214)** Performs a deep merge of a new JSON string into the existing structure. Uses `Union` strategy for arrays to prevent duplicates.
        
    - `MergeFromFile(string filePath)`: **(215)** Efficiently reads a JSON file from disk and merges it directly into the current session.
        
    - `GetTokenType(string path)`: **(216)** Returns the .NET/Newtonsoft type of a specific node (e.g., _Object, Array, String, Integer, Boolean_). Essential for dynamic data validation.
        
    - `RemoveToken(string path)`: **(217)** Allows dynamic deletion of specific keys or array elements, providing full CRUD (Create, Read, Update, Delete) capabilities
      
    - **`Search(string query)`**: **(218)** Executes a JSONPath query and returns a JSON array of all matching tokens. Enables powerful filtering and deep searching with a single call.
      
    - **`Flatten()`**: **(219)** Flattens the JSON structure into a single-level object with dot-notated paths.
      
    - **`CloneTo(string parserName)`**: **(220)** Clones the current JSON data to another named parser instance.
      
    - **`FlattenToTable(string colDelim, string rowDelim)`**: **(221)** Flattens the JSON structure into a table-like string with specified delimiters.
    

- **Web Content Extraction** (DispId 200):
    
    - **`GetInnerText()`**: **(200)** Retrieves the entire visible text content (`innerText`) of the document. The result is returned asynchronously via the `OnMessageReceived` event with the `Inner_Text|` prefix. This enables powerful web scraping and content analysis without manual DOM parsing.
        

#### **Improvements**

- **Enhanced Error Handling**: All new JSON and Web methods are wrapped in try-catch blocks to prevent COM crashes when dealing with malformed data or invalid DOM states.
    
- **Memory Efficiency**: `MergeFromFile` utilizes local C# file streams, reducing the memory overhead for the calling AutoIt script when handling large configuration files.
    
- **Unified Messaging**: Content extraction now follows the standardized `Command|Data` format, making it easier to route messages in the AutoIt event loop.


---
## Version 1.4.0 - (2026-01-01)

### Added

- **Unified Settings & Permissions (New Property System)**
    
    - Implemented a comprehensive set of Read/Write properties to control WebView2 behavior directly from AutoIt.
    - **Properties** (DispIds 170-179, 183):
        - `AreDevToolsEnabled` (170): Toggle Developer Tools.
        - `AreDefaultContextMenusEnabled` (171): Control native context menus.
        - `AreDefaultScriptDialogsEnabled` (172): Suppress or allow alerts/prompts.
        - `AreBrowserAcceleratorKeysEnabled` (173): Manage browser shortcuts.
        - `IsStatusBarEnabled` (174): Toggle the status bar.
        - ZoomFactor (175): Direct access to zoom level.
        - `BackColor` (176): Set background color using Hex strings (e.g., "0xFFFFFF").
        - `AreHostObjectsAllowed` (177): Control JS bridge access.
        - `Anchor` (178): Manage control resizing behavior.
        - `BorderStyle` (179): Placeholder for border style configuration.
        - `AreBrowserPopupsAllowed` (183): Control new window/popup allowance.
    - **Methods** (DispIds 180-182, 184):
        - SetZoomFactor (180): Helper method for zoom.
        - OpenDevToolsWindow (181): Programmatically open DevTools.
        - WebViewSetFocus (182): Force focus to the WebView control.
        - **
            
            AddInitializationScript** (184): Injects and manages persistent JS logic.
- **Custom Context Menu System**
    
    - Implemented `OnContextMenu` COM event (DispId 6) to intercept user right-clicks.
    - Added data payload support providing context metadata (**Coordinates, Kind, TagName, Selection, Source URL, Link URL**) via JSON.
    - Sent as raw JSON string (prefixed with "JSON:") to avoid Base64 overhead.
- **Focus Management Overhaul**
    
    - `OnBrowserGotFocus` (DispId 11): Native event triggering when WebView gains focus.
    - `OnBrowserLostFocus` (DispId 12): Native event triggering when focus leaves the WebView hierarchy.
    - Refactored logic to use `AreDevToolsEnabled` style properties instead of legacy timers for cleaner integration.
- **Utilities**
    
    - EncodeURI (DispId 165): Native UTF-8 encoding for safe URL parameter generation.
    - DecodeURI (DispId 166): Native decoding to convert percent-encoded strings.
    - EncodeB64 (DispId 167): Native encoding (UTF-8) -> Base64.
    - DecodeB64 (DispId 168): Native decoding Base64 -> String (UTF8).
- **Navigation Lifecycle Events**
    
    - `OnNavigationStarting` (DispId 2): Intercepts and validates URLs before loading.
    - `OnNavigationCompleted` (DispId 3): Detailed navigation status and `WebErrorStatus`.
- **State Synchronization**
    
    - `OnTitleChanged` (DispId 4): Real-time synchronization of document title.
    - `OnURLChanged` (DispId 13): Real-time tracking of URL changes.
    - `OnZoomChanged` (DispId 10): Event fired when zoom level changes.
- **Property Getters**
    
    - GetSource (**DispId 135**) & 
        
        GetDocumentTitle (**DispId 134**).
    - GetCanGoBack (DispId 162) & 
        
        GetCanGoForward (DispId 163).
    - GetBrowserProcessId (DispId 164).
- **Permanent JavaScript Injection System**
    
    - Implemented 
        
        AddInitializationScript (DispId 184): Allows permanent injection of JavaScript libraries (like `bridge.js`) that persist across navigations and page refreshes.
    - Added automated script lifecycle management using `AddScriptToExecuteOnDocumentCreatedAsync`.
    - Integrated **Script ID Tracking**: The library now remembers the last injected script ID to allow clean replacement or removal, preventing memory leaks and script duplication.

---

### Fixed

- **Focus Bounce Issue** Resolved where internal focus changes triggered false "LostFocus" events. Implemented robust checks using `BeginInvoke` and `GetFocus` with `IsChild` verification.
- **CS1061 Compile Error** Corrected `TitleChanged` to standard `DocumentTitleChanged` event mapping.
- **Context Menu JSON** Fixed JSON escaping for special characters in selection text and URLs.

### Changed

- **Refactored Event Registration** Cleaned up 
    
    RegisterEvents to remove legacy AdBlock/Context Menu duplication while preserving functionality.
- **DispId Standardization** Re-mapped `OnURLChanged` to DispId 13 to avoid conflicts.
- **Extension Management**
    - AddExtension (DispId 150) now **triggers a notification event** with the internal ID for better lifecycle management via 
        
        RemoveExtension (DispId 151).

---
## Version 1.3.0 - (2025-12-25)

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
