; AutoIt ScriptOMatic
; -------------------
;
; AutoIt's counterpart of Microsoft's Scriptomatic
;
; Author:		SvenP
; Date/version:	2005-04-17
; See also:		http://www.microsoft.com/technet/scriptcenter/tools/scripto2.mspx
; Requires:		AutoIt beta version 3.1.1.8 or higher (COM support!!)
;
; GUI generated by AutoBuilder 0.5 Prototype

#include <GuiConstantsEx.au3>
#include <WindowsConstants.au3>

; ************************
; * Global State Variables
; ************************
Global $g_strCurrentNamespace = "\root\CIMV2"
Global $g_iCurrentNamespaceIndex = 0
Global $g_strWMISource = "localhost"
Global $g_strOutputFormat = "Dialog"

; ************************
; * Main GUI
; ************************

GUICreate("AutoIt Scriptomatic Tool", 684, 561, (@DesktopWidth - 684) / 2, (@DesktopHeight - 561) / 2, $WS_OVERLAPPEDWINDOW + $WS_VISIBLE + $WS_CLIPSIBLINGS)

Global $GUI_AST_MainGroup = GUICtrlCreateGroup("", 10, 10, 660, 530)
Global $GUI_WMI_NamespaceLabel = GUICtrlCreateLabel("WMI Namespace", 20, 30, 150, 20)
Global $GUI_WMI_Namespace = GUICtrlCreateCombo("WMI_Namespaces", 20, 50, 280, 21)
Global $GUI_WMI_ClassLabel = GUICtrlCreateLabel("WMI Class", 320, 30, 140, 20)
Global $GUI_WMI_Classes = GUICtrlCreateCombo("WMI_Classes", 320, 50, 340, 21)
Global $GUI_AST_Web = GUICtrlCreateButton("Lookup on WWW", 560, 27, 100, 20)
Global $GUI_AST_ButtonGroup = GUICtrlCreateGroup("", 10, 80, 660, 50)
Global $GUI_AST_Run = GUICtrlCreateButton("Run", 20, 100, 50, 20)
Global $GUI_AST_CIMv2 = GUICtrlCreateButton("CIMv2", 80, 100, 50, 20)
Global $GUI_AST_WMISource = GUICtrlCreateButton("WMISource", 140, 100, 70, 20)
Global $GUI_AST_Open = GUICtrlCreateButton("Open", 220, 100, 60, 20)
Global $GUI_AST_Save = GUICtrlCreateButton("Save", 290, 100, 60, 20)
Global $GUI_AST_Quit = GUICtrlCreateButton("Quit", 360, 100, 60, 20)
Global $GUI_AST_OptionGroup = GUICtrlCreateGroup("Output", 430, 80, 240, 50)
Global $GUI_AST_RadioDialog = GUICtrlCreateRadio("Dialog", 440, 100, 50, 20)
Global $GUI_AST_RadioText = GUICtrlCreateRadio("Text", 510, 100, 50, 20)
Global $GUI_AST_RadioHTML = GUICtrlCreateRadio("HTML", 570, 100, 50, 20)
Global $GUI_AST_ScriptCode = GUICtrlCreateEdit("One moment...", 20, 140, 640, 390)

GUISetState()

; Initial GUI Settings
GUICtrlSetState($GUI_AST_Web, $GUI_DISABLE)
GUICtrlSetState($GUI_AST_Run, $GUI_DISABLE)
GUICtrlSetState($GUI_AST_Save, $GUI_DISABLE)
GUICtrlSetState($GUI_AST_RadioDialog, $GUI_CHECKED)

; Fill the WMI_Namespaces Combobox
LoadWMINamespaces()

; Fill the WMI_Classes Combobox
HandleNamespaceChange()

Local $msg
While 1
	$msg = GUIGetMsg()
	Select
		Case $msg = $GUI_EVENT_CLOSE
			ExitLoop
		Case $msg = $GUI_AST_Quit
			ExitLoop
		Case $msg = $GUI_WMI_Namespace
			HandleNamespaceChange()
		Case $msg = $GUI_WMI_Classes
			ComposeCode()
		Case $msg = $GUI_AST_Web
			LookupWeb()
		Case $msg = $GUI_AST_Run
			RunScript()
		Case $msg = $GUI_AST_Save
			SaveScript()
		Case $msg = $GUI_AST_Open
			OpenScript()
		Case $msg = $GUI_AST_CIMv2
			SetNamespaceToCIMV2()
		Case $msg = $GUI_AST_WMISource
			SetWMIRepository()
		Case $msg = $GUI_AST_RadioDialog Or _
				$msg = $GUI_AST_RadioText Or _
				$msg = $GUI_AST_RadioHTML
			HandleOutputChange()
	EndSelect
WEnd

GUIDelete()

Exit

; ********************************************************************
; * LoadWMINamespaces
; ********************************************************************
Func LoadWMINamespaces()
	Local $strCsvListOfNamespaces = ""
	Local $strNameSpacesCombo = ""

	Local $strWaitNamespaces = "Please wait, Loading WMI Namespaces"
	GUICtrlSetData($GUI_WMI_Namespace, $strWaitNamespaces, $strWaitNamespaces)

	EnumNamespaces("root", $strCsvListOfNamespaces)

	Local $arrNamespaces = StringSplit($strCsvListOfNamespaces, ",")

	For $strNamespace In $arrNamespaces
		$strNameSpacesCombo = $strNameSpacesCombo & "|" & $strNamespace
	Next

	GUICtrlSetData($GUI_WMI_Namespace, $strNameSpacesCombo, "ROOT\CIMV2")
EndFunc   ;==>LoadWMINamespaces

; ********************************************************************
; * EnumNamespaces
; ********************************************************************
Func EnumNamespaces($strNamespace, ByRef $tmpCsvListOfNamespaces)
	If $tmpCsvListOfNamespaces = "" Then
		$tmpCsvListOfNamespaces = $strNamespace
	Else
		$tmpCsvListOfNamespaces = $tmpCsvListOfNamespaces & "," & $strNamespace
	EndIf

	; Local $strComputer = $g_strWMISource
	Local $objWMIService = ObjGet("winmgmts:\\" & $g_strWMISource & "\" & $strNamespace)

	If Not @error Then

		Local $colNameSpaces = $objWMIService.InstancesOf("__NAMESPACE")

		For $objNameSpace In $colNameSpaces
			EnumNamespaces($strNamespace & "\" & $objNameSpace.Name, $tmpCsvListOfNamespaces)
		Next
	Else
		$tmpCsvListOfNamespaces = ""
	EndIf
EndFunc   ;==>EnumNamespaces

; ********************************************************************
; * HandleNamespaceChange
; ********************************************************************
Func HandleNamespaceChange()
	;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	; Clear the WMI classes pulldown location.
	;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	Local $strSelectedNamespace = GUICtrlRead($GUI_WMI_Namespace)

	; Disable the namespace combobox until class load has been completed
	GUICtrlSetState($GUI_WMI_Namespace, $GUI_DISABLE)

	Local $strWMIWaitMsg = "Please wait, trying to load WMI Classes in namespace " & $strSelectedNamespace
	GUICtrlSetData($GUI_WMI_Classes, $strWMIWaitMsg, $strWMIWaitMsg)
	GUICtrlSetData($GUI_AST_ScriptCode, "One moment...", "")

	LoadWMIClasses()
	$g_strCurrentNamespace = "\" & $strSelectedNamespace

	;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	; Clear the code textarea and disable run and save.
	;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	GUICtrlSetData($GUI_AST_ScriptCode, "", "")

	GUICtrlSetState($GUI_WMI_Namespace, $GUI_ENABLE)
	GUICtrlSetState($GUI_AST_Run, $GUI_DISABLE)
	GUICtrlSetState($GUI_AST_Save, $GUI_DISABLE)
EndFunc   ;==>HandleNamespaceChange

; ********************************************************************
; * LoadWMIClasses
; *
; * Fetch all the classes in the currently selected namespace, and
; * populate the keys of a dictionary object with the names of all
; * dynamic (non-association) classes. Then we transfer the keys to
; * an array, sort the array, and finally use the sorted array to
; * populate the WMI classes pulldown.
; ********************************************************************
Func LoadWMIClasses()
	Const $SORT_KEYS = 1
	; Const $SORT_ITEMS = 2

	Local $objClassDictionary = ObjCreate("Scripting.Dictionary")
	Local $objQualifierDictionary = ObjCreate("Scripting.Dictionary")

	Local $strComputer = "."
	Local $objWMIService = ObjGet("winmgmts:\\" & $strComputer & $g_strCurrentNamespace)

	If Not @error Then

		For $objClass In $objWMIService.SubclassesOf()

			For $objQualifier In $objClass.Qualifiers_() ; Dummy (), because it ends with an underscore !
				$objQualifierDictionary.Add(StringLower($objQualifier.Name), "")
			Next

			If $objQualifierDictionary.Exists("dynamic") Then

				;$TempVar = $objClass.Path_.Class
				;$objClassDictionary.Add($TempVar, "")	; Can't use object in arguments ?!!

				$objClassDictionary.Add($objClass.Path_.Class, "")

			EndIf

			$objQualifierDictionary.RemoveAll

		Next

		$objQualifierDictionary = ""

		;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
		; If the current namespace contains dynamic classes...
		;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
		If $objClassDictionary.Count Then

			;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
			; Sort the dictionary.
			;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
			SortDictionary($objClassDictionary, $SORT_KEYS)

			;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
			; Populate the WMI classes pulldown with the sorted dictionary.
			;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

			Local $strClassesCombo = "|Select a WMI class"

			For $strWMIClass In $objClassDictionary ;  method .Keys is not an object ??
				$strClassesCombo = $strClassesCombo & "|" & $strWMIClass
			Next

			GUICtrlSetData($GUI_WMI_Classes, $strClassesCombo, "Select a WMI class")

		EndIf
	EndIf

	If @error Or $objClassDictionary.Count = 0 Then
		;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
		; And If the current namespace doesn't contain dynamic classes.
		;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
		GUICtrlSetData($GUI_WMI_Classes, "|No dynamic classes found in current namespace.|Select a different namespace", "")

	EndIf

	$objClassDictionary = ""
EndFunc   ;==>LoadWMIClasses

; ********************************************************************
; * SortDictionary
; *
; * Shell sort based on:
; * http://support.microsoft.com/support/kb/articles/q246/0/67.asp
; ********************************************************************
Func SortDictionary(ByRef $objDict, $intSort)
	Const $dictKey = 1
	Const $dictItem = 2

	Local $strDict[1][3]

	Local $intCount = $objDict.Count

	If $intCount > 1 Then

		ReDim $strDict[$intCount][3]

		Local $i = 0
		For $objKey In $objDict

			$strDict[$i][$dictKey] = String($objKey)
			$strDict[$i][$dictItem] = String($objDict($objKey))

			$i = $i + 1
		Next

		;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
		; Perform a shell sort of the 2D string array
		;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
		For $i = 0 To ($intCount - 2)
			For $j = $i To ($intCount - 1)
				If $strDict[$i][$intSort] > $strDict[$j][$intSort] Then
					Local $strKey = $strDict[$i][$dictKey]
					Local $strItem = $strDict[$i][$dictItem]
					$strDict[$i][$dictKey] = $strDict[$j][$dictKey]
					$strDict[$i][$dictItem] = $strDict[$j][$dictItem]
					$strDict[$j][$dictKey] = $strKey
					$strDict[$j][$dictItem] = $strItem
				EndIf
			Next
		Next

		;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
		; Erase the contents of the dictionary object
		;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
		$objDict.RemoveAll

		;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
		; Repopulate the dictionary with the sorted information
		;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
		For $i = 0 To ($intCount - 1)
			$objDict.Add($strDict[$i][$dictKey], $strDict[$i][$dictItem])
		Next

	EndIf
EndFunc   ;==>SortDictionary

; ********************************************************************
; * ComposeCode
; ********************************************************************
Func ComposeCode()
	Local $objClass = ""

	Local $strSelectedClass = GUICtrlRead($GUI_WMI_Classes)
	; Check If a valid class has been selected
	If $strSelectedClass <> "Select a WMI class" Then

		Local $bHasDates = False ; Flag: output has date fields
		Local $strHeaderStart = Chr(34)
		Local $strRowStart = Chr(34)
		Local $strColumnSeparator = ": "
		Local $strRowEnd = " & @CRLF"

		Local $strComputerCommand = "$strComputer = " & Chr(34) & $g_strWMISource & Chr(34)

		Local $objWMIService = ObjGet("winmgmts:{impersonationLevel=impersonate}!\\" & @ComputerName & $g_strCurrentNamespace)
		$objClass = $objWMIService.Get($strSelectedClass)

		If IsObj($objClass) Then

			Local $strScriptCode = ""
			$strScriptCode = $strScriptCode & "; Generated by AutoIt Scriptomatic" & @CRLF & @CRLF
			$strScriptCode = $strScriptCode & "$wbemFlagReturnImmediately = 0x10" & @CRLF
			$strScriptCode = $strScriptCode & "$wbemFlagForwardOnly = 0x20" & @CRLF
			$strScriptCode = $strScriptCode & '$colItems = ""' & @CRLF
			$strScriptCode = $strScriptCode & $strComputerCommand & @CRLF & @CRLF
			$strScriptCode = $strScriptCode & '$Output=""' & @CRLF

			If $g_strOutputFormat = "HTML" Then
				$strScriptCode = $strScriptCode & "$Output = $Output & '<html><head><title>Scriptomatic HTML Output</title></head><body> " & _
						"<style>table {font-size: 10pt; font-family: arial;} th {background-color: buttonface; font-decoration: bold;} " & _
						"</style><table BORDER=" & Chr(34) & "1" & Chr(34) & "><tr><th>Property</th><th>Value</th></tr>'" & @CRLF
				$strRowStart = Chr(34) & "<tr><td>"
				$strHeaderStart = "'<tr bgcolor=" & Chr(34) & "yellow" & Chr(34) & "><td>' & " & Chr(34)
				$strColumnSeparator = "</td><td>&nbsp;"
				$strRowEnd = " & " & Chr(34) & "</td></tr>" & Chr(34) & " & @CRLF"
			EndIf

			$strScriptCode = $strScriptCode & "$Output = $Output & " & $strHeaderStart & "Computer" & $strColumnSeparator & Chr(34) & " & $strComputer " & $strRowEnd & @CRLF

			If $g_strOutputFormat = "Dialog" Then
				$strScriptCode = $strScriptCode & "$Output = $Output & " & Chr(34) & "==========================================" & Chr(34) & $strRowEnd & @CRLF
			EndIf

			$strScriptCode = $strScriptCode & "$objWMIService = ObjGet(" & Chr(34) & "winmgmts:\\" & Chr(34) & " & $strComputer & " & Chr(34) & $g_strCurrentNamespace & Chr(34) & ")" & @CRLF
			$strScriptCode = $strScriptCode & "$colItems = $objWMIService.ExecQuery(" & Chr(34) & "SELECT * FROM " & $strSelectedClass & Chr(34) & ", " & Chr(34) & "WQL" & Chr(34) & ", _" & @CRLF
			$strScriptCode = $strScriptCode & "                                          $wbemFlagReturnImmediately + $wbemFlagForwardOnly)" & @CRLF & @CRLF
			$strScriptCode = $strScriptCode & "If IsObj($colItems) Then" & @CRLF
			$strScriptCode = $strScriptCode & "   For $objItem In $colItems" & @CRLF

			For $objProperty In $objClass.Properties_() ; Must use (), because method ends with an underscore

				If $objProperty.IsArray = True Then
					$strScriptCode = $strScriptCode & "      $str" & $objProperty.Name & " = $objItem." & $objProperty.Name & "(0)" & @CRLF
					$strScriptCode = $strScriptCode & "      $Output = $Output & " & $strRowStart & $objProperty.Name & $strColumnSeparator & Chr(34) & " & $str" & $objProperty.Name & $strRowEnd & @CRLF
				ElseIf $objProperty.CIMTYPE = 101 Then
					$bHasDates = True
					$strScriptCode = $strScriptCode & "      $Output = $Output & " & $strRowStart & $objProperty.Name & $strColumnSeparator & Chr(34) & " & WMIDateStringToDate($objItem." & $objProperty.Name & ")" & $strRowEnd & @CRLF
				Else
					$strScriptCode = $strScriptCode & "      $Output = $Output & " & $strRowStart & $objProperty.Name & $strColumnSeparator & Chr(34) & " & $objItem." & $objProperty.Name & $strRowEnd & @CRLF
				EndIf
			Next

			If $g_strOutputFormat = "Dialog" Then
				$strScriptCode = $strScriptCode & '      If MsgBox(1,"WMI Output",$Output) = 2 Then ExitLoop' & @CRLF
				$strScriptCode = $strScriptCode & '      $Output=""' & @CRLF
			EndIf
			$strScriptCode = $strScriptCode & "   Next" & @CRLF

			If $g_strOutputFormat = "Text" Then
				$strScriptCode = $strScriptCode & '   ConsoleWrite($Output)' & @CRLF
				$strScriptCode = $strScriptCode & '   FileWrite(@TempDir & "\' & $strSelectedClass & '.TXT", $Output )' & @CRLF
				$strScriptCode = $strScriptCode & '   Run(@ComSpec & " /c start " & @TempDir & "\' & $strSelectedClass & '.TXT" )' & @CRLF
			ElseIf $g_strOutputFormat = "HTML" Then
				$strScriptCode = $strScriptCode & '   FileWrite(@TempDir & "\' & $strSelectedClass & '.HTML", $Output )' & @CRLF
				$strScriptCode = $strScriptCode & '   Run(@ComSpec & " /c start " & @TempDir & "\' & $strSelectedClass & '.HTML" )' & @CRLF
			EndIf

			$strScriptCode = $strScriptCode & "Else" & @CRLF
			$strScriptCode = $strScriptCode & '   MsgBox(0,"WMI Output","No WMI Objects Found for class: " & ' & Chr(34) & $strSelectedClass & Chr(34) & ' )' & @CRLF

			$strScriptCode = $strScriptCode & "EndIf" & @CRLF
			$strScriptCode = $strScriptCode & @CRLF & @CRLF

			If $bHasDates Then
				$strScriptCode = $strScriptCode & "Func WMIDateStringToDate($dtmDate)" & @CRLF
				$strScriptCode = $strScriptCode & @CRLF
				$strScriptCode = $strScriptCode & Chr(9) & "Return (StringMid($dtmDate, 5, 2) & ""/"" & _" & @CRLF
				$strScriptCode = $strScriptCode & Chr(9) & "StringMid($dtmDate, 7, 2) & ""/"" & StringLeft($dtmDate, 4) _" & @CRLF
				$strScriptCode = $strScriptCode & Chr(9) & "& "" "" & StringMid($dtmDate, 9, 2) & "":"" & StringMid($dtmDate, 11, 2) & "":"" & StringMid($dtmDate,13, 2))" & @CRLF
				$strScriptCode = $strScriptCode & "EndFunc"
			EndIf
		Else
			$strScriptCode = "Error: No Class properties found for " & $g_strCurrentNamespace & "\" & $strSelectedClass
		EndIf

		GUICtrlSetData($GUI_AST_ScriptCode, $strScriptCode)

		;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
		; Once the code is successfully composed and put into the
		; textarea, ensure that the run and save buttons are enabled.
		;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

		GUICtrlSetState($GUI_AST_Run, $GUI_ENABLE)
		GUICtrlSetState($GUI_AST_Save, $GUI_ENABLE)

		; Enable Web lookup button
		GUICtrlSetState($GUI_AST_Web, $GUI_ENABLE)
	Else
		; Disable Web, Run and Save buttons, because no valid code has been generated
		GUICtrlSetState($GUI_AST_Web, $GUI_DISABLE)
		GUICtrlSetState($GUI_AST_Run, $GUI_DISABLE)
		GUICtrlSetState($GUI_AST_Save, $GUI_DISABLE)
	EndIf
EndFunc   ;==>ComposeCode

; ********************************************************************
; * RunScript
; ********************************************************************
Func RunScript()
	;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	; Create a temporary script file named "temp_script.au3".
	;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

	Local $strTmpName = @TempDir & "\temp_script.au3"

	If FileExists($strTmpName) Then FileDelete($strTmpName)

	FileWrite($strTmpName, GUICtrlRead($GUI_AST_ScriptCode))

	;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	; Start constructing the command line that will run the script...
	;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	Local $strCmdLine = @AutoItExe & " " & $strTmpName

	RunWait($strCmdLine)

	FileDelete($strTmpName)
EndFunc   ;==>RunScript

; ********************************************************************
; * SaveScript
; ********************************************************************
Func SaveScript()
	Local $strTmpName = FileSaveDialog("Save Script", @DesktopDir, "AutoIt3 Scripts (*.au3)", 16, GUICtrlRead($GUI_WMI_Classes))

	If Not @error And $strTmpName <> "" Then
		If StringRight($strTmpName, 4) <> ".AU3" Then $strTmpName = $strTmpName & ".AU3"
		If FileExists($strTmpName) Then FileDelete($strTmpName)
		FileWrite($strTmpName, GUICtrlRead($GUI_AST_ScriptCode))
	EndIf
EndFunc   ;==>SaveScript

; ********************************************************************
; * OpenScript
; ********************************************************************

Func OpenScript()
	Local $strTmpName = FileOpenDialog("Open Script", @DesktopDir, "AutoIt3 Scripts (*.au3)")

	If Not @error And $strTmpName <> "" Then
		If FileExists($strTmpName) Then
			GUICtrlSetData($GUI_AST_ScriptCode, FileRead($strTmpName, FileGetSize($strTmpName)))
		EndIf
	EndIf
EndFunc   ;==>OpenScript

; ****************************************************************************
; * SetNamespaceToCIMV2
; ****************************************************************************
Func SetNamespaceToCIMV2()
	If StringUpper(GUICtrlRead($GUI_WMI_Namespace)) <> "ROOT\CIMV2" Then
		GUICtrlSetData($GUI_WMI_Namespace, "ROOT\CIMV2", "ROOT\CIMV2")
		HandleNamespaceChange()
	EndIf
EndFunc   ;==>SetNamespaceToCIMV2

; ****************************************************************************
; * SetWMIRepository
; ****************************************************************************
Func SetWMIRepository()
	Local $strWMISourceName = InputBox("Set WMI Repository Source", _
			"Please enter the computer whose WMI repository you want to read from: ", _
			$g_strWMISource)
	If $strWMISourceName <> "" Then

		$g_strWMISource = StringStripWS($strWMISourceName, 1 + 2)
		;target_computers.Value = $g_strWMISource
		LoadWMINamespaces()
	EndIf
EndFunc   ;==>SetWMIRepository

; ****************************************************************************
; * HandleOutputChange
; ****************************************************************************
Func HandleOutputChange()
	Local $ChosenFormat = $g_strOutputFormat
	If GUICtrlRead($GUI_AST_RadioDialog) = $GUI_CHECKED Then $ChosenFormat = "Dialog"
	If GUICtrlRead($GUI_AST_RadioText) = $GUI_CHECKED Then $ChosenFormat = "Text"
	If GUICtrlRead($GUI_AST_RadioHTML) = $GUI_CHECKED Then $ChosenFormat = "HTML"
	If $ChosenFormat <> $g_strOutputFormat Then
		$g_strOutputFormat = $ChosenFormat
		ComposeCode()
	EndIf
EndFunc   ;==>HandleOutputChange

; ****************************************************************************
; * LookupWeb
; ****************************************************************************
Func LookupWeb()
	Local $strSelectedClass = GUICtrlRead($GUI_WMI_Classes)

	; Check If a valid class has been selected
	If $strSelectedClass <> "Select a WMI class" Then
		Run(@ComSpec & " /c start http://msdn.microsoft.com/library/en-us/wmisdk/wmi/" & $strSelectedClass & ".asp?frame=true", "", @SW_HIDE)
	EndIf
EndFunc   ;==>LookupWeb
