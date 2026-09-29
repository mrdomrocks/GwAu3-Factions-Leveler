#include-once

; Walk to an NPC and send GwAu3 quest dialogs (accept / update / reward).

#Region Quest Dialogs
; GwAu3 quest helper. Walk to the NPC, Agent_GoNPC, then send
; Ui_AcceptQuest / Ui_UpdateQuest / Ui_RewardQuest (or a custom Ui_Dialog).
; $a_s_Mode: "accept" | "complete" | "step" | "skip"
Func Leveler_QuestLoop($a_i_QuestID, $a_f_X, $a_f_Y, $a_i_Dialog, $a_s_Mode = "accept", $a_i_NpcModel = 0, $a_i_Multi = 0)
	Local $l_i_StartMap = Map_GetMapID()
	Local $l_f_X = $a_f_X
	Local $l_f_Y = $a_f_Y
	; For complete: distinguish "never started" from "just handed in and left the log".
	Local $l_b_HadQuest = Leveler_HasQuest($a_i_QuestID) Or Leveler_QuestReadyForReward($a_i_QuestID)

	If Leveler_QuestAlreadyDone($a_i_QuestID, $a_s_Mode) Then
		If $a_s_Mode = "accept" And $a_i_QuestID <> 0 Then Ui_ActiveQuest($a_i_QuestID)
		If $a_s_Mode = "complete" And $a_i_QuestID <> 0 Then Leveler_MarkQuestDone($a_i_QuestID)
		Out("[Quest] #" & $a_i_QuestID & " " & $a_s_Mode & " already done")
		Return True
	EndIf

	If $a_s_Mode = "complete" And $a_i_QuestID <> 0 And Not Leveler_HasQuest($a_i_QuestID) And $a_i_QuestID <> $QUEST_SECONDARY Then
		Return Leveler_FinishIfCompleteUnavailable($a_i_QuestID, $a_i_NpcModel)
	EndIf

	; Do not set a quest active or request its info until it is in the log.
	; Doing that on accept (before pickup) crashes the client.
	If $a_i_QuestID <> 0 And Leveler_HasQuest($a_i_QuestID) Then
		Ui_ActiveQuest($a_i_QuestID)
		Quest_RequestInfos($a_i_QuestID)
		Sleep(200)
	EndIf

	Local $l_b_Talked = False
	Local $l_i_Attempt
	For $l_i_Attempt = 1 To 8
		If $g_b_LevelerPaused Then Return False
		If Leveler_IsWiped() Then Return False
		; Step dialogs must actually be sent. "No marker on the nearest NPC" is not success
		; before we have walked to the quest NPC.
		If $a_s_Mode <> "step" And Leveler_QuestActionSucceeded($a_i_QuestID, $a_s_Mode, $a_i_NpcModel, $l_i_StartMap, $l_b_HadQuest) Then ExitLoop
		If $a_s_Mode = "step" And $l_i_Attempt > 1 And Leveler_QuestActionSucceeded($a_i_QuestID, $a_s_Mode, $a_i_NpcModel, $l_i_StartMap, $l_b_HadQuest) Then ExitLoop
		If $a_s_Mode = "step" And $a_i_QuestID <> 0 And Quest_GetQuestInfo($a_i_QuestID, "IsCompleted") Then ExitLoop

		Leveler_ResolveQuestXY($a_i_NpcModel, $l_f_X, $l_f_Y)
		If $l_f_X = 0 And $l_f_Y = 0 And $a_i_QuestID <> 0 Then Leveler_FillQuestMarker($a_i_QuestID, $l_f_X, $l_f_Y)

		Out("[Quest] " & $a_s_Mode & " #" & $a_i_QuestID & " attempt " & $l_i_Attempt)
		If Not Leveler_QuestTalk($l_f_X, $l_f_Y, $a_i_QuestID, $a_s_Mode, $a_i_Dialog, $a_i_NpcModel, $a_i_Multi) Then
			Sleep(500)
			ContinueLoop
		EndIf
		$l_b_Talked = True

		; RequestInfos on a quest that just left the log crashes the client.
		If $a_i_QuestID <> 0 And Leveler_HasQuest($a_i_QuestID) Then Quest_RequestInfos($a_i_QuestID)
		If Leveler_WaitQuestResult($a_i_QuestID, $a_s_Mode, $a_i_NpcModel, $l_i_StartMap, 4000, $l_b_HadQuest) Then ExitLoop
	Next

	If Not Leveler_QuestActionSucceeded($a_i_QuestID, $a_s_Mode, $a_i_NpcModel, $l_i_StartMap, $l_b_HadQuest) Then
		If $a_s_Mode = "complete" And $l_b_Talked And Leveler_FinishIfCompleteUnavailable($a_i_QuestID, $a_i_NpcModel) Then Return True
		Out("[Quest] Failed to " & $a_s_Mode & " #" & $a_i_QuestID)
		Return False
	EndIf

	If $a_s_Mode = "accept" And $a_i_QuestID <> 0 Then Ui_ActiveQuest($a_i_QuestID)
	If $a_s_Mode = "complete" And $a_i_QuestID <> 0 Then Leveler_MarkQuestDone($a_i_QuestID)
	Out("[Quest] " & $a_s_Mode & " #" & $a_i_QuestID & " finished")
	Return True
EndFunc

; Walk into talk range, open the NPC, then send the GwAu3 quest dialog.
Func Leveler_QuestTalk($a_f_X, $a_f_Y, $a_i_QuestID, $a_s_Mode, $a_i_Dialog, $a_i_NpcModel = 0, $a_i_Multi = 0)
	Local $l_i_StartMap = Map_GetMapID()
	If $a_f_X <> 0 Or $a_f_Y <> 0 Then
		If Not Leveler_MoveTo($a_f_X, $a_f_Y, Leveler_ShouldFightHere()) And Map_GetMapID() = $l_i_StartMap Then Return False
	EndIf
	If Map_GetMapID() <> $l_i_StartMap Then Return True

	Local $l_i_Npc = Leveler_ResolveTalkNpc($a_f_X, $a_f_Y, $a_i_NpcModel)
	If $l_i_Npc = 0 Then
		Out("[Quest] No NPC near " & Round($a_f_X) & ", " & Round($a_f_Y))
		Return False
	EndIf

	Agent_ChangeTarget($l_i_Npc)
	Sleep(150)
	Agent_GoNPC($l_i_Npc)

	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < 5000
		If Agent_GetDistance($l_i_Npc) < $LEVELER_ARRIVE_RANGE Then ExitLoop
		Sleep(100)
	WEnd
	If Agent_GetDistance($l_i_Npc) >= $LEVELER_ARRIVE_RANGE Then
		Out("[Quest] Could not reach NPC model " & Agent_GetAgentInfo($l_i_Npc, "PlayerNumber"))
		Return False
	EndIf

	Sleep(700)
	Leveler_SendQuestAction($a_i_QuestID, $a_s_Mode, $a_i_Dialog)
	Sleep(500)
	If $a_i_Multi <> 0 Then
		Ui_Dialog($a_i_Multi)
		Sleep(400)
	EndIf
	Return True
EndFunc

; Always send the numeric dialog ID. Do not rely on Ui_AcceptQuest string hex.
Func Leveler_SendQuestAction($a_i_QuestID, $a_s_Mode, $a_i_Dialog)
	; Complete IDs are the reward button. The Python leveler sends it once.
	; Extra copies go out after the window closes and the client errors 007.
	If $a_s_Mode = "complete" Then
		If $a_i_Dialog <> 0 Then
			Game_Dialog($a_i_Dialog)
		ElseIf $a_i_QuestID <> 0 Then
			Ui_RewardQuest($a_i_QuestID)
		EndIf
		Return
	EndIf
	If $a_i_Dialog <> 0 Then Ui_Dialog($a_i_Dialog)
	Switch $a_s_Mode
		Case "accept"
			If $a_i_QuestID <> 0 And $a_i_Dialog = 0 Then Ui_AcceptQuest($a_i_QuestID)
		Case "step"
			If $a_i_QuestID <> 0 And $a_i_Dialog = 0 Then Ui_UpdateQuest($a_i_QuestID)
		Case Else
	EndSwitch
EndFunc

#EndRegion Quest Dialogs

#Region Quest State

; Copy the quest compass marker into X/Y when the quest is in the log.
Func Leveler_FillQuestMarker($a_i_QuestID, ByRef $a_f_X, ByRef $a_f_Y)
	If Not Leveler_HasQuest($a_i_QuestID) Then Return
	Local $l_f_MX = Quest_GetQuestInfo($a_i_QuestID, "MarkerX")
	Local $l_f_MY = Quest_GetQuestInfo($a_i_QuestID, "MarkerY")
	If $l_f_MX = 0 And $l_f_MY = 0 Then Return
	$a_f_X = $l_f_MX
	$a_f_Y = $l_f_MY
EndFunc

; Replace X/Y with the live NPC position when that model (or nearest NPC) is found.
Func Leveler_ResolveQuestXY($a_i_NpcModel, ByRef $a_f_X, ByRef $a_f_Y)
	Local $l_i_Npc = 0
	If $a_i_NpcModel <> 0 Then $l_i_Npc = Leveler_GetAgentByModel($a_i_NpcModel)
	If $l_i_Npc = 0 And $a_f_X = 0 And $a_f_Y = 0 Then Return
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetNearestNPCAt($a_f_X, $a_f_Y, 400)
	If $l_i_Npc = 0 Then Return
	$a_f_X = Agent_GetAgentInfo($l_i_Npc, "X")
	$a_f_Y = Agent_GetAgentInfo($l_i_Npc, "Y")
EndFunc

; Poll until accept/complete/step succeeds or the timeout elapses.
Func Leveler_WaitQuestResult($a_i_QuestID, $a_s_Mode, $a_i_NpcModel, $a_i_StartMap, $a_i_Timeout = 4000, $a_b_HadQuest = True)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If Leveler_IsWiped() Then Return False
		If Leveler_QuestActionSucceeded($a_i_QuestID, $a_s_Mode, $a_i_NpcModel, $a_i_StartMap, $a_b_HadQuest) Then Return True
		Sleep(200)
	WEnd
	Return Leveler_QuestActionSucceeded($a_i_QuestID, $a_s_Mode, $a_i_NpcModel, $a_i_StartMap, $a_b_HadQuest)
EndFunc

; True when this accept/complete action does not need to be sent again.
Func Leveler_QuestAlreadyDone($a_i_QuestID, $a_s_Mode)
	Switch $a_s_Mode
		Case "accept"
			If $a_i_QuestID = 0 Then Return False
			If Leveler_HasQuest($a_i_QuestID) Then Return True
			Return Leveler_QuestFinished($a_i_QuestID)
		Case "complete"
			If $a_i_QuestID = $QUEST_SECONDARY Then Return Leveler_SecondaryRewardTaken()
			If $a_i_QuestID = $QUEST_FORMAL_INTRO Then Return Leveler_FormalIntroductionTurnedIn()
			If $a_i_QuestID = 0 Then Return False
			If Leveler_QuestNeedsHandIn($a_i_QuestID) Then Return False
			; Never-started must not look "already done" (NeedsHandIn is also false then).
			If Leveler_IsQuestDone($a_i_QuestID) Then Return True
			If Leveler_QuestFinished($a_i_QuestID) Then Return True
			Return False
		Case Else
			Return False
	EndSwitch
EndFunc

; True when the accept, complete, or step dialog already took effect.
Func Leveler_QuestActionSucceeded($a_i_QuestID, $a_s_Mode, $a_i_NpcModel, $a_i_StartMap, $a_b_HadQuest = True)
	Switch $a_s_Mode
		Case "accept"
			Return Leveler_HasQuest($a_i_QuestID) Or Leveler_QuestFinished($a_i_QuestID)
		Case "complete"
			If $a_i_QuestID = $QUEST_SECONDARY Then Return Leveler_SecondaryRewardTaken()
			If $a_i_QuestID = $QUEST_FORMAL_INTRO Then Return Leveler_FormalIntroductionTurnedIn()
			If Leveler_QuestNeedsHandIn($a_i_QuestID) Then Return False
			If Leveler_IsQuestDone($a_i_QuestID) Or Leveler_QuestFinished($a_i_QuestID) Then Return True
			; Hand-in removed it from the log during this QuestLoop.
			Return $a_b_HadQuest
		Case "step", "skip"
			If Map_GetMapID() <> $a_i_StartMap Then Return True
			If $a_s_Mode = "step" And $a_i_QuestID <> 0 And Quest_GetQuestInfo($a_i_QuestID, "IsCompleted") Then Return True
			Return Not Leveler_NpcHasQuestMarker($a_i_NpcModel)
		Case Else
			Return Leveler_HasQuest($a_i_QuestID)
	EndSwitch
EndFunc

; 0 = not in log, 1 = in log (objectives open), 2 = in log (reward ready).
; Bit 0x2 is Quest_GetQuestInfo "IsCompleted": the reward can be taken. It is not finished for #317 or #318.
Func Leveler_QuestLogMatch($a_i_QuestID)
	If $a_i_QuestID = 0 Then Return 0
	If Quest_GetQuestInfo($a_i_QuestID, "HasQuest") Then
		If Quest_GetQuestInfo($a_i_QuestID, "IsCompleted") Then Return 2
		If BitAND(Quest_GetQuestInfo($a_i_QuestID, "LogState"), 0x2) <> 0 Then Return 2
		Return 1
	EndIf
	Local $l_p_Log = World_GetWorldInfo("QuestLog")
	Local $l_i_Size = World_GetWorldInfo("QuestLogSize")
	If $l_p_Log = 0 Or $l_i_Size <= 0 Then Return 0
	Local $i
	For $i = 0 To $l_i_Size - 1
		Local $l_p_Entry = $l_p_Log + ($i * 0x34)
		If Memory_Read($l_p_Entry, "long") <> $a_i_QuestID Then ContinueLoop
		If BitAND(Memory_Read($l_p_Entry + 0x4, "long"), 0x2) <> 0 Then Return 2
		Return 1
	Next
	Return 0
EndFunc

; True when the quest is in this character's log (objectives or reward-ready).
Func Leveler_QuestInLog($a_i_QuestID)
	If $a_i_QuestID = 0 Then Return False
	If Quest_GetQuestInfo($a_i_QuestID, "HasQuest") Then Return True
	Return Leveler_QuestLogMatch($a_i_QuestID) <> 0
EndFunc

; True when the quest is in the log and IsCompleted / LogState bit 2 is set.
Func Leveler_QuestReadyForReward($a_i_QuestID)
	If Quest_GetQuestInfo($a_i_QuestID, "IsCompleted") Then Return True
	Return Leveler_QuestLogMatch($a_i_QuestID) = 2
EndFunc

; True when the reward is ready, or #317/#318 have been handed in.
Func Leveler_QuestLogCompleted($a_i_QuestID)
	If $a_i_QuestID = $QUEST_SECONDARY Then Return Leveler_SecondaryRewardTaken()
	If $a_i_QuestID = $QUEST_FORMAL_INTRO Then Return Leveler_FormalIntroductionTurnedIn()
	Return Leveler_QuestReadyForReward($a_i_QuestID)
EndFunc

; Raw LogState from Quest_GetQuestInfo or the quest-log memory entry.
Func Leveler_QuestLogStateValue($a_i_QuestID)
	If $a_i_QuestID = 0 Then Return 0
	Local $l_i_State = Quest_GetQuestInfo($a_i_QuestID, "LogState")
	If $l_i_State <> 0 Then Return $l_i_State
	Local $l_p_Log = World_GetWorldInfo("QuestLog")
	Local $l_i_Size = World_GetWorldInfo("QuestLogSize")
	If $l_p_Log = 0 Or $l_i_Size <= 0 Then Return 0
	Local $i
	For $i = 0 To $l_i_Size - 1
		Local $l_p_Entry = $l_p_Log + ($i * 0x34)
		If Memory_Read($l_p_Entry, "long") <> $a_i_QuestID Then ContinueLoop
		Return Memory_Read($l_p_Entry + 0x4, "long")
	Next
	Return 0
EndFunc

; Print a human-readable quest-log line for debugging.
Func Leveler_LogQuestState($a_i_QuestID, $a_s_Label = "")
	Local $l_i_Match = Leveler_QuestLogMatch($a_i_QuestID)
	Local $l_i_State = Leveler_QuestLogStateValue($a_i_QuestID)
	Local $l_s_State = "not in log"
	If $l_i_Match = 0 And Leveler_QuestFinished($a_i_QuestID) Then $l_s_State = "completed (handed in)"
	If $l_i_Match = 1 Then $l_s_State = "ACTIVE (complete dialog not taken)"
	If $l_i_Match = 2 Then $l_s_State = "in log, reward ready (complete dialog not taken)"
	If $a_i_QuestID = $QUEST_FORMAL_INTRO And $l_i_Match <> 0 Then
		$l_s_State = "ACTIVE (needs Kayao Accept 0x17, LogState=0x" & Hex($l_i_State, 8) & ")"
	EndIf
	If $a_i_QuestID = $QUEST_SECONDARY Then
		If $l_i_Match <> 0 Then
			$l_s_State = "ACTIVE (needs Togo complete, LogState=0x" & Hex($l_i_State, 8) & ")"
		ElseIf Leveler_SecondaryRewardTaken() Then
			$l_s_State = "turned in (secondary " & Leveler_SecondaryProfession() & ")"
		ElseIf Leveler_HasSecondaryProfession() Then
			$l_s_State = "not turned in (secondary " & Leveler_SecondaryProfession() & ", gold " & Leveler_CharacterGold() & ")"
		Else
			$l_s_State = "not in log (secondary still unset)"
		EndIf
	EndIf
	If $a_s_Label = "" Then $a_s_Label = "Quest"
	Out("[QuestLog] " & $a_s_Label & " #" & $a_i_QuestID & " = " & $l_s_State)
	Return $l_i_Match
EndFunc

; Primary quest ID this step must hand in before leaving, or 0.
Func Leveler_StepQuestID($a_i_Step)
	Switch $a_i_Step
		Case $LEVELER_STEP_PARTY
			Return $QUEST_FORMING_A_PARTY
		Case $LEVELER_STEP_SECONDARY
			Return $QUEST_SECONDARY
		Case $LEVELER_STEP_TO_CHO
			Return $QUEST_FORMAL_INTRO
		Case $LEVELER_STEP_ATTR_1
			Return $QUEST_LOST_TREASURE
		Case $LEVELER_STEP_TENGU
			Return $QUEST_WARNING_TENGU
		Case $LEVELER_STEP_THREAT
			Return $QUEST_THREAT_GROWS
		Case $LEVELER_STEP_ROAD
			Return $QUEST_ROAD_LESS
		Case $LEVELER_STEP_CURE
			Return $QUEST_SEARCH_CURE
		Case $LEVELER_STEP_BURDEN
			Return $QUEST_MASTERS_BURDEN
		Case $LEVELER_STEP_EOTN_POOL
			Return $QUEST_AGAINST_DESTROYERS
		Case $LEVELER_STEP_ATTR_2
			Return $QUEST_UNWELCOME
		Case $LEVELER_STEP_KILROY
			Return $QUEST_PUNCH_CLOWN
		Case $LEVELER_STEP_TO_LA
			Return $QUEST_CHAOS_KRYTA
		Case $LEVELER_STEP_TO_KAMADAN
			Return $QUEST_SUNSPEARS_CANTHA
		Case $LEVELER_STEP_UNLOCK_OLIAS
			Return $QUEST_OLIAS
	EndSwitch
	Return 0
EndFunc

; True when HasQuest or the quest-log scan finds this ID.
Func Leveler_HasQuest($a_i_QuestID)
	If $a_i_QuestID = 0 Then Return False
	If Quest_GetQuestInfo($a_i_QuestID, "HasQuest") Then Return True
	Return Leveler_QuestInLog($a_i_QuestID)
EndFunc

; Still in the quest log, including reward-ready. IsCompleted is not a hand-in.
Func Leveler_QuestNeedsHandIn($a_i_QuestID)
	If $a_i_QuestID = 0 Then Return False
	If Leveler_QuestInLog($a_i_QuestID) Then Return True
	If Leveler_QuestReadyForReward($a_i_QuestID) Then Return True
	If Quest_GetQuestInfo($a_i_QuestID, "HasQuest") Then Return True
	Return False
EndFunc

; Alias for Leveler_QuestNeedsHandIn.
Func Leveler_HasIncompleteQuest($a_i_QuestID)
	Return Leveler_QuestNeedsHandIn($a_i_QuestID)
EndFunc

; Reward-ready or Fen already finished: go to Kamadan instead of re-entering Bloodstone Fen.
Func Leveler_OliasReadyToTurnIn()
	If $g_b_OliasFenDone Then Return True
	If Leveler_QuestReadyForReward($QUEST_OLIAS) Then Return True
	If Quest_GetQuestInfo($QUEST_OLIAS, "IsCompleted") Then Return True
	If Leveler_QuestLogCompleted($QUEST_OLIAS) Then Return True
	Return False
EndFunc

#EndRegion Quest State

#Region Resume
; True in an explorable / mission. False in towns and while loading.
Func Leveler_IsOutpost()
	If Map_GetInstanceInfo("IsLoading") Then Return False
	Return Map_GetInstanceInfo("IsOutpost") = True
EndFunc

; After a Start/restart only: quest in the log, not in town, and this map belongs to that step.
Func Leveler_ShouldResumeExplorable($a_i_QuestID = 0, $a_i_Step = -1)
	If Not $g_b_ExplorableResume Then Return False
	If Leveler_IsOutpost() Then Return False
	If Map_GetInstanceInfo("IsLoading") Then Return False
	If Not Map_GetInstanceInfo("IsExplorable") Then Return False
	If $a_i_Step < 0 Then $a_i_Step = $g_i_Step
	If $a_i_Step >= 0 And Not Leveler_StepAllowsMap($a_i_Step, Map_GetMapID()) Then Return False
	If $a_i_QuestID = 0 Then Return Leveler_StepHasActiveQuest($a_i_Step)
	Return Leveler_QuestNeedsHandIn($a_i_QuestID)
EndFunc

; Any quest this step is running. Used to stay in explorables after a disconnect.
Func Leveler_StepHasActiveQuest($a_i_Step)
	Switch $a_i_Step
		Case $LEVELER_STEP_PARTY
			Return Leveler_QuestNeedsHandIn($QUEST_FORMING_A_PARTY)
		Case $LEVELER_STEP_SECONDARY, $LEVELER_STEP_TO_CHO
			Return Leveler_QuestNeedsHandIn($QUEST_SECONDARY) Or Leveler_QuestNeedsHandIn($QUEST_FORMAL_INTRO)
		Case $LEVELER_STEP_ATTR_1
			Return Leveler_QuestNeedsHandIn($QUEST_LOST_TREASURE)
		Case $LEVELER_STEP_TENGU
			Return Leveler_QuestNeedsHandIn($QUEST_WARNING_TENGU)
		Case $LEVELER_STEP_THREAT
			Return Leveler_QuestNeedsHandIn($QUEST_THREAT_GROWS) Or Leveler_QuestNeedsHandIn($QUEST_JOURNEY_MASTER)
		Case $LEVELER_STEP_ROAD
			Return Leveler_QuestNeedsHandIn($QUEST_JOURNEY_MASTER) Or Leveler_QuestNeedsHandIn($QUEST_ROAD_LESS)
		Case $LEVELER_STEP_TO_MARKET, $LEVELER_STEP_BURDEN
			Return Leveler_QuestNeedsHandIn($QUEST_MASTERS_BURDEN)
		Case $LEVELER_STEP_CURE
			Return Leveler_QuestNeedsHandIn($QUEST_SEARCH_CURE)
		Case $LEVELER_STEP_TO_BOREAL
			Return Leveler_QuestNeedsHandIn($QUEST_EARTH_MOVE)
		Case $LEVELER_STEP_TO_EOTN, $LEVELER_STEP_EOTN_POOL
			Return Leveler_QuestNeedsHandIn($QUEST_AGAINST_DESTROYERS)
		Case $LEVELER_STEP_ATTR_2
			Return Leveler_QuestNeedsHandIn($QUEST_UNWELCOME)
		Case $LEVELER_STEP_TO_GUNNAR
			Return Leveler_QuestNeedsHandIn($QUEST_NORNBEAR)
		Case $LEVELER_STEP_KILROY
			Return Leveler_QuestNeedsHandIn($QUEST_PUNCH_CLOWN)
		Case $LEVELER_STEP_TO_LA
			Return Leveler_QuestNeedsHandIn($QUEST_CHAOS_KRYTA)
		Case $LEVELER_STEP_TO_KAMADAN
			Return Leveler_QuestNeedsHandIn($QUEST_SUNSPEARS_CANTHA)
		Case $LEVELER_STEP_UNLOCK_OLIAS
			Return Leveler_QuestNeedsHandIn($QUEST_OLIAS)
	EndSwitch
	Return False
EndFunc

; True when the nearest talk NPC still shows a quest marker.
Func Leveler_NpcHasQuestMarker($a_i_NpcModel)
	Local $l_i_Npc = 0
	If $a_i_NpcModel <> 0 Then $l_i_Npc = Leveler_GetAgentByModel($a_i_NpcModel)
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetNearestNPC(400)
	If $l_i_Npc = 0 Then Return False
	If Not Leveler_IsTalkNpc($l_i_Npc) Then Return False
	Return Agent_GetAgentInfo($l_i_Npc, "HasQuest")
EndFunc

; After talking and sending complete: no reward dialog means the quest is already handed in.
Func Leveler_FinishIfCompleteUnavailable($a_i_QuestID, $a_i_NpcModel = 0)
	If $a_i_QuestID = $QUEST_SECONDARY Then Return Leveler_SecondaryRewardTaken()
	If $a_i_QuestID = $QUEST_FORMAL_INTRO Then Return Leveler_FormalIntroductionTurnedIn()
	If Leveler_QuestReadyForReward($a_i_QuestID) Then Return False
	If Leveler_QuestNeedsHandIn($a_i_QuestID) And Leveler_NpcHasQuestMarker($a_i_NpcModel) Then Return False
	Leveler_MarkQuestDone($a_i_QuestID, True)
	Out("[Quest] #" & $a_i_QuestID & " complete dialog is not available. Treating as already handed in.")
	Return True
EndFunc

#EndRegion Resume
