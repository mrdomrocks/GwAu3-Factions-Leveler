; GUI, Start / Pause, and the main bot loop for the Factions character leveler.
; AutoIt conversion of the Py4GW Factions Character Leveler by Apo and Wick (Divinus).
; Do not use #RequireAdmin. AutoIt always exits to relaunch elevated, and under Wine
; that relaunch never shows a window. Native Windows still needs an admin token to
; read gw.exe, so Leveler_EnsureAdmin() relaunches only when this is not Wine.
; Includes GwAu3 API, Pathfinder, then Leveler_* modules (Const first).

Opt("GUIOnEventMode", True)
Opt("GUICloseOnESC", False)
Opt("ExpandVarStrings", 1)
Opt("TrayAutoPause", 0)
Opt("TrayMenuMode", 1)

; Before GwAu3 loads: Windows relaunches elevated, Wine stays in this process.
Leveler_EnsureAdmin()

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
	$g_h_NameCombo = GUICtrlCreateCombo("", 24, 32, 180, 25, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
	Leveler_FillNameCombo()
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

$g_h_AutoSellCheckbox = GUICtrlCreateCheckbox("Auto Sell", 24, 128, 200, 22)
GUICtrlSetOnEvent($g_h_AutoSellCheckbox, "GuiButtonHandler")

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

$g_h_EditText = _GUICtrlRichEdit_Create($g_h_MainGui, "", 16, 154, 356, 306, BitOR($ES_AUTOVSCROLL, $ES_MULTILINE, $WS_VSCROLL, $ES_READONLY))
_GUICtrlRichEdit_SetBkColor($g_h_EditText, $COLOR_WHITE)

GUICtrlCreateGroup("", -99, -99, 1, 1)
GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit")
GUISetState(@SW_SHOW)
#EndRegion GUI

Out("Factions Character Leveler")
Out("Factions leveler through remaining secondary professions.")
Out("Pathing: GwAu3 Pathfinder plugin + GWPathfinder.dll")
Out("Run AutoIt3 x86 with Guild Wars launched.")
If Leveler_IsWine() Then
	Out("Wine detected. Admin elevation is skipped. Run this in the same prefix as Guild Wars.")
ElseIf Not IsAdmin() Then
	Out("Not running as admin. If the client cannot be read, start AutoIt as administrator.")
EndIf
Local $l_s_ListedChar = Leveler_NormCharName(GUICtrlRead($g_h_NameCombo))
If $l_s_ListedChar = "" Then
	Out("No character was read from Guild Wars. Log in, then press Refresh.")
Else
	Out("Character listed: " & $l_s_ListedChar)
EndIf
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
; Drop a trailing NUL and surrounding whitespace from a character name.
Func Leveler_NormCharName($a_s_Name)
	Local $l_i_Nul = StringInStr($a_s_Name, Chr(0))
	If $l_i_Nul > 0 Then $a_s_Name = StringLeft($a_s_Name, $l_i_Nul - 1)
	Return StringStripWS($a_s_Name, 3)
EndFunc

Func Leveler_NamesMatch($a_s_A, $a_s_B)
	$a_s_A = Leveler_NormCharName($a_s_A)
	$a_s_B = Leveler_NormCharName($a_s_B)
	If $a_s_A = "" Or $a_s_B = "" Then Return False
	Return StringCompare($a_s_A, $a_s_B, 1) = 0
EndFunc

; Put logged-in character names in the combo and select one. Returns the selected name.
Func Leveler_FillNameCombo()
	Local $l_s_Names = Scanner_GetLoggedCharNames()
	GUICtrlSetData($g_h_NameCombo, "")
	If $l_s_Names = "" Then Return ""
	Local $l_s_Default = $l_s_Names
	Local $l_i_Bar = StringInStr($l_s_Names, "|")
	If $l_i_Bar > 1 Then $l_s_Default = StringLeft($l_s_Names, $l_i_Bar - 1)
	If $g_s_MainCharName <> "" Then $l_s_Default = $g_s_MainCharName
	GUICtrlSetData($g_h_NameCombo, $l_s_Names, $l_s_Default)
	Return Leveler_NormCharName(GUICtrlRead($g_h_NameCombo))
EndFunc

; Resolve gw.exe to a PID. One logged-in client is used when the combo text does not match.
Func Leveler_FindGwPid($a_s_Wanted, ByRef $a_s_Seen)
	$a_s_Wanted = Leveler_NormCharName($a_s_Wanted)
	Local $l_as_Procs = ProcessList("gw.exe")
	Local $l_i_Count = 0
	If IsArray($l_as_Procs) Then $l_i_Count = $l_as_Procs[0][0]
	Local $l_ai_NamedPids[1]
	Local $l_as_Named[1]
	Local $l_i_Named = 0
	Local $l_i_OnlyPid = 0
	$a_s_Seen = ""

	For $i = 1 To $l_i_Count
		Local $l_i_Pid = Number($l_as_Procs[$i][1])
		Memory_Open($l_i_Pid)
		Local $l_s_Name = ""
		Local $l_b_Open = False
		If $g_h_GWProcess <> 0 Then $l_b_Open = Scanner_InitializeSections()
		If $l_b_Open Then
			Scanner_ScanForCharname()
			$l_s_Name = Leveler_NormCharName(Player_GetCharName())
			If $l_i_OnlyPid = 0 Then
				$l_i_OnlyPid = $l_i_Pid
			Else
				$l_i_OnlyPid = -1
			EndIf
		EndIf
		Memory_Close()
		If $a_s_Seen <> "" Then $a_s_Seen &= ", "
		$a_s_Seen &= "pid " & $l_i_Pid
		If $l_s_Name <> "" Then
			$a_s_Seen &= " '" & $l_s_Name & "'"
			$l_i_Named += 1
			ReDim $l_ai_NamedPids[$l_i_Named]
			ReDim $l_as_Named[$l_i_Named]
			$l_ai_NamedPids[$l_i_Named - 1] = $l_i_Pid
			$l_as_Named[$l_i_Named - 1] = $l_s_Name
		Else
			$a_s_Seen &= " (no character name)"
		EndIf
		If $a_s_Wanted <> "" And Leveler_NamesMatch($l_s_Name, $a_s_Wanted) Then Return $l_i_Pid
	Next

	If $l_i_Named = 1 Then
		If $a_s_Wanted <> "" And Not Leveler_NamesMatch($l_as_Named[0], $a_s_Wanted) Then
			Out("[Init] Using the only logged-in character '" & $l_as_Named[0] & "' for combo '" & $a_s_Wanted & "'.")
		EndIf
		Return $l_ai_NamedPids[0]
	EndIf
	If $l_i_OnlyPid > 0 Then
		Out("[Init] Character name was not readable. Attaching to the only Guild Wars process " & $l_i_OnlyPid & ".")
		Return $l_i_OnlyPid
	EndIf
	Return SetError(1, 0, 0)
EndFunc

; Attach to the Guild Wars client, reset run flags, and start StatusCheck.
Func StartBot()
	Local $l_s_MainCharName = Leveler_NormCharName(GUICtrlRead($g_h_NameCombo))
	Local $l_s_Seen = ""
	Local $l_i_Pid = 0
	If $g_i_ProcessID Then
		$l_i_Pid = Number($g_i_ProcessID)
	Else
		$l_i_Pid = Leveler_FindGwPid($l_s_MainCharName, $l_s_Seen)
	EndIf
	If $l_i_Pid = 0 Then
		Local $l_s_Why = "Guild Wars is not running."
		If $l_s_MainCharName <> "" Then $l_s_Why = "Could not find a Guild Wars client named '" & $l_s_MainCharName & "'."
		If $l_s_Seen <> "" Then $l_s_Why &= " Saw: " & $l_s_Seen & "."
		Out("[Init] " & $l_s_Why)
		MsgBox(16, "Error", $l_s_Why)
		Return
	EndIf

	$g_p_BasePointer = 0
	$g_h_GWWindow = 0
	Out("[Init] Attaching to pid " & $l_i_Pid & ".")
	Core_Initialize($l_i_Pid, True)
	; A missing window handle used to look like "no client" after a successful scan.
	If $g_h_GWProcess = 0 Or $g_p_BasePointer = 0 Then
		Local $l_s_Why = "Pattern scan failed. Guild Wars may have updated, or AutoIt needs to run as administrator."
		If $g_h_GWProcess = 0 Then $l_s_Why = "Opened pid " & $l_i_Pid & " but could not read Guild Wars. Run AutoIt as administrator."
		Out("[Init] " & $l_s_Why)
		MsgBox(16, "Error", $l_s_Why)
		Return
	EndIf
	; Scanner_GetHwnd only accepts ArenaNet_Dx_Window_Class. Reforged often uses another class, so key lookup misses it.
	Leveler_BindGameWindow($l_i_Pid)

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

#Region Platform
; True when ntdll exports wine_get_version. Native Windows does not.
Func Leveler_IsWine()
	DllCall("ntdll.dll", "ptr", "wine_get_version")
	Local $l_i_Err = @error
	Return $l_i_Err = 0
EndFunc

; Leave this process and start an elevated copy on native Windows. Wine returns immediately.
Func Leveler_EnsureAdmin()
	If Leveler_IsWine() Or IsAdmin() Then Return
	Local $l_i_Arg
	For $l_i_Arg = 1 To $CmdLine[0]
		If $CmdLine[$l_i_Arg] = "-elevated" Then
			MsgBox(16, "Factions Character Leveler", "Windows needs this script to run as administrator so it can read Guild Wars." & @CRLF & "Start AutoIt with Run as administrator.")
			Exit
		EndIf
	Next
	; $CmdLineRaw also contains the script path, and SciTE prefixes AutoIt switches.
	; $CmdLine is only the parameters this script received, so the elevated copy is started once.
	Local $l_s_Args = ""
	Local $l_s_One = ""
	If Not @Compiled Then $l_s_Args = '"' & @ScriptFullPath & '"'
	For $l_i_Arg = 1 To $CmdLine[0]
		$l_s_One = $CmdLine[$l_i_Arg]
		If StringInStr($l_s_One, " ") Or StringInStr($l_s_One, @TAB) Or $l_s_One = "" Then $l_s_One = '"' & $l_s_One & '"'
		If $l_s_Args <> "" Then $l_s_Args &= " "
		$l_s_Args &= $l_s_One
	Next
	If $l_s_Args <> "" Then $l_s_Args &= " "
	$l_s_Args &= "-elevated"
	Local $l_i_Ret = ShellExecute(@AutoItExe, $l_s_Args, @ScriptDir, "runas")
	If $l_i_Ret <= 32 Then
		MsgBox(16, "Factions Character Leveler", "Windows needs this script to run as administrator so it can read Guild Wars." & @CRLF & "The elevation prompt was declined or could not be shown.")
	EndIf
	Exit
EndFunc

; Keep a DX-class handle when it belongs to this pid. Otherwise search by title and size.
Func Leveler_BindGameWindow($a_i_Pid)
	Local $l_h = $g_h_GWWindow
	If $l_h <> 0 And $a_i_Pid > 0 Then
		Local $l_i_Have = Leveler_HwndPid($l_h)
		If $l_i_Have <> 0 And $l_i_Have <> Number($a_i_Pid) Then $l_h = 0
	EndIf
	If $l_h = 0 Then $l_h = Scanner_GetHwnd($a_i_Pid)
	If $l_h = 0 Then $l_h = Leveler_FindGameWindow($a_i_Pid)
	If $l_h = 0 Then
		Out("[Init] Memory is attached. The game window was not found, so key presses may not land.")
		Return False
	EndIf
	$l_h = Leveler_PreferDxChild($l_h)
	$g_h_GWWindow = $l_h
	Local $l_s_Char = Leveler_NormCharName(Player_GetCharName())
	If $l_s_Char <> "" Then
		; Core_GetGuildWarsWindow looks up "Guild Wars - " plus this name. Reforged's own title does not match.
		$g_s_MainCharName = $l_s_Char
		WinSetTitle($g_h_GWWindow, "", "Guild Wars - " & $l_s_Char)
	EndIf
	; WinActivate hangs under Wine. Native Windows needs the game forward so ControlSend lands.
	If Not Leveler_IsWine() Then WinActivate($g_h_GWWindow)
	Out("[Init] Game window found. class=" & Leveler_WindowClass($g_h_GWWindow) & " title=[" & WinGetTitle($g_h_GWWindow) & "]")
	Return True
EndFunc

; Process id that owns a window. GetWindowThreadProcessId still works when WinGetProcess does not.
Func Leveler_HwndPid($a_h)
	If $a_h = 0 Then Return 0
	Local $l_a = DllCall("user32.dll", "dword", "GetWindowThreadProcessId", "hwnd", $a_h, "dword*", 0)
	If IsArray($l_a) Then Return Number($l_a[2])
	Return 0
EndFunc

; Window class name, or an empty string.
Func Leveler_WindowClass($a_h)
	Local $l_a = DllCall("user32.dll", "int", "GetClassNameW", "hwnd", $a_h, "wstr", "", "int", 256)
	If IsArray($l_a) And $l_a[0] > 0 Then Return $l_a[2]
	Return ""
EndFunc

; Client width and height of a window.
Func Leveler_WindowClient($a_h, ByRef $a_i_W, ByRef $a_i_H)
	$a_i_W = 0
	$a_i_H = 0
	Local $l_d = DllStructCreate("long left;long top;long right;long bottom")
	Local $l_a = DllCall("user32.dll", "int", "GetClientRect", "hwnd", $a_h, "ptr", DllStructGetPtr($l_d))
	If IsArray($l_a) And $l_a[0] Then
		$a_i_W = Number(DllStructGetData($l_d, "right"))
		$a_i_H = Number(DllStructGetData($l_d, "bottom"))
	EndIf
EndFunc

; Higher is a better game window. Stubs score -1.
Func Leveler_GameWindowScore($a_h)
	If $a_h = 0 Then Return -1
	Local $l_s_Class = Leveler_WindowClass($a_h)
	Local $l_s_Title = WinGetTitle($a_h)
	If StringInStr($l_s_Class, "IME") Or StringInStr($l_s_Class, "MSCTF") Or StringInStr($l_s_Class, "IoLookup") Then Return -1
	If StringInStr($l_s_Title, "IoLookup") Then Return -1
	Local $l_i_W = 0
	Local $l_i_H = 0
	Leveler_WindowClient($a_h, $l_i_W, $l_i_H)
	Local $l_b_Named = StringInStr($l_s_Title, "Guild Wars") Or StringInStr($l_s_Title, "Reforged")
	Local $l_b_Dx = ($l_s_Class = $GC_S_CLASS_DX_WINDOW)
	If Not $l_b_Named And Not $l_b_Dx And ($l_i_W < 640 Or $l_i_H < 400) Then Return -1
	If $l_i_W > 0 And $l_i_W < 32 And $l_i_H < 32 Then Return -1
	Local $l_i_Score = 0
	If $l_b_Dx Then $l_i_Score += 10000
	If StringInStr($l_s_Title, "Guild Wars") Then $l_i_Score += 8000
	If StringInStr($l_s_Title, "Reforged") Then $l_i_Score += 4000
	If $l_i_W >= 640 And $l_i_H >= 400 Then $l_i_Score += 500 + Int(($l_i_W * $l_i_H) / 1000)
	Return $l_i_Score
EndFunc

; Remember the highest-scoring window that belongs to this Guild Wars pid.
Func Leveler_ConsiderGameWindow($a_h, $a_i_Pid, ByRef $a_h_Best, ByRef $a_i_Best, ByRef $a_s_Seen)
	If $a_h = 0 Then Return
	Local $l_s_Key = "|" & Hex($a_h) & "|"
	If StringInStr($a_s_Seen, $l_s_Key) Then Return
	$a_s_Seen &= $l_s_Key
	Local $l_i_Pid = Leveler_HwndPid($a_h)
	If $a_i_Pid > 0 And $l_i_Pid <> 0 And $l_i_Pid <> Number($a_i_Pid) Then Return
	If $a_i_Pid > 0 And $l_i_Pid = 0 Then
		Local $l_s_Title = WinGetTitle($a_h)
		If Not StringInStr($l_s_Title, "Guild Wars") And Leveler_WindowClass($a_h) <> $GC_S_CLASS_DX_WINDOW Then Return
	EndIf
	Local $l_i_Score = Leveler_GameWindowScore($a_h)
	If $l_i_Score > $a_i_Best Then
		$a_i_Best = $l_i_Score
		$a_h_Best = $a_h
	EndIf
EndFunc

; Use a DX-class child when the top-level Reforged frame is only a wrapper.
Func Leveler_PreferDxChild($a_h)
	If $a_h = 0 Then Return 0
	If Leveler_WindowClass($a_h) = $GC_S_CLASS_DX_WINDOW Then Return $a_h
	Local $l_a = DllCall("user32.dll", "hwnd", "FindWindowExW", "hwnd", $a_h, "hwnd", 0, "wstr", $GC_S_CLASS_DX_WINDOW, "ptr", 0)
	If IsArray($l_a) And $l_a[0] <> 0 Then Return $l_a[0]
	Return $a_h
EndFunc

; Find the Guild Wars or Guild Wars Reforged window for this pid.
Func Leveler_FindGameWindow($a_i_Pid)
	Local $l_h_Best = 0
	Local $l_i_Best = -1
	Local $l_s_Seen = ""
	Local $l_h_Dx = 0
	Local $l_i_N = 0
	While $l_i_N < 8
		Local $l_a_Ex = DllCall("user32.dll", "hwnd", "FindWindowExW", "hwnd", 0, "hwnd", $l_h_Dx, "wstr", $GC_S_CLASS_DX_WINDOW, "ptr", 0)
		If Not IsArray($l_a_Ex) Or $l_a_Ex[0] = 0 Or $l_a_Ex[0] = $l_h_Dx Then ExitLoop
		$l_h_Dx = $l_a_Ex[0]
		Leveler_ConsiderGameWindow($l_h_Dx, $a_i_Pid, $l_h_Best, $l_i_Best, $l_s_Seen)
		$l_i_N += 1
	WEnd

	Local $l_as_Titles[2] = ["Guild Wars Reforged", "Guild Wars"]
	Local $l_i_T = 0
	For $l_i_T = 0 To 1
		Local $l_a_Title = DllCall("user32.dll", "hwnd", "FindWindowW", "ptr", 0, "wstr", $l_as_Titles[$l_i_T])
		If IsArray($l_a_Title) And $l_a_Title[0] <> 0 Then Leveler_ConsiderGameWindow($l_a_Title[0], $a_i_Pid, $l_h_Best, $l_i_Best, $l_s_Seen)
	Next

	Local $l_a_Class = WinList("[CLASS:" & $GC_S_CLASS_DX_WINDOW & "]")
	If IsArray($l_a_Class) Then
		Local $l_i_C = 1
		For $l_i_C = 1 To Number($l_a_Class[0][0])
			Leveler_ConsiderGameWindow($l_a_Class[$l_i_C][1], $a_i_Pid, $l_h_Best, $l_i_Best, $l_s_Seen)
		Next
	EndIf

	; A full WinList hangs under Wine. Windows needs it when Reforged is not the DX class.
	If Not Leveler_IsWine() Then
		Local $l_a_Wins = WinList()
		If IsArray($l_a_Wins) Then
			Local $l_i_W = 1
			For $l_i_W = 1 To $l_a_Wins[0][0]
				Leveler_ConsiderGameWindow($l_a_Wins[$l_i_W][1], $a_i_Pid, $l_h_Best, $l_i_Best, $l_s_Seen)
			Next
		EndIf
	EndIf
	Return $l_h_Best
EndFunc
#EndRegion Platform

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
			Local $l_s_Refreshed = Leveler_FillNameCombo()
			If $l_s_Refreshed = "" Then
				Out("Refresh found no logged-in character.")
			Else
				Out("Character listed: " & $l_s_Refreshed)
			EndIf

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

		Case $g_h_AutoSellCheckbox
			If GetChecked($g_h_AutoSellCheckbox) Then
				$g_i_WhiteSellMap = -1
				Out("Auto Sell is on. Sellable drops go to a merchant. Materials and equipped armor and weapons stay.")
			Else
				Out("Auto Sell is off.")
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
