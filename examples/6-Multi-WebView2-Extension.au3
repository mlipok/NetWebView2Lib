#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

; Global Objects & Handles
Global $oWeb1, $oWeb2
Global $oWebEvt1, $oWebEvt2
Global $oBridge1, $oBridge2
Global $oEvtBridge1, $oEvtBridge2
Global $hMainGUI, $hID1, $hID2

; Create Main GUI
; We use $WS_CLIPCHILDREN to prevent flickering when resizing child windows
$hMainGUI = GUICreate("Multi-WebView2 v1.3.0", 1000, 600, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))

; Register the WM_SIZE message to handle window resizing dynamically
GUIRegisterMsg($WM_SIZE, "WM_SIZE")

; Initialize Browsers and their containers
_InitBrowsers()

; Show the main window
GUISetState(@SW_SHOW, $hMainGUI)

; Main Message Loop
While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			; Cleanup resources before exiting
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

	; Show Child Windows
	; GUISetState(@SW_SHOW, $hID1) ; Container 1
	; GUISetState(@SW_SHOW, $hID2) ; Container 2
	; Tip: is hidden initially and shown after INIT_READY in its event handler

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
; BROWSER 1 EVENTS
;---------------------------------------------------------------------------------------
Func Web1_OnMessageReceived($sMsg)
	ConsoleWrite("+> [Web1]: " & $sMsg & @CRLF)
	Local Static $bIsInitialized, $sCurentURL = ""

	; Parse messages with parameters (e.g., COMMAND|VALUE)
	Local $aParts = StringSplit($sMsg, "|")
	Local $sCommand = StringStripWS($aParts[1], 3)

	Switch $sCommand
		Case "INIT_READY"
			$bIsInitialized = True
			$oWeb1.SetContextMenuEnabled(True) ; Enable Right Click (Context Menu)
			$oWeb1.Navigate("https://www.google.com")
			GUISetState(@SW_SHOWNOACTIVATE, $hID1) ; Show container once engine is ready

		Case "NAV_COMPLETED"
			; Handle navigation completion here

		Case "TITLE_CHANGED"
			If $aParts[0] > 1 Then
				; Example: Update main window title or labels
			EndIf

		Case "URL_CHANGED"
			If $aParts[0] > 1 Then
				$sCurentURL = $aParts[2]
			EndIf
	EndSwitch
EndFunc   ;==>Web1_OnMessageReceived

Func Bridge1_OnMessageReceived($sMsg)
	; Handles data received from JavaScript 'window.chrome.webview.postMessage'
	ConsoleWrite("+> [Bridge1]: " & $sMsg & @CRLF)
EndFunc   ;==>Bridge1_OnMessageReceived

;---------------------------------------------------------------------------------------
; BROWSER 2 EVENTS
;---------------------------------------------------------------------------------------
Func Web2_OnMessageReceived($sMsg)
	ConsoleWrite("+> [Web2]: " & $sMsg & @CRLF)
	Local Static $bIsInitialized, $sCurentURL = ""

	Local $aParts = StringSplit($sMsg, "|")
	Local $sCommand = StringStripWS($aParts[1], 3)

	Switch $sCommand
		Case "INIT_READY"
			$bIsInitialized = True

			; Load Extension for Browser 2
			Local $sExtPath = @ScriptDir & "\Extensions_Lib\DarkReader"
			ConsoleWrite("> Loading: " & $sExtPath & @CRLF)
			$oWeb2.AddExtension($sExtPath)

			$oWeb2.Navigate("https://www.autoitscript.com/forum/")
			GUISetState(@SW_SHOWNOACTIVATE, $hID2)

		Case "NAV_COMPLETED"
			; Handle navigation completion here

		Case "URL_CHANGED"
			If $aParts[0] > 1 Then
				$sCurentURL = $aParts[2]
			EndIf
	EndSwitch
EndFunc   ;==>Web2_OnMessageReceived

Func Bridge2_OnMessageReceived($sMsg)
	; Handles data received from JavaScript 'window.chrome.webview.postMessage'
	ConsoleWrite("+> [Bridge2]: " & $sMsg & @CRLF)
EndFunc   ;==>Bridge2_OnMessageReceived

;---------------------------------------------------------------------------------------
; Function: WM_SIZE
; Description: Synchronizes GUI containers and WebView2 instances when main window resizes
;---------------------------------------------------------------------------------------
Func WM_SIZE($hWnd, $iMsg, $wParam, $lParam)
	If $wParam = 1 Then Return $GUI_RUNDEFMSG ; SIZE_MINIMIZED

	; Extract Width and Height from lParam
	Local $iMainWidth = BitAND($lParam, 0xFFFF)
	Local $iMainHeight = BitShift($lParam, 16)

	; Layout Settings (Margins and Gaps)
	Local $iGap = 10      ; Gap between windows
	Local $iMargin = 10   ; Outer margin
	Local $iTop = 10      ; Top margin
	Local $iBottom = 50   ; Bottom margin (room for buttons/status)

	; Calculate width for each WebView (50% split)
	Local $iW = Int(($iMainWidth - ($iMargin * 2) - $iGap) / 2)
	Local $iH = $iMainHeight - $iTop - $iBottom

	; Safety check for minimum dimensions
	If $iW < 50 Or $iH < 50 Then Return $GUI_RUNDEFMSG

	; Sync WEB1 (Left Side)
	If IsHWnd($hID1) Then
		ControlMove($hMainGUI, "", $hID1, $iMargin, $iTop, $iW, $iH)
		If IsObj($oWeb1) Then $oWeb1.Resize($iW, $iH)
	EndIf

	; Sync WEB2 (Right Side)
	If IsHWnd($hID2) Then
		ControlMove($hMainGUI, "", $hID2, $iMargin + $iW + $iGap, $iTop, $iW, $iH)
		If IsObj($oWeb2) Then $oWeb2.Resize($iW, $iH)
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_SIZE
;---------------------------------------------------------------------------------------
