;~ #AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Run_AU3Check=Y
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#Au3Stripper_Ignore_Funcs=__NetWebView2_WebEvents_*,__NetWebView2_JSEvents_*

#include <Array.au3>
#include <GUIConstantsEx.au3>
#include <WinAPIShPath.au3>
#include <WindowsConstants.au3>

; Global objects
Global $_g_hNetWebView2Lib_DLL = ''
Global $_g_oWeb
Global $g_DebugInfo = True

#Region ; NetWebView2Lib UDF
Func _NetWebView2_StartUp($sDLLFileFullPath)
	#RegistrationFree is WorkInProgress
	$sDLLFileFullPath = _WinAPI_PathCanonicalize($sDLLFileFullPath)
;~ 	ConsoleWrite($sDLLFileFullPath & @CRLF)
	$_g_hNetWebView2Lib_DLL = DllOpen($sDLLFileFullPath)

;~ 	ConsoleWrite("! " & VarGetType($_g_hNetWebView2Lib_DLL) & @CRLF)
;~ 	ConsoleWrite("! " & $_g_hNetWebView2Lib_DLL & @CRLF)
	If $_g_hNetWebView2Lib_DLL = -1 Then
		__NetWebView2_Log(@ScriptLineNumber, 'Error loading AcitevX DLL : ' & $_g_hNetWebView2Lib_DLL)
		Return SetError(1, @extended, $_g_hNetWebView2Lib_DLL)
	EndIf
	Return SetError(@error, @extended, $_g_hNetWebView2Lib_DLL)
EndFunc   ;==>_NetWebView2_StartUp

Func _NetWebView2_ShutDown()
	DllClose($_g_hNetWebView2Lib_DLL)
EndFunc   ;==>_NetWebView2_ShutDown

; #FUNCTION# ====================================================================================================================
; Name ..........: _NetWebView2_CreateManager
; Description ...:
; Syntax ........: _NetWebView2_CreateManager()
; Parameters ....: None
; Return values .: None
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _NetWebView2_CreateManager()
	Local $oMyError = ObjEvent("AutoIt.Error", __NetWebView2_COMErrFunc) ; Local COM Error Handler
	#forceref $oMyError
	Local $oWebV2M = ObjCreate("NetWebView2.Manager") ; REGISTERED VERSION
;~ 	Local $oWebV2M = ObjCreate("NetWebView2.Manager", "{CCB12345-6789-4ABC-DEF0-1234567890AB}", $_g_hNetWebView2Lib_DLL) ; NOT REGISTERED VERSION
;~ 	_NetWebView2_ObjName_FlagsValue($oWebV2M)
	If @error Then __NetWebView2_Log(@ScriptLineNumber, "! [NetWebView2Lib]: Manager Creation ERROR")
	Return SetError(@error, @extended, $oWebV2M)
EndFunc   ;==>_NetWebView2_CreateManager

; #FUNCTION# ====================================================================================================================
; Name ..........: _NetJson_CreateParser
; Description ...:
; Syntax ........: _NetJson_CreateParser([$sInitialJson = "{}"])
; Parameters ....: $sInitialJson        - [optional] a string value. Default is "{}".
; Return values .: None
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _NetJson_CreateParser($sInitialJson = "{}")
	Local $oMyError = ObjEvent("AutoIt.Error", __NetWebView2_COMErrFunc) ; Local COM Error Handler
	#forceref $oMyError
	If $sInitialJson = "" Or $sInitialJson = Default Then $sInitialJson = "{}"
	Local $oParser = ObjCreate("NetJson.Parser") ; REGISTERED VERSION
;~ 	Local $oParser = ObjCreate("NetJson.Parser", "{D1E2F3A4-B5C6-4D7E-8F9A-0B1C2D3E4F5A}", $_g_hNetWebView2Lib_DLL) ; NOT REGISTERED VERSION
	If Not IsObj($oParser) Then Return SetError(1, 0, 0)
	$oParser.Parse($sInitialJson)
	Return $oParser
EndFunc   ;==>_NetJson_CreateParser

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __NetWebView2_Log
; Description ...: Debug Write utility
; Syntax ........: __NetWebView2_Log($s_ScriptLineNumber, $sString[, $iErrorNoLineNo = 1[, $iError = @error[, $iExtended = @extended]]])
; Parameters ....: $s_ScriptLineNumber  - a string value.
;                  $sString             - a string value.
;                  $iErrorNoLineNo      - [optional] an integer value. Default is 1.
;                  $iError              - [optional] an integer value. Default is @error.
;                  $iExtended           - [optional] an integer value. Default is @extended.
; Return values .: None
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __NetWebView2_Log($s_ScriptLineNumber, $sString, $iErrorNoLineNo = 1, $iError = @error, $iExtended = @extended)
	If Not $g_DebugInfo Then Return SetError($iError, $iExtended, 0)
	If $iErrorNoLineNo = 1 Then
		If $iError Then
			$sString = "@@ ( NetWebView2Lib UDF Line: " & $s_ScriptLineNumber & " ) :: @error=" & $iError & ", @extended=" & $iExtended & " :: " & $sString
		Else
			$sString = "+> ( NetWebView2Lib UDF Line: " & $s_ScriptLineNumber & " ) :: " & $sString
		EndIf
	EndIf
	Local $iReturn = ConsoleWrite($sString & @CRLF)
	Return SetError($iError, $iExtended, $iReturn)
EndFunc   ;==>__NetWebView2_Log

; #FUNCTION# ====================================================================================================================
; Name ..........: _NetWebView2_ObjName_FlagsValue
; Description ...:
; Syntax ........: _NetWebView2_ObjName_FlagsValue(ByRef $oObj)
; Parameters ....: $oObj                - [in/out] an object.
; Return values .: None
; Author ........: AutoIt HelpFile ObjName Example 2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _NetWebView2_ObjName_FlagsValue(ByRef $oObj)
	Local $sInfo = ''
	$sInfo &= '+>' & @TAB & 'ObjName($oObj,1) {The name of the Object} =' & @CRLF & @TAB & ObjName($oObj, $OBJ_NAME) & @CRLF

	; HELPFILE REMARKS: Not all Objects support flags 2 to 7. Always test for @error in these cases.
	$sInfo &= '+>' & @TAB & 'ObjName($oObj,2) {Description string of the Object} =' & @CRLF & @TAB & ObjName($oObj, $OBJ_STRING)
	If @error Then $sInfo &= '@error = ' & @error
	$sInfo &= @CRLF & @CRLF

	$sInfo &= '+>' & @TAB & 'ObjName($oObj,3) {The ProgID of the Object} =' & @CRLF & @TAB & ObjName($oObj, $OBJ_PROGID)
	If @error Then $sInfo &= '@error = ' & @error
	$sInfo &= @CRLF & @CRLF

	$sInfo &= '+>' & @TAB & 'ObjName($oObj,4) {The file that is associated with the object in the Registry} =' & @CRLF & @TAB & ObjName($oObj, $OBJ_FILE)
	If @error Then $sInfo &= '@error = ' & @error
	$sInfo &= @CRLF & @CRLF

	$sInfo &= '+>' & @TAB & 'ObjName($oObj,5) {Module name in which the object runs (WIN XP And above). Marshaller for non-inproc objects.} =' & @CRLF & @TAB & ObjName($oObj, $OBJ_MODULE)
	If @error Then $sInfo &= '@error = ' & @error
	$sInfo &= @CRLF & @CRLF

	$sInfo &= '+>' & @TAB & 'ObjName($oObj,6) {CLSID of the object''s coclass} =' & @CRLF & @TAB & ObjName($oObj, $OBJ_CLSID)
	If @error Then $sInfo &= '@error = ' & @error
	$sInfo &= @CRLF & @CRLF

	$sInfo &= '+>' & @TAB & 'ObjName($oObj,7) {IID of the object''s interface} =' & @CRLF & @TAB & ObjName($oObj, $OBJ_IID)
	If @error Then $sInfo &= '@error = ' & @error
	$sInfo &= @CRLF & @CRLF

	ConsoleWrite($sInfo & @CRLF)
EndFunc   ;==>_NetWebView2_ObjName_FlagsValue

#Region ; === EVENT HANDLERS ===
; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __NetWebView2_COMErrFunc
; Description ...:
; Syntax ........: __NetWebView2_COMErrFunc($oError)
; Parameters ....: $oError              - an object.
; Return values .: None
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __NetWebView2_COMErrFunc($oError) ; COM Error Function used by COM Error Handler
	If @Compiled Then Return
	ConsoleWrite("NetWebView2Lib UDF (" & $oError.scriptline & ") : ==> COM Error intercepted !" & @CRLF & _
			@TAB & "err.number is: " & @TAB & @TAB & "0x" & Hex($oError.number) & @CRLF & _
			@TAB & "err.windescription:" & @TAB & $oError.windescription & @CRLF & _
			@TAB & "err.description is: " & @TAB & $oError.description & @CRLF & _
			@TAB & "err.source is: " & @TAB & @TAB & $oError.source & @CRLF & _
			@TAB & "err.helpfile is: " & @TAB & $oError.helpfile & @CRLF & _
			@TAB & "err.helpcontext is: " & @TAB & $oError.helpcontext & @CRLF & _
			@TAB & "err.lastdllerror is: " & @TAB & $oError.lastdllerror & @CRLF & _
			@TAB & "err.scriptline is: " & @TAB & $oError.scriptline & @CRLF & _
			@TAB & "err.retcode is: " & @TAB & "0x" & Hex($oError.retcode) & @CRLF & @CRLF)
EndFunc   ;==>__NetWebView2_COMErrFunc

; Handles native WebView2 events
#TODO => Func __NetWebView2_WebEvents_OnMessageReceived(ByRef $oWebV2M, $sMsg)
Func __NetWebView2_WebEvents_OnMessageReceived($sMsg)
	Local $oMyError = ObjEvent("AutoIt.Error", __NetWebView2_COMErrFunc) ; Local COM Error Handler
	#forceref $oMyError
	__NetWebView2_Log(@ScriptLineNumber, "+++ [WebEvents]: " & (StringLen($sMsg) > 150 ? StringLeft($sMsg, 150) & "..." : $sMsg), 0)
	Local $iSplitPos = StringInStr($sMsg, "|")
	Local $sCommand = $iSplitPos ? StringStripWS(StringLeft($sMsg, $iSplitPos - 1), 3) : $sMsg
	Local $sData = $iSplitPos ? StringTrimLeft($sMsg, $iSplitPos) : ""
	Local $aParts

	Switch $sCommand
		Case "INIT_READY"
			$_g_oWeb.ExecuteScript('window.chrome.webview.postMessage(JSON.stringify({ "type": "COM_TEST", "status": "OK" }));')

		Case "WINDOW_RESIZED"
			$aParts = StringSplit($sData, "|")
			If $aParts[0] >= 2 Then
				Local $iW = Int($aParts[1]), $iH = Int($aParts[2])
				; Filter minor resize glitches
				If $iW > 50 And $iH > 50 Then __NetWebView2_Log(@ScriptLineNumber, "+++ [WebEvents]: WINDOW_RESIZED : " & $iW & "x" & $iH)
			EndIf
	EndSwitch
EndFunc   ;==>__NetWebView2_WebEvents_OnMessageReceived

; Handles custom messages from JavaScript (window.chrome.webview.postMessage)
#TODO => Func __NetWebView2_JSEvents_OnMessageReceived(ByRef $oWebV2M, $sMsg)
Func __NetWebView2_JSEvents_OnMessageReceived($sMsg)
	Local $oMyError = ObjEvent("AutoIt.Error", __NetWebView2_COMErrFunc) ; Local COM Error Handler
	#forceref $oMyError
	__NetWebView2_Log(@ScriptLineNumber, ">>> [JavaScriptEvents]: " & (StringLen($sMsg) > 150 ? StringLeft($sMsg, 150) & "..." : $sMsg), 0)
	Local $sFirstChar = StringLeft($sMsg, 1)

	; 1. Modern JSON Messaging
	If $sFirstChar = "{" Or $sFirstChar = "[" Then
		__NetWebView2_Log(@ScriptLineNumber, "+> : Processing JSON message..." & @CRLF)
		Local $oJSON = _NetJson_CreateParser()
		If Not IsObj($oJSON) Then Return ConsoleWrite("!> Error: Failed to create NetJson object." & @CRLF)

		$oJSON.Parse($sMsg)
		Local $sJobType = $oJSON.GetTokenValue("type")

		Switch $sJobType
			Case "COM_TEST"
				__NetWebView2_Log(@ScriptLineNumber, "- COM_TEST Confirmed: " & $oJSON.GetTokenValue("status") & @CRLF)
		EndSwitch

	Else
		; 2. Legacy / Native Pipe-Delimited Messaging
		__NetWebView2_Log(@ScriptLineNumber, "+> [JavaScriptEvents]: Processing Delimited message...", 0)
		Local $sCommand, $sData, $iSplitPos
		$iSplitPos = StringInStr($sMsg, "|") - 1

		If $iSplitPos < 0 Then
			$sCommand = StringStripWS($sMsg, 3)
			$sData = ""
		Else
			$sCommand = StringStripWS(StringLeft($sMsg, $iSplitPos), 3)
			$sData = StringTrimLeft($sMsg, $iSplitPos + 1)
		EndIf

		Switch $sCommand
			Case "JSON_CLICKED"
				Local $aClickData = StringSplit($sData, "=", 2) ; Split "Key = Value"
				If UBound($aClickData) >= 2 Then
					Local $sKey = StringStripWS($aClickData[0], 3)
					Local $sVal = StringStripWS($aClickData[1], 3)
					__NetWebView2_Log(@ScriptLineNumber, "+++ [JavaScriptEvents]: Property: " & $sKey & " | Value: " & $sVal)
				EndIf

			Case "COM_TEST"
				__NetWebView2_Log(@ScriptLineNumber, "- [JavaScriptEvents]: Status: Legacy COM_TEST: " & $sData)

			Case "ERROR"
				__NetWebView2_Log(@ScriptLineNumber, "! [JavaScriptEvents]: Status: " & $sData)
		EndSwitch
	EndIf
EndFunc   ;==>__NetWebView2_JSEvents_OnMessageReceived

#TODO => Func __NetWebView2_WebEvents_OnContextMenuRequested(ByRef $oWebV2M, $sLink, $iX, $iY, $sSelection)
Func __NetWebView2_WebEvents_OnContextMenuRequested($sLink, $iX, $iY, $sSelection)
	#forceref $sLink, $iX, $iY, $sSelection
	Local $oMyError = ObjEvent("AutoIt.Error", __NetWebView2_COMErrFunc) ; Local COM Error Handler
	#forceref $oMyError
EndFunc   ;==>__NetWebView2_WebEvents_OnContextMenuRequested
#EndRegion ; === EVENT HANDLERS ===

#EndRegion ; NetWebView2Lib UDF
