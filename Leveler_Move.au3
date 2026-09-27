#include-once

; Pathfinder, travel, NPC talk, combat waits, punch-out, and wipe recover.

#Region Pathfinder
; Load GWPathfinder.dll without blocking on maps.rar.

; Load the Pathfinder DLL only. Skip Pathfinder_Initialize() so we do not block
; on the GitHub maps.rar check / download during Start.
Func Leveler_EnsurePathfinder()
	If $DLL_PATH = "" Then
		$DLL_PATH = @ScriptDir & "\..\..\API\Plugins\Pathfinder\GWPathfinder.dll"
	EndIf
	If $g_hPathfinderDLL <> 0 And $g_hPathfinderDLL <> -1 Then Return True

	If Not FileExists($DLL_PATH) Then
		Out("[Move] Pathfinder DLL missing; using direct Map_Move fallback.")
		Return False
	EndIf

	$g_hPathfinderDLL = DllOpen($DLL_PATH)
	If $g_hPathfinderDLL = -1 Then
		Out("[Move] Pathfinder DLL failed to load; using direct Map_Move fallback.")
		Return False
	EndIf

	Local $l_av_Init = DllCall($g_hPathfinderDLL, "int:cdecl", "Initialize")
	If @error Or Not IsArray($l_av_Init) Then
		Out("[Move] Pathfinder Initialize call failed; using direct Map_Move fallback.")
		Return False
	EndIf
	If $l_av_Init[0] = 2 Then
		Out("[Move] Pathfinder maps.rar not found yet; using direct Map_Move until maps are present.")
	ElseIf $l_av_Init[0] = 0 Then
		Out("[Move] Pathfinder Initialize returned 0; using direct Map_Move fallback.")
		Return False
	EndIf
	Return True
EndFunc
#EndRegion Pathfinder

#Region Movement
; Pathfinder_MoveTo / Map_MoveLayer wrappers and portal exits.
; Bridges need Pathfinder layers — plain Map_Move sticks on elevated paths.

; Fight in explorables and punch-out instances. Stay pacifist in outposts.
Func Leveler_ShouldFightHere()
	If Map_GetInstanceInfo("IsLoading") Then Return False
	If Map_GetInstanceInfo("IsOutpost") Then Return False
	If Leveler_IsPunchoutMap() Then Return True
	Return Map_GetInstanceInfo("IsExplorable") = True
EndFunc

; $a_b_Combat True = fight while walking. False is ignored in explorables.
; Outposts never fight. Returns True if we arrived or the map changed.
; Missions / explorables always prefer Pathfinder_MoveTo (Map_MoveLayer) so bridges work.
Func Leveler_MoveTo($a_f_X, $a_f_Y, $a_b_Combat = False)
	If $g_b_LevelerPaused Then Return False
	If $g_b_KilroyMode Or $g_b_FarmMode Or Leveler_IsPunchoutMap() Then Leveler_HandleKilroyDeath()
	If Leveler_IsWiped() Then Return False

	If Leveler_ShouldFightHere() Then
		$a_b_Combat = True
		$g_b_CombatMode = True
	ElseIf Map_GetInstanceInfo("IsOutpost") Then
		$a_b_Combat = False
	EndIf

	; Punch-out arenas: AU3 Runner_MoveAndFight (walk, clear foes, resume). No Pathfinder/UAI.
	If Leveler_IsPunchoutMap() And $a_b_Combat Then
		Return Leveler_MoveAndFight($a_f_X, $a_f_Y)
	EndIf

	Local $l_i_StartMap = Map_GetMapID()
	Local $l_b_Mission = Leveler_InMissionInstance()
	Local $l_b_Explorable = Leveler_ShouldFightHere()
	Leveler_EnsurePathfinder()

	Local $l_v_Obstacles = 0
	; Aggro -1 so Pathfinder's UAI_Fight exits before UAI_UseSkills. Aggro 0 still runs when distance is 0.
	Local $l_i_Aggro = -1
	If $a_b_Combat Then
		Leveler_PrepareCombatAI()
		; Mission bridges are single-file. Enemy obstacles block A* on the only walkable strip.
		If Not $l_b_Mission Then $l_v_Obstacles = "Leveler_GetObstacles"
	EndIf

	$g_b_LevelerPathCombat = $a_b_Combat
	Local $l_s_Callback = ""
	If $a_b_Combat Or $g_b_SpiritRiftWatch Then $l_s_Callback = "Leveler_PathCombat"

	Local $l_b_Ok = False
	Local $l_b_HaveMesh = Pathfinder_IsMapAvailable($l_i_StartMap)
	; Missions and explorables: always Pathfinder_MoveTo so waypoints use Map_MoveLayer.
	If $l_b_HaveMesh Or $l_b_Mission Or $l_b_Explorable Then
		If Not $l_b_HaveMesh Then
			Out("[Move] No path mesh flag for map " & $l_i_StartMap & "; Pathfinder_MoveTo still used for layer-aware bridges")
		EndIf
		$l_b_Ok = Pathfinder_MoveTo($a_f_X, $a_f_Y, -1, $l_v_Obstacles, $l_i_Aggro, $LEVELER_FIGHT_RANGE_OUT, 0, $l_s_Callback)
		If Not $l_b_Ok And Map_GetMapID() = $l_i_StartMap And Agent_GetDistanceToXY($a_f_X, $a_f_Y) >= $LEVELER_ARRIVE_RANGE Then
			If $l_v_Obstacles <> 0 Then
				Out("[Move] Retrying Pathfinder without combat obstacles")
				$l_b_Ok = Pathfinder_MoveTo($a_f_X, $a_f_Y, -1, 0, $l_i_Aggro, $LEVELER_FIGHT_RANGE_OUT, 0, $l_s_Callback)
			EndIf
		EndIf
		If Not $l_b_Ok And Map_GetMapID() = $l_i_StartMap And Agent_GetDistanceToXY($a_f_X, $a_f_Y) >= $LEVELER_ARRIVE_RANGE Then
			Out("[Move] Pathfinder did not arrive; falling back to layer-aware direct move")
			$l_b_Ok = Leveler_MoveDirect($a_f_X, $a_f_Y, 90000, $a_b_Combat)
		EndIf
	Else
		$l_b_Ok = Leveler_MoveDirect($a_f_X, $a_f_Y, 90000, $a_b_Combat)
	EndIf

	If Map_GetMapID() <> $l_i_StartMap Then Return True
	If Leveler_IsWiped() Then Return False
	If $a_b_Combat And Not Map_GetInstanceInfo("IsLoading") And Not $g_b_KilroyRecovery Then Leveler_LootNearby(0, 1200, 2500)
	If Agent_GetDistanceToXY($a_f_X, $a_f_Y) < $LEVELER_ARRIVE_RANGE Then Return True
	Return $l_b_Ok
EndFunc

; Run to a point without stopping to fight. One path is followed to the end.
; Enemy obstacles are used for the first path so Destroyers are skirted when the mesh allows.
; Rebuilding that path every tick, and cancelling the move, only stepped two waypoints at a time.
Func Leveler_RunTo($a_f_X, $a_f_Y, $a_i_Timeout = 180000)
	If $g_b_LevelerPaused Then Return False
	Leveler_SetPacifist()
	Leveler_EnsurePathfinder()
	Local $l_i_StartMap = Map_GetMapID()
	Local $l_b_Avoid = True
	Local $l_a_Path = Leveler_BuildRunPath($a_f_X, $a_f_Y, True)
	If Not IsArray($l_a_Path) Or UBound($l_a_Path) = 0 Then
		$l_b_Avoid = False
		$l_a_Path = Leveler_BuildRunPath($a_f_X, $a_f_Y, False)
		Out("[Move] No path around enemies. Running straight to " & Round($a_f_X) & ", " & Round($a_f_Y))
	Else
		Out("[Move] Running to " & Round($a_f_X) & ", " & Round($a_f_Y) & " (" & UBound($l_a_Path) & " waypoints, no fighting)")
	EndIf

	Local $l_i_Index = 0
	Local $l_h_Timer = TimerInit()
	Local $l_h_Stuck = TimerInit()
	Local $l_f_StuckX = Agent_GetAgentInfo(-2, "X")
	Local $l_f_StuckY = Agent_GetAgentInfo(-2, "Y")

	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If Leveler_IsWiped() Then Return False
		If Map_GetMapID() <> $l_i_StartMap Then Return True
		If Agent_GetDistanceToXY($a_f_X, $a_f_Y) < $LEVELER_ARRIVE_RANGE Then Return True

		If IsArray($l_a_Path) Then
			While $l_i_Index < UBound($l_a_Path)
				If Agent_GetDistanceToXY($l_a_Path[$l_i_Index][0], $l_a_Path[$l_i_Index][1]) >= 300 Then ExitLoop
				$l_i_Index += 1
			WEnd
		EndIf

		Local $l_f_GoX = $a_f_X
		Local $l_f_GoY = $a_f_Y
		Local $l_i_GoLayer = Agent_GetAgentInfo(-2, "Plane")
		If IsArray($l_a_Path) And $l_i_Index < UBound($l_a_Path) Then
			$l_f_GoX = $l_a_Path[$l_i_Index][0]
			$l_f_GoY = $l_a_Path[$l_i_Index][1]
			$l_i_GoLayer = $l_a_Path[$l_i_Index][2]
		EndIf
		Map_MoveLayer($l_f_GoX, $l_f_GoY, $l_i_GoLayer)

		If TimerDiff($l_h_Stuck) > 2500 Then
			Local $l_f_NowX = Agent_GetAgentInfo(-2, "X")
			Local $l_f_NowY = Agent_GetAgentInfo(-2, "Y")
			Local $l_f_Moved = Sqrt(($l_f_NowX - $l_f_StuckX) ^ 2 + ($l_f_NowY - $l_f_StuckY) ^ 2)
			If $l_f_Moved < 120 Then
				If $l_b_Avoid Then
					$l_b_Avoid = False
					Out("[Move] Avoid path is blocked. Running through to " & Round($a_f_X) & ", " & Round($a_f_Y))
				EndIf
				$l_a_Path = Leveler_BuildRunPath($a_f_X, $a_f_Y, False)
				$l_i_Index = 0
			EndIf
			$l_f_StuckX = $l_f_NowX
			$l_f_StuckY = $l_f_NowY
			$l_h_Stuck = TimerInit()
		EndIf
		Sleep(50)
	WEnd
	If Map_GetMapID() <> $l_i_StartMap Then Return True
	Return Agent_GetDistanceToXY($a_f_X, $a_f_Y) < $LEVELER_ARRIVE_RANGE
EndFunc

; Pathfinder path to a point. $a_b_Avoid adds nearby obstacles so the run steps around them.
Func Leveler_BuildRunPath($a_f_X, $a_f_Y, $a_b_Avoid)
	Local $l_v_Obs = 0
	If $a_b_Avoid Then $l_v_Obs = Leveler_GetObstacles(400, 2500)
	Local $l_a_Path = _Pathfinder_GetPath(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), Agent_GetAgentInfo(-2, "Plane"), $a_f_X, $a_f_Y, -1, $l_v_Obs)
	If IsArray($l_a_Path) And UBound($l_a_Path) > 0 Then Return $l_a_Path
	Local $l_a_Empty[0][4]
	Return $l_a_Empty
EndFunc

; Heroes avoid combat so they follow the run instead of pulling Destroyers. 0 = Fight, 2 = Avoid.
Func Leveler_SetHeroesBehavior($a_i_Behavior)
	Local $l_i_Count = Party_GetMyPartyInfo("ArrayHeroPartyMemberSize")
	If $l_i_Count < 1 Then Return
	Local $i
	For $i = 1 To $l_i_Count
		If Party_GetMyPartyHeroInfo($i, "AgentID") = 0 Then ContinueLoop
		Ui_SetHeroBehavior($i, $a_i_Behavior)
	Next
EndFunc

; Layer-aware direct move. Prefer Pathfinder_MoveTo; this is the fallback when mesh path fails.
; Walk straight to X/Y with Map_Move. In KilroyMode, STAND UP! on KO instead of aborting.
Func Leveler_MoveDirect($a_f_X, $a_f_Y, $a_i_Timeout = 30000, $a_b_Combat = False)
	Local $l_i_StartMap = Map_GetMapID()
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If Leveler_IsWiped() Then Return False
		If Map_GetMapID() <> $l_i_StartMap Then Return True
		If Agent_GetDistanceToXY($a_f_X, $a_f_Y) < $LEVELER_ARRIVE_RANGE Then Return True
		If $a_b_Combat Then Leveler_CombatTick()
		; Map_Move has no plane — sticks on bridges. Keep the current layer.
		Map_MoveLayer($a_f_X, $a_f_Y, Agent_GetAgentInfo(-2, "Plane"))
		Sleep(250)
	WEnd
	Return Agent_GetDistanceToXY($a_f_X, $a_f_Y) < $LEVELER_ARRIVE_RANGE
EndFunc

; Walk to X/Y, open the NPC, and send a dialog.
Func Leveler_MoveAndDialog($a_f_X, $a_f_Y, $a_i_Dialog, $a_b_Combat = False, $a_i_NpcModel = 0)
	Local $l_i_StartMap = Map_GetMapID()
	If Not Leveler_MoveTo($a_f_X, $a_f_Y, $a_b_Combat) And Map_GetMapID() = $l_i_StartMap Then Return False
	If Map_GetMapID() <> $l_i_StartMap Then Return True

	Local $l_i_Npc = Leveler_ResolveTalkNpc($a_f_X, $a_f_Y, $a_i_NpcModel)
	If $l_i_Npc = 0 Then
		Out("[Move] No NPC near " & Round($a_f_X) & ", " & Round($a_f_Y))
		Return False
	EndIf

	Return Leveler_TalkAndDialog($l_i_Npc, $a_i_Dialog)
EndFunc
#EndRegion Movement

#Region Eye Of The North
; Jora on Ice Cliff and Hall of Monuments hero talk.

Func Leveler_TalkHomHero($a_i_Model, $a_f_X, $a_f_Y, $a_i_Dialog, $a_s_Name)
	Out("[Step] Talking to " & $a_s_Name)
	Leveler_MoveTo($a_f_X, $a_f_Y, False)
	Local $l_i_Npc = Leveler_GetAgentByModel($a_i_Model)
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetNearestNPCAt($a_f_X, $a_f_Y, 500)
	If $l_i_Npc = 0 Then
		Out("[Step] " & $a_s_Name & " not found (model " & $a_i_Model & ")")
		Return False
	EndIf
	Local $l_i_Id = Number(Agent_GetAgentInfo($l_i_Npc, "ID"))
	If $l_i_Id = 0 Then $l_i_Id = Number($l_i_Npc)
	Agent_ChangeTarget($l_i_Id)
	Sleep(250)
	If Number(Agent_GetCurrentTarget()) <> $l_i_Id Then Agent_ChangeTarget($l_i_Npc)
	Sleep(150)
	Agent_GoNPC($l_i_Id)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < 8000
		If Agent_GetDistance($l_i_Npc) < $LEVELER_ARRIVE_RANGE Then ExitLoop
		Map_Move(Agent_GetAgentInfo($l_i_Npc, "X"), Agent_GetAgentInfo($l_i_Npc, "Y"), 20)
		Sleep(250)
	WEnd
	If Agent_GetDistance($l_i_Npc) >= $LEVELER_ARRIVE_RANGE Then
		Out("[Step] Could not reach " & $a_s_Name)
		Return False
	EndIf
	Sleep(500)
	Out("[Step] " & $a_s_Name & " dialog 0x" & Hex($a_i_Dialog, 6))
	Ui_Dialog($a_i_Dialog)
	Sleep(800)
	Return True
EndFunc

; Jora's agent id, matched by model then by name.
Func Leveler_GetJora()
	Local $l_i_Npc = Leveler_GetAgentByModel($MODEL_JORA)
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetAgentByModel($MODEL_JORA_ALT)
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetAgentByName("Jora")
	Return $l_i_Npc
EndFunc

; Jora is in Ice Cliff Chasms at 2825, -481. Tracking the Nornbear is 0x832801.
Func Leveler_ExitEotnToIceCliff()
	If Map_GetMapID() = $MAP_ICE_CLIFF Then Return True
	If Map_GetMapID() = $MAP_HOM Then
		If Not Leveler_Travel($MAP_EOTN) Then Return False
	EndIf
	If Map_GetMapID() <> $MAP_EOTN Then
		If Not Leveler_Travel($MAP_EOTN) Then Return False
	EndIf
	Out("[Step] Leaving Eye of the North for Ice Cliff Chasms")
	Local $l_ai_Hench[3] = [4, 5, 6]
	Leveler_PrepareHeroTeam($l_ai_Hench)
	Local $l_af_Exit[5][2] = [ _
			[-1814.0, 2917.0], _
			[-964.0, 2270.0], _
			[-115.0, 1677.0], _
			[718.0, 1060.0], _
			[1522.0, 464.0] _
			]
	Leveler_FollowCoords($l_af_Exit, False)
	If Not Leveler_WaitForMap($MAP_ICE_CLIFF, 30000) Then Return False
	Return Map_GetMapID() = $MAP_ICE_CLIFF
EndFunc

; Reach Ice Cliff Chasms and take Tracking the Nornbear from Jora.
Func Leveler_TalkJoraOnIceCliff()
	If Leveler_HasNornbearTracking() Then
		Out("[Step] Tracking the Nornbear is already handled")
		Return True
	EndIf
	If Map_GetMapID() <> $MAP_ICE_CLIFF Then
		If Not Leveler_ExitEotnToIceCliff() Then Return False
	EndIf
	If Map_GetMapID() <> $MAP_ICE_CLIFF Then
		Out("[Step] Failed to reach Ice Cliff Chasms for Jora")
		Return False
	EndIf

	$g_b_CombatMode = True
	Out("[Step] Talking to Jora in Ice Cliff Chasms. Sending 0x832801.")
	Leveler_MoveTo($JORA_ICE_CLIFF_X, $JORA_ICE_CLIFF_Y, True)
	Local $l_i_Jora = Leveler_GetJora()
	Local $l_f_X = $JORA_ICE_CLIFF_X
	Local $l_f_Y = $JORA_ICE_CLIFF_Y
	If $l_i_Jora <> 0 Then
		$l_f_X = Agent_GetAgentInfo($l_i_Jora, "X")
		$l_f_Y = Agent_GetAgentInfo($l_i_Jora, "Y")
		Out("[Step] Jora at " & Round($l_f_X) & ", " & Round($l_f_Y))
	EndIf
	If Not Leveler_TalkHomHero($MODEL_JORA, $l_f_X, $l_f_Y, $DIALOG_NORNBEAR_ACCEPT, "Jora") Then
		If Not Leveler_TalkHomHero($MODEL_JORA_ALT, $l_f_X, $l_f_Y, $DIALOG_NORNBEAR_ACCEPT, "Jora") Then
			$l_i_Jora = Leveler_GetJora()
			If $l_i_Jora = 0 Or Not Leveler_TalkAndDialog($l_i_Jora, $DIALOG_NORNBEAR_ACCEPT) Then
				Out("[Step] Failed to take Tracking the Nornbear from Jora")
				Return False
			EndIf
		EndIf
	EndIf
	Ui_Dialog($DIALOG_NORNBEAR_ACCEPT)
	Sleep(800)
	If Not Leveler_HasNornbearTracking() Then
		Out("[Step] Tracking the Nornbear is not in the log after talking to Jora")
		Return False
	EndIf
	Out("[Step] Tracking the Nornbear accepted from Jora")
	Return True
EndFunc
#EndRegion Eye Of The North

#Region Agents
; NPC lookup, talk, Lost Treasure follow, gadgets, loot.

; Target the living NPC, walk into talk range, then send the dialog.
Func Leveler_TalkAndDialog($a_i_Npc, $a_i_Dialog)
	If $a_i_Npc = 0 Then Return False
	Agent_ChangeTarget($a_i_Npc)
	Sleep(150)
	Agent_GoNPC($a_i_Npc)

	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < 5000
		If Agent_GetDistance($a_i_Npc) < $LEVELER_ARRIVE_RANGE Then ExitLoop
		Sleep(100)
	WEnd
	If Agent_GetDistance($a_i_Npc) >= $LEVELER_ARRIVE_RANGE Then
		Out("[Move] Could not reach NPC model " & Agent_GetAgentInfo($a_i_Npc, "PlayerNumber"))
		Return False
	EndIf

	Sleep(500)
	Ui_Dialog($a_i_Dialog)
	Sleep(600)
	Return True
EndFunc

#EndRegion Agents

#Region Travel
; Map_TravelTo, step outposts, and portal exits.

; Walk to a portal coordinate and wait for the destination map.
Func Leveler_MoveAndExit($a_f_X, $a_f_Y, $a_i_MapID, $a_b_Combat = False)
	Local $l_i_StartMap = Map_GetMapID()
	If $l_i_StartMap = $a_i_MapID Then Return True

	Out("[Move] Exit to map " & $a_i_MapID & " via " & Round($a_f_X) & ", " & Round($a_f_Y))
	If Not Leveler_MoveTo($a_f_X, $a_f_Y, $a_b_Combat) Then
		If Map_GetMapID() = $a_i_MapID Then Return Leveler_WaitUntilMapReady()
		Out("[Move] Did not reach the portal at " & Round($a_f_X) & ", " & Round($a_f_Y))
	EndIf
	If Map_GetMapID() = $a_i_MapID Then Return Leveler_WaitUntilMapReady()

	; Nudge into the portal several times — a single Map_Move often stops short.
	Local $i
	For $i = 1 To 10
		If Map_GetMapID() <> $l_i_StartMap Then ExitLoop
		Map_MoveLayer($a_f_X, $a_f_Y, Agent_GetAgentInfo(-2, "Plane"))
		Sleep(400)
	Next
	If Map_GetMapID() = $a_i_MapID Then Return Leveler_WaitUntilMapReady()
	If Not Map_WaitMapLoading($a_i_MapID) Then
		Out("[Move] Timed out waiting for map " & $a_i_MapID & " (still " & Map_GetMapID() & ")")
		Return False
	EndIf
	Return Leveler_WaitUntilMapReady()
EndFunc

; Pathfinder to a portal, then walk through it.
Func Leveler_PathToExit($a_f_X, $a_f_Y, $a_i_MapID, $a_b_Combat = False)
	Out("[Path] Pathfinder to portal " & Round($a_f_X) & ", " & Round($a_f_Y) & " → map " & $a_i_MapID)
	If Map_GetMapID() = $a_i_MapID Then Return True
	If Not Leveler_MoveTo($a_f_X, $a_f_Y, $a_b_Combat) Then
		If Map_GetMapID() = $a_i_MapID Then Return True
		Out("[Path] Pathfinder did not reach the portal. Walking the last stretch.")
	EndIf
	If Map_GetMapID() = $a_i_MapID Then Return True
	If Not Leveler_MoveAndExit($a_f_X, $a_f_Y, $a_i_MapID, $a_b_Combat) Then
		Out("[Path] Did not load map " & $a_i_MapID & " (now " & Map_GetMapID() & ")")
		Return False
	EndIf
	Return Leveler_WaitUntilMapReady()
EndFunc

; Marketplace → Wajjun Bazaar portal (same coords as the Python leveler).
Func Leveler_GoToWajjun()
	If Map_GetMapID() = $MAP_WAJJUN Then Return True
	If Not Leveler_Travel($MAP_MARKETPLACE) Then Return False
	If Not Leveler_WaitUntilMapReady() Then Return False
	Leveler_PrepareForBattle()
	If Not Leveler_WaitUntilMapReady() Then Return False
	Out("[Step] Exiting The Marketplace to Wajjun Bazaar")
	If Not Leveler_PathToExit(11430.00, 15200.00, $MAP_WAJJUN, False) Then Return False
	Return True
EndFunc

; Walk the Lost Treasure entrance portal back to Ran Musu. Used when a completed
; Lost Treasure restart dumped the character in Cho explorable with Tengu still open.
Func Leveler_LeaveChoExplorableToRanMusu()
	If Map_GetMapID() = $MAP_RAN_MUSU Then Return True
	If Map_GetMapID() <> $MAP_CHO_EXPLORABLE Then Return True
	If Not Leveler_WaitUntilMapReady() Then Return False
	Out("[Recover] Pathing Lost Treasure exit to Ran Musu Gardens")
	If Not Leveler_EquipTrainerSkills(False) Then Return False
	Sleep(1500)
	$g_b_UAIReady = False
	If Not Leveler_PrepareCombatAI() Then Return False
	If Not Leveler_MoveTo(-17979.38, -493.08, True) Then
		If Map_GetMapID() <> $MAP_CHO_EXPLORABLE Then Return Map_GetMapID() = $MAP_RAN_MUSU
		Out("[Recover] Could not reach the Cho explorable portal")
		Return False
	EndIf
	If Not Leveler_MoveAndExit(-17979.38, -493.08, $MAP_RAN_MUSU, True) Then Return False
	Return Leveler_WaitUntilMapReady()
EndFunc

; $a_b_Rezone True = leave and re-enter the outpost so we spawn at the portal
; instead of pathing across town from the last NPC (bag merchant, crafter, ...).
Func Leveler_Travel($a_i_MapID, $a_b_Rezone = False)
	If Map_GetMapID() = $a_i_MapID And Map_GetInstanceInfo("IsOutpost") Then
		If Not $a_b_Rezone Then Return True
		Out("[Move] Rezoning map " & $a_i_MapID & " to reset position")
		If Map_RndTravel($a_i_MapID, True, True) Then Return True
		Out("[Move] Rezone failed; walking from the current position")
		Return True
	EndIf
	If Map_GetInstanceInfo("IsExplorable") Then
		Out("[Move] Leaving explorable map " & Map_GetMapID() & " to travel to " & $a_i_MapID)
		If Map_TravelTo($a_i_MapID) Then
			If Not Leveler_WaitUntilMapReady() Then Return False
			If Map_GetMapID() = $a_i_MapID Then Return True
		EndIf
		Chat_SendChat("resign", "/")
		Sleep(1200)
		If Party_GetPartyContextInfo("IsDefeated") Then Map_ReturnToOutpost(False)
		Map_WaitMapLoading()
		Sleep(800)
		If Not Leveler_WaitUntilMapReady() Then Return False
	EndIf
	Out("[Move] Travel to map " & $a_i_MapID)
	If Not Map_TravelTo($a_i_MapID) Then Return False
	Return Leveler_WaitUntilMapReady() And Map_GetMapID() = $a_i_MapID
EndFunc

; Destination outpost for the step. Prefer an unlocked town over walking there.
Func Leveler_StepOutpost($a_i_Step)
	Switch $a_i_Step
		Case $LEVELER_STEP_PARTY, $LEVELER_STEP_SECONDARY, $LEVELER_STEP_XUNLAI, $LEVELER_STEP_WEAPON, $LEVELER_STEP_ARMOR, $LEVELER_STEP_DESTROY, $LEVELER_STEP_BAGS, $LEVELER_STEP_SKILLS, $LEVELER_STEP_THREAT, $LEVELER_STEP_ROAD
			Return $MAP_SHING_JEA
		Case $LEVELER_STEP_TO_CHO, $LEVELER_STEP_CHO_MISSION
			If Map_IsMapUnlocked($MAP_CHO_OUTPOST) Then Return $MAP_CHO_OUTPOST
			If $a_i_Step = $LEVELER_STEP_TO_CHO Then Return $MAP_SHING_JEA
			Return $MAP_CHO_OUTPOST
		Case $LEVELER_STEP_ATTR_1, $LEVELER_STEP_TENGU
			Return $MAP_RAN_MUSU
		Case $LEVELER_STEP_SEITUNG, $LEVELER_STEP_DESTROY_MON
			Return $MAP_SEITUNG
		Case $LEVELER_STEP_ATTR_2
			If Leveler_ReachedGunnarsHold() Or Map_IsMapUnlocked($MAP_GUNNAR) Then Return $MAP_GUNNAR
			Return $MAP_SEITUNG
		Case $LEVELER_STEP_TO_ZEN
			If Map_IsMapUnlocked($MAP_ZEN_OP) Then Return $MAP_ZEN_OP
			Return $MAP_SEITUNG
		Case $LEVELER_STEP_ZEN_MISSION
			Return $MAP_ZEN_OP
		Case $LEVELER_STEP_TO_MARKET
			If Map_IsMapUnlocked($MAP_MARKETPLACE) Then Return $MAP_MARKETPLACE
			If Map_GetMapID() = $MAP_SEITUNG And Map_GetInstanceInfo("IsOutpost") Then Return $MAP_SEITUNG
			If Map_GetMapID() = $MAP_KAINENG_DOCKS Then Return $MAP_KAINENG_DOCKS
			Return $MAP_ZEN_OP
		Case $LEVELER_STEP_BURDEN
			If Map_IsMapUnlocked($MAP_MARKETPLACE) Then Return $MAP_MARKETPLACE
			If Map_IsMapUnlocked($MAP_KAINENG) Then Return $MAP_KAINENG
			Return $MAP_SEITUNG
		Case $LEVELER_STEP_TO_KC
			If Map_IsMapUnlocked($MAP_KAINENG) Then Return $MAP_KAINENG
			Return $MAP_MARKETPLACE
		Case $LEVELER_STEP_SKILLS2, $LEVELER_STEP_MAX_ARMOR, $LEVELER_STEP_DESTROY_SEITUNG, $LEVELER_STEP_CURE, $LEVELER_STEP_UNLOCK_MOX, $LEVELER_STEP_TO_BOREAL
			Return $MAP_KAINENG
		Case $LEVELER_STEP_TO_EOTN
			If Map_IsMapUnlocked($MAP_EOTN) Then Return $MAP_EOTN
			Return $MAP_BOREAL
		Case $LEVELER_STEP_EOTN_POOL, $LEVELER_STEP_TO_GUNNAR
			Return $MAP_EOTN
		Case $LEVELER_STEP_KILROY, $LEVELER_STEP_FARM_20
			Return $MAP_GUNNAR
		Case $LEVELER_STEP_TO_LA
			If Map_IsMapUnlocked($MAP_LIONS_ARCH) Then Return $MAP_LIONS_ARCH
			Return $MAP_GUNNAR
		Case $LEVELER_STEP_TO_KAMADAN
			If Map_IsMapUnlocked($MAP_KAMADAN) Then Return $MAP_KAMADAN
			Return $MAP_LIONS_ARCH
		Case $LEVELER_STEP_TO_DOCKS
			If Map_IsMapUnlocked($MAP_DOCKS) Then Return $MAP_DOCKS
			Return $MAP_KAMADAN
		Case $LEVELER_STEP_UNLOCK_OLIAS
			If Leveler_OliasReadyToTurnIn() Then Return $MAP_KAMADAN
			If Leveler_HasQuest($QUEST_OLIAS) Then Return $MAP_LIONS_ARCH
			Return $MAP_DOCKS
		Case $LEVELER_STEP_UNLOCK_PROFS
			Return $MAP_GTOB
	EndSwitch
	Return 0
EndFunc

; Stay only if already at the destination outpost or inside that step's instance.
; Approach towns (Sunqua, Jaya, ...) are not enough once the dest outpost is unlocked.
Func Leveler_StepAllowsMap($a_i_Step, $a_i_Map)
	Local $l_i_Outpost = Leveler_StepOutpost($a_i_Step)
	If $l_i_Outpost <> 0 And $a_i_Map = $l_i_Outpost Then Return True
	Switch $a_i_Step
		Case $LEVELER_STEP_OVERLOOK
			Return $a_i_Map = $MAP_MONASTERY_OVERLOOK Or $a_i_Map = 285 Or $a_i_Map = 416
		Case $LEVELER_STEP_PARTY
			Return $a_i_Map = $MAP_SUNQUA_VALE
		Case $LEVELER_STEP_SECONDARY
			Return $a_i_Map = $MAP_LINNOK
		Case $LEVELER_STEP_TO_CHO
			If Map_IsMapUnlocked($MAP_CHO_OUTPOST) Then Return $a_i_Map = $MAP_CHO_OUTPOST
			Return $a_i_Map = $MAP_SHING_JEA Or $a_i_Map = $MAP_SUNQUA_VALE
		Case $LEVELER_STEP_CHO_MISSION
			Return $a_i_Map = $MAP_CHO_OUTPOST Or $a_i_Map = $MAP_RAN_MUSU
		Case $LEVELER_STEP_ATTR_1
			Return $a_i_Map = $MAP_CHO_EXPLORABLE Or $a_i_Map = $MAP_KINYA
		Case $LEVELER_STEP_TENGU
			Return $a_i_Map = $MAP_KINYA Or $a_i_Map = $MAP_CHO_EXPLORABLE Or $a_i_Map = $MAP_RAN_MUSU
		Case $LEVELER_STEP_THREAT
			Return $a_i_Map = $MAP_KINYA Or $a_i_Map = $MAP_SUNQUA_VALE Or $a_i_Map = $MAP_TSUMEI Or $a_i_Map = $MAP_PANJIANG
		Case $LEVELER_STEP_ROAD
			Return $a_i_Map = $MAP_LINNOK Or $a_i_Map = $MAP_SAOSHANG Or $a_i_Map = $MAP_SEITUNG
		Case $LEVELER_STEP_SEITUNG
			Return $a_i_Map = $MAP_SHING_JEA Or $a_i_Map = $MAP_SEITUNG
		Case $LEVELER_STEP_TO_ZEN
			If Map_IsMapUnlocked($MAP_ZEN_OP) Then Return $a_i_Map = $MAP_ZEN_OP
			Return $a_i_Map = $MAP_JAYA Or $a_i_Map = $MAP_HAIJU
		Case $LEVELER_STEP_ZEN_MISSION
			Return $a_i_Map = $MAP_ZEN_EXP Or $a_i_Map = $MAP_ZEN_OP
		Case $LEVELER_STEP_TO_MARKET
			If Map_IsMapUnlocked($MAP_MARKETPLACE) Then Return $a_i_Map = $MAP_MARKETPLACE
			Return $a_i_Map = $MAP_KAINENG_DOCKS
		Case $LEVELER_STEP_BURDEN
			Return $a_i_Map = $MAP_WAJJUN Or $a_i_Map = $MAP_KAINENG_DOCKS Or $a_i_Map = $MAP_MARKETPLACE Or $a_i_Map = $MAP_KAINENG Or $a_i_Map = $MAP_SEITUNG
		Case $LEVELER_STEP_TO_KC
			If Map_IsMapUnlocked($MAP_KAINENG) Then Return $a_i_Map = $MAP_KAINENG
			Return $a_i_Map = $MAP_BUKDEK Or $a_i_Map = $MAP_WAJJUN Or $a_i_Map = $MAP_MARKETPLACE
		Case $LEVELER_STEP_CURE
			Return $a_i_Map = $MAP_WAJJUN Or $a_i_Map = $MAP_KAINENG_DOCKS Or $a_i_Map = $MAP_MARKETPLACE Or $a_i_Map = $MAP_KAINENG
		Case $LEVELER_STEP_UNLOCK_MOX, $LEVELER_STEP_TO_BOREAL
			Return $a_i_Map = $MAP_TUNNELS
		Case $LEVELER_STEP_TO_EOTN
			If Map_IsMapUnlocked($MAP_EOTN) Then Return $a_i_Map = $MAP_EOTN Or $a_i_Map = $MAP_HOM
			Return $a_i_Map = $MAP_ICE_CLIFF
		Case $LEVELER_STEP_EOTN_POOL
			If Leveler_HomHeroesTalked() Then Return $a_i_Map = $MAP_EOTN Or $a_i_Map = $MAP_ICE_CLIFF Or $a_i_Map = $MAP_NORRHART Or $a_i_Map = $MAP_GUNNAR
			Return $a_i_Map = $MAP_HOM
		Case $LEVELER_STEP_ATTR_2
			Return $a_i_Map = $MAP_ZEN_EXP
		Case $LEVELER_STEP_TO_GUNNAR
			Return $a_i_Map = $MAP_GUNNAR Or $a_i_Map = $MAP_ICE_CLIFF Or $a_i_Map = $MAP_NORRHART
		Case $LEVELER_STEP_KILROY
			Return $a_i_Map = $MAP_KILROY
		Case $LEVELER_STEP_FARM_20
			Return $a_i_Map = $MAP_GUNNAR Or $a_i_Map = $MAP_FRONIS
		Case $LEVELER_STEP_TO_LA
			If Map_IsMapUnlocked($MAP_LIONS_ARCH) Then Return $a_i_Map = $MAP_LIONS_ARCH
			Return $a_i_Map = $MAP_BEJUNKAN Or $a_i_Map = $MAP_LIONS_GATE
		Case $LEVELER_STEP_TO_KAMADAN
			If Map_IsMapUnlocked($MAP_KAMADAN) Then Return $a_i_Map = $MAP_KAMADAN
			Return $a_i_Map = $MAP_KC_SUNSPEARS
		Case $LEVELER_STEP_TO_DOCKS
			If Map_IsMapUnlocked($MAP_DOCKS) Then Return $a_i_Map = $MAP_DOCKS
			Return $a_i_Map = $MAP_SUN_DOCKS Or $a_i_Map = $MAP_CONSULATE
		Case $LEVELER_STEP_UNLOCK_OLIAS
			If Leveler_OliasReadyToTurnIn() Then Return $a_i_Map = $MAP_KAMADAN Or $a_i_Map = $MAP_LIONS_ARCH
			Return $a_i_Map = $MAP_BLOODSTONE_FEN Or $a_i_Map = $MAP_LIONS_ARCH Or $a_i_Map = $MAP_DOCKS Or $a_i_Map = $MAP_CONSULATE
	EndSwitch
	Return False
EndFunc

; Map-travel to the step outpost. Stay in the explorable if the step's quest is already in the log.
Func Leveler_EnsureStepOutpost($a_i_Step)
	If $a_i_Step = $LEVELER_STEP_DONE Then Return True
	If Map_GetInstanceInfo("IsLoading") Then Return Leveler_WaitUntilMapReady()
	If Not Leveler_WaitUntilMapReady() Then Return False
	Local $l_i_Map = Map_GetMapID()
	Local $l_i_Outpost = Leveler_StepOutpost($a_i_Step)
	If $l_i_Outpost = 0 Then Return True
	If $l_i_Map = $l_i_Outpost And Map_GetInstanceInfo("IsOutpost") Then Return True
	If $l_i_Map = $l_i_Outpost And Map_GetInstanceInfo("IsExplorable") Then Return True
	If Leveler_StepAllowsMap($a_i_Step, $l_i_Map) Then Return True
	If $g_b_ExplorableResume And Not Leveler_IsOutpost() And Leveler_StepHasActiveQuest($a_i_Step) And Leveler_StepAllowsMap($a_i_Step, $l_i_Map) Then
		Out("[Move] Restart recovery: quest is in the log on map " & $l_i_Map & ". Resuming '" & $g_as_StepNames[$a_i_Step] & "' from here.")
		Return True
	EndIf
	If Leveler_HasIncompleteQuest($QUEST_AGAINST_DESTROYERS) And Not Leveler_HomHeroesTalked() And ($l_i_Map = $MAP_EOTN Or $l_i_Map = $MAP_HOM) And $l_i_Outpost <> $MAP_EOTN And $l_i_Outpost <> $MAP_HOM Then
		Out("[Move] Against the Destroyers is in the log. Not map-traveling to " & $l_i_Outpost & " for '" & $g_as_StepNames[$a_i_Step] & "'.")
		Return True
	EndIf
	If Not Map_IsMapUnlocked($l_i_Outpost) Then
		Out("[Move] Need map " & $l_i_Outpost & " for '" & $g_as_StepNames[$a_i_Step] & "' but it is not unlocked yet")
		Return True
	EndIf
	Out("[Move] Map-traveling to " & $l_i_Outpost & " for '" & $g_as_StepNames[$a_i_Step] & "' (was map " & $l_i_Map & ")")
	If Not Leveler_Travel($l_i_Outpost) Then
		Out("[Move] Map travel to " & $l_i_Outpost & " failed")
		Return False
	EndIf
	If Map_GetMapID() <> $l_i_Outpost Then
		Out("[Move] Map travel did not arrive at " & $l_i_Outpost & " (now " & Map_GetMapID() & ")")
		Return False
	EndIf
	Return Leveler_WaitUntilMapReady()
EndFunc

#EndRegion Travel

#Region Agents
; Name / model lookup and talk helpers.

; First talk NPC whose name contains the string.
Func Leveler_GetAgentByName($a_s_Name)
	Local $l_i_Max = Agent_GetMaxAgents()
	For $i = 1 To $l_i_Max - 1
		If Not Leveler_IsTalkNpc($i) Then ContinueLoop
		If StringInStr(Agent_GetAgentInfo($i, "Name"), $a_s_Name) Then Return $i
	Next
	Return 0
EndFunc

; Town NPCs only. Skip party henchmen/heroes, who are also IsNPC.
Func Leveler_IsTalkNpc($a_i_Agent)
	If $a_i_Agent = 0 Then Return False
	If Agent_GetAgentPtr($a_i_Agent) = 0 Then Return False
	If Agent_GetAgentInfo($a_i_Agent, "IsDead") Then Return False
	If Not Agent_GetAgentInfo($a_i_Agent, "IsNPC") Then Return False
	If Agent_GetAgentInfo($a_i_Agent, "Allegiance") <> $GC_I_ALLEGIANCE_NPC Then Return False
	Return True
EndFunc

; NPC nearest to the player. Prefer Leveler_GetNearestNPCAt for dialogs.
Func Leveler_GetNearestNPC($a_f_Range = 250)
	Return Leveler_GetNearestNPCAt(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), $a_f_Range)
EndFunc

; NPC nearest to a map coordinate, not to the player.
Func Leveler_GetNearestNPCAt($a_f_X, $a_f_Y, $a_f_Range = 250)
	Local $l_i_Best = 0
	Local $l_f_Best = $a_f_Range
	Local $l_i_Max = Agent_GetMaxAgents()
	For $i = 1 To $l_i_Max - 1
		If Not Leveler_IsTalkNpc($i) Then ContinueLoop
		Local $l_f_Dist = Agent_GetDistanceToXY($a_f_X, $a_f_Y, $i)
		If $l_f_Dist < $l_f_Best Then
			$l_f_Best = $l_f_Dist
			$l_i_Best = $i
		EndIf
	Next
	Return $l_i_Best
EndFunc

; First living agent whose PlayerNumber matches the model.
Func Leveler_GetAgentByModel($a_i_Model)
	If $a_i_Model = 0 Then Return 0
	Local $l_i_Max = Agent_GetMaxAgents()
	For $i = 1 To $l_i_Max - 1
		If Agent_GetAgentPtr($i) = 0 Then ContinueLoop
		If Agent_GetAgentInfo($i, "IsDead") Then ContinueLoop
		If Agent_GetAgentInfo($i, "PlayerNumber") = $a_i_Model Then Return $i
	Next
	Return 0
EndFunc

; True for the known Master Togo model IDs.
Func Leveler_IsTogoModel($a_i_Model)
	If $a_i_Model = $MODEL_TOGO_1 Then Return True
	If $a_i_Model = $MODEL_TOGO_2 Then Return True
	If $a_i_Model = $MODEL_TOGO_3 Then Return True
	If $a_i_Model = $MODEL_TOGO_4 Then Return True
	Return False
EndFunc

; Escort Togo can change allegiance after the dialog. Do not require town-NPC flags.
Func Leveler_GetTogo($a_f_NearX = 0, $a_f_NearY = 0)
	Local $l_i_Best = 0
	Local $l_f_Best = 999999
	Local $l_i_Max = Agent_GetMaxAgents()
	Local $i
	For $i = 1 To $l_i_Max - 1
		If Agent_GetAgentPtr($i) = 0 Then ContinueLoop
		If Agent_GetAgentInfo($i, "IsDead") Then ContinueLoop
		Local $l_s_Name = Agent_GetAgentInfo($i, "Name")
		Local $l_i_Model = Agent_GetAgentInfo($i, "PlayerNumber")
		If Not Leveler_IsTogoModel($l_i_Model) And StringInStr($l_s_Name, "Togo") = 0 Then ContinueLoop
		If $a_f_NearX = 0 And $a_f_NearY = 0 Then Return $i
		Local $l_f_Dist = Agent_GetDistanceToXY($a_f_NearX, $a_f_NearY, $i)
		If $l_f_Dist < $l_f_Best Then
			$l_f_Best = $l_f_Dist
			$l_i_Best = $i
		EndIf
	Next
	If $l_i_Best <> 0 Then Return $l_i_Best
	If $a_f_NearX <> 0 Or $a_f_NearY <> 0 Then Return Leveler_GetNearestNPCAt($a_f_NearX, $a_f_NearY, 700)
	Return 0
EndFunc

; Model ID of the Togo agent currently on this map, or 0.
Func Leveler_TogoModel()
	Local $l_i_Togo = Leveler_GetTogo()
	If $l_i_Togo = 0 Then Return 0
	Return Agent_GetAgentInfo($l_i_Togo, "PlayerNumber")
EndFunc

; Gate guards are not always town-NPC allegiance. Match by name, then any living NPC on the tile.
Func Leveler_GetTsukaro()
	Local $l_i_Best = 0
	Local $l_f_Best = 999999
	Local $l_i_Max = Agent_GetMaxAgents()
	Local $l_i_Me = Agent_GetMyID()
	Local $i
	For $i = 1 To $l_i_Max - 1
		If Agent_GetAgentPtr($i) = 0 Then ContinueLoop
		If $i = $l_i_Me Then ContinueLoop
		If Agent_GetAgentInfo($i, "IsDead") Then ContinueLoop
		If StringInStr(Agent_GetAgentInfo($i, "Name"), "Tsukaro") = 0 Then ContinueLoop
		Local $l_f_Named = Agent_GetDistanceToXY($TSUKARO_LINNOK_X, $TSUKARO_LINNOK_Y, $i)
		If $l_f_Named < $l_f_Best Then
			$l_f_Best = $l_f_Named
			$l_i_Best = $i
		EndIf
	Next
	If $l_i_Best <> 0 Then Return $l_i_Best
	$l_f_Best = 700
	For $i = 1 To $l_i_Max - 1
		If Agent_GetAgentPtr($i) = 0 Then ContinueLoop
		If $i = $l_i_Me Then ContinueLoop
		If Agent_GetAgentInfo($i, "IsDead") Then ContinueLoop
		If Not Agent_GetAgentInfo($i, "IsNPC") Then ContinueLoop
		Local $l_f_Dist = Agent_GetDistanceToXY($TSUKARO_LINNOK_X, $TSUKARO_LINNOK_Y, $i)
		If $l_f_Dist < $l_f_Best Then
			$l_f_Best = $l_f_Dist
			$l_i_Best = $i
		EndIf
	Next
	If $l_i_Best <> 0 Then Return $l_i_Best
	Return Leveler_GetNearestNPCAt($TSUKARO_LINNOK_X, $TSUKARO_LINNOK_Y, 700)
EndFunc

; Stay on Master Togo until he stops near Guardsman Zui.
Func Leveler_FollowTogo($a_i_Timeout = 180000)
	Local $l_i_StartMap = Map_GetMapID()
	Local $l_h_Timer = TimerInit()
	Local $l_f_LastX = $TOGO_SUNQUA_X
	Local $l_f_LastY = $TOGO_SUNQUA_Y
	Local $l_h_Moved = TimerInit()
	Local $l_i_Togo = Leveler_GetTogo($l_f_LastX, $l_f_LastY)
	If $l_i_Togo <> 0 Then
		$l_f_LastX = Agent_GetAgentInfo($l_i_Togo, "X")
		$l_f_LastY = Agent_GetAgentInfo($l_i_Togo, "Y")
	EndIf
	Out("[Move] Following Master Togo from " & Round($l_f_LastX) & ", " & Round($l_f_LastY))

	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If Leveler_IsWiped() Then Return False
		If Map_GetMapID() <> $l_i_StartMap Or Map_GetMapID() = $MAP_CHO_OUTPOST Then
			Out("[Move] Followed Togo to map " & Map_GetMapID())
			Return True
		EndIf

		$l_i_Togo = Leveler_GetTogo($l_f_LastX, $l_f_LastY)
		If $l_i_Togo = 0 Then
			Map_Move($l_f_LastX, $l_f_LastY, 0)
			Sleep(400)
			ContinueLoop
		EndIf

		Local $l_f_X = Agent_GetAgentInfo($l_i_Togo, "X")
		Local $l_f_Y = Agent_GetAgentInfo($l_i_Togo, "Y")
		Local $l_f_Dist = Agent_GetDistance($l_i_Togo)
		$l_f_LastX = $l_f_X
		$l_f_LastY = $l_f_Y

		If $l_f_Dist > 180 Then
			Map_Move($l_f_X, $l_f_Y, 0)
			If $l_f_Dist > 450 Then Agent_GoNPC($l_i_Togo)
		EndIf

		Local $l_f_Zui = Agent_GetDistanceToXY($ZUI_SUNQUA_X, $ZUI_SUNQUA_Y, $l_i_Togo)
		If $l_f_Zui < 400 And $l_f_Dist < 350 Then
			Out("[Move] Togo reached Guardsman Zui")
			Return True
		EndIf

		If TimerDiff($l_h_Moved) > 4000 Then
			Out("[Move] Togo at " & Round($l_f_X) & ", " & Round($l_f_Y) & " dist " & Round($l_f_Dist))
			$l_h_Moved = TimerInit()
		EndIf
		Sleep(250)
	WEnd

	Out("[Move] Follow Togo timed out on map " & Map_GetMapID())
	Return Agent_GetDistanceToXY($ZUI_SUNQUA_X, $ZUI_SUNQUA_Y) < 500 Or Map_GetMapID() <> $l_i_StartMap
EndFunc

; Talk NPC nearest to X/Y that still has a quest marker.
Func Leveler_GetQuestNpcAt($a_f_X, $a_f_Y, $a_f_Range = 500)
	Local $l_i_Best = 0
	Local $l_f_Best = $a_f_Range
	Local $l_i_Marked = 0
	Local $l_f_Marked = $a_f_Range
	Local $l_i_Max = Agent_GetMaxAgents()
	For $i = 1 To $l_i_Max - 1
		If Not Leveler_IsTalkNpc($i) Then ContinueLoop
		Local $l_f_Dist = Agent_GetDistanceToXY($a_f_X, $a_f_Y, $i)
		If $l_f_Dist >= $a_f_Range Then ContinueLoop
		If Agent_GetAgentInfo($i, "HasQuest") And $l_f_Dist < $l_f_Marked Then
			$l_f_Marked = $l_f_Dist
			$l_i_Marked = $i
		EndIf
		If $l_f_Dist < $l_f_Best Then
			$l_f_Best = $l_f_Dist
			$l_i_Best = $i
		EndIf
	Next
	If $l_i_Marked <> 0 Then Return $l_i_Marked
	Return $l_i_Best
EndFunc

; Pick a talk NPC by model, then by coordinate, then nearest to the player.
Func Leveler_ResolveTalkNpc($a_f_X, $a_f_Y, $a_i_NpcModel = 0)
	Local $l_i_Npc = 0
	If $a_i_NpcModel <> 0 Then $l_i_Npc = Leveler_GetAgentByModel($a_i_NpcModel)
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetQuestNpcAt($a_f_X, $a_f_Y, 500)
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetNearestNPCAt($a_f_X, $a_f_Y, 400)
	Return $l_i_Npc
EndFunc

; Walk to X/Y and Agent_GoNPC the nearest talk NPC.
Func Leveler_InteractNpcAt($a_f_X, $a_f_Y, $a_b_Combat = False)
	If Not Leveler_MoveTo($a_f_X, $a_f_Y, $a_b_Combat) Then Return False
	Local $l_i_Npc = Leveler_ResolveTalkNpc($a_f_X, $a_f_Y)
	If $l_i_Npc = 0 Then Return False
	Agent_ChangeTarget($l_i_Npc)
	Sleep(150)
	Agent_GoNPC($l_i_Npc)
	Sleep(800)
	Return True
EndFunc
#EndRegion Agents

#Region Combat
; Aggro waits, spirit-rift interrupt, and danger checks.

; True when the party is defeated.
Func Leveler_IsWiped()
	If Leveler_IsPunchoutMap() Or $g_b_FarmMode Then Return False
	If Party_GetPartyContextInfo("IsDefeated") Then Return True
	If Party_IsWiped() Then Return True
	Return False
EndFunc

; Dynamic obstacles for Pathfinder_MoveTo. Living enemies in detection range.
Func Leveler_GetObstacles($a_f_Radius = 100, $a_f_DetectionRange = 4000)
	Local $l_i_MyID = Agent_GetMyID()
	Local $l_i_Max = Agent_GetMaxAgents()
	Local $l_i_Count = 0
	Local $l_af_Obs[1][3]
	Local $i
	For $i = 1 To $l_i_Max - 1
		If Agent_GetAgentPtr($i) = 0 Then ContinueLoop
		If Agent_GetAgentInfo($i, "IsDead") Then ContinueLoop
		If Agent_GetAgentInfo($i, "Allegiance") <> $GC_I_ALLEGIANCE_ENEMY Then ContinueLoop
		If Agent_GetDistance($i, $l_i_MyID) > $a_f_DetectionRange Then ContinueLoop
		ReDim $l_af_Obs[$l_i_Count + 1][3]
		$l_af_Obs[$l_i_Count][0] = Agent_GetAgentInfo($i, "X")
		$l_af_Obs[$l_i_Count][1] = Agent_GetAgentInfo($i, "Y")
		$l_af_Obs[$l_i_Count][2] = $a_f_Radius
		$l_i_Count += 1
	Next
	If $l_i_Count = 0 Then Return 0
	Return $l_af_Obs
EndFunc

; One fight tick at the player's current position.
; Punch-out maps use brawling skills (old Kilroy_Fight); everywhere else uses UtilityAI.
Func Leveler_CombatTick()
	If $g_b_KilroyMode Or $g_b_FarmMode Or Leveler_IsPunchoutMap() Then
		If Leveler_HandleKilroyDeath() Then Return
		If Leveler_IsPunchoutMap() Then
			Leveler_KilroyCombatTick(1500, True)
			Return
		EndIf
	EndIf
	If Not Leveler_ShouldFightHere() Then Return
	If Not Leveler_PrepareCombatAI() Then Return
	Leveler_UAI_Fight(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), $LEVELER_AGGRO, $LEVELER_FIGHT_RANGE_OUT)
EndFunc

; Fight in place for the given milliseconds.
Func Leveler_WaitCombat($a_i_Ms)
	If Not Leveler_ShouldFightHere() Then
		Sleep($a_i_Ms)
		Return True
	EndIf
	Leveler_PrepareCombatAI()
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Ms
		If $g_b_LevelerPaused Then Return False
		If Leveler_IsWiped() Then Return False
		Leveler_CombatTick()
		Sleep(50)
	WEnd
	Return True
EndFunc

; True when a living enemy is inside aggro range.
Func Leveler_InDanger($a_f_Range = $LEVELER_AGGRO)
	Local $l_i_MyID = Agent_GetMyID()
	Local $l_i_Max = Agent_GetMaxAgents()
	For $i = 1 To $l_i_Max - 1
		If Agent_GetAgentPtr($i) = 0 Then ContinueLoop
		If Agent_GetAgentInfo($i, "IsDead") Then ContinueLoop
		If Agent_GetAgentInfo($i, "Allegiance") <> $GC_I_ALLEGIANCE_ENEMY Then ContinueLoop
		If Agent_GetDistance($i, $l_i_MyID) < $a_f_Range Then Return True
	Next
	Return False
EndFunc

; Wait until no enemies are in aggro range, or the timeout.
Func Leveler_WaitOutOfCombat($a_i_Timeout = 120000)
	Local $l_h_Timer = TimerInit()
	Local $l_h_Clear = 0
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If Leveler_IsWiped() Then Return False
		If $g_b_SpiritRiftWatch Then Leveler_InterruptSpiritRifts()
		If Not Leveler_InDanger($LEVELER_AGGRO) Then
			If $l_h_Clear = 0 Then $l_h_Clear = TimerInit()
			If TimerDiff($l_h_Clear) >= 2000 Then
				If Not Map_GetInstanceInfo("IsLoading") And Not $g_b_KilroyRecovery Then Leveler_LootNearby(0, 1200, 2500)
				Return True
			EndIf
		Else
			$l_h_Clear = 0
			Leveler_CombatTick()
		EndIf
		Sleep(250)
	WEnd
	Return Not Leveler_InDanger($LEVELER_AGGRO)
EndFunc

#EndRegion Combat

#Region Lost Treasure
; Follow Raitahn Nem through Cho explorable.

; Wait until the NPC model shows a quest marker.
Func Leveler_WaitUntilModelHasQuest($a_i_Model, $a_i_Timeout = 180000)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If Leveler_IsWiped() Then Return False
		Local $l_i_Npc = Leveler_GetAgentByModel($a_i_Model)
		If $l_i_Npc <> 0 And Agent_GetAgentInfo($l_i_Npc, "HasQuest") Then Return True
		Sleep(400)
	WEnd
	Out("[Move] Timed out waiting for model " & $a_i_Model & " quest marker")
	Return False
EndFunc

; True when Raitahn Nem is at the Cho-explorable hand-in.
Func Leveler_LostTreasureAtRouteEnd($a_i_Npc = 0)
	If Leveler_InDanger($LEVELER_SPIRIT_RANGE) Then Return False
	If Agent_GetDistanceToXY($LOST_CHO_END_X, $LOST_CHO_END_Y) < 800 Then Return True
	If $a_i_Npc = 0 Then $a_i_Npc = Leveler_GetAgentByModel($MODEL_LOST_TREASURE_GUARD)
	If $a_i_Npc = 0 Then Return False
	Local $l_f_NpcX = Agent_GetAgentInfo($a_i_Npc, "X")
	Local $l_f_NpcY = Agent_GetAgentInfo($a_i_Npc, "Y")
	If Sqrt(($l_f_NpcX - $LOST_CHO_END_X) ^ 2 + ($l_f_NpcY - $LOST_CHO_END_Y) ^ 2) < 800 Then Return True
	Return False
EndFunc

; True if this character is already at Raitahn Nem's hand-in after a disconnect or script stop.
Func Leveler_NearLostTreasureHandIn($a_f_Range = $LOST_CHO_END_RANGE)
	If Map_GetMapID() <> $MAP_CHO_EXPLORABLE Then Return False
	If Agent_GetDistanceToXY($LOST_CHO_END_X, $LOST_CHO_END_Y) < $a_f_Range Then Return True
	Local $l_i_Npc = Leveler_GetAgentByModel($MODEL_LOST_TREASURE_GUARD)
	If $l_i_Npc = 0 Then Return False
	Local $l_f_NpcX = Agent_GetAgentInfo($l_i_Npc, "X")
	Local $l_f_NpcY = Agent_GetAgentInfo($l_i_Npc, "Y")
	If Sqrt(($l_f_NpcX - $LOST_CHO_END_X) ^ 2 + ($l_f_NpcY - $LOST_CHO_END_Y) ^ 2) >= 800 Then Return False
	Return Agent_GetDistance($l_i_Npc) < $a_f_Range
EndFunc

; Follow Raitahn Nem to 20660.90, -9207.07. Do not stop for pickup, start dialog, or a mid-route pause.
Func Leveler_FollowLostTreasurePath($a_i_Timeout = 600000)
	Out("[Path] Follow Raitahn Nem to " & Round($LOST_CHO_END_X) & ", " & Round($LOST_CHO_END_Y))
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If Leveler_IsWiped() Then Return False
		Local $l_i_Npc = Leveler_GetAgentByModel($MODEL_LOST_TREASURE_GUARD)
		If Leveler_LostTreasureAtRouteEnd($l_i_Npc) Then
			Out("[Path] Reached Raitahn Nem's final location")
			Return True
		EndIf
		If $l_i_Npc = 0 Then
			If Leveler_ShouldFightHere() Then
				If Not Leveler_PrepareCombatAI() Then Return False
				Leveler_UAI_UseSkills(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), $LEVELER_AGGRO, $LEVELER_FIGHT_RANGE_OUT)
			EndIf
			Map_Move($LOST_CHO_END_X, $LOST_CHO_END_Y, 20)
			Sleep(400)
			ContinueLoop
		EndIf
		If Agent_GetDistance($l_i_Npc) > $LEVELER_AREA_RANGE Then
			If Leveler_ShouldFightHere() Then
				If Not Leveler_PrepareCombatAI() Then Return False
				Leveler_UAI_UseSkills(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), $LEVELER_AGGRO, $LEVELER_FIGHT_RANGE_OUT)
			EndIf
			Map_Move(Agent_GetAgentInfo($l_i_Npc, "X"), Agent_GetAgentInfo($l_i_Npc, "Y"), 20)
		Else
			Leveler_CombatTick()
		EndIf
		Sleep(250)
	WEnd
	Out("[Path] Follow timed out. Moving to Raitahn Nem's final location.")
	Return True
EndFunc

#EndRegion Lost Treasure

#Region Gadgets
; Mission gadgets and ground loot.

; Nearest gadget/signpost agent.
Func Leveler_GetNearestGadget($a_f_Range = 400)
	Return Leveler_GetNearestGadgetAt(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), $a_f_Range)
EndFunc

; Nearest gadget or signpost within range of a point.
Func Leveler_GetNearestGadgetAt($a_f_X, $a_f_Y, $a_f_Range = 400)
	Local $l_i_Best = 0
	Local $l_f_Best = $a_f_Range
	Local $l_i_Max = Agent_GetMaxAgents()
	Local $i
	For $i = 1 To $l_i_Max - 1
		If Agent_GetAgentPtr($i) = 0 Then ContinueLoop
		If Not Agent_GetAgentInfo($i, "IsGadgetType") Then ContinueLoop
		Local $l_f_Dist = Agent_GetDistanceToXY($a_f_X, $a_f_Y, $i)
		If $l_f_Dist < $l_f_Best Then
			$l_f_Best = $l_f_Dist
			$l_i_Best = $i
		EndIf
	Next
	Return $l_i_Best
EndFunc

; Walk to X/Y and use the nearest gadget.
Func Leveler_InteractGadgetAt($a_f_X, $a_f_Y, $a_b_Combat = False)
	If Not Leveler_MoveTo($a_f_X, $a_f_Y, $a_b_Combat) Then Return False
	Local $l_i_Gadget = Leveler_GetNearestGadget(400)
	If $l_i_Gadget = 0 Then
		Out("[Move] No gadget near " & Round($a_f_X) & ", " & Round($a_f_Y))
		Return False
	EndIf
	Agent_GoSignpost($l_i_Gadget)
	Sleep(800)
	Return True
EndFunc

; Nearest pick-up item matching the model (0 = any).
Func Leveler_GetGroundItemByModel($a_i_Model, $a_f_Range = 2500)
	Local $l_i_MyID = Agent_GetMyID()
	Local $l_i_Best = 0
	Local $l_f_Best = $a_f_Range
	Local $l_i_Max = Agent_GetMaxAgents()
	For $i = 1 To $l_i_Max - 1
		If Agent_GetAgentPtr($i) = 0 Then ContinueLoop
		If Not Agent_GetAgentInfo($i, "IsItemType") Then ContinueLoop
		If Not Agent_GetAgentInfo($i, "CanPickUp") Then ContinueLoop
		Local $l_i_ItemID = Agent_GetAgentInfo($i, "ItemID")
		If $l_i_ItemID = 0 Then ContinueLoop
		If $a_i_Model <> 0 And Item_GetItemInfoByItemID($l_i_ItemID, "ModelID") <> $a_i_Model Then ContinueLoop
		Local $l_f_Dist = Agent_GetDistance($i, $l_i_MyID)
		If $l_f_Dist < $l_f_Best Then
			$l_f_Best = $l_f_Dist
			$l_i_Best = $i
		EndIf
	Next
	Return $l_i_Best
EndFunc

; Pick up nearby ground items and gold. White drops are sold later, in town.
Func Leveler_LootNearby($a_i_Model = 0, $a_f_Range = 2000, $a_i_Timeout = 10000)
	Local $l_h_Timer = TimerInit()
	Local $l_i_Picked = 0
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_KilroyMode Or $g_b_FarmMode Then Leveler_HandleKilroyDeath()
		If $g_b_KilroyRecovery Then ExitLoop
		If Leveler_IsWiped() Then Return False
		Local $l_i_Agent = Leveler_GetGroundItemByModel($a_i_Model, $a_f_Range)
		If $l_i_Agent = 0 Then ExitLoop
		If Agent_GetDistance($l_i_Agent) > $LEVELER_ARRIVE_RANGE Then
			Map_Move(Agent_GetAgentInfo($l_i_Agent, "X"), Agent_GetAgentInfo($l_i_Agent, "Y"), 20)
			Sleep(250)
		EndIf
		Item_PickUpItem($l_i_Agent)
		Sleep(400)
		$l_i_Picked += 1
	WEnd
	If $l_i_Picked > 0 Then
		Out("[Move] Looted " & $l_i_Picked & " item(s)")
		$g_i_WhiteSellMap = -1
	EndIf
	Return True
EndFunc

; True when the Auto Sell box is ticked.
Func Leveler_WantsAutoSell()
	If $g_h_AutoSellCheckbox = 0 Then Return False
	Return GetChecked($g_h_AutoSellCheckbox)
EndFunc

; Unequipped white weapons and armor. Blues, rares, materials, kits, and quest items stay.
Func Leveler_IsWhiteSellDrop($a_p_Item)
	If $a_p_Item = 0 Then Return False
	If Item_GetItemInfoByPtr($a_p_Item, "Customized") <> 0 Then Return False
	If Item_GetItemInfoByPtr($a_p_Item, "Equipped") <> 0 Then Return False
	If Item_GetItemInfoByPtr($a_p_Item, "Rarity") <> $GC_I_RARITY_WHITE Then Return False
	Switch Item_GetItemInfoByPtr($a_p_Item, "ItemType")
		Case $GC_I_TYPE_LEADHAND, $GC_I_TYPE_AXE, $GC_I_TYPE_BOOTS, $GC_I_TYPE_BOW, $GC_I_TYPE_CHESTPIECE, _
				$GC_I_TYPE_OFFHAND, $GC_I_TYPE_GLOVES, $GC_I_TYPE_HAMMER, $GC_I_TYPE_HEADPIECE, $GC_I_TYPE_LEGGINS, _
				$GC_I_TYPE_WAND, $GC_I_TYPE_SHIELD, $GC_I_TYPE_STAFF, $GC_I_TYPE_SWORD, $GC_I_TYPE_DAGGERS, _
				$GC_I_TYPE_SCYTHE, $GC_I_TYPE_SPEAR
			Return True
	EndSwitch
	Return False
EndFunc

; Nearest town NPC whose name is Merchant. Skips material traders.
Func Leveler_FindTownMerchant()
	Local $l_i_Best = 0
	Local $l_f_Best = 999999
	Local $l_i_Max = Agent_GetMaxAgents()
	Local $i
	For $i = 1 To $l_i_Max - 1
		If Not Leveler_IsTalkNpc($i) Then ContinueLoop
		If Agent_GetAgentInfo($i, "Name") <> "Merchant" Then ContinueLoop
		Local $l_f_Dist = Agent_GetDistance($i)
		If $l_f_Dist < $l_f_Best Then
			$l_f_Best = $l_f_Dist
			$l_i_Best = $i
		EndIf
	Next
	Return $l_i_Best
EndFunc

; Once per outpost visit, sell white drops. They are not identified.
Func Leveler_MaybeSellWhiteDrops()
	If Not Leveler_WantsAutoSell() Then Return True
	If Not Leveler_IsOutpost() Or Map_GetInstanceInfo("IsLoading") Then
		$g_i_WhiteSellMap = -1
		Return True
	EndIf
	If $g_i_WhiteSellMap = Map_GetMapID() Then Return True

	Local $l_ai_Ids[32]
	Local $l_i_Bag, $l_i_Slot, $l_p_Item, $l_i_Count = 0
	For $l_i_Bag = 1 To 4
		If Item_GetBagPtr($l_i_Bag) = 0 Then ContinueLoop
		For $l_i_Slot = 1 To Item_GetBagInfo($l_i_Bag, "Slots")
			$l_p_Item = Item_GetItemBySlot($l_i_Bag, $l_i_Slot)
			If Not Leveler_IsWhiteSellDrop($l_p_Item) Then ContinueLoop
			If $l_i_Count >= UBound($l_ai_Ids) Then ReDim $l_ai_Ids[$l_i_Count + 16]
			$l_ai_Ids[$l_i_Count] = Item_GetItemInfoByPtr($l_p_Item, "ItemID")
			$l_i_Count += 1
		Next
	Next
	If $l_i_Count = 0 Then
		$g_i_WhiteSellMap = Map_GetMapID()
		Return True
	EndIf

	Local $l_i_Merchant = Leveler_FindTownMerchant()
	If $l_i_Merchant = 0 Then
		Out("[Sell] No merchant in this outpost. White drops stay in the bags.")
		$g_i_WhiteSellMap = Map_GetMapID()
		Return True
	EndIf

	Out("[Sell] Selling " & $l_i_Count & " white drop(s)")
	If Not Leveler_MoveTo(Agent_GetAgentInfo($l_i_Merchant, "X"), Agent_GetAgentInfo($l_i_Merchant, "Y"), False) Then
		Out("[Sell] Could not reach the merchant")
		Return True
	EndIf
	$l_i_Merchant = Leveler_FindTownMerchant()
	If $l_i_Merchant = 0 Then Return True
	Agent_ChangeTarget($l_i_Merchant)
	Sleep(150)
	Agent_GoNPC($l_i_Merchant)
	Sleep(400)

	Local $l_i_Sold = 0
	Local $i
	For $i = 0 To $l_i_Count - 1
		$l_p_Item = Item_GetItemPtr($l_ai_Ids[$i])
		If Not Leveler_IsWhiteSellDrop($l_p_Item) Then ContinueLoop
		If Merchant_SellItem($l_ai_Ids[$i]) Then
			$l_i_Sold += 1
			Sleep(200)
		EndIf
	Next
	$g_i_WhiteSellMap = Map_GetMapID()
	Out("[Sell] Sold " & $l_i_Sold & " white drop(s)")
	Return True
EndFunc

#EndRegion Gadgets

#Region Spirit Rifts
; Zen Daijun rift interrupt while pathing.

; Pathfinder callback: interrupt nearby Spirit Rift casts.
Func Leveler_InterruptSpiritRifts()
	If Map_GetMapID() <> $MAP_ZEN_OP Then Return
	If $g_h_RiftCooldown <> 0 And TimerDiff($g_h_RiftCooldown) < 1000 Then Return

	Local $l_i_Max = Agent_GetMaxAgents()
	For $i = 1 To $l_i_Max - 1
		If Agent_GetAgentPtr($i) = 0 Then ContinueLoop
		If Agent_GetAgentInfo($i, "IsDead") Then ContinueLoop
		If Agent_GetAgentInfo($i, "Allegiance") <> $GC_I_ALLEGIANCE_ENEMY Then ContinueLoop
		If Agent_GetAgentInfo($i, "Skill") <> $SKILL_SPIRIT_RIFT Then ContinueLoop

		Local $l_ai_Skills[4] = [$SKILL_CRY_OF_FRUSTRATION, $SKILL_POWER_DRAIN, $SKILL_SIGNET_OF_DISRUPTION, $SKILL_LEECH_SIGNET]
		For $s = 0 To 3
			Local $l_i_Slot = Skill_GetSlotByID($l_ai_Skills[$s])
			If $l_i_Slot > 0 Then
				Agent_ChangeTarget($i)
				Skill_UseSkill($l_i_Slot, $i)
				$g_h_RiftCooldown = TimerInit()
				Return
			EndIf
		Next
	Next
EndFunc

; Open the first agent with this model and send a dialog.
Func Leveler_TalkModel($a_i_Model, $a_i_Dialog)
	Local $l_i_Npc = Leveler_GetAgentByModel($a_i_Model)
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetNearestNPC(400)
	If $l_i_Npc = 0 Then
		Out("[Move] No NPC for model " & $a_i_Model)
		Return False
	EndIf
	Agent_GoNPC($l_i_Npc)
	Sleep(800)
	Ui_Dialog($a_i_Dialog)
	Sleep(600)
	Return True
EndFunc
#EndRegion Spirit Rifts

#Region Cinematic
; Skip known videos; wait out new ones.

; Wine can report a live cinematic pointer that is actually null. Do not treat that as a video.
Func Leveler_InCinematic()
	Local $l_p_Ptr = Game_GetGameInfo("Cinematic")
	If $l_p_Ptr = 0 Then Return False
	If Memory_Read($l_p_Ptr) = 0 And Memory_Read($l_p_Ptr + 0x4) = 0 Then Return False
	Return True
EndFunc

; True on the known cinematic map ids used after the scrying pool.
Func Leveler_OnCinematicMap()
	Local $l_i_Map = Map_GetMapID()
	If $l_i_Map >= 679 And $l_i_Map <= 685 Then Return True
	If $l_i_Map = 689 Or $l_i_Map = 694 Then Return True
	Return False
EndFunc

; After the scrying pool: skip if this account already knows the video, else wait it out.
; Wait out a cinematic, then a short extra delay.
Func Leveler_WaitCinematic($a_i_StartTimeout = 8000, $a_i_PlayTimeout = 240000)
	Local $l_h_Timer = TimerInit()
	Local $l_b_Saw = False
	While TimerDiff($l_h_Timer) < $a_i_StartTimeout
		If $g_b_LevelerPaused Then Return False
		If Leveler_InCinematic() Then
			$l_b_Saw = True
			ExitLoop
		EndIf
		Sleep(150)
	WEnd
	If Not $l_b_Saw Then Return True

	Other_PingSleep(1500)
	$l_h_Timer = TimerInit()
	While Leveler_InCinematic() And TimerDiff($l_h_Timer) < 6000
		Cinematic_SkipCinematic()
		Sleep(250)
	WEnd
	If Not Leveler_InCinematic() Then
		Out("[Move] Skipped known cinematic")
		Sleep(500)
		Return True
	EndIf

	Out("[Move] Cinematic is new; waiting for it to finish")
	$l_h_Timer = TimerInit()
	While Leveler_InCinematic() Or Map_GetInstanceInfo("IsLoading") Or Leveler_OnCinematicMap()
		If $g_b_LevelerPaused Then Return False
		If TimerDiff($l_h_Timer) > $a_i_PlayTimeout Then
			Out("[Move] Cinematic wait timed out")
			Return False
		EndIf
		Sleep(400)
	WEnd
	Sleep(500)
	Return True
EndFunc
#EndRegion Cinematic

#Region Scrying Pool
; Eye of the North pool gadget / living agent.

; Model 5959 may be living or gadget. Do not match ExtraType (garbage on other agents).
Func Leveler_GetScryingPool()
	Local $l_i_Best = 0
	Local $l_f_Best = 999999
	Local $l_i_Max = Agent_GetMaxAgents()
	Local $i
	For $i = 1 To $l_i_Max - 1
		If Agent_GetAgentPtr($i) = 0 Then ContinueLoop
		Local $l_i_Model = Number(Agent_GetAgentInfo($i, "PlayerNumber"))
		Local $l_i_GadgetID = Number(Agent_GetAgentInfo($i, "GadgetID"))
		Local $l_b_Gadget = Agent_GetAgentInfo($i, "IsGadgetType")
		If $l_i_Model <> $MODEL_EOTN_POOL And Not ($l_b_Gadget And $l_i_GadgetID = $MODEL_EOTN_POOL) Then ContinueLoop
		Local $l_f_Dist = Agent_GetDistanceToXY($EOTN_POOL_TILE_X, $EOTN_POOL_TILE_Y, $i)
		If $l_f_Dist < $l_f_Best Then
			$l_f_Best = $l_f_Dist
			$l_i_Best = $i
		EndIf
	Next
	If $l_i_Best <> 0 Then Return $l_i_Best
	$l_i_Best = Leveler_GetNearestGadgetAt($EOTN_POOL_TILE_X, $EOTN_POOL_TILE_Y, 350)
	If $l_i_Best <> 0 Then Return $l_i_Best
	Return Leveler_GetNearestGadgetAt($EOTN_POOL_X, $EOTN_POOL_Y, 350)
EndFunc

; Debug log of living and gadget agents near the scrying pool.
Func Leveler_LogPoolAgents($a_f_Range = 1500)
	Local $l_i_Max = Agent_GetMaxAgents()
	Local $i
	Local $l_i_Count = 0
	For $i = 1 To $l_i_Max - 1
		If Agent_GetAgentPtr($i) = 0 Then ContinueLoop
		If Agent_GetDistance($i) > $a_f_Range Then ContinueLoop
		Local $l_i_Type = Number(Agent_GetAgentInfo($i, "Type"))
		If $l_i_Type <> 0x200 And $l_i_Type <> 0xDB Then ContinueLoop
		$l_i_Count = $l_i_Count + 1
		Out("[Move] Agent " & $i & " ID=" & Agent_GetAgentInfo($i, "ID") & _
				" type=0x" & Hex($l_i_Type, 3) & _
				" gadget=" & Agent_GetAgentInfo($i, "IsGadgetType") & _
				" GadgetID=" & Agent_GetAgentInfo($i, "GadgetID") & _
				" Model=" & Agent_GetAgentInfo($i, "PlayerNumber") & _
				" at " & Round(Agent_GetAgentInfo($i, "X")) & ", " & Round(Agent_GetAgentInfo($i, "Y")))
		If $l_i_Count >= 12 Then Return
	Next
	If $l_i_Count = 0 Then Out("[Move] No living/gadget agents within " & $a_f_Range)
EndFunc

; Target an agent and wait until the client reports that target.
Func Leveler_SelectAgent($a_i_Agent, $a_i_Timeout = 6000)
	If $a_i_Agent = 0 Then Return False
	Local $l_i_Id = Number(Agent_GetAgentInfo($a_i_Agent, "ID"))
	If $l_i_Id = 0 Then $l_i_Id = Number($a_i_Agent)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		Agent_ChangeTarget($l_i_Id)
		Sleep(250)
		Local $l_i_Cur = Number(Agent_GetCurrentTarget())
		If $l_i_Cur = $l_i_Id Or $l_i_Cur = Number($a_i_Agent) Then
			Out("[Move] Selected scrying pool (target " & $l_i_Cur & ")")
			Return True
		EndIf
		Agent_ChangeTarget($a_i_Agent)
		Sleep(250)
		$l_i_Cur = Number(Agent_GetCurrentTarget())
		If $l_i_Cur = $l_i_Id Or $l_i_Cur = Number($a_i_Agent) Then
			Out("[Move] Selected scrying pool (target " & $l_i_Cur & ")")
			Return True
		EndIf
	WEnd
	Out("[Move] Did not select pool agent " & $a_i_Agent & " id " & $l_i_Id & " (current " & Agent_GetCurrentTarget() & ", rejects " & Agent_GetTargetRejectCount() & ")")
	Return False
EndFunc

; Stand on the pool tile, select it, interact, then send 0x63D.
Func Leveler_UseScryingPool()
	Out("[Move] Walking to the scrying pool tile")
	Leveler_MoveTo($EOTN_POOL_TILE_X, $EOTN_POOL_TILE_Y, False)
	Local $l_i_Pool = Leveler_GetScryingPool()
	If $l_i_Pool = 0 Then
		Leveler_MoveTo($EOTN_POOL_X, $EOTN_POOL_Y, False)
		$l_i_Pool = Leveler_GetScryingPool()
	EndIf
	If $l_i_Pool = 0 Then
		$l_i_Pool = Leveler_GetNearestGadget(400)
	EndIf
	If $l_i_Pool = 0 Then
		Leveler_LogPoolAgents()
		Out("[Move] Scrying pool was not found")
		Return False
	EndIf

	Local $l_i_Id = Number(Agent_GetAgentInfo($l_i_Pool, "ID"))
	If $l_i_Id = 0 Then $l_i_Id = Number($l_i_Pool)
	Local $l_f_X = Agent_GetAgentInfo($l_i_Pool, "X")
	Local $l_f_Y = Agent_GetAgentInfo($l_i_Pool, "Y")
	Out("[Move] Pool agent " & $l_i_Pool & " ID=" & $l_i_Id & _
			" type=0x" & Hex(Number(Agent_GetAgentInfo($l_i_Pool, "Type")), 3) & _
			" GadgetID=" & Agent_GetAgentInfo($l_i_Pool, "GadgetID") & _
			" Model=" & Agent_GetAgentInfo($l_i_Pool, "PlayerNumber") & _
			" at " & Round($l_f_X) & ", " & Round($l_f_Y))

	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < 20000
		If $g_b_LevelerPaused Then Return False
		If Agent_GetDistance($l_i_Pool) < 180 Then ExitLoop
		Map_Move($l_f_X, $l_f_Y, 20)
		Sleep(250)
		$l_i_Pool = Leveler_GetScryingPool()
		If $l_i_Pool = 0 Then $l_i_Pool = Leveler_GetNearestGadget(400)
		If $l_i_Pool = 0 Then ExitLoop
		$l_f_X = Agent_GetAgentInfo($l_i_Pool, "X")
		$l_f_Y = Agent_GetAgentInfo($l_i_Pool, "Y")
		$l_i_Id = Number(Agent_GetAgentInfo($l_i_Pool, "ID"))
		If $l_i_Id = 0 Then $l_i_Id = Number($l_i_Pool)
	WEnd

	If Not Leveler_SelectAgent($l_i_Pool) Then
		Leveler_LogPoolAgents()
		Return False
	EndIf

	If Agent_GetAgentInfo($l_i_Pool, "IsGadgetType") Then
		Agent_GoSignpost($l_i_Id)
	Else
		Agent_GoNPC($l_i_Id)
	EndIf
	Sleep(800)
	If Number(Agent_GetCurrentTarget()) <> $l_i_Id Then Agent_ChangeTarget($l_i_Id)
	If Agent_GetAgentInfo($l_i_Pool, "IsGadgetType") Then
		Agent_GoNPC($l_i_Id)
	Else
		Agent_GoSignpost($l_i_Id)
	EndIf
	Sleep(1000)
	Out("[Move] Sending 0x63D for Look deep into the pool")
	Game_Dialog($DIALOG_POOL_LOOK_DEEP)
	Sleep(700)
	Out("[Move] Sending 0x63F I'll keep my eyes open")
	Game_Dialog($DIALOG_POOL_EYES_OPEN)
	Sleep(400)
	Return True
EndFunc

; True when Keiran's Bow is in inventory or a weapon set.
Func Leveler_HasKeiranBow()
	If Item_FindItemByModelID($MODEL_KEIRAN_BOW) <> 0 Then Return True
	If Item_GetInventoryInfo("WeaponSet0WeaponModelID") = $MODEL_KEIRAN_BOW Then Return True
	If Item_GetInventoryInfo("WeaponSet1WeaponModelID") = $MODEL_KEIRAN_BOW Then Return True
	Return False
EndFunc

; Character level from the player agent, with a party-info fallback.
Func Leveler_PlayerLevel()
	Local $l_i_Level = Agent_GetAgentInfo(-2, "Level")
	If $l_i_Level = 0 Then $l_i_Level = Party_GetPartyProfessionInfo(-2, "Level")
	Return $l_i_Level
EndFunc
#EndRegion Scrying Pool

#Region Map Ready
; Client load, disconnect, and outpost waits.

; Walk a list of [X,Y] points. In KilroyMode, handle KO between points.
Func Leveler_FollowCoords(ByRef $a_af_Path, $a_b_Combat = False)
	Local $l_i_StartMap = Map_GetMapID()
	Local $i
	For $i = 0 To UBound($a_af_Path) - 1
		If $g_b_LevelerPaused Then Return False
		If Leveler_IsWiped() Then Return False
		If $g_b_KilroyMode Then Leveler_HandleKilroyDeath()
		If Map_GetMapID() <> $l_i_StartMap Then Return True
		Leveler_MoveTo($a_af_Path[$i][0], $a_af_Path[$i][1], $a_b_Combat)
	Next
	Return Not Leveler_IsWiped()
EndFunc

; Outpost click-move. Pathfinder on Eye of the North stops short of the Hall portal.
Func Leveler_OutpostMove($a_f_X, $a_f_Y, $a_i_ExitMap = 0, $a_i_Timeout = 45000)
	Local $l_i_StartMap = Map_GetMapID()
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		Local $l_i_Map = Map_GetMapID()
		If $a_i_ExitMap <> 0 And $l_i_Map = $a_i_ExitMap Then Return True
		If $l_i_Map <> $l_i_StartMap Then Return True
		If Agent_GetDistanceToXY($a_f_X, $a_f_Y) < $LEVELER_ARRIVE_RANGE Then Return True
		Map_Move($a_f_X, $a_f_Y, 0)
		Sleep(250)
	WEnd
	If $a_i_ExitMap <> 0 And Map_GetMapID() = $a_i_ExitMap Then Return True
	Return Agent_GetDistanceToXY($a_f_X, $a_f_Y) < $LEVELER_ARRIVE_RANGE
EndFunc

; Sleep in 250 ms slices, aborting on pause/wipe or handling a Kilroy KO.
Func Leveler_WaitMs($a_i_Ms)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Ms
		If $g_b_LevelerPaused Then Return False
		If Leveler_IsWiped() And Not $g_b_KilroyMode Then Return False
		If $g_b_KilroyMode Then Leveler_HandleKilroyDeath()
		If Leveler_ShouldFightHere() Then Leveler_CombatTick()
		Sleep(50)
	WEnd
	Return True
EndFunc

; Turn combat on and wait the given milliseconds.
Func Leveler_CombatBurst($a_i_Ms)
	$g_b_CombatMode = True
	Return Leveler_WaitMs($a_i_Ms)
EndFunc

; Wait until the instance returns to an outpost (Punch-Out / training).
Func Leveler_WaitUntilOutpost($a_i_Timeout = 180000)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If $g_b_KilroyMode Then Leveler_HandleKilroyDeath()
		If Map_GetInstanceInfo("IsOutpost") Then Return True
		If Leveler_IsWiped() And Not $g_b_KilroyMode Then Return False
		If Leveler_ShouldFightHere() Then Leveler_CombatTick()
		Sleep(50)
	WEnd
	Return Map_GetInstanceInfo("IsOutpost")
EndFunc

; Wait until Map_GetMapID equals the target.
Func Leveler_WaitForMap($a_i_MapID, $a_i_Timeout = 45000)
	If Map_GetMapID() = $a_i_MapID Then Return True
	Return Map_WaitMapLoading($a_i_MapID, -1, $a_i_Timeout)
EndFunc

; After a disconnect the client can sit on a loading / zero map. Wait until we can act.
Func Leveler_ClientIsReady()
	If Map_GetMapID() <= 0 Then Return False
	If Map_GetInstanceInfo("IsLoading") Then Return False
	If Agent_GetAgentPtr(-2) = 0 Then Return False
	If Agent_GetAgentInfo(-2, "X") = 0 And Agent_GetAgentInfo(-2, "Y") = 0 Then Return False
	Return True
EndFunc

; True when the map ID is gone or the player agent pointer is missing.
Func Leveler_ClientDisconnected()
	If Map_GetMapID() <= 0 Then Return True
	If Agent_GetAgentPtr(-2) = 0 And Not Map_GetInstanceInfo("IsLoading") Then Return True
	Return False
EndFunc

; Drop the old path and continue from the live character XY after a reconnect.
Func Leveler_ResumeFromCurrentPosition()
	Pathfinder_Shutdown()
	$g_b_UAIReady = False
	$g_i_LastUAIMap = 0
	If Not Leveler_ClientIsReady() Then Return False
	Local $l_i_Map = Map_GetMapID()
	Local $l_f_X = Agent_GetAgentInfo(-2, "X")
	Local $l_f_Y = Agent_GetAgentInfo(-2, "Y")
	Out("[Recover] Connection resumed. Map " & $l_i_Map & "  Pos " & Round($l_f_X) & ", " & Round($l_f_Y) & ". Continuing from here.")
	Sleep(2000)
	If Map_GetInstanceInfo("IsExplorable") Then Leveler_PrepareCombatAI()
	$g_b_ConnectionLost = False
	Return True
EndFunc

; Wait until the client can act, resuming from XY after a reconnect.
Func Leveler_WaitUntilMapReady($a_i_Timeout = 45000)
	Local $l_b_Dropped = Leveler_ClientDisconnected()
	If $l_b_Dropped Then $g_b_ConnectionLost = True
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If Leveler_ClientDisconnected() Then $g_b_ConnectionLost = True
		If Leveler_ClientIsReady() Then
			If $g_b_ConnectionLost Then Return Leveler_ResumeFromCurrentPosition()
			Return True
		EndIf
		Sleep(250)
	WEnd
	If Leveler_ClientIsReady() Then
		If $g_b_ConnectionLost Then Return Leveler_ResumeFromCurrentPosition()
		Return True
	EndIf
	Return False
EndFunc
#EndRegion Map Ready

#Region Punch Out
; Kilroy / Fronis instance and brass knuckles.

Func Leveler_IsPunchoutMap($a_i_Map = 0)
	If $a_i_Map = 0 Then $a_i_Map = Map_GetMapID()
	Return $a_i_Map = $MAP_KILROY Or $a_i_Map = $MAP_FRONIS
EndFunc

; Wait until Punch the Clown has finished loading.
Func Leveler_WaitKilroyInstance($a_i_Timeout = 45000)
	Return Leveler_WaitPunchoutInstance($MAP_KILROY, $a_i_Timeout)
EndFunc

; Wait until a punch-out map is loaded and the client is ready.
Func Leveler_WaitPunchoutInstance($a_i_MapID, $a_i_Timeout = 45000)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If Map_GetMapID() = $a_i_MapID And Not Map_GetInstanceInfo("IsLoading") And Not Map_GetInstanceInfo("IsOutpost") And Leveler_ClientIsReady() Then Return True
		Sleep(200)
	WEnd
	Return Map_GetMapID() = $a_i_MapID And Not Map_GetInstanceInfo("IsLoading") And Not Map_GetInstanceInfo("IsOutpost") And Leveler_ClientIsReady()
EndFunc

; Same equip path as the Clairvoyant Staff: wait for bags, then Leveler_EquipModel.
Func Leveler_EquipBrassKnuckles()
	If Not Leveler_IsPunchoutMap() Then
		Out("[Kilroy] Brass knuckles wait until the punch-out map is loaded")
		Return False
	EndIf
	If Leveler_IsModelEquipped($MODEL_BRASS_KNUCKLES) Then
		Out("[Kilroy] Brass knuckles already equipped")
		Return True
	EndIf
	; Granted on Punch the Clown load — same wait used after crafting the staff.
	If Not Leveler_WaitForBagModel($MODEL_BRASS_KNUCKLES, 20000) Then
		Out("[Kilroy] Brass knuckles (24897) did not appear in bags")
		Return False
	EndIf
	Out("[Kilroy] Equipping brass knuckles via Leveler_EquipModel(24897)")
	Return Leveler_EquipModel($MODEL_BRASS_KNUCKLES)
EndFunc

; UtilityAI brawling skills (API/Plugins/UtilityAI + GwAu3_Const_Skill):
; BRAWLING, BLOCK, JAB1/2, STRAIGHT_RIGHT, HOOK1/2, UPPERCUT, COMBO_PUNCH, HEADBUTT, STAND_UP.
Func Leveler_IsBrawlingSkillID($a_i_SkillID)
	Return $a_i_SkillID >= $GC_I_SKILL_ID_BRAWLING And $a_i_SkillID <= $GC_I_SKILL_ID_STAND_UP
EndFunc

; True when the live bar has Stand Up or another brawling skill.
Func Leveler_HasBrawlingBar()
	If Skill_GetSkillbarInfo(8, "SkillID") = $GC_I_SKILL_ID_STAND_UP Then Return True
	Local $i
	For $i = 1 To 7
		If Leveler_IsBrawlingSkillID(Skill_GetSkillbarInfo($i, "SkillID")) Then Return True
	Next
	Return False
EndFunc

; After Cache_SkillBar: read UAI static IDs, find STAND UP + fight slots (Punch_Out order).
Func Leveler_ResolveKilroySlotsFromCache()
	$g_i_KilroyStandUpSlot = 0
	$g_ai_KilroyFightSlots[0] = 0

	Local $i
	For $i = 1 To 8
		Local $l_i_ID = UAI_GetStaticSkillInfo($i, $GC_UAI_STATIC_SKILL_SkillID)
		If $l_i_ID = 0 Then $l_i_ID = Skill_GetSkillbarInfo($i, "SkillID")
		If $l_i_ID = $GC_I_SKILL_ID_STAND_UP Then
			$g_i_KilroyStandUpSlot = $i
			ExitLoop
		EndIf
	Next
	If $g_i_KilroyStandUpSlot = 0 Then $g_i_KilroyStandUpSlot = 8

	; Punch_Out_Farm / Kilroy.au3 cast order: slots 1,2,3,5,6,4 (skip STAND UP).
	Local $l_ai_Order[6] = [1, 2, 3, 5, 6, 4]
	Local $l_i_Count = 0
	For $i = 0 To 5
		Local $l_i_Slot = $l_ai_Order[$i]
		Local $l_i_ID = UAI_GetStaticSkillInfo($l_i_Slot, $GC_UAI_STATIC_SKILL_SkillID)
		If $l_i_ID = 0 Then $l_i_ID = Skill_GetSkillbarInfo($l_i_Slot, "SkillID")
		If Not Leveler_IsBrawlingSkillID($l_i_ID) Then ContinueLoop
		If $l_i_ID = $GC_I_SKILL_ID_STAND_UP Then ContinueLoop
		$l_i_Count += 1
		$g_ai_KilroyFightSlots[$l_i_Count] = $l_i_Slot
	Next
	$g_ai_KilroyFightSlots[0] = $l_i_Count
	Return $l_i_Count > 0
EndFunc

; Cache_SkillBar() from UtilityAI, then resolve brawling slots from the static cache.
Func Leveler_PrepareKilroyCombat()
	$g_b_CombatMode = True
	$g_b_UAIReady = False
	$g_i_LastUAIMap = 0
	$g_ai_KilroyFightSlots[0] = 0
	If Not Leveler_WaitBrawlingBar() Then
		Out("[Kilroy] Brawling skills are not on the bar yet")
		Return False
	EndIf

	; UtilityAI only: Cache_SkillBar (binds CanUse_Brawling* / BestTarget_Brawling*).
	If Not Leveler_CacheUtilityAIForMap(Map_GetMapID()) Then
		Out("[Kilroy] Cache_SkillBar failed")
		Return False
	EndIf
	If Not Leveler_ResolveKilroySlotsFromCache() Then
		Out("[Kilroy] No brawling fight skills in UtilityAI skill-bar cache")
		Return False
	EndIf

	Local $l_s_Bar = "", $i
	For $i = 1 To 8
		If $i > 1 Then $l_s_Bar &= ", "
		Local $l_i_ID = UAI_GetStaticSkillInfo($i, $GC_UAI_STATIC_SKILL_SkillID)
		$l_s_Bar &= $i & "=" & $l_i_ID & "/" & $g_as_CanUseCache[$i]
	Next
	Out("[Kilroy] UtilityAI brawling cache: " & $l_s_Bar)
	Out("[Kilroy] Fight slots=" & $g_ai_KilroyFightSlots[0] & " STAND UP slot=" & $g_i_KilroyStandUpSlot)
	Return True
EndFunc

; Wait until the punch-out brawling bar replaces the normal bar.
Func Leveler_WaitBrawlingBar($a_i_Timeout = 8000)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If Leveler_HasBrawlingBar() Then Return True
		Sleep(200)
	WEnd
	Return Leveler_HasBrawlingBar()
EndFunc

; Equip an inventory model via the same helper as staff/armor.
Func Leveler_EquipItemByModel($a_i_Model)
	Return Leveler_EquipModel($a_i_Model)
EndFunc

; Enemy filter for punch-out brawling (Allegiance enemy, living).
Func Leveler_KilroyEnemyFilter($a_p_Agent)
	If Agent_GetAgentInfo($a_p_Agent, "Allegiance") <> $GC_I_ALLEGIANCE_ENEMY Then Return False
	If Agent_GetAgentInfo($a_p_Agent, "HP") <= 0 Then Return False
	If Agent_GetAgentInfo($a_p_Agent, "IsDead") Then Return False
	Return True
EndFunc

; Nearest living enemy in punch-out range.
Func Leveler_KilroyNearestFoe($a_i_Range = 1500)
	Return GetAgents(-2, $a_i_Range, $GC_I_AGENT_TYPE_LIVING, 1, "Leveler_KilroyEnemyFilter")
EndFunc

; How many living enemies are inside punch-out range.
Func Leveler_KilroyFoeCount($a_i_Range = 1200)
	Return GetAgents(-2, $a_i_Range, $GC_I_AGENT_TYPE_LIVING, 0, "Leveler_KilroyEnemyFilter")
EndFunc

; UAI_CanUse checks recharge and adrenaline. CanUse_Brawling* then holds the jabs
; while Straight Right or a finisher is ready, so the rest of the bar gets used.
Func Leveler_KilroyUseSkill($a_i_Slot, $a_v_Target = -2, $a_i_Range = 300)
	If Agent_GetAgentInfo(-2, "IsDead") Then Return False
	Leveler_UAI_RefreshSkillCache()
	If Not UAI_CanUse($a_i_Slot) Then Return False
	If $a_i_Slot >= 1 And $a_i_Slot <= 8 And $g_as_CanUseCache[$a_i_Slot] <> "" Then
		If Not Call($g_as_CanUseCache[$a_i_Slot]) Then Return False
	EndIf
	Return Leveler_UAI_UseSkillEx($a_i_Slot, $a_v_Target, $a_i_Range)
EndFunc

; The skillbar array entry moves when the character is knocked down. Re-find it without wiping CanUse.
Func Leveler_RebindSkillbarPtr()
	Local $l_p_Array = World_GetWorldInfo("SkillbarArray")
	Local $l_i_Size = World_GetWorldInfo("SkillbarArraySize")
	If $l_p_Array = 0 Or $l_i_Size = 0 Then Return False
	Local $l_i_MyID = Agent_GetMyID()
	Local $i
	For $i = 0 To $l_i_Size - 1
		Local $l_p_Ptr = $l_p_Array + (0xBC * $i)
		If Memory_Read($l_p_Ptr, "long") = $l_i_MyID Then
			$g_p_StaticSkillbarPtr = $l_p_Ptr
			Return True
		EndIf
	Next
	Return False
EndFunc

; True when the cached skill IDs and CanUse names still match the live bar.
Func Leveler_KilroyCacheMatchesBar()
	If Not $g_b_UAIReady Or $g_p_StaticSkillbarPtr = 0 Then Return False
	If Memory_Read($g_p_StaticSkillbarPtr, "long") <> Agent_GetMyID() Then Return False
	Local $i
	For $i = 1 To 8
		Local $l_i_Live = Skill_GetSkillbarInfo($i, "SkillID")
		If $l_i_Live <> UAI_GetStaticSkillInfo($i, $GC_UAI_STATIC_SKILL_SkillID) Then Return False
		If $l_i_Live <> 0 And $g_as_CanUseCache[$i] = "" Then Return False
	Next
	Return True
EndFunc

; Rebuild the brawling cache only once the skills are back on the bar. An empty downed bar must not wipe it.
Func Leveler_EnsureKilroySkillCache()
	Leveler_RebindSkillbarPtr()
	If Leveler_KilroyCacheMatchesBar() Then
		UAI_CacheDynamicSkillbarInfo()
		Return True
	EndIf
	If Not Leveler_HasBrawlingBar() Then Return False
	If Not Leveler_CacheSkillBarNow() Then Return False
	$g_i_LastUAIMap = Map_GetMapID()
	$g_b_UAIReady = True
	Leveler_ResolveKilroySlotsFromCache()
	UAI_CacheDynamicSkillbarInfo()
	Out("[Kilroy] Skill cache restored")
	Return True
EndFunc

; Energy at 0: skill 8 until the bar is 100% of MaxEnergy. The maximum grows as foes die.
Func Leveler_KilroyRecoverTick()
	If Map_GetInstanceInfo("IsLoading") Then Return False
	If Not $g_b_KilroyMode And Not $g_b_FarmMode And Not Leveler_IsPunchoutMap() Then Return False

	Local $l_f_Energy = Agent_GetAgentInfo(-2, "CurrentEnergy")
	Local $l_f_MaxEnergy = Agent_GetAgentInfo(-2, "MaxEnergy")
	Local $l_b_EnergyFull = ($l_f_MaxEnergy > 0 And $l_f_Energy >= $l_f_MaxEnergy) Or Agent_GetAgentInfo(-2, "EnergyPercent") >= 1

	If $l_f_Energy <= 0 And Not $g_b_KilroyRecovery Then
		$g_b_KilroyRecovery = True
		Out("[Kilroy] Energy is 0. Using skill 8 until energy is 100% (" & $l_f_MaxEnergy & ").")
	EndIf
	If Not $g_b_KilroyRecovery Then Return False

	; Keep the dynamic recharge/adrenaline cache on the live skillbar while downed.
	Leveler_RebindSkillbarPtr()
	If $g_p_StaticSkillbarPtr <> 0 Then UAI_CacheDynamicSkillbarInfo()

	If $l_b_EnergyFull Then
		$g_b_KilroyRecovery = False
		Leveler_EnsureKilroySkillCache()
		Out("[Kilroy] Energy is 100% (" & Round($l_f_Energy, 1) & "/" & $l_f_MaxEnergy & "). Stood up. Continuing combat.")
		Return False
	EndIf

	Skill_UseSkill(8, -2)
	Return True
EndFunc

; One pass of Punch_Out_Farm Brawling_Fight: stand up, close to 150, then slots 1, 2, 3, 5, 6, 4.
Func Leveler_KilroyCombatTick($a_i_Range = 1500, $a_b_Chase = True)
	If Map_GetInstanceInfo("IsLoading") Then Return False
	If Not Leveler_IsPunchoutMap() Then Return False
	; Energy at 0: skill 8 until the bar is 100%, then slots 1, 2, 3, 5, 6, 4.
	If Leveler_KilroyRecoverTick() Then Return True

	If Not Leveler_EnsureKilroySkillCache() Then
		If $g_b_UAIReady And Not Leveler_HasBrawlingBar() Then Return True
		If Not Leveler_PrepareKilroyCombat() Then Return False
	EndIf

	Local $l_p_Target = Leveler_KilroyNearestFoe($a_i_Range)
	If $l_p_Target = 0 Then Return False
	Local $l_i_Target = Agent_ConvertID($l_p_Target)
	If $l_i_Target = 0 Then Return False

	Local $l_f_Dist = Agent_GetDistance($l_i_Target, Agent_GetMyID())
	If $l_f_Dist > 150 Then
		Agent_ChangeTarget($l_p_Target)
		Agent_Attack($l_p_Target)
		Sleep(250)
		$l_f_Dist = Agent_GetDistance($l_i_Target, Agent_GetMyID())
		If $a_b_Chase And $l_f_Dist > 200 Then
			Map_Move(Agent_GetAgentInfo($l_i_Target, "X"), Agent_GetAgentInfo($l_i_Target, "Y"), 0)
		EndIf
		Return True
	EndIf

	If $l_f_Dist >= 300 Then Return True

	UAI_UpdateAgentCache($a_i_Range)
	Leveler_UAI_RefreshSkillCache()
	; Auto-attack sets the skill-bar cast flag and only builds adrenaline. Skills still have to go out.
	If Not Leveler_UAI_GetIsIdle(-2) Then Return True
	If Agent_GetAgentInfo($l_p_Target, "HP") <= 0 Then Return True

	If Agent_GetCurrentTarget() <> $l_i_Target Then
		Agent_ChangeTarget($l_p_Target)
		Agent_Attack($l_p_Target)
		Sleep(250)
	EndIf

	Local $l_ai_Order[6] = [1, 2, 3, 5, 6, 4]
	Local $l_i_Count = $g_ai_KilroyFightSlots[0]
	Local $i
	If $l_i_Count > 0 Then
		For $i = 1 To $l_i_Count
			If Leveler_KilroyUseSkill($g_ai_KilroyFightSlots[$i], $l_i_Target, 300) Then Return True
		Next
	Else
		For $i = 0 To 5
			If Leveler_KilroyUseSkill($l_ai_Order[$i], $l_i_Target, 300) Then Return True
		Next
	EndIf
	Return True
EndFunc

; Walk to X/Y. In punch-out, clear foes with the Punch_Out_Farm brawling loop, then resume.
Func Leveler_MoveAndFight($a_f_X, $a_f_Y, $a_i_ArriveRange = 250, $a_i_TimeoutMS = 120000)
	If $g_b_LevelerPaused Then Return False
	Local $l_i_StartMap = Map_GetMapID()
	Local $l_h_Timer = TimerInit()
	Local $l_h_MoveRefresh = TimerInit()
	Local $l_i_Plane = Agent_GetAgentInfo(-2, "Plane")
	; Randomize=0 — Map_Move(..., 50) re-rolls the target every call and looks like stutter-stepping.
	Map_MoveLayer($a_f_X, $a_f_Y, $l_i_Plane)

	While TimerDiff($l_h_Timer) < $a_i_TimeoutMS
		If $g_b_LevelerPaused Then Return False
		If Map_GetMapID() <> $l_i_StartMap Then Return True
		If Leveler_LeaveFarmAtLevel20() Then Return True
		; A move cancels Stand Up. Stay on skill 8 from energy 0 until energy is 100%.
		If Leveler_IsPunchoutMap() And ($g_b_KilroyRecovery Or Agent_GetAgentInfo(-2, "CurrentEnergy") <= 0) Then
			Leveler_KilroyRecoverTick()
			Sleep(50)
			ContinueLoop
		EndIf

		If Agent_GetDistanceToXY($a_f_X, $a_f_Y) <= $a_i_ArriveRange Then Return True

		; Punch_Out_Farm Brawling_ClearArea: fight anything within 1500, then resume the walk.
		If Leveler_IsPunchoutMap() And Leveler_KilroyFoeCount(1500) > 0 Then
			Local $l_h_Fight = TimerInit()
			While (Leveler_KilroyFoeCount(1500) > 0 Or $g_b_KilroyRecovery) And TimerDiff($l_h_Fight) < 180000
				If $g_b_LevelerPaused Or Map_GetMapID() <> $l_i_StartMap Then ExitLoop
				If Map_GetInstanceInfo("IsLoading") Then ExitLoop
				If Leveler_LeaveFarmAtLevel20() Then Return True
				Leveler_KilroyCombatTick(1500, True)
				Sleep(50)
			WEnd
			If $g_b_KilroyRecovery Then ContinueLoop
			If Not Map_GetInstanceInfo("IsLoading") Then Leveler_LootNearby(0, 1200, 2500)
			Map_MoveLayer($a_f_X, $a_f_Y, Agent_GetAgentInfo(-2, "Plane"))
			$l_h_MoveRefresh = TimerInit()
		ElseIf TimerDiff($l_h_MoveRefresh) > 2000 Then
			Map_MoveLayer($a_f_X, $a_f_Y, Agent_GetAgentInfo(-2, "Plane"))
			$l_h_MoveRefresh = TimerInit()
		EndIf

		Sleep(100)
	WEnd
	If Map_GetMapID() <> $l_i_StartMap Then Return True
	Return Agent_GetDistanceToXY($a_f_X, $a_f_Y) <= $a_i_ArriveRange
EndFunc

; Stand Up while energy reads 0. Combat continues once energy is 100% of the current maximum.
Func Leveler_IsPunchoutDowned()
	Return $g_b_KilroyRecovery Or Agent_GetAgentInfo(-2, "CurrentEnergy") <= 0
EndFunc

; One stand-up tick. Callers keep looping; a move during this cancels skill 8.
Func Leveler_HandleKilroyDeath()
	Return Leveler_KilroyRecoverTick()
EndFunc
#EndRegion Punch Out

#Region Recovery
; Resign, return to outpost, retry the current step.

; Resign or travel back after a wipe. Punch-out stays in the instance and stands up.
Func Leveler_RecoverWipe()
	$g_b_SpiritRiftWatch = False
	$g_b_UAIReady = False
	$g_i_LastUAIMap = 0
	If $g_b_FarmMode Or $g_b_KilroyMode Or Leveler_IsPunchoutMap() Then
		Out("[Recover] Downed in punch-out. Staying in the instance and using skill 8.")
		Leveler_HandleKilroyDeath()
		Return True
	EndIf

	Out("[Recover] Party wiped or dead. Resigning and returning to outpost.")
	Chat_SendChat("resign", "/")
	Sleep(1500)
	If Not Leveler_ReturnFromDefeat() Then
		Out("[Recover] Failed to reach an outpost.")
		Return False
	EndIf
	Out("[Recover] Back in outpost. Settling before retry: " & $g_s_CurrentHeader)
	Sleep(3000)
	Return True
EndFunc

; Send ReturnToOutpost once, then wait. Do not spam it — that disconnects on re-enter.
Func Leveler_ReturnFromDefeat()
	Local $l_b_SentReturn = False
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < 60000
		If $g_b_LevelerPaused Then Return False
		If Map_GetInstanceInfo("IsLoading") Then
			Sleep(250)
			ContinueLoop
		EndIf
		If Map_GetInstanceInfo("IsOutpost") Then
			Sleep(1000)
			Return True
		EndIf
		If Party_GetPartyContextInfo("IsDefeated") And Not $l_b_SentReturn Then
			Out("[Recover] Returning to outpost")
			Map_ReturnToOutpost(False)
			$l_b_SentReturn = True
			Sleep(2000)
			ContinueLoop
		EndIf
		Sleep(500)
	WEnd
	If Map_GetInstanceInfo("IsOutpost") Then Return True
	Return False
EndFunc
#EndRegion Recovery
