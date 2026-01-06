#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include <WindowsConstants.au3>
#include <GUIConstants.au3>
#include <GuiMenu.au3>

; =======================================================================================================
; GOG Demo Showcase (v1.4.2)
; Description: Demonstrates advanced WebView2 features including unified context menus,
;              JSON data binding, and robust event handling.
; =======================================================================================================

OnAutoItExitRegister("_ExitApp")

; Global objects for COM
Global $oWeb, $oJS
Global $oMyError = ObjEvent("AutoIt.Error", "_WV2_ErrFunc") ; Global COM Error Handler
Global $hGUI, $Bar
Global $g_sProfilePath = @ScriptDir & "\UserDataFolder"
Global $g_bURLFullSelected = 0
Global $g_bHighlight = 0
Global $g_GOG_bShowHidden = False

_MainGUI()

#Region ; === MainGUI ===
;---------------------------------------------------------------------------------------
Func _MainGUI() ; Create the Main GUI
	$hGUI = GUICreate("WebView2 v1.4.2 - GOG Showcase", 1000, 800, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	GUISetBkColor(0x1E1E1E, $hGUI)

	GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")

	; Initialize COM Objects
	_Web_ObjectsInit($g_sProfilePath)

	Local $sURL = "https://www.gog.com/en/games"
	GUICtrlSetData($Bar.Address, $sURL)

	If IsObj($oWeb) Then $oWeb.Navigate($sURL)

	GUISetState(@SW_SHOW, $hGUI)

	Local $iMsg
	While 1
		$iMsg = GUIGetMsg()
		If IsObj($oWeb) Then
			Switch $iMsg
				Case $GUI_EVENT_CLOSE
					Exit
				Case $Bar.Address
					_Web_GoTo(GUICtrlRead($Bar.Address))
				Case $Bar.ClearBrowserCache
					If MsgBox(8192 + 36, "Confirm", "Clear Browser Cache?", $hGUI) = 6 Then $oWeb.ClearCache()
					$oWeb.WebViewSetFocus()
				Case $Bar.GoBack
					$oWeb.GoBack()
				Case $Bar.Reload
					$oWeb.Reload()
				Case $Bar.GoForward
					$oWeb.GoForward()
				Case $Bar.Stop
					$oWeb.Stop()
				Case $Bar.GlobalNavButton
					MouseClick("right")
				Case $Bar.ctx_Google
					$oWeb.Navigate("https://www.google.com")
				Case $Bar.ctx_AutoIt
					$oWeb.Navigate("https://www.autoitscript.com/forum")
				Case $Bar.ctx_GOG
					$oWeb.Navigate("https://www.gog.com/en/games")
				Case $Bar.ctx_Show_Hidden_Games
					$g_GOG_bShowHidden = Not $g_GOG_bShowHidden
					_Web_Notify(($g_GOG_bShowHidden ? "Showing Hidden Games" : "Hiding Blacklisted Games"), ($g_GOG_bShowHidden ? "#FF0000" : "#2196F3"))
					_GOG_SyncAndRefresh()
					$oWeb.WebViewSetFocus()
				Case $Bar.ctx_Show_All_Tables
					$oWeb.ExecuteScript("scanTables();")
				Case $Bar.ctx_EnableCustomMenu
					$oWeb.SetContextMenuEnabled(False)
					ConsoleWrite("> Context Menu: Handled by AutoIt" & @CRLF)
				Case $Bar.ctx_EnableNativeMenu
					$oWeb.SetContextMenuEnabled(True)
					ConsoleWrite("> Context Menu: Handled by Edge" & @CRLF)
				Case $Bar.ctx_ClearBrowserData
					If MsgBox(8192 + 36, "Confirm", "Clear all browsing data?", $hGUI) = 6 Then $oWeb.ClearBrowserData()
					$oWeb.WebViewSetFocus()
				Case $Bar.ctx_Highlights
					$g_bHighlight = Not $g_bHighlight
					$oWeb.ToggleAuditHighlights($g_bHighlight)
					_Web_Notify("Highlights " & ($g_bHighlight ? "ON" : "OFF"), ($g_bHighlight ? "#FF6A00" : "#2196F3"))
				Case $Bar.ctx_ShowPrintUI
					$oWeb.ShowPrintUI()
				Case $Bar.ctx_About
					_Web_Notify("WebView2 v1.4.2 Demo - Optimized for GOG", "info")
			EndSwitch
		EndIf

		If $g_bURLFullSelected Then
			$g_bURLFullSelected = False
			GUICtrlSendMsg($Bar.Address, $EM_SETSEL, 0, -1)
		EndIf
	WEnd
EndFunc   ;==>_MainGUI
#EndRegion ; === MainGUI ===

#Region ; === CORE FUNCTIONS ===
;---------------------------------------------------------------------------------------
Func _ExitApp()
	If IsObj($oWeb) Then $oWeb.Cleanup()
	$oWeb = 0
	$oJS = 0
	Exit
EndFunc   ;==>_ExitApp
;---------------------------------------------------------------------------------------
Func _Web_GoTo($sURL)
	$sURL = StringStripWS($sURL, 3)
	If $sURL = "" Then Return False
	Local $bHasProtocol = StringRegExp($sURL, '(?i)^[a-z]+://', 0)
	Local $bIsURL = StringRegExp($sURL, '(?i)^([a-z0-9\-]+\.)+[a-z]{2,}', 0)
	Local $sFinalURL = ""
	If $bHasProtocol Then
		$sFinalURL = $sURL
	ElseIf $bIsURL Then
		$sFinalURL = "https://" & $sURL
	Else
		Local $sEncodedQuery = IsObj($oWeb) ? $oWeb.EncodeURI($sURL) : StringReplace($sURL, " ", "+")
		$sFinalURL = "https://www.google.com/search?q=" & $sEncodedQuery
	EndIf
	If IsObj($oWeb) Then $oWeb.Navigate($sFinalURL)
	Return True
EndFunc   ;==>_Web_GoTo
;---------------------------------------------------------------------------------------
Func _Web_ObjectsInit($sProfilePath)
	$oWeb = ObjCreate("NetWebView2.Manager")
	If Not IsObj($oWeb) Then Exit MsgBox(16, "Error", "WebView2 DLL not registered!")

	ObjEvent($oWeb, "WebEvents_", "IWebViewEvents")
	$oJS = $oWeb.GetBridge()
	ObjEvent($oJS, "JavaScript_", "IBridgeEvents")

	$oWeb.Initialize(($hGUI), $sProfilePath, 0, 25, 1000, 775)
	$oWeb.SetAutoResize(True)

	Local $sExtra = "Google, AutoIt, -, GOG, Show_Hidden_Games, -,Show_All_Tables, -, " & _
			"Highlights, EnableCustomMenu, EnableNativeMenu, ClearBrowserData, ShowPrintUI"

	$Bar = _Web_MakeBar($hGUI, $sExtra, 1)

	_GOG_InitializeDatabase()

	Do
		Sleep(50)
	Until $oWeb.IsReady

	$oWeb.BackColor = "0x2B2B2B"
	$oWeb.BorderStyle = 1
	$oWeb.AreDevToolsEnabled = True
	$oWeb.SetContextMenuEnabled(False) ; Force custom handling for showcase
	$oWeb.ZoomFactor = 1.1

	; 1. Loading the main bridge (Context Menus, etc.)
	Local $sBridge = FileRead(@ScriptDir & "\_gog_Bridge.js")
	$oWeb.AddInitializationScript($sBridge)

	; 2. (Stacked Scripts) Add List selection View Automation
    Local $sJS = ""
    $sJS &= "// --- GOG Sniper Logic ---" & @CRLF
    $sJS &= "let sniperSent = false; // Our flag to prevent re-sending the message" & @CRLF
    $sJS &= "" & @CRLF
    $sJS &= "setInterval(function() {" & @CRLF
    $sJS &= "    var cookieBanner = document.getElementById('CybotCookiebotDialog');" & @CRLF
    $sJS &= "    " & @CRLF
    $sJS &= "    // If the banner doesn't exist or is hidden" & @CRLF
    $sJS &= "    if (!cookieBanner || cookieBanner.offsetParent === null) {" & @CRLF
    $sJS &= "        var listBtn = document.querySelector('button[selenium-id=""listButton""]');" & @CRLF
    $sJS &= "        " & @CRLF
    $sJS &= "        // If the button exists and we haven't sent yet" & @CRLF
    $sJS &= "        if (listBtn && !sniperSent) {" & @CRLF
    $sJS &= "            sniperSent = true; // Immediately lock the flag" & @CRLF
    $sJS &= "            clearInterval(this); // Stop the timer" & @CRLF
    $sJS &= "" & @CRLF
    $sJS &= "            // Check if the list button is active" & @CRLF
    $sJS &= "            if (!listBtn.classList.contains('display-switch__button--active')) {" & @CRLF
    $sJS &= "                listBtn.click();" & @CRLF
    $sJS &= "                window.chrome.webview.postMessage('JSON: {""event"": ""debug"", ""msg"": ""🚀 Sniper: List Applied!""}');" & @CRLF
    $sJS &= "            } else {" & @CRLF
    $sJS &= "                window.chrome.webview.postMessage('JSON: {""event"": ""debug"", ""msg"": ""✨ Sniper: List is already Active""}');" & @CRLF
    $sJS &= "            }" & @CRLF
    $sJS &= "        }" & @CRLF
    $sJS &= "    }" & @CRLF
    $sJS &= "}, 1000);"

$oWeb.AddInitializationScript($sJS)

	_GOG_SyncAndRefresh()

EndFunc   ;==>_Web_ObjectsInit
;---------------------------------------------------------------------------------------
Func _Web_MakeBar($hGUI, $ctx_list = "", $bAddress = 1)
	Local $Btn[][] = [[59136, "GlobalNavButton"], [59213, "ClearBrowserCache"], [59179, "GoBack"], [59153, "Stop"], [59178, "GoForward"], [59180, "Reload"]]
	Local $iX = 0, $iY = 0, $iH = 25, $iW = 25, $iCnt = UBound($Btn), $m[]
	For $i = 0 To $iCnt - 1
		$m[$Btn[$i][1]] = GUICtrlCreateButton(ChrW($Btn[$i][0]), $iX, $iY, $iW, $iH)
		GUICtrlSetFont(-1, 12, 400, 0, "Segoe Fluent Icons")
		GUICtrlSetTip(-1, $Btn[$i][1])
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
		$iX += $iW
	Next
	Local $aCsz = WinGetClientSize($hGUI)
	$m.Address = GUICtrlCreateInput("", $iX, $iY, $aCsz[0] - $iX - 5, $iH)
	GUICtrlSetFont(-1, 11, 400, 0, "Segoe UI")
	GUICtrlSetResizing(-1, $GUI_DOCKLEFT + $GUI_DOCKRIGHT + $GUI_DOCKMENUBAR)
	If Not $bAddress Then GUICtrlSetState(-1, $GUI_HIDE)
	$m.ctx = GUICtrlCreateContextMenu($m.GlobalNavButton)
	Local $sFinalList = $ctx_list & ($ctx_list <> "" ? ",-," : "") & "About"
	Local $aItems = StringSplit($sFinalList, ","), $sName
	For $i = 1 To $aItems[0]
		$sName = StringReplace(StringStripWS($aItems[$i], 3), " ", "_")
		If $sName = "-" Then
			GUICtrlCreateMenuItem("", $m.ctx)
		Else
			$m["ctx_" & $sName] = GUICtrlCreateMenuItem($sName, $m.ctx)
		EndIf
	Next
	Return $m
EndFunc   ;==>_Web_MakeBar
;---------------------------------------------------------------------------------------
Func _Web_Notify($sMessage, $sType = "success", $iDuration = 3000)
	If Not IsObj($oWeb) Then Return
	Local $sCleanMsg = StringReplace(StringRegExpReplace($sMessage, "[\r\n]+", " "), "'", "\'")
	$oWeb.ExecuteScript(StringFormat("showNotification('%s', '%s', %i);", $sCleanMsg, $sType, $iDuration))
EndFunc   ;==>_Web_Notify
;---------------------------------------------------------------------------------------
Func WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg
	Local Static $hidURL = GUICtrlGetHandle($Bar.Address)
	If $lParam = $hidURL And BitShift($wParam, 16) = $EN_SETFOCUS Then $g_bURLFullSelected = True
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_COMMAND
#EndRegion ; === CORE FUNCTIONS ===

#Region ; === EVENT HANDLERS ===
;---------------------------------------------------------------------------------------
Func JavaScript_OnMessageReceived($sMsg)
	; ConsoleWrite("> JavaScript=" & $sMsg & @CRLF)
	Local $sFirstChar = StringLeft($sMsg, 1)
	If $sFirstChar = "{" Or $sFirstChar = "[" Then
		Local $oJson = ObjCreate("NetJson.Parser")
		If Not IsObj($oJson) Then Return
		$oJson.Parse($sMsg)
		Local $sJobType = $oJson.GetTokenValue("type")
		Switch $sJobType
			Case "SUBMIT_FORM"
				_Web_Notify("Form Data Received!", "success")
			Case "GOG_MENU"
				_GOG_HandleMenu($oJson.GetTokenValue("link"), $oJson.GetTokenValue("x"), $oJson.GetTokenValue("y"), $oJson.GetTokenValue("selection"), "GOG_Game")
		EndSwitch
	EndIf
EndFunc   ;==>JavaScript_OnMessageReceived
;---------------------------------------------------------------------------------------
Func WebEvents_OnMessageReceived($sMsg)
	; ConsoleWrite("+ WebEvents=" & $sMsg & @CRLF)
	Local $iSplitPos = StringInStr($sMsg, "|")
	Local $sCommand = $iSplitPos ? StringStripWS(StringLeft($sMsg, $iSplitPos - 1), 3) : $sMsg
	Local $sData = $iSplitPos ? StringTrimLeft($sMsg, $iSplitPos) : ""
	Local $aParts
	Switch $sCommand
		Case "NAV_COMPLETED"
			$oWeb.ExecuteScript("finalizeProgress();")
			_GOG_SyncAndRefresh()
			$oWeb.WebViewSetFocus()
		Case "URL_CHANGED"
			GUICtrlSetData($Bar.Address, $sData)
		Case "TITLE_CHANGED"
			WinSetTitle($hGUI, "", "GOG Showcase - " & $sData)
		Case "WINDOW_RESIZED"
			$aParts = StringSplit($sData, "|")
			If $aParts[0] >= 2 Then
				Local $iW = Int($aParts[1]), $iH = Int($aParts[2])
				; Filter 10x10 minimize glitch
				If $iW > 50 And $iH > 50 Then ConsoleWrite("-  Resized: " & $iW & "x" & $iH & @CRLF)
			EndIf
		Case "CONTEXT_MENU_REQUEST"
			$aParts = StringSplit($sData, "|")
			If $aParts[0] >= 4 Then _GOG_HandleMenu($aParts[1], Int($aParts[2]), Int($aParts[3]), $aParts[4])
		Case "JSON"
			Local $oP = ObjCreate("NetJson.Parser")
			$oP.Parse($sData)
			_GOG_HandleMenu($oP.GetTokenValue("link"), $oP.GetTokenValue("x"), $oP.GetTokenValue("y"), $oP.GetTokenValue("selection"), $oP.GetTokenValue("kind"))
		Case "CDP_RESULT"
			$aParts = StringSplit($sData, "|")
			_HandleScreenshotSequence($aParts[1], $aParts[2])
		Case "debug"

	EndSwitch
EndFunc   ;==>WebEvents_OnMessageReceived
;---------------------------------------------------------------------------------------
Func WebEvents_OnContextMenuRequested($sLink, $iX, $iY, $sSelection)
	_GOG_HandleMenu($sLink, $iX, $iY, $sSelection)
EndFunc   ;==>WebEvents_OnContextMenuRequested
;---------------------------------------------------------------------------------------
Func _GOG_HandleMenu($sLink, $iX, $iY, $sSelection, $sKind = "")
	#forceref $iX, $iY, $sSelection
	If Not IsObj($oWeb) Then Return

	; 1. ID Extraction
	Local $sGameID = ""
	If StringInStr($sLink, "/game/") Then
		Local $aUrlSplit = StringSplit($sLink, "?")
		Local $sURL = $aUrlSplit[1]
		$sGameID = StringRegExpReplace($sURL, ".*/game/(.*)", "$1")
		$sGameID = StringReplace($sGameID, "/", "")
		$sKind = "GOG_Game"
	EndIf

	; 2. Build Menu
	Local $hMenu = _GUICtrlMenu_CreatePopup()
	If $sKind = "GOG_Game" Then
		_GUICtrlMenu_AddMenuItem($hMenu, "🚫 Hide Game [" & $sGameID & "]", 1010)
		_GUICtrlMenu_AddMenuItem($hMenu, "✔️ Mark as Owned", 1011)
		_GUICtrlMenu_AddMenuItem($hMenu, "👀 Watchlist", 1012)
		_GUICtrlMenu_AddMenuItem($hMenu, "")
	EndIf

	If $sSelection <> "" Then
		_GUICtrlMenu_AddMenuItem($hMenu, "Copy Selection", 1001)
		_GUICtrlMenu_AddMenuItem($hMenu, "🔍 Search Google", 1002)
		_GUICtrlMenu_AddMenuItem($hMenu, "")
	EndIf

	_GUICtrlMenu_AddMenuItem($hMenu, "Reload Page", 1004)
	_GUICtrlMenu_AddMenuItem($hMenu, "Full Screenshot", 1009)
	_GUICtrlMenu_AddMenuItem($hMenu, "Export To Pdf", 1015)

	; 3. Track
	Local $tPoint = _WinAPI_GetMousePos()
	Local $iCmd = _GUICtrlMenu_TrackPopupMenu($hMenu, $hGUI, DllStructGetData($tPoint, "X"), DllStructGetData($tPoint, "Y"), 1, 1, 2)

	Switch $iCmd
		Case 1001
			ClipPut($sSelection)
		Case 1002
			_Web_GoTo("https://www.google.com/search?q=" & $oWeb.EncodeURI($sSelection))
		Case 1004
			$oWeb.Reload()
		Case 1009
			_HandleScreenshotSequence("Screenshot", @ScriptDir & "\GOG_" & @HOUR & @MIN & "-" & @SEC & @MSEC & ".png")
		Case 1010
			_GOG_ManageList($sGameID, "Blacklist")
		Case 1011
			_GOG_ManageList($sGameID, "Owned")
		Case 1012
			_GOG_ManageList($sGameID, "Watchlist")
		Case 1015 ; PDF Export
			; We hide the campaign-bar AND the nav menu
			Local $js = "var style = document.getElementById('gog-print-fix') || document.createElement('style'); " & _
            "style.id = 'gog-print-fix'; " & _
            "style.innerHTML = '@media print { " & _
            "   .campaign-bar, nav, .menu, [gog-menu] { display: none !important; } " & _
            "} /* --- Α4 Portrait --- */ " & _
            "@page { size: A4; margin: 1cm; }'; " & _
            "document.head.appendChild(style);"
			$oWeb.ExecuteScript($js)

			; Now the PDF will come out correctly
			$oWeb.ExportToPdf(@ScriptDir & "\GOG_" & @HOUR & @MIN & "-" & @SEC & @MSEC & ".pdf")
			_Web_Notify("PDF Exported!", "success")

	EndSwitch
	_GUICtrlMenu_DestroyMenu($hMenu)
EndFunc   ;==>_GOG_HandleMenu
#EndRegion ; === EVENT HANDLERS ===

#Region ; === _GOG_ SECTION ===
;---------------------------------------------------------------------------------------
Func _GOG_InitializeDatabase()
	Local $sFilePath = @ScriptDir & "\GOG_Data.json"
	If Not FileExists($sFilePath) Then
		FileWrite($sFilePath, '{"Blacklist": ["cyberpunk_2077"], "Owned": ["diablo"], "Watchlist": ["elden_ring"]}')
	EndIf
EndFunc   ;==>_GOG_InitializeDatabase
;---------------------------------------------------------------------------------------
Func _GOG_ManageList($sGameID, $sList)
	If $sGameID = "" Then Return
	Local $oParser = ObjCreate("NetJson.Parser")
	If Not IsObj($oParser) Then Return
	$oParser.LoadFromFile(@ScriptDir & "\GOG_Data.json")

	Local $bExisted = False
	Local $aL[3] = ["Blacklist", "Owned", "Watchlist"]
	For $l In $aL
		Local $path = "$." & $l & "[?(@ == '" & $sGameID & "')]"
		If $oParser.Search($path) <> "[]" Then
			If $l = $sList Then $bExisted = True
			$oParser.RemoveToken($path)
		EndIf
	Next

	If Not $bExisted Then
		$oParser.Merge('{"' & $sList & '": ["' & $sGameID & '"]}')
		_Web_Notify($sGameID & " -> " & $sList)
	Else
		_Web_Notify($sGameID & " removed")
	EndIf

	$oParser.SaveToFile(@ScriptDir & "\GOG_Data.json")
	_GOG_SyncAndRefresh()
EndFunc   ;==>_GOG_ManageList
;---------------------------------------------------------------------------------------
Func _GOG_SyncAndRefresh()
	If Not IsObj($oWeb) Then Return
	Local $sData = FileRead(@ScriptDir & "\GOG_Data.json")
	$oWeb.SyncInternalData($sData, "GOG_Data")

	Local $sHideCSS = $g_GOG_bShowHidden ? "opacity:0.4; filter:grayscale(1); border:2px dashed red;" : "display:none;"
	Local $sJS = "console.log('GOG Sync: v1.4.2'); " & _
			"var s = document.getElementById('gog-sync-css') || document.createElement('style'); " & _
			"s.id = 'gog-sync-css'; " & _
			"var r = ''; " & _
			"if(window.GOG_Data.Blacklist) window.GOG_Data.Blacklist.forEach(id => r += `a[href*='${id}'] { " & $sHideCSS & " } `); " & _
			"if(window.GOG_Data.Owned) window.GOG_Data.Owned.forEach(id => r += `a[href*='${id}'] { border:4px solid #4CAF50 !important; } `); " & _
			"if(window.GOG_Data.Watchlist) window.GOG_Data.Watchlist.forEach(id => r += `a[href*='${id}'] { border:4px solid #FFD700 !important; box-shadow:0 0 10px gold; } `); " & _
			"s.innerHTML = r; " & _
			"if(!s.parentNode) document.head.appendChild(s);"
	$oWeb.ExecuteScript($sJS)
EndFunc   ;==>_GOG_SyncAndRefresh
#EndRegion ; === _GOG_ SECTION ===

#Region ; === UTILS ===
;---------------------------------------------------------------------------------------
Func _WV2_ErrFunc($oError)
	Local $iNum = $oError.number
	Local $sHex = "0x" & Hex($iNum, 8)
	ConsoleWrite("!> COM Error: " & $oError.description & " [Code: " & $sHex & "] (Line: " & $oError.scriptline & ")" & @CRLF)
EndFunc   ;==>_WV2_ErrFunc
;---------------------------------------------------------------------------------------
Func _HandleScreenshotSequence($sMethod, $sData)
	Local Static $sSavePath = "", $bProcessing = False
	If $sMethod = "Screenshot" Then
		$bProcessing = True
		$sSavePath = $sData
	EndIf
	If Not $bProcessing Or StringInStr($sData, '"error":') Then Return
	Local $oP
	Switch $sMethod
		Case "Screenshot"
			$oWeb.CallDevToolsProtocolMethod("Page.getLayoutMetrics", "{}")
		Case "Page.getLayoutMetrics"
			$oP = ObjCreate("NetJson.Parser")
			$oP.Parse($sData)
			Local $sParams = StringFormat('{"width":%d, "height":%d, "deviceScaleFactor":1, "mobile":false}', $oP.GetTokenValue("contentSize.width"), $oP.GetTokenValue("contentSize.height"))
			$oWeb.CallDevToolsProtocolMethod("Emulation.setDeviceMetricsOverride", $sParams)
		Case "Emulation.setDeviceMetricsOverride"
			Sleep(500)
			$oWeb.CallDevToolsProtocolMethod("Page.captureScreenshot", '{"format": "png", "fromSurface": true}')
		Case "Page.captureScreenshot"
			$oP = ObjCreate("NetJson.Parser")
			$oP.Parse($sData)
			$oP.DecodeB64ToFile($oP.GetTokenValue("data"), $sSavePath)
			_Web_Notify("Full Page Captured!", "success")
			ShellExecute($sSavePath)
			$oWeb.CallDevToolsProtocolMethod("Emulation.clearDeviceMetricsOverride", "{}")
			$bProcessing = False
	EndSwitch
EndFunc   ;==>_HandleScreenshotSequence
#EndRegion ; === UTILS ===
