;----------------------------------------------------------------------------------------
; Title...........: Active_Help.au3
; Description.....: Multi-WebView2 interface for synchronized side-by-side search.
; AutoIt Version..: 3.3.18.0    Author: ioa747           Script Version: 0.1
; Note............: Tested in Windows 11 Pro 25H2        Date: 25/12/2025
;
; USAGE INSTRUCTIONS:
; 1. The Right Browser (Web2) loads the AutoIt Forum.
; 2. Use your mouse to select (highlight) any text or keyword on the Right Browser.
; 3. A floating button "🔍 Search Google" will appear near your selection.
; 4. Click the button to automatically perform a Google Search on the Left Browser (Web1).
; 5. The search is automatically restricted to the current domain (site:domain.com).
;----------------------------------------------------------------------------------------
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

; Global Objects & Handles
Global $oWeb1, $oWeb2
Global $oWebEvt1, $oWebEvt2
Global $oBridge1, $oBridge2
Global $oEvtBridge1, $oEvtBridge2
Global $g_sURL1 = "", $g_sURL2 = ""
Global $hMainGUI, $hID1, $hID2

; Create Main GUI
; Use $WS_CLIPCHILDREN to prevent flickering when resizing child windows
$hMainGUI = GUICreate("Multi-WebView2 v1.3.0", 1000, 600, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))

; Register the WM_SIZE message to handle window resizing dynamically
GUIRegisterMsg($WM_SIZE, "WM_SIZE")

; Initialize Browsers and their containers
_InitBrowsers()

; Show the main window
GUISetState(@SW_SHOW, $hMainGUI)

Global $nMsg
; Main Message Loop
While 1
    $nMsg = GUIGetMsg()
    Switch $nMsg
        Case $GUI_EVENT_CLOSE
            ; Cleanup WebView2 resources before exiting to prevent orphan processes
            If IsObj($oWeb1) Then $oWeb1.Cleanup()
            If IsObj($oWeb2) Then $oWeb2.Cleanup()
            Exit
    EndSwitch
WEnd

;---------------------------------------------------------------------------------------
; Function: _InitBrowsers
; Description: Creates child window containers and initializes WebView2 instances
;---------------------------------------------------------------------------------------
Func _InitBrowsers()
    ; Create Child Windows as containers for the WebViews
    $hID1 = GUICreate("", 460, 500, 20, 30, BitOR($WS_CHILD, $WS_CLIPCHILDREN), -1, $hMainGUI)
    $hID2 = GUICreate("", 460, 500, 520, 30, BitOR($WS_CHILD, $WS_CLIPCHILDREN), -1, $hMainGUI)

    ; Instance 1 - Isolated "Profile_1" folder
    $oWeb1 = ObjCreate("NetWebView2.Manager")
    $oWebEvt1 = ObjEvent($oWeb1, "Web1_", "IWebViewEvents")
    $oBridge1 = $oWeb1.GetBridge()
    $oEvtBridge1 = ObjEvent($oBridge1, "Bridge1_", "IBridgeEvents")
    $oWeb1.Initialize($hID1, @ScriptDir & "\Profile_1", 0, 0, 460, 500)

    ; Instance 2 - Isolated "Profile_2" folder
    $oWeb2 = ObjCreate("NetWebView2.Manager")
    $oWebEvt2 = ObjEvent($oWeb2, "Web2_", "IWebViewEvents")
    $oBridge2 = $oWeb2.GetBridge()
    $oEvtBridge2 = ObjEvent($oBridge2, "Bridge2_", "IBridgeEvents")
    $oWeb2.Initialize($hID2, @ScriptDir & "\Profile_2", 0, 0, 460, 500)
EndFunc   ;==>_InitBrowsers

;---------------------------------------------------------------------------------------
; BROWSER 1 EVENTS (Search Results Engine)
;---------------------------------------------------------------------------------------
Func Web1_OnMessageReceived($sMsg)
    ConsoleWrite("+> [Web1]: " & $sMsg & @CRLF)
    Local Static $bIsInitialized = False

    Local $aParts = StringSplit($sMsg, "|")
    Local $sCommand = StringStripWS($aParts[1], 3)

    Switch $sCommand
		Case "INIT_READY"
			If Not $bIsInitialized Then
            $bIsInitialized = True
            $oWeb1.SetContextMenuEnabled(True)
            $oWeb1.Navigate("https://www.google.com")
            GUISetState(@SW_SHOWNOACTIVATE, $hID1) ; Show without stealing focus
			EndIf

        Case "URL_CHANGED"
            If $aParts[0] > 1 Then $g_sURL1 = $aParts[2]
    EndSwitch
EndFunc   ;==>Web1_OnMessageReceived

Func Bridge1_OnMessageReceived($sMsg)
    ConsoleWrite("+> [Bridge1 JS]: " & $sMsg & @CRLF)
EndFunc   ;==>Bridge1_OnMessageReceived

;---------------------------------------------------------------------------------------
; BROWSER 2 EVENTS (Main Navigation & Selection Source)
;---------------------------------------------------------------------------------------
Func Web2_OnMessageReceived($sMsg)
    ConsoleWrite("+> [Web2]: " & $sMsg & @CRLF)
    Local Static $bIsInitialized = False

    Local $aParts = StringSplit($sMsg, "|")
    Local $sCommand = StringStripWS($aParts[1], 3)

    Switch $sCommand
		Case "INIT_READY"
			If Not $bIsInitialized Then
            $bIsInitialized = True

            ; Example of loading a browser extension
            Local $sExtPath = @ScriptDir & "\Extensions_Lib\DarkReader"
            If FileExists($sExtPath) Then $oWeb2.AddExtension($sExtPath)

            $oWeb2.Navigate("https://www.autoitscript.com/forum/")
            GUISetState(@SW_SHOWNOACTIVATE, $hID2)
			EndIf

        Case "NAV_COMPLETED"
            ; Re-inject the selection script every time a new page is loaded
            ConsoleWrite("> Web2 Navigation Completed. Injecting Selection Script..." & @CRLF)
            $oWeb2.ExecuteScript(JS_getSelection())

        Case "URL_CHANGED"
            If $aParts[0] > 1 Then $g_sURL2 = $aParts[2]
    EndSwitch
EndFunc   ;==>Web2_OnMessageReceived

Func Bridge2_OnMessageReceived($sMsg)
    ConsoleWrite("+> [Bridge2 JS]: " & $sMsg & @CRLF)

    ; Split message from JS: COMMAND|VALUE
    Local $aParts = StringSplit($sMsg, "|")
    If $aParts[0] < 2 Then Return

    Local $sCommand = StringStripWS($aParts[1], 3)
    Local $sSearchText = StringStripWS($aParts[2], 3)

    Switch $sCommand
        Case "SEARCH_GOOGLE"
            If IsObj($oWeb1) Then
                ConsoleWrite("!> Re-routing search to Web1: " & $sSearchText & @CRLF)

                ; Extract domain for site-specific search (e.g., autoitscript.com)
                Local $sDomain2 = StringRegExpReplace($g_sURL2, "https?://([^/]+).*", "$1")

                ; URL Encode spaces
                Local $sCleanSearch = StringReplace($sSearchText, " ", "+")

                ; Construct Google search URL with 'site:' operator
                Local $sURL = "https://www.google.com/search?q=" & $sCleanSearch & "+site:" & $sDomain2

                ; Update Browser 1
                $oWeb1.Navigate($sURL)
            EndIf
    EndSwitch
EndFunc   ;==>Bridge2_OnMessageReceived

;---------------------------------------------------------------------------------------
; Function: JS_getSelection
; Description: Returns JavaScript code that monitors text selection and creates a popup
;---------------------------------------------------------------------------------------
Func JS_getSelection()
    Local $sJS = _
        "(function() {" & _
        "   document.onmouseup = function(e) {" & _
        "       var selection = window.getSelection();" & _
        "       var text = selection.toString().trim();" & _
        "       var old = document.getElementById('search-popup');" & _
        "       if (old) old.remove();" & _
        "       if (text.length > 0) {" & _
        "           var btn = document.createElement('div');" & _
        "           btn.id = 'search-popup';" & _
        "           btn.innerHTML = '🔍 Search Google';" & _
        "           btn.setAttribute('style', 'position:absolute; top:'+(e.pageY-45)+'px; left:'+e.pageX+'px; ' +" & _
        "               'z-index:2147483647; background:#4285f4; color:white; padding:8px 12px; ' +" & _
        "               'border-radius:5px; cursor:pointer; font-family:sans-serif; font-size:14px; ' +" & _
        "               'box-shadow:0 4px 10px rgba(0,0,0,0.4); user-select:none;');" & _
        "" & _
        "           btn.addEventListener('mousedown', function(ev) {" & _
        "               ev.preventDefault();" & _
        "               ev.stopPropagation();" & _
        "               if (window.chrome && window.chrome.webview) {" & _
        "                   window.chrome.webview.postMessage('SEARCH_GOOGLE|' + text);" & _
        "               }" & _
        "               this.remove();" & _
        "           }, true);" & _
        "           document.body.appendChild(btn);" & _
        "       }" & _
        "   };" & _
        "})();"
    Return $sJS
EndFunc   ;==>JS_getSelection

;---------------------------------------------------------------------------------------
; Function: WM_SIZE
; Description: Handles GUI resizing and adjusts WebViews
;---------------------------------------------------------------------------------------
Func WM_SIZE($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam
    If $wParam = 1 Then Return $GUI_RUNDEFMSG

    Local $iMainWidth = BitAND($lParam, 0xFFFF)
    Local $iMainHeight = BitShift($lParam, 16)

    Local $iGap = 10, $iMargin = 10, $iTop = 10, $iBottom = 50
    Local $iW = Int(($iMainWidth - ($iMargin * 2) - $iGap) / 2)
    Local $iH = $iMainHeight - $iTop - $iBottom

    If $iW < 50 Or $iH < 50 Then Return $GUI_RUNDEFMSG

    If IsHWnd($hID1) Then
        ControlMove($hMainGUI, "", $hID1, $iMargin, $iTop, $iW, $iH)
        If IsObj($oWeb1) Then $oWeb1.Resize($iW, $iH)
    EndIf

    If IsHWnd($hID2) Then
        ControlMove($hMainGUI, "", $hID2, $iMargin + $iW + $iGap, $iTop, $iW, $iH)
        If IsObj($oWeb2) Then $oWeb2.Resize($iW, $iH)
    EndIf

    Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_SIZE