; GUI, Start / Pause, and the main bot loop for the Factions character leveler.
; AutoIt conversion of the Py4GW Factions Character Leveler by Apo and Wick (Divinus).
; Do not use #RequireAdmin: AutoIt exits the first process to relaunch elevated,
; and under Wine that relaunch fails so the window never appears.
; Includes GwAu3 API, Pathfinder, then Leveler_* modules (Const first).

Opt("GUIOnEventMode", True)
Opt("GUICloseOnESC", False)
Opt("ExpandVarStrings", 1)
Opt("TrayAutoPause", 0)
Opt("TrayMenuMode", 1)

#include "../../API/_GwAu3.au3"
#include "../../API/Plugins/Pathfinder/_Pathfinder.au3"
#include "Leveler_Const.au3"
#include "Leveler_UtilityAI.au3"
#include "Leveler_Move.au3"
#include "Leveler_Quest.au3"
#include "Leveler_Prof.au3"
#include "Leveler_Henchman.au3"
#include "Leveler_Party.au3"
#include "Leveler_Mission.au3"
#include "Leveler_Craft.au3"
#include "Leveler_Status.au3"
#include "Leveler_Steps.au3"

Global Const $GC_B_LOAD_LOGGED_CHARS = True

$DLL_PATH = @ScriptDir & "\..\..\API\Plugins\Pathfinder\GWPathfinder.dll"

#Region Declarations
Global $g_i_ProcessID = ""
Global $g_i_Timer = TimerInit()
Global $g_b_BotRunning = False
Global $g_b_BotCoreInitialized = False
Global Const $GC_S_BOT_TITLE = "Factions Character Leveler"

$g_b_AutoStart = False
$g_s_MainCharName = ""
#EndRegion Declarations

For $i = 1 To $CmdLine[0]
	If $CmdLine[$i] = "-character" And $i < $CmdLine[0] Then
		$g_s_MainCharName = $CmdLine[$i + 1]
		; Core_AutoStart() reads $g_bAutoStart from GwAu3_Const_Core.au3.
		$g_bAutoStart = True
		$g_b_AutoStart = True
		ExitLoop
	EndIf
Next

#Region GUI
$g_h_MainGui = GUICreate($GC_S_BOT_TITLE, 640, 480, -1, -1, -1, BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE))
GUISetBkColor(0xEAEAEA, $g_h_MainGui)
GUICtrlCreateGroup("Factions Leveler  -  through remaining secondary professions", 8, 8, 624, 464)

Global $g_h_NameCombo
If $GC_B_LOAD_LOGGED_CHARS Then
	$g_h_NameCombo = GUICtrlCreateCombo($g_s_MainCharName, 24, 32, 180, 25, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
	GUICtrlSetData(-1, Scanner_GetLoggedCharNames())
Else
	$g_h_NameCombo = GUICtrlCreateInput($g_s_MainCharName, 24, 32, 180, 25)
EndIf

$g_h_OnTopCheckbox = GUICtrlCreateCheckbox("On Top", 220, 31, 60, 24)
GUICtrlSetState($g_h_OnTopCheckbox, $GUI_CHECKED)
GUICtrlSetOnEvent($g_h_OnTopCheckbox, "GuiButtonHandler")

$g_h_DebugCheckbox = GUICtrlCreateCheckbox("Debug", 286, 31, 56, 24)
GUICtrlSetState($g_h_DebugCheckbox, $GUI_CHECKED)
GUICtrlSetOnEvent($g_h_DebugCheckbox, "GuiButtonHandler")

$g_h_InfKitCheckbox = GUICtrlCreateCheckbox("Inf Ident/Salvage Pick Up", 348, 31, 260, 24)
GUICtrlSetOnEvent($g_h_InfKitCheckbox, "GuiButtonHandler")

$g_h_UnlockProfsCheckbox = GUICtrlCreateCheckbox("Unlock All Secondary Professions", 24, 104, 250, 22)
GUICtrlSetOnEvent($g_h_UnlockProfsCheckbox, "GuiButtonHandler")

$g_h_StartButton = GUICtrlCreateButton("Start", 24, 72, 80, 25)
GUICtrlSetOnEvent($g_h_StartButton, "GuiButtonHandler")

$g_h_PauseButton = GUICtrlCreateButton("Pause", 112, 72, 80, 25)
GUICtrlSetOnEvent($g_h_PauseButton, "GuiButtonHandler")
GUICtrlSetState($g_h_PauseButton, $GUI_DISABLE)
; Keep Enter from activating Pause once Start is disabled.
Global $g_h_DummyDefault = GUICtrlCreateButton("", -200, -200, 1, 1)
GUICtrlSetState($g_h_DummyDefault, BitOR($GUI_HIDE, $GUI_DEFBUTTON))

$g_h_RefreshButton = GUICtrlCreateButton("Refresh", 200, 72, 80, 25)
GUICtrlSetOnEvent($g_h_RefreshButton, "GuiButtonHandler")

GUICtrlCreateLabel("Progress:", 300, 76, 80, 20)
$g_h_StepList = GUICtrlCreateListView("Step", 384, 72, 230, 388, BitOR($LVS_REPORT, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS, $LVS_NOCOLUMNHEADER, $LVS_NOSORTHEADER), $WS_EX_CLIENTEDGE)
_GUICtrlListView_SetExtendedListViewStyle($g_h_StepList, $LVS_EX_FULLROWSELECT)
_GUICtrlListView_SetColumnWidth($g_h_StepList, 0, 206)
For $i = 0 To $LEVELER_STEP_COUNT - 1
	GUICtrlCreateListViewItem($g_as_StepNames[$i], $g_h_StepList)
	$g_ab_StepDone[$i] = False
Next
_GUICtrlListView_SetItemSelected($g_h_StepList, 0, True, True)
GUICtrlSetOnEvent($g_h_StepList, "GuiButtonHandler")
GUIRegisterMsg($WM_NOTIFY, "Leveler_WM_NOTIFY")

Global Const $LEVELER_TAG_NMLVCUSTOMDRAW = $tagNMHDR & ";dword dwDrawStage;handle hdc;int Left;int Top;int Right;int Bottom;dword_ptr dwItemSpec;uint uItemState;lparam lItemlParam;dword clrText;dword clrTextBk;int iSubItem"

$g_h_EditText = _GUICtrlRichEdit_Create($g_h_MainGui, "", 16, 132, 356, 328, BitOR($ES_AUTOVSCROLL, $ES_MULTILINE, $WS_VSCROLL, $ES_READONLY))
_GUICtrlRichEdit_SetBkColor($g_h_EditText, $COLOR_WHITE)

GUICtrlCreateGroup("", -99, -99, 1, 1)
GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit")
GUISetState(@SW_SHOW)
#EndRegion GUI

Out("Factions Character Leveler")
Out("Factions leveler through remaining secondary professions.")
Out("Pathing: GwAu3 Pathfinder plugin + GWPathfinder.dll")
Out("Run AutoIt3 x86 with Guild Wars launched.")
If Not IsAdmin() Then Out("Not running as admin. If the client cannot be read, start AutoIt as administrator.")
Out("")

; GwAu3 Log_Message scrolls this control with Edit APIs. That crashes AutoIt on a RichEdit.
$g_s_Log_Callback = "Leveler_LogCallback"

#Region Main Loop
Core_AutoStart()

While 1
	Sleep(80)
	If $g_b_BotCoreInitialized And $g_b_BotRunning And Not $g_b_LevelerPaused Then
		If $g_b_NeedStatusCheck Then
			$g_i_Step = Leveler_StatusCheck()
			$g_b_NeedStatusCheck = False
			Out("Starting at step: " & $g_i_Step & " — " & $g_as_StepNames[$g_i_Step])
		ElseIf $g_i_Step >= $LEVELER_STEP_DONE Then
			Out("Remaining secondary professions unlocked. Leveler is done.")
			$g_b_BotRunning = False
			GUICtrlSetData($g_h_StartButton, "Start")
			GUICtrlSetState($g_h_PauseButton, $GUI_DISABLE)
		Else
			If Not Leveler_ExecuteStep($g_i_Step) Then Sleep(500)
		EndIf
	EndIf
WEnd
#EndRegion Main Loop

#Region Bot
; Attach to the Guild Wars client, reset run flags, and start StatusCheck.
Func StartBot()
	Local $l_s_MainCharName = GUICtrlRead($g_h_NameCombo)
	Local $l_i_Init = 0
	If $l_s_MainCharName = "" Then
		$l_i_Init = Core_Initialize(ProcessExists("gw.exe"), True)
	ElseIf $g_i_ProcessID Then
		Local $l_i_ProcIdInt = Number($g_i_ProcessID, 2)
		$l_i_Init = Core_Initialize($l_i_ProcIdInt, True)
	Else
		$l_i_Init = Core_Initialize($l_s_MainCharName, True)
	EndIf
	If $l_i_Init = 0 Then
		Local $l_i_Err = @error
		Local $l_s_Why = "Guild Wars is not running."
		If $l_i_Err = 2 Then $l_s_Why = "Pattern scan failed. Guild Wars may have updated, or AutoIt needs to run as administrator."
		If $l_s_MainCharName <> "" And $l_i_Err <> 2 Then $l_s_Why = "Could not find a Guild Wars client named '" & $l_s_MainCharName & "'."
		Out("[Init] " & $l_s_Why)
		MsgBox(16, "Error", $l_s_Why)
		Return
	EndIf

	GUICtrlSetState($g_h_NameCombo, $GUI_DISABLE)
	GUICtrlSetState($g_h_RefreshButton, $GUI_DISABLE)
	GUICtrlSetState($g_h_PauseButton, $GUI_ENABLE)
	GUICtrlSetData($g_h_StartButton, "Running")
	GUICtrlSetState($g_h_StartButton, $GUI_DISABLE)

	WinSetTitle($g_h_MainGui, "", Player_GetCharName() & " - " & $GC_S_BOT_TITLE)
	GUICtrlSetState($g_h_DummyDefault, $GUI_DEFBUTTON)
	ControlFocus($g_h_MainGui, "", $g_h_DummyDefault)
	$g_b_BotRunning = True
	$g_b_BotCoreInitialized = True
	$g_b_LevelerPaused = False
	$g_b_LevelerFailed = False
	$g_b_NeedStatusCheck = True
	$g_b_PunchClownSettled = False
	$g_b_InfKitsClaimed = False
	$g_i_InfKitTravelFails = 0
	$g_b_InfKitsNoSpace = False
	$g_b_LostTreasureToTenguOnce = False
	$g_b_ExplorableResume = True
	$g_b_CureStepLocked = False
	Leveler_RefreshQuestFlags(True)

	Out("Initialized for: " & Player_GetCharName())
	Out("Map: " & Map_GetMapID() & "  Pos: " & Round(Agent_GetAgentInfo(-2, "X")) & ", " & Round(Agent_GetAgentInfo(-2, "Y")))
	If Not Leveler_IsOutpost() Then Out("Restart recovery is on. Will resume the current quest here if it is in the log.")
	Out("Core ready. Returning to the run loop.")
EndFunc

; Pause or resume the run loop. Resume queues a fresh StatusCheck.
Func TogglePause()
	If Not $g_b_BotCoreInitialized Then Return
	$g_b_LevelerPaused = Not $g_b_LevelerPaused
	If $g_b_LevelerPaused Then
		$g_b_BotRunning = False
		GUICtrlSetData($g_h_PauseButton, "Resume")
		GUICtrlSetState($g_h_StartButton, $GUI_ENABLE)
		GUICtrlSetData($g_h_StartButton, "Start")
		Out("Paused. Use Resume from to pick a step, then Start.")
	Else
		$g_b_BotRunning = True
		$g_b_NeedStatusCheck = True
		GUICtrlSetData($g_h_PauseButton, "Pause")
		GUICtrlSetData($g_h_StartButton, "Running")
		GUICtrlSetState($g_h_StartButton, $GUI_DISABLE)
		GUICtrlSetState($g_h_DummyDefault, $GUI_DEFBUTTON)
		ControlFocus($g_h_MainGui, "", $g_h_DummyDefault)
		Out("Resuming. Status check will run on the next loop tick.")
	EndIf
EndFunc

#EndRegion Bot

#Region GUI Helpers
; Return the Progress list index the user has selected.
Func Leveler_GetSelectedStep()
	Local $l_s_Idx = _GUICtrlListView_GetSelectedIndices($g_h_StepList)
	If $l_s_Idx = "" Then Return 0
	Return Number($l_s_Idx)
EndFunc

; Grey finished steps through the current one and select it in the list.
Func Leveler_UpdateStepCombo()
	If $g_i_Step < 0 Then Return
	If $g_i_Step > 0 Then Leveler_MarkStepsThrough($g_i_Step - 1)
	Leveler_RefreshStepList($g_i_Step)
EndFunc

; Rewrite Progress list text (x prefix for done) and optionally select a row.
Func Leveler_RefreshStepList($a_i_Select = -1)
	For $i = 0 To $LEVELER_STEP_COUNT - 1
		Local $l_s_Text = $g_as_StepNames[$i]
		If $g_ab_StepDone[$i] Then $l_s_Text = "x  " & $l_s_Text
		_GUICtrlListView_SetItemText($g_h_StepList, $i, $l_s_Text)
	Next
	If $a_i_Select >= 0 Then
		_GUICtrlListView_SetItemSelected($g_h_StepList, $a_i_Select, True, True)
		_GUICtrlListView_EnsureVisible($g_h_StepList, $a_i_Select)
	EndIf
	_WinAPI_RedrawWindow(GUICtrlGetHandle($g_h_StepList))
EndFunc

; Custom-draw handler: grey out completed steps in the Progress list.
Func Leveler_WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam
	Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	If HWnd(DllStructGetData($tNMHDR, "hWndFrom")) <> GUICtrlGetHandle($g_h_StepList) Then Return $GUI_RUNDEFMSG
	If DllStructGetData($tNMHDR, "Code") <> $NM_CUSTOMDRAW Then Return $GUI_RUNDEFMSG

	Local $tNMLVCD = DllStructCreate($LEVELER_TAG_NMLVCUSTOMDRAW, $lParam)
	Local $iDrawStage = DllStructGetData($tNMLVCD, "dwDrawStage")
	If $iDrawStage = 0x1 Then Return 0x20 ; CDDS_PREPAINT -> CDRF_NOTIFYITEMDRAW
	If $iDrawStage = 0x10001 Then ; CDDS_ITEMPREPAINT
		Local $iItem = DllStructGetData($tNMLVCD, "dwItemSpec")
		If $iItem >= 0 And $iItem < $LEVELER_STEP_COUNT And $g_ab_StepDone[$iItem] Then
			DllStructSetData($tNMLVCD, "clrText", 0x808080)
			DllStructSetData($tNMLVCD, "clrTextBk", 0xEAEAEA)
		EndIf
		Return 0x2 ; CDRF_NEWFONT
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc

; Route Start, Pause, Refresh, On Top, Debug, and step-list clicks.
Func GuiButtonHandler()
	Switch @GUI_CtrlId
		Case $g_h_StartButton
			If $g_b_BotCoreInitialized Then
				$g_b_LevelerPaused = False
				$g_b_BotRunning = True
				$g_b_NeedStatusCheck = True
				GUICtrlSetData($g_h_StartButton, "Running")
				GUICtrlSetState($g_h_StartButton, $GUI_DISABLE)
				GUICtrlSetData($g_h_PauseButton, "Pause")
				GUICtrlSetState($g_h_PauseButton, $GUI_ENABLE)
				GUICtrlSetState($g_h_DummyDefault, $GUI_DEFBUTTON)
				ControlFocus($g_h_MainGui, "", $g_h_DummyDefault)
				Out("Start pressed. Status check will run on the next loop tick.")
			Else
				StartBot()
			EndIf

		Case $g_h_StepList
			$g_i_Step = Leveler_GetSelectedStep()
			Out("Selected step: " & $g_i_Step & " — " & $g_as_StepNames[$g_i_Step])

		Case $g_h_PauseButton
			TogglePause()

		Case $g_h_RefreshButton
			GUICtrlSetData($g_h_NameCombo, "")
			GUICtrlSetData($g_h_NameCombo, Scanner_GetLoggedCharNames())

		Case $g_h_OnTopCheckbox
			If GetChecked($g_h_OnTopCheckbox) Then
				WinSetOnTop($g_h_MainGui, "", 1)
			Else
				WinSetOnTop($g_h_MainGui, "", 0)
			EndIf

		Case $g_h_DebugCheckbox
			If GetChecked($g_h_DebugCheckbox) Then
				Log_SetDebugMode(True)
			Else
				Log_SetDebugMode(False)
			EndIf

		Case $g_h_InfKitCheckbox
			If GetChecked($g_h_InfKitCheckbox) Then
				$g_b_InfKitsClaimed = False
				Out("Inf Ident/Salvage Pick Up is on. One trip to The Purveyor once the Great Temple of Balthazar is unlocked.")
			Else
				Out("Inf Ident/Salvage Pick Up is off.")
			EndIf

		Case $g_h_UnlockProfsCheckbox
			If GetChecked($g_h_UnlockProfsCheckbox) Then
				Out("Unlock All Secondary Professions is on. Trainers at the Great Temple will be paid.")
			Else
				Out("Unlock All Secondary Professions is off. That step will be skipped.")
			EndIf

		Case $GUI_EVENT_CLOSE
			_Exit()
	EndSwitch
EndFunc

; Append a line to the log pane, clearing it if it is about to overflow.
Func Out($a_s_Text)
	Leveler_LogLine($a_s_Text, 0x000000)
EndFunc

; RichEdit only. _GUICtrlEdit_* on this control crashes AutoIt during init logging.
Func Leveler_LogLine($a_s_Text, $a_i_Color = 0x000000)
	If $g_h_EditText = 0 Then Return
	If _GUICtrlRichEdit_GetTextLength($g_h_EditText) > 30000 Then _GUICtrlRichEdit_SetText($g_h_EditText, "")
	_GUICtrlRichEdit_SetSel($g_h_EditText, -1, -1)
	_GUICtrlRichEdit_SetCharColor($g_h_EditText, $a_i_Color)
	_GUICtrlRichEdit_AppendText($g_h_EditText, $a_s_Text & @CRLF)
EndFunc

; GwAu3 log hook. Writes API messages into the GUI log pane.
Func Leveler_LogCallback($a_s_Message, $a_i_MsgType, $a_s_Author)
	Local $l_i_Color = 0x008000
	Local $l_s_Type = "INFO"
	Switch $a_i_MsgType
		Case $GC_I_LOG_MSGTYPE_DEBUG
			If Not $g_b_DebugMode Then Return
			$l_s_Type = "DEBUG"
			$l_i_Color = 0xFFA500
		Case $GC_I_LOG_MSGTYPE_WARNING
			$l_s_Type = "WARNING"
			$l_i_Color = 0x00C8FF
		Case $GC_I_LOG_MSGTYPE_ERROR
			$l_s_Type = "ERROR"
			$l_i_Color = 0x0000CC
		Case $GC_I_LOG_MSGTYPE_CRITICAL
			$l_s_Type = "CRITICAL"
			$l_i_Color = 0x0000FF
	EndSwitch
	Leveler_LogLine("[" & $l_s_Type & "] [" & $a_s_Author & "] " & $a_s_Message, $l_i_Color)
EndFunc

; True when the checkbox is checked.
Func GetChecked($a_h_Ctrl)
	If BitAND(GUICtrlRead($a_h_Ctrl), $GUI_CHECKED) = $GUI_CHECKED Then
		Return True
	Else
		Return False
	EndIf
EndFunc

; Shut down Pathfinder and leave the script.
Func _Exit()
	Pathfinder_Shutdown()
	Exit
EndFunc

#EndRegion GUI Helpers
