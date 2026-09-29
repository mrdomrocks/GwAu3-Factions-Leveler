#include-once

; Ui_EnterChallenge for Cho / Zen (native Canthan), and the wait for the next outpost after a mission.
; Caller adds henchmen, walks out the portal and back, then Leveler_EnterMission.
; Enter Challenge in the same instance that just changed the party crashes the client with 007.

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

; Explorable on the far side of a mission-outpost portal.
Func Leveler_MissionPortalMap($a_i_Outpost, $a_i_Map)
	If $a_i_Outpost = $MAP_CHO_OUTPOST Then
		Return $a_i_Map = $MAP_SUNQUA_VALE Or $a_i_Map = $MAP_CHO_EXPLORABLE
	EndIf
	If $a_i_Outpost = $MAP_ZEN_OP Then Return $a_i_Map = $MAP_HAIJU
	Return False
EndFunc

; Portal coordinate for these two outposts. Cho uses Sunqua Vale, beside the spawn.
; Zen uses Haiju Lagoon. Cho's other gate opens the explorable and a restart there skips the mission.
Func Leveler_KnownMissionPortal($a_i_FromMap, $a_i_ToMap = 0)
	Local $l_af_XY[2]
	Switch $a_i_FromMap
		Case $MAP_CHO_OUTPOST
			$l_af_XY[0] = 6921
			$l_af_XY[1] = -11388
		Case $MAP_SUNQUA_VALE
			If $a_i_ToMap <> 0 And $a_i_ToMap <> $MAP_CHO_OUTPOST Then Return 0
			$l_af_XY[0] = 6975
			$l_af_XY[1] = 16535
		Case $MAP_CHO_EXPLORABLE
			If $a_i_ToMap <> 0 And $a_i_ToMap <> $MAP_CHO_OUTPOST Then Return 0
			$l_af_XY[0] = 7684
			$l_af_XY[1] = -6887
		Case $MAP_ZEN_OP
			$l_af_XY[0] = 19354
			$l_af_XY[1] = 14378
		Case $MAP_HAIJU
			If $a_i_ToMap <> 0 And $a_i_ToMap <> $MAP_ZEN_OP Then Return 0
			$l_af_XY[0] = 15973
			$l_af_XY[1] = -22787
		Case Else
			Return 0
	EndSwitch
	Return $l_af_XY
EndFunc

; Live travel-portal prop, already offset through the gate. 0 when the map has none.
Func Leveler_NearestPortalXY()
	Local $l_a_Portal = Map_GetNearestTravelPortal(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), 150)
	If Not IsArray($l_a_Portal) Then Return 0
	If UBound($l_a_Portal) < 2 Then Return 0
	Local $l_af_XY[2]
	$l_af_XY[0] = $l_a_Portal[0]
	$l_af_XY[1] = $l_a_Portal[1]
	Return $l_af_XY
EndFunc

; Walk through a portal. Success is leaving $a_i_LeaveMap, whatever map loads next.
Func Leveler_CrossPortal($a_f_X, $a_f_Y, $a_i_LeaveMap)
	If Map_GetMapID() <> $a_i_LeaveMap Then Return Leveler_WaitUntilMapReady()
	Leveler_MoveTo($a_f_X, $a_f_Y, False)
	If Map_GetMapID() <> $a_i_LeaveMap Then Return Leveler_WaitUntilMapReady()

	Local $i
	Local $l_f_DirX = 0
	Local $l_f_DirY = 0
	For $i = 1 To 12
		If Map_GetMapID() <> $a_i_LeaveMap Then ExitLoop
		If Map_GetInstanceInfo("IsLoading") Then ExitLoop
		Local $l_f_MyX = Agent_GetAgentInfo(-2, "X")
		Local $l_f_MyY = Agent_GetAgentInfo(-2, "Y")
		Local $l_f_Dx = $a_f_X - $l_f_MyX
		Local $l_f_Dy = $a_f_Y - $l_f_MyY
		Local $l_f_Len = Sqrt($l_f_Dx * $l_f_Dx + $l_f_Dy * $l_f_Dy)
		If $l_f_Len > 80 Then
			$l_f_DirX = $l_f_Dx / $l_f_Len
			$l_f_DirY = $l_f_Dy / $l_f_Len
		EndIf
		If $l_f_DirX = 0 And $l_f_DirY = 0 Then
			Map_MoveLayer($a_f_X, $a_f_Y, Agent_GetAgentInfo(-2, "Plane"))
		Else
			Map_MoveLayer($a_f_X + $l_f_DirX * 300, $a_f_Y + $l_f_DirY * 300, Agent_GetAgentInfo(-2, "Plane"))
		EndIf
		Sleep(400)
	Next
	If Map_GetMapID() <> $a_i_LeaveMap Then Return Leveler_WaitUntilMapReady()

	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < 20000
		If $g_b_LevelerPaused Then Return False
		If Map_GetInstanceInfo("IsLoading") Then
			Sleep(250)
			ContinueLoop
		EndIf
		If Map_GetMapID() <> $a_i_LeaveMap And Leveler_ClientIsReady() Then Return Leveler_WaitUntilMapReady()
		Sleep(250)
	WEnd
	If Map_GetMapID() <> $a_i_LeaveMap Then Return Leveler_WaitUntilMapReady()
	Out("[Step] Portal at " & Round($a_f_X) & ", " & Round($a_f_Y) & " did not leave map " & $a_i_LeaveMap)
	Return False
EndFunc

; Leave the current map through the nearest portal that is the outpost's explorable exit.
Func Leveler_LeaveViaPortal($a_i_Outpost)
	Local $l_i_Start = Map_GetMapID()
	Local $l_af_Known = Leveler_KnownMissionPortal($l_i_Start)
	Local $l_af_Near = Leveler_NearestPortalXY()
	Local $l_f_X
	Local $l_f_Y
	If IsArray($l_af_Near) Then
		$l_f_X = $l_af_Near[0]
		$l_f_Y = $l_af_Near[1]
		If IsArray($l_af_Known) Then
			Local $l_f_Dx = $l_af_Near[0] - $l_af_Known[0]
			Local $l_f_Dy = $l_af_Near[1] - $l_af_Known[1]
			If Sqrt($l_f_Dx * $l_f_Dx + $l_f_Dy * $l_f_Dy) > 2500 Then
				$l_f_X = $l_af_Known[0]
				$l_f_Y = $l_af_Known[1]
			EndIf
		EndIf
	ElseIf IsArray($l_af_Known) Then
		$l_f_X = $l_af_Known[0]
		$l_f_Y = $l_af_Known[1]
	Else
		Out("[Step] No portal on map " & $l_i_Start)
		Return False
	EndIf

	Out("[Step] Walking out the portal at " & Round($l_f_X) & ", " & Round($l_f_Y))
	If Leveler_CrossPortal($l_f_X, $l_f_Y, $l_i_Start) Then Return True
	If Not IsArray($l_af_Known) Then Return False
	If Abs($l_af_Known[0] - $l_f_X) < 400 And Abs($l_af_Known[1] - $l_f_Y) < 400 Then Return False
	Out("[Step] Retrying the outpost portal at " & Round($l_af_Known[0]) & ", " & Round($l_af_Known[1]))
	Return Leveler_CrossPortal($l_af_Known[0], $l_af_Known[1], $l_i_Start)
EndFunc

; From the explorable, walk the portal that returns to the mission outpost.
Func Leveler_ReturnToMissionOutpost($a_i_Outpost)
	If Map_GetMapID() = $a_i_Outpost And Map_GetInstanceInfo("IsOutpost") Then Return Leveler_WaitUntilMapReady()
	If Leveler_InMissionInstance($a_i_Outpost) Then Return True

	Local $l_i_Here = Map_GetMapID()
	Local $l_af_Back = Leveler_KnownMissionPortal($l_i_Here, $a_i_Outpost)
	Local $l_af_Near = Leveler_NearestPortalXY()
	Local $l_f_X
	Local $l_f_Y
	Local $l_b_Have = False
	If IsArray($l_af_Near) And IsArray($l_af_Back) Then
		Local $l_f_Dx = $l_af_Near[0] - $l_af_Back[0]
		Local $l_f_Dy = $l_af_Near[1] - $l_af_Back[1]
		If Sqrt($l_f_Dx * $l_f_Dx + $l_f_Dy * $l_f_Dy) < 2500 Then
			$l_f_X = $l_af_Near[0]
			$l_f_Y = $l_af_Near[1]
			$l_b_Have = True
		EndIf
	EndIf
	If Not $l_b_Have And IsArray($l_af_Back) Then
		$l_f_X = $l_af_Back[0]
		$l_f_Y = $l_af_Back[1]
		$l_b_Have = True
	EndIf
	If Not $l_b_Have And IsArray($l_af_Near) Then
		$l_f_X = $l_af_Near[0]
		$l_f_Y = $l_af_Near[1]
		$l_b_Have = True
	EndIf
	If Not $l_b_Have Then
		Out("[Step] No portal back to outpost " & $a_i_Outpost & " from map " & $l_i_Here)
		Return False
	EndIf

	Out("[Step] Walking back into the outpost via " & Round($l_f_X) & ", " & Round($l_f_Y))
	If Not Leveler_CrossPortal($l_f_X, $l_f_Y, $l_i_Here) Then Return False
	If Map_GetMapID() = $a_i_Outpost And Map_GetInstanceInfo("IsOutpost") Then Return True
	Out("[Step] Portal led to map " & Map_GetMapID() & ", not outpost " & $a_i_Outpost)
	Return False
EndFunc

; After the party is formed: out the portal, back in, and do not touch the party.
Func Leveler_SettlePartyForMission($a_i_Outpost)
	If Leveler_InMissionInstance($a_i_Outpost) Then Return True
	If Map_GetMapID() <> $a_i_Outpost Or Not Map_GetInstanceInfo("IsOutpost") Then
		Return Leveler_ReturnToMissionOutpost($a_i_Outpost)
	EndIf

	Out("[Step] Party stays as it is. Walking out the portal and back before the mission")
	If Not Leveler_LeaveViaPortal($a_i_Outpost) Then Return False
	If Leveler_InMissionInstance($a_i_Outpost) Then Return True
	If Not Map_GetInstanceInfo("IsExplorable") Then
		Out("[Step] Portal did not reach an explorable (map " & Map_GetMapID() & ", type " & Map_GetInstanceInfo("Type") & ")")
		Return False
	EndIf
	Return Leveler_ReturnToMissionOutpost($a_i_Outpost)
EndFunc

#EndRegion Mission
