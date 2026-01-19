#AutoIt3Wrapper_UseX64=y
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#include "..\NetWebView2Lib.au3"

; ==============================================================================
; WebView2 Multi-Channel Presentation Script
; ==============================================================================

; Global objects

; GUI & Controls
Global $hGUI, $idLabelStatus

Main()

Func Main()
	Local $oMyError = ObjEvent("AutoIt.Error", __NetWebView2_COMErrFunc)
	#forceref $oMyError

	; Create the UI
	Local $iHeight = 400
	$hGUI = GUICreate("WebView2 .NET Manager - Community Demo", 800, $iHeight, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	$idLabelStatus = GUICtrlCreateLabel("Status: Initializing Engine...", 10, $iHeight -20 , 880, 20)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	; Initialize WebView2 Manager and register events
	Local $oWebV2M = _NetWebView2_CreateManager()
	$_g_oWeb = $oWebV2M
	If @error Then Return SetError(@error, @extended, $oWebV2M)

	; Initialize JavaScript Bridge
	Local $oJSBridge = _NetWebView2_GetBridge($oWebV2M, "_BridgeMyEventsHandler_")
	If @error Then Return SetError(@error, @extended, $oWebV2M)

	Local $sProfileDirectory = @TempDir & "\NetWebView2Lib-UserDataFolder"
	_NetWebView2_Initialize($oWebV2M, $hGUI, $sProfileDirectory, 0, 0, 0, 0, True, True, True, 1.2, "0x2B2B2B")

	GUISetState(@SW_SHOW)
	ConsoleWrite("! ===" & @ScriptLineNumber & @CRLF)
	MsgBox($MB_TOPMOST, "TEST #" & @ScriptLineNumber, 0)
	Local $s_PDF_FileFullPath

	$s_PDF_FileFullPath = "file:///" & @ScriptDir & '/FileViewerDemo_1.pdf'
	_NetWebView2_Navigate($oWebV2M, $s_PDF_FileFullPath)
	ConsoleWrite("! ===" & @ScriptLineNumber & @CRLF)
	MsgBox($MB_TOPMOST, "TEST #" & @ScriptLineNumber, $s_PDF_FileFullPath)

	$s_PDF_FileFullPath = "file:///" & @ScriptDir & '/FileViewerDemo_2.pdf'
	_NetWebView2_Navigate($oWebV2M, $s_PDF_FileFullPath)
	ConsoleWrite("! ===" & @ScriptLineNumber & @CRLF)
	MsgBox($MB_TOPMOST, "TEST #" & @ScriptLineNumber, $s_PDF_FileFullPath)

	; Main Loop
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	WEnd

	GUIDelete($hGUI)

	_NetWebView2_CleanUp($oWebV2M, $oJSBridge)
EndFunc   ;==>Main
