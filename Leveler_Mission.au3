#include-once

; Ui_EnterChallenge for Cho / Zen (native Canthan), and the wait for the next outpost after a mission.
; Caller adds henchmen first, then Leveler_EnterMission.

#Region Mission

; True when the client is inside a Cho / Zen mission instance (not the outpost lobby).
Func Leveler_InMissionInstance($a_i_MapID = 0)
	If Map_GetInstanceInfo("IsLoading") Then Return False
	If Map_GetInstanceInfo("IsOutpost") Then Return False
	If Not Map_GetInstanceInfo("IsExplorable") Then Return False
	If $a_i_MapID <> 0 And Map_GetMapID() = $a_i_MapID Then Return True
	; Cho and Zen sometimes keep the outpost map ID. The mission area is 257 / 258 when it does not.
	If Map_GetMapID() = $MAP_CHO_OUTPOST Or Map_GetMapID() = $MAP_CHO_MISSION Then Return True
	If Map_GetMapID() = $MAP_ZEN_OP Or Map_GetMapID() = $MAP_ZEN_MISSION Or Map_GetMapID() = $MAP_ZEN_EXP Then Return True
	Return False
EndFunc

; Poll until the mission instance is explorable. Stay silent while loading.
; Do not use Map_WaitMapLoading / Map_WaitMapIsLoaded: Cho / Zen keep the outpost MapID.
Func Leveler_WaitMissionExplorable($a_i_MapID, $a_i_StartMap, $a_i_Timeout = 90000)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If Map_GetInstanceInfo("IsLoading") Then
			Sleep(250)
			ContinueLoop
		EndIf
		If Leveler_InMissionInstance($a_i_MapID) Then Return True
		If Map_GetInstanceInfo("IsExplorable") Then
			Local $l_i_Map = Map_GetMapID()
			If $l_i_Map = $a_i_StartMap Or $l_i_Map = $a_i_MapID Then Return True
		EndIf
		Sleep(250)
	WEnd
	Return Leveler_InMissionInstance($a_i_MapID)
EndFunc

; Henchmen (caller), then native Ui_EnterChallenge.
; $a_b_Foreign = False (native Canthan). Wait ourselves — API Map_WaitMapIsLoaded is wrong for Cho / Zen.
Func Leveler_EnterMission($a_s_Name, $a_i_MapID)
	Local $l_i_StartMap = Map_GetMapID()
	If Leveler_InMissionInstance($a_i_MapID) Then
		Out("[Step] Already inside " & $a_s_Name & " (map " & $l_i_StartMap & ")")
		Return True
	EndIf
	If Not Map_GetInstanceInfo("IsOutpost") Then
		Out("[Step] Cannot enter " & $a_s_Name & " from map " & $l_i_StartMap & " type " & Map_GetInstanceInfo("Type"))
		Return False
	EndIf

	Out("Let's do " & $a_s_Name)
	Out("Exiting Outpost")
	; Native character. Do not use Foreign = True or Map_EnterChallenge.
	Ui_EnterChallenge(False, False)
	If Not Leveler_WaitMissionExplorable($a_i_MapID, $l_i_StartMap) Then
		Out("[Step] Mission map did not become explorable (map " & Map_GetMapID() & ", type " & Map_GetInstanceInfo("Type") & ")")
		Return False
	EndIf
	Sleep(2000)
	Out("[Step] Mission instance loaded on map " & Map_GetMapID())
	Return True
EndFunc

; After a mission ends: skip the cinematic, then wait for whatever outpost the
; game loads. Do not travel and do not require a specific map ID.
Func Leveler_WaitMissionOutpost($a_i_Timeout = 60000)
	Local $l_i_StartMap = Map_GetMapID()
	If Map_GetInstanceInfo("IsOutpost") And Not Map_GetInstanceInfo("IsLoading") And Not Game_GetGameInfo("IsCinematic") Then
		If Not Leveler_InMissionInstance() Then Return True
	EndIf

	Local $l_h_Timer = TimerInit()
	Local $l_b_Skipped = False
	While TimerDiff($l_h_Timer) < 20000
		If $g_b_LevelerPaused Then Return False
		If Game_GetGameInfo("IsCinematic") Or Leveler_InCinematic() Then ExitLoop
		If Map_GetInstanceInfo("IsLoading") Then ExitLoop
		If Map_GetInstanceInfo("IsOutpost") And Map_GetMapID() <> $l_i_StartMap Then
			Out("[Step] Next outpost loaded: map " & Map_GetMapID())
			Return True
		EndIf
		Sleep(200)
	WEnd

	If (Game_GetGameInfo("IsCinematic") Or Leveler_InCinematic()) And Not Map_GetInstanceInfo("IsLoading") Then
		Other_PingSleep(1500)
		Local $l_h_Skip = TimerInit()
		While (Game_GetGameInfo("IsCinematic") Or Leveler_InCinematic()) And Not Map_GetInstanceInfo("IsLoading") And TimerDiff($l_h_Skip) < 8000
			Cinematic_SkipCinematic()
			$l_b_Skipped = True
			Sleep(250)
		WEnd
		If $l_b_Skipped Then Out("[Step] Skipped mission cinematic")
	EndIf

	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If (Game_GetGameInfo("IsCinematic") Or Leveler_InCinematic()) And Not Map_GetInstanceInfo("IsLoading") Then
			Cinematic_SkipCinematic()
			Sleep(250)
			ContinueLoop
		EndIf
		If Map_GetInstanceInfo("IsLoading") Then
			Sleep(250)
			ContinueLoop
		EndIf
		If Map_GetInstanceInfo("IsOutpost") And Leveler_ClientIsReady() Then
			Out("[Step] Next outpost loaded: map " & Map_GetMapID())
			Return True
		EndIf
		Sleep(250)
	WEnd

	If Map_GetInstanceInfo("IsOutpost") And Not Map_GetInstanceInfo("IsLoading") Then
		Out("[Step] Next outpost loaded: map " & Map_GetMapID())
		Return True
	EndIf
	Out("[Step] Next outpost did not load (map " & Map_GetMapID() & ", type " & Map_GetInstanceInfo("Type") & ")")
	Return False
EndFunc

#EndRegion Mission
