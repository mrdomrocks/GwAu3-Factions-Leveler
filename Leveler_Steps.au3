#include-once

; Step dispatcher and per-step runners, grouped by campaign.

#Region Dispatcher
; Run one step: wait for the map, travel to its outpost, dispatch, then advance on success.
Func Leveler_ExecuteStep($a_i_Step)
	If $g_b_LevelerPaused Then Return False
	If Not Leveler_WaitUntilMapReady() Then Return False
	Local $l_i_Map = Map_GetMapID()
	If Leveler_HasIncompleteQuest($QUEST_AGAINST_DESTROYERS) And Not Leveler_HomHeroesTalked() And ($l_i_Map = $MAP_EOTN Or $l_i_Map = $MAP_HOM) And $a_i_Step <> $LEVELER_STEP_EOTN_POOL Then
		Out("[Step] Against the Destroyers is in the log. Not traveling for '" & $g_as_StepNames[$a_i_Step] & "'. Switching to Hall of Monuments.")
		$g_i_Step = $LEVELER_STEP_EOTN_POOL
		Leveler_UpdateStepCombo()
		$a_i_Step = $LEVELER_STEP_EOTN_POOL
	EndIf
	If $a_i_Step < $LEVELER_STEP_CURE And ($g_b_CureStepLocked Or Leveler_Quest336Seen()) And Not Leveler_CureStepComplete() Then
		Out("[Step] The Search For A Cure is still open. Not going back to '" & $g_as_StepNames[$a_i_Step] & "'.")
		$g_b_CureStepLocked = True
		$g_ab_StepDone[$LEVELER_STEP_CURE] = False
		$g_i_Step = $LEVELER_STEP_CURE
		Leveler_UpdateStepCombo()
		$a_i_Step = $LEVELER_STEP_CURE
	EndIf
	If Not Leveler_MaybeClaimInfiniteKits() Then Return False
	Leveler_MaybeSellWhiteDrops()
	If Not Leveler_EnsureStepOutpost($a_i_Step) Then Return False
	If Leveler_IsWiped() Then
		Out("[Step] Wipe detected before '" & $g_as_StepNames[$a_i_Step] & "'. Recovering.")
		Leveler_RecoverWipe()
		Return False
	EndIf

	Local $l_b_Ok = False
	Switch $a_i_Step
		Case $LEVELER_STEP_OVERLOOK
			$l_b_Ok = Leveler_Step_ExitOverlook()
		Case $LEVELER_STEP_PARTY
			$l_b_Ok = Leveler_Step_FormingAParty()
		Case $LEVELER_STEP_SECONDARY
			$l_b_Ok = Leveler_Step_UnlockSecondary()
		Case $LEVELER_STEP_XUNLAI
			$l_b_Ok = Leveler_Step_UnlockXunlai()
		Case $LEVELER_STEP_WEAPON
			$l_b_Ok = Leveler_Step_CraftWeapon()
		Case $LEVELER_STEP_ARMOR
			$l_b_Ok = Leveler_Step_CraftMonasteryArmor()
		Case $LEVELER_STEP_DESTROY
			$l_b_Ok = Leveler_Step_DestroyStarter()
		Case $LEVELER_STEP_BAGS
			$l_b_Ok = Leveler_Step_ExtendInventory()
		Case $LEVELER_STEP_SKILLS
			$l_b_Ok = Leveler_Step_UnlockSkills()
		Case $LEVELER_STEP_TO_CHO
			$l_b_Ok = Leveler_Step_ToChosEstate()
		Case $LEVELER_STEP_CHO_MISSION
			$l_b_Ok = Leveler_Step_ChosMission()
		Case $LEVELER_STEP_ATTR_1
			$l_b_Ok = Leveler_Step_LostTreasure()
		Case $LEVELER_STEP_TENGU
			$l_b_Ok = Leveler_Step_WarningTheTengu()
		Case $LEVELER_STEP_THREAT
			$l_b_Ok = Leveler_Step_TheThreatGrows()
		Case $LEVELER_STEP_ROAD
			$l_b_Ok = Leveler_Step_TheRoadLessTraveled()
		Case $LEVELER_STEP_SEITUNG
			$l_b_Ok = Leveler_Step_CraftSeitungArmor()
		Case $LEVELER_STEP_DESTROY_MON
			$l_b_Ok = Leveler_Step_DestroyMonastery()
		Case $LEVELER_STEP_TO_ZEN
			$l_b_Ok = Leveler_Step_ToZenDaijun()
		Case $LEVELER_STEP_ZEN_MISSION
			$l_b_Ok = Leveler_Step_ZenDaijunMission()
		Case $LEVELER_STEP_TO_MARKET
			$l_b_Ok = Leveler_Step_ToMarketplace()
		Case $LEVELER_STEP_BURDEN
			$l_b_Ok = Leveler_Step_AMastersBurden()
		Case $LEVELER_STEP_TO_KC
			$l_b_Ok = Leveler_Step_ToKainengCenter()
		Case $LEVELER_STEP_SKILLS2
			$l_b_Ok = Leveler_Step_CompleteSkillsTraining()
		Case $LEVELER_STEP_MAX_ARMOR
			$l_b_Ok = Leveler_Step_CraftMaxArmor()
		Case $LEVELER_STEP_DESTROY_SEITUNG
			$l_b_Ok = Leveler_Step_DestroySeitung()
		Case $LEVELER_STEP_CURE
			$l_b_Ok = Leveler_Step_SearchForACure()
		Case $LEVELER_STEP_UNLOCK_MOX
			$l_b_Ok = Leveler_Step_UnlockMox()
		Case $LEVELER_STEP_TO_BOREAL
			$l_b_Ok = Leveler_Step_ToBorealStation()
		Case $LEVELER_STEP_TO_EOTN
			$l_b_Ok = Leveler_Step_ToEyeOfTheNorth()
		Case $LEVELER_STEP_EOTN_POOL
			$l_b_Ok = Leveler_Step_UnlockEotnPool()
		Case $LEVELER_STEP_ATTR_2
			$l_b_Ok = Leveler_Step_AnUnwelcomeGuest()
		Case $LEVELER_STEP_TO_GUNNAR
			$l_b_Ok = Leveler_Step_ToGunnarsHold()
		Case $LEVELER_STEP_KILROY
			$l_b_Ok = Leveler_Step_UnlockKilroy()
		Case $LEVELER_STEP_FARM_20
			$l_b_Ok = Leveler_Step_FarmUntil20()
		Case $LEVELER_STEP_TO_LA
			$l_b_Ok = Leveler_Step_ToLionsArch()
		Case $LEVELER_STEP_TO_KAMADAN
			$l_b_Ok = Leveler_Step_ToKamadan()
		Case $LEVELER_STEP_TO_DOCKS
			$l_b_Ok = Leveler_Step_ToConsulateDocks()
		Case $LEVELER_STEP_UNLOCK_OLIAS
			$l_b_Ok = Leveler_Step_UnlockOlias()
		Case $LEVELER_STEP_UNLOCK_PROFS
			$l_b_Ok = Leveler_Step_UnlockSecondaryProfs()
		Case Else
			Return True
	EndSwitch

	If Leveler_IsWiped() Then
		Leveler_RecoverWipe()
		Return False
	EndIf

	If $l_b_Ok Then
		If $a_i_Step = $LEVELER_STEP_SECONDARY And Not Leveler_SecondaryStepReadyToLeave() Then
			Leveler_LogQuestState($QUEST_SECONDARY, "Choose Secondary")
			Out("[Step] #317 reward or Formal Introduction still missing. Staying on '" & $g_as_StepNames[$a_i_Step] & "'.")
			Return False
		EndIf
		If $a_i_Step = $LEVELER_STEP_SKILLS2 And Not Leveler_Skills2Unlocked() Then
			Out("[Step] Cry of Frustration or Power Drain still missing. Staying on Michiko.")
			Return False
		EndIf
		If $a_i_Step = $LEVELER_STEP_BURDEN And Not Leveler_MastersBurdenDone() Then
			Out("[Step] A Master's Burden is not finished. Staying on this step.")
			Return False
		EndIf
		If $a_i_Step = $LEVELER_STEP_CURE And Not Leveler_CureStepComplete() Then
			Out("[Step] Search for a Cure or Seek out Brother Tosai still open. Staying on this step.")
			Return False
		EndIf
		If $a_i_Step = $LEVELER_STEP_MAX_ARMOR And Not Leveler_ArmorSetEquipped(Leveler_GetMaxArmorPieces()) Then
			Out("[Step] Max armor is not equipped. Staying on the crafter.")
			Return False
		EndIf
		If $a_i_Step = $LEVELER_STEP_DESTROY_SEITUNG And Not Leveler_ArmorSetEquipped(Leveler_GetMaxArmorPieces()) Then
			Out("[Step] Max armor is not equipped after destroying Seitung. Staying on this step.")
			Return False
		EndIf
		If $a_i_Step = $LEVELER_STEP_UNLOCK_MOX And Not Leveler_HasMoxUnlocked() Then
			Out("[Step] Mox is not on the hero list. Staying on Unlock Mox.")
			Return False
		EndIf
		If $a_i_Step = $LEVELER_STEP_UNLOCK_OLIAS And Not Leveler_HasOliasUnlocked() Then
			Out("[Step] Olias is not on the hero list. Staying on Unlock Olias.")
			Return False
		EndIf
		If $a_i_Step = $LEVELER_STEP_UNLOCK_PROFS And Leveler_WantsAllSecondaries() And Not Leveler_RemainingSecondariesUnlocked() Then
			Out("[Step] Not every profession (including Paragon and Dervish) is selectable yet. Staying on this step.")
			Return False
		EndIf
		If $a_i_Step = $LEVELER_STEP_TO_BOREAL And Not Leveler_HasMoxUnlocked() Then
			Out("[Step] Mox is not unlocked. Not leaving Kaineng for Boreal.")
			Return False
		EndIf
		If $a_i_Step = $LEVELER_STEP_EOTN_POOL And Not Leveler_HomHeroesTalked() And Not Leveler_EotnPoolReady() Then
			Out("[Step] Hall of Monuments hero dialogs are not finished. Staying on this step.")
			Return False
		EndIf
		If $a_i_Step = $LEVELER_STEP_ATTR_2 And Not Leveler_UnwelcomeGuestDone() Then
			Out("[Step] An Unwelcome Guest is not finished. Staying on this step.")
			Return False
		EndIf
		If $a_i_Step = $LEVELER_STEP_TO_GUNNAR Then
			If Not Leveler_ReachedGunnarsHold() Then
				Out("[Step] Need Gunnar's Hold. Staying on this step.")
				Return False
			EndIf
		EndIf
		Local $l_i_QuestID = Leveler_StepQuestID($a_i_Step)
		If $l_i_QuestID <> 0 And Leveler_QuestNeedsHandIn($l_i_QuestID) Then
			If Leveler_IsQuestDone($l_i_QuestID) Then
				Out("[Step] Quest #" & $l_i_QuestID & " complete dialog was not available. Moving on.")
			ElseIf $a_i_Step = $LEVELER_STEP_UNLOCK_OLIAS And Leveler_HasOliasUnlocked() Then
				; Hero unlock is enough even if the quest is still in the log.
			ElseIf $a_i_Step = $LEVELER_STEP_EOTN_POOL And (Leveler_HomHeroesTalked() Or Leveler_HasNornbearTracking()) Then
				; Hall dialogs, or Tracking the Nornbear in the log, finish Unlock Eye of the North.
			ElseIf Not (Leveler_ReachedGunnarsHold() And ($a_i_Step = $LEVELER_STEP_EOTN_POOL Or $a_i_Step = $LEVELER_STEP_ATTR_2 Or $a_i_Step = $LEVELER_STEP_TO_GUNNAR)) Then
				Leveler_LogQuestState($l_i_QuestID, $g_as_StepNames[$a_i_Step])
				Out("[Step] Quest #" & $l_i_QuestID & " still needs its complete dialog. Staying on '" & $g_as_StepNames[$a_i_Step] & "'.")
				Return False
			EndIf
		EndIf
		If $a_i_Step = $LEVELER_STEP_ATTR_1 And Leveler_WarningTheTenguDone() Then
			Out("[Step] Warning the Tengu already completed. Moving to The Threat Grows.")
			$g_i_Step = $LEVELER_STEP_TENGU + 1
		Else
			$g_i_Step = $a_i_Step + 1
		EndIf
		If $g_i_Step >= $LEVELER_STEP_DONE Then $g_ab_StepDone[$LEVELER_STEP_DONE] = True
		$g_b_ExplorableResume = False
		Leveler_UpdateStepCombo()
		Return True
	EndIf
	Return False
EndFunc

; Empty backpack, belt pouch, and bag slots.
Func Leveler_EmptyBagSlots()
	Local $l_ai_Bags[4] = [$GC_I_INVENTORY_BACKPACK, $GC_I_INVENTORY_BELT_POUCH, $GC_I_INVENTORY_BAG1, $GC_I_INVENTORY_BAG2]
	Local $l_i_Empty = 0
	Local $b, $s
	For $b = 0 To 3
		If Item_GetBagPtr($l_ai_Bags[$b]) = 0 Then ContinueLoop
		For $s = 1 To Item_GetBagInfo($l_ai_Bags[$b], "Slots")
			If Item_GetItemBySlot($l_ai_Bags[$b], $s) = 0 Then $l_i_Empty += 1
		Next
	Next
	Return $l_i_Empty
EndFunc

; True when both infinite salvage and identification kits are in the bags.
Func Leveler_HasInfiniteKits()
	Return Leveler_CountModel($GC_I_MODELID_INFINITE_SALVAGE_KIT, False) > 0 And Leveler_CountModel($GC_I_MODELID_INFINITE_IDENTIFICATION_KIT, False) > 0
EndFunc

; One Purveyor trip after the Great Temple of Balthazar can be traveled to.
Func Leveler_MaybeClaimInfiniteKits()
	If $g_b_InfKitsClaimed Then Return True
	If $g_h_InfKitCheckbox = 0 Or Not GetChecked($g_h_InfKitCheckbox) Then Return True
	If Leveler_HasInfiniteKits() Then
		$g_b_InfKitsClaimed = True
		Out("[Kits] Infinite identification and salvage kits are already in the bags.")
		Return True
	EndIf
	If Not Map_IsMapUnlocked($MAP_GTOB) Then Return True
	If Map_GetInstanceInfo("IsLoading") Then Return True
	If Not Map_GetInstanceInfo("IsOutpost") Then Return True
	If Leveler_IsPunchoutMap() Then Return True
	If Leveler_EmptyBagSlots() < 2 Then
		If Not $g_b_InfKitsNoSpace Then
			Out("[Kits] Need two empty bag slots before picking up the infinite kits.")
			$g_b_InfKitsNoSpace = True
		EndIf
		Return True
	EndIf
	$g_b_InfKitsNoSpace = False

	Out("[Kits] Great Temple of Balthazar is unlocked. Picking up infinite kits from The Purveyor.")
	If Map_GetMapID() <> $MAP_GTOB Then
		If Not Leveler_Travel($MAP_GTOB) Then
			$g_i_InfKitTravelFails += 1
			Out("[Kits] Could not travel to the Great Temple of Balthazar.")
			If $g_i_InfKitTravelFails >= 3 Then
				$g_b_InfKitsClaimed = True
				Out("[Kits] Stopping infinite-kit pickup after repeated travel failures.")
			EndIf
			Return True
		EndIf
	EndIf

	If Not Leveler_MoveTo($PURVEYOR_X, $PURVEYOR_Y, False) Then Return False
	Local $l_i_Npc = Leveler_GetAgentByName("Purveyor")
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetNearestNPCAt($PURVEYOR_X, $PURVEYOR_Y, 600)
	If $l_i_Npc = 0 Then
		Out("[Kits] The Purveyor was not found.")
		Return False
	EndIf
	Agent_ChangeTarget($l_i_Npc)
	Sleep(150)
	Agent_GoNPC($l_i_Npc)
	Sleep(800)
	Out("[Kits] Sending dialog 0x8D to The Purveyor.")
	Game_Dialog($DIALOG_PURVEYOR_KITS)
	Sleep(800)

	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < 4000
		If Leveler_HasInfiniteKits() Then ExitLoop
		Sleep(250)
	WEnd
	$g_b_InfKitsClaimed = True
	If Leveler_HasInfiniteKits() Then
		Out("[Kits] Infinite Superior Salvage Kit (38621) and Infinite Identification Kit (38620) are in the bags.")
	Else
		Out("[Kits] Dialog 0x8D was sent. The infinite kits did not both appear. Not repeating the pickup.")
	EndIf
	Return True
EndFunc

#EndRegion Dispatcher

#Region Shing Jea Monastery
; Overlook through Zhao Di skills.

; Leave Monastery Overlook into Shing Jea Monastery.
Func Leveler_Step_ExitOverlook()
	$g_s_CurrentHeader = "Exit Monastery Overlook"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Map_GetMapID() = $MAP_SHING_JEA Then
		Out("[Step] Already in Shing Jea Monastery")
		Return True
	EndIf
	Leveler_SetPacifist()
	If Not Leveler_MoveAndDialog(-7048, 5817, $DIALOG_EXIT_OVERLOOK, False) Then
		If Map_GetMapID() <> $MAP_SHING_JEA Then Map_Move(-7048, 5817, 10)
	EndIf
	Return Map_WaitMapLoading($MAP_SHING_JEA)
EndFunc

; Forming A Party: Travel Shing Jea → PrepareForBattle (leave + hench 2/5/1)
; → accept #440 at Instructor Ng coords → exit Sunqua Vale → complete #440.
; Do not pass TogoModel; the accept NPC is not Master Togo.
; Accept and complete Forming A Party (#440).
Func Leveler_Step_FormingAParty()
	$g_s_CurrentHeader = "Quest: Forming A Party"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_SkipIfQuestDone($QUEST_FORMING_A_PARTY, "Forming A Party") Then Return True
	If Leveler_ShouldResumeExplorable($QUEST_FORMING_A_PARTY) Then
		Out("[Step] Forming A Party is in the log and map " & Map_GetMapID() & " is not an outpost. Resuming from here.")
		If Map_GetMapID() = $MAP_SUNQUA_VALE Then
			; Henchmen can only be invited in outposts. If the party is already full, hand in;
			; otherwise return to Shing Jea, form the party, and re-enter Sunqua.
			If Leveler_HasFormingPartyHenchmen() Then
				If Not Leveler_QuestLoop($QUEST_FORMING_A_PARTY, 19673.00, -6982.00, $DIALOG_FORMING_COMPLETE, "complete") Then Return False
				Return True
			EndIf
			Out("[Step] Party is incomplete in Sunqua. Returning to Shing Jea to invite henchmen 2, 5, 1.")
			If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
		Else
			; Wrong explorable with #440 in the log: get back to Shing Jea and run the full path.
			If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
		EndIf
	Else
		If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
	EndIf
	; Party_LeaveGroup + Leveler_AddHenchmanList before accept. Forming A Party requires a full party of 4.
	Leveler_PrepareForBattle()
	If Not Leveler_EnsureFormingPartyHenchmen() Then Return False
	If Not Leveler_HasQuest($QUEST_FORMING_A_PARTY) Then
		If Not Leveler_QuestLoop($QUEST_FORMING_A_PARTY, -14063.00, 10044.00, $DIALOG_FORMING_ACCEPT, "accept") Then Return False
	Else
		Out("[Step] Forming A Party already in the log")
	EndIf
	If Leveler_SkipIfQuestDone($QUEST_FORMING_A_PARTY, "Forming A Party") Then Return True
	If Not Leveler_MoveAndExit(-14961, 11453, $MAP_SUNQUA_VALE, True) Then Return False
	If Not Leveler_QuestLoop($QUEST_FORMING_A_PARTY, 19673.00, -6982.00, $DIALOG_FORMING_COMPLETE, "complete") Then Return False
	Return True
EndFunc

; Choose the secondary at Togo, take the #317 gold, and accept Formal Introduction.
Func Leveler_Step_UnlockSecondary()
	$g_s_CurrentHeader = "Unlock Secondary Profession"
	Out("=== " & $g_s_CurrentHeader & " ===")
	Out("[Step] Profession " & Leveler_PrimaryProfession() & "/" & Leveler_SecondaryProfession() & "  Gold " & Leveler_CharacterGold())
	Leveler_LogQuestState($QUEST_SECONDARY, "Choose Secondary")
	Leveler_LogQuestState($QUEST_FORMAL_INTRO, "Formal Introduction")
	If Leveler_SecondaryStepReadyToLeave() Then
		Out("[Step] #317 turned in and Formal Introduction is ready")
		Return True
	EndIf
	Out("[Step] Talking to Togo in Linnok for #317 complete and #318 accept.")
	If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
	Leveler_SetPacifist()
	If Map_GetMapID() <> $MAP_LINNOK Then
		If Not Leveler_MoveAndExit(-3480, 9460, $MAP_LINNOK, False) Then Return False
	EndIf
	Leveler_MoveTo(-159, 9174, False)

	Local $l_i_AcceptDialog = $DIALOG_SECONDARY_OTHER
	If Leveler_IsMesmer() Then $l_i_AcceptDialog = $DIALOG_SECONDARY_MESMER
	Local $l_i_Togo = Leveler_TogoModel()
	If Not Leveler_HasQuest($QUEST_SECONDARY) And Not Leveler_SecondaryRewardTaken() Then
		If Not Leveler_QuestLoop($QUEST_SECONDARY, -92, 9217, $l_i_AcceptDialog, "accept", $l_i_Togo) Then Return False
	EndIf
	If Leveler_QuestInLog($QUEST_SECONDARY) Or Not Leveler_SecondaryRewardTaken() Then
		Out("[Step] Sending Togo complete dialog 0x813D07 for the #317 gold reward.")
		If Not Leveler_QuestLoop($QUEST_SECONDARY, -92, 9217, $DIALOG_SECONDARY_COMPLETE, "complete", $l_i_Togo) Then Return False
	EndIf
	Sleep(1500)
	Leveler_LogQuestState($QUEST_SECONDARY, "Choose Secondary")
	If Leveler_QuestInLog($QUEST_SECONDARY) Then
		Out("[Step] Quest #317 is still in the log after Togo. Staying on this step.")
		Return False
	EndIf
	If Not Leveler_HasSecondaryProfession() Then
		Out("[Step] Togo dialog sent but secondary is still unset. Retrying.")
		Return False
	EndIf
	If Not Leveler_SecondaryRewardTaken() Then
		Out("[Step] #317 reward not taken yet (gold " & Leveler_CharacterGold() & "). Retrying Togo complete.")
		Return False
	EndIf
	Leveler_MarkQuestDone($QUEST_SECONDARY)
	Sleep(1500)
	If Not Leveler_HasQuest($QUEST_FORMAL_INTRO) And Not Leveler_QuestFinished($QUEST_FORMAL_INTRO) Then
		If Not Leveler_QuestLoop($QUEST_FORMAL_INTRO, -92, 9217, $DIALOG_FORMAL_ACCEPT, "accept", $l_i_Togo) Then Return False
	EndIf
	If Not Leveler_HasFormalOrLater() Then
		Out("[Step] Formal Introduction #318 is not in the log. Staying on this step.")
		Return False
	EndIf
	If Not Leveler_MoveAndExit(-3762, 9471, $MAP_SHING_JEA, False) Then Return False
	Return True
EndFunc

; Open the Xunlai chest so storage is available.
Func Leveler_Step_UnlockXunlai()
	$g_s_CurrentHeader = "Unlock Xunlai Storage"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_XunlaiUnlocked() Then
		Out("[Step] Xunlai storage already unlocked on this character")
		Return True
	EndIf
	; Account storage pointers stay populated from other characters. Log them; do not skip.
	If Leveler_HasStorageAccess() Then
		Out("[Step] Account storage bags are present (Storage1Ptr set). Still need this character's 50g unlock.")
	EndIf
	Local $l_i_Gold = Leveler_CharacterGold()
	If Not Leveler_SecondaryStepReadyToLeave() Then
		Leveler_LogQuestState($QUEST_SECONDARY, "Choose Secondary")
		Out("[Step] Need Togo's #317 reward before Xunlai (gold " & $l_i_Gold & "). Returning to Unlock Secondary.")
		$g_i_Step = $LEVELER_STEP_SECONDARY
		Return False
	EndIf
	If $l_i_Gold < $XUNLAI_GOLD_COST Then
		Out("[Step] Xunlai needs " & $XUNLAI_GOLD_COST & " gold. Not advancing.")
		Return False
	EndIf
	If Map_GetMapID() <> $MAP_SHING_JEA Then
		If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
	EndIf
	Leveler_SetPacifist()
	Out("[Step] Character gold: " & $l_i_Gold)
	If Not Leveler_MoveTo(-4958, 9472, False) Then Return False
	If Not Leveler_MoveTo(-5465, 9727, False) Then Return False
	If Not Leveler_MoveTo(-4791, 10140, False) Then Return False
	If Not Leveler_MoveTo(-3945, 10328, False) Then Return False
	If Not Leveler_MoveAndDialog($XUNLAI_X, $XUNLAI_Y, $DIALOG_GENERIC_TALK, False, $MODEL_XUNLAI) Then Return False
	Local $l_i_Xunlai = Leveler_GetAgentByModel($MODEL_XUNLAI)
	If $l_i_Xunlai <> 0 Then Agent_GoNPC($l_i_Xunlai)
	Sleep(600)
	Ui_Dialog($DIALOG_XUNLAI_1)
	Sleep(800)
	Ui_Dialog($DIALOG_XUNLAI_2)
	Sleep(800)
	; Proof this character paid: gold must drop by ~50. Do not trust Storage1Ptr.
	Local $l_i_GoldAfter = Item_GetInventoryInfo("GoldCharacter")
	If $l_i_GoldAfter > $l_i_Gold - $XUNLAI_GOLD_COST + 5 Then
		Out("[Step] Xunlai unlock did not take " & $XUNLAI_GOLD_COST & " gold (now " & $l_i_GoldAfter & "). Not advancing.")
		Return False
	EndIf
	Leveler_MarkXunlaiUnlocked()
	Out("[Step] Xunlai storage unlocked (gold " & $l_i_Gold & " -> " & $l_i_GoldAfter & ")")
	Return True
EndFunc

; Buy mats and craft the Clairvoyant Staff.
Func Leveler_Step_CraftWeapon()
	$g_s_CurrentHeader = "Craft Weapon"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_HasCraftedWeapon() Then
		Out("[Step] Staff already crafted. Equipping it.")
		Return Leveler_EquipModel($MODEL_CLAIRVOYANT_STAFF)
	EndIf
	If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
	Leveler_SetPacifist()
	If Not Leveler_PrepareCraftWeaponFunds() Then Return False
	If Not Leveler_MoveTo(-10896.94, 10807.54, False) Then Return False
	If Not Leveler_MoveTo(-10942.73, 10783.19, False) Then Return False
	If Not Leveler_InteractNpcAt(-10614.00, 10996.00, False) Then Return False
	If Not Leveler_BuyWeaponMaterials() Then Return False
	If Not Leveler_BuyEarlyArmorMaterials() Then Return False
	If Not Leveler_MoveTo(-10896.94, 10807.54, False) Then Return False
	If Not Leveler_InteractNpcAt(-6519.00, 12335.00, False) Then Return False
	Sleep(1000)
	If Not Leveler_CraftWeapon() Then Return False
	Return True
EndFunc

; Buy mats and craft the monastery armor set.
Func Leveler_Step_CraftMonasteryArmor()
	$g_s_CurrentHeader = "Craft Monastery Armor"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_HasMonasteryArmor() Then
		Out("[Step] Monastery armor already crafted. Equipping it.")
		Return Leveler_EquipArmorPieces(Leveler_GetMonasteryPieces())
	EndIf
	If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
	Leveler_SetPacifist()
	If Not Leveler_InteractNpcAt(-7115.00, 12636.00, False) Then Return False
	If Not Leveler_CraftMonasteryArmor() Then Return False
	Return True
EndFunc

; Destroy leftover starter armor.
Func Leveler_Step_DestroyStarter()
	$g_s_CurrentHeader = "Destroy Starter Armor"
	Out("=== " & $g_s_CurrentHeader & " ===")
	Return Leveler_DestroyStarterArmorAndJunk()
EndFunc

; Buy a bag and belt pouch.
Func Leveler_Step_ExtendInventory()
	$g_s_CurrentHeader = "Extend Inventory"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_HasExtendedBags() Then
		Out("[Step] Belt Pouch is equipped; inventory already extended")
		Return True
	EndIf
	If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
	Leveler_SetPacifist()
	Return Leveler_ExtendInventory()
EndFunc

; Buy Zhao Di skills in Shing Jea and put them on the bar.
Func Leveler_Step_UnlockSkills()
	$g_s_CurrentHeader = "Unlock Skills Trainer"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_ZhaoDiSkillsUnlocked() Then
		Out("[Step] Signet of Disruption and Leech Signet already acquired; skipping trainer")
		Leveler_EquipTrainerSkills()
		Return True
	EndIf
	; Rezone so we do not path from the bag merchant around courtyard objects.
	If Not Leveler_Travel($MAP_SHING_JEA, True) Then Return False
	Leveler_SetPacifist()
	If Agent_GetDistanceToXY(-11866, 11444) < 1200 Then
		Out("[Step] Still near the bag merchant; taking the courtyard around the obstacle")
		If Not Leveler_MoveTo(-10896.94, 10807.54, False) Then Return False
	EndIf
	If Not Leveler_MoveAndDialog(-8790.00, 10366.00, $DIALOG_GENERIC_TALK, False) Then Return False
	Sleep(3000)
	Leveler_BuySkillIfNeeded($SKILL_SIGNET_OF_DISRUPTION)
	Sleep(400)
	Leveler_BuySkillIfNeeded($SKILL_LEECH_SIGNET)
	Sleep(400)
	Leveler_BuySkillIfNeeded($SKILL_ENERGY_BURN)
	Sleep(400)
	Leveler_CloseTrainerWindow()
	Out("[Step] Zhao Di buy done. Learnt 860=" & World_IsSkillLearnt($SKILL_SIGNET_OF_DISRUPTION) & " 61=" & World_IsSkillLearnt($SKILL_LEECH_SIGNET) & " 42=" & World_IsSkillLearnt($SKILL_ENERGY_BURN))
	If Not World_IsSkillLearnt($SKILL_SIGNET_OF_DISRUPTION) Then
		Out("[Step] Signet of Disruption was not learnt. Staying on the trainer.")
		Return False
	EndIf
	If Not World_IsSkillLearnt($SKILL_LEECH_SIGNET) Then
		Out("[Step] Leech Signet was not learnt. Staying on the trainer.")
		Return False
	EndIf
	If Not Leveler_EquipTrainerSkills() Then Return False
	Return True
EndFunc

; Michiko's agent id, matched by model then by name.
Func Leveler_GetMichiko()
	Local $l_i_Npc = Leveler_GetAgentByModel($MODEL_MICHIKO)
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetAgentByName("Michiko")
	Return $l_i_Npc
EndFunc

; Walk Kaineng Center to Michiko via the open streets.
Func Leveler_PathToMichiko()
	Local $l_i_Npc = Leveler_GetMichiko()
	If $l_i_Npc <> 0 And Agent_GetDistance($l_i_Npc) < 600 Then
		Out("[Step] Already near Michiko")
		Return True
	EndIf

	Out("[Step] Pathing to Michiko (model " & $MODEL_MICHIKO & ")")
	Local $l_af_Path[7][2] = [ _
			[2492.00, -3991.00], _
			[2941.00, -2362.00], _
			[2959.00, -734.00], _
			[2375.00, 597.00], _
			[1169.00, 611.00], _
			[374.00, 926.00], _
			[413.00, 1312.00] _
			]
	If Not Leveler_FollowCoords($l_af_Path, False) Then Return False
	Return True
EndFunc

; Michiko in Kaineng sells Cry of Frustration and Power Drain.
Func Leveler_BuyKainengInterrupts()
	If Leveler_Skills2Unlocked() Then
		Return Leveler_EquipTrainerSkills()
	EndIf
	If Map_GetMapID() <> $MAP_KAINENG Then Return False
	If Not Leveler_PathToMichiko() Then Return False

	Local $l_i_Npc = Leveler_GetMichiko()
	If $l_i_Npc = 0 Then
		Out("[Step] Michiko (model " & $MODEL_MICHIKO & ") not found in Kaineng")
		Return False
	EndIf
	Local $l_f_X = Agent_GetAgentInfo($l_i_Npc, "X")
	Local $l_f_Y = Agent_GetAgentInfo($l_i_Npc, "Y")
	Out("[Step] Talking to Michiko at " & Round($l_f_X) & ", " & Round($l_f_Y))
	If Not Leveler_MoveAndDialog($l_f_X, $l_f_Y, $DIALOG_GENERIC_TALK, False, $MODEL_MICHIKO) Then Return False
	Sleep(3000)
	If Not Leveler_BuySkillIfNeeded($SKILL_CRY_OF_FRUSTRATION) Then Return False
	Sleep(400)
	If Not Leveler_BuySkillIfNeeded($SKILL_POWER_DRAIN) Then Return False
	Sleep(400)
	Leveler_CloseTrainerWindow()
	Out("[Step] Bought Cry of Frustration and Power Drain from Michiko")
	Return Leveler_EquipTrainerSkills()
EndFunc

; True when standing at Togo's Sunqua Vale start point.
Func Leveler_NearSunquaTogoStart()
	If Map_GetMapID() <> $MAP_SUNQUA_VALE Then Return False
	Return Agent_GetDistanceToXY($TOGO_SUNQUA_X, $TOGO_SUNQUA_Y) < 800
EndFunc

; Talk to Zui in Sunqua Vale for Formal Introduction.
Func Leveler_TalkToGuardsmanZui()
	If Not Leveler_MoveTo($ZUI_SUNQUA_X, $ZUI_SUNQUA_Y, False) Then Return False
	Local $l_i_Zui = Leveler_GetAgentByName("Zui")
	If $l_i_Zui = 0 Then $l_i_Zui = Leveler_GetNearestNPCAt($ZUI_SUNQUA_X, $ZUI_SUNQUA_Y, 400)
	If $l_i_Zui = 0 Then
		Out("[Step] Guardsman Zui not found")
		Return False
	EndIf
	Out("[Step] Guardsman Zui: 0x15+0x813E04, 0x18+0x800008, 0x800009+0x19, 0x80000B+0x19")
	If Not Leveler_TalkAndDialog($l_i_Zui, $DIALOG_FORMAL_TOGO_TALK) Then Return False
	If Map_GetMapID() <> $MAP_SUNQUA_VALE Then Return Leveler_HandInFormalAtKayao()
	Sleep(500)
	Ui_Dialog($DIALOG_FORMAL_STEP)
	Sleep(800)
	If Map_GetMapID() <> $MAP_SUNQUA_VALE Then Return Leveler_HandInFormalAtKayao()
	Ui_Dialog($DIALOG_FORMAL_TOGO_DONE)
	Sleep(500)
	Ui_Dialog($DIALOG_FORMAL_ZUI)
	Sleep(800)
	If Map_GetMapID() <> $MAP_SUNQUA_VALE Then Return Leveler_HandInFormalAtKayao()
	Ui_Dialog($DIALOG_FORMAL_ZUI_2)
	Sleep(500)
	Ui_Dialog($DIALOG_FORMAL_ZUI_2_TALK)
	Sleep(800)
	If Map_GetMapID() <> $MAP_SUNQUA_VALE Then Return Leveler_HandInFormalAtKayao()
	Ui_Dialog($DIALOG_FORMAL_SKIP)
	Sleep(500)
	Ui_Dialog($DIALOG_FORMAL_ZUI_2_TALK)
	Sleep(1500)
	If Map_GetMapID() <> $MAP_CHO_OUTPOST Then
		If Not Map_WaitMapLoading($MAP_CHO_OUTPOST) Then Return False
	EndIf
	Return Leveler_HandInFormalAtKayao()
EndFunc

; Talk to Togo in Sunqua Vale for Formal Introduction.
Func Leveler_TalkToSunquaTogo()
	If Not Leveler_NearSunquaTogoStart() Then
		Out("[Step] Togo start talk already done; going to Guardsman Zui")
		Return Leveler_TalkToGuardsmanZui()
	EndIf
	Out("[Step] Talking to Master Togo in Sunqua Vale at " & Round($TOGO_SUNQUA_X) & ", " & Round($TOGO_SUNQUA_Y))
	If Not Leveler_MoveTo($TOGO_SUNQUA_X, $TOGO_SUNQUA_Y, False) Then Return False
	Local $l_i_Togo = Leveler_GetTogo($TOGO_SUNQUA_X, $TOGO_SUNQUA_Y)
	If $l_i_Togo = 0 Then
		Out("[Step] Master Togo not found in Sunqua Vale")
		Return False
	EndIf
	Out("[Step] Sending Togo dialogs 0x15 and 0x813E04")
	If Not Leveler_TalkAndDialog($l_i_Togo, $DIALOG_FORMAL_TOGO_TALK) Then Return False
	Sleep(400)
	Ui_Dialog($DIALOG_FORMAL_STEP)
	Sleep(1500)
	If Map_GetMapID() = $MAP_SUNQUA_VALE Then
		If Not Leveler_FollowTogo() Then Return False
	EndIf
	If Map_GetMapID() = $MAP_SUNQUA_VALE Then Return Leveler_TalkToGuardsmanZui()
	If Map_GetMapID() <> $MAP_CHO_OUTPOST Then
		If Not Map_WaitMapLoading($MAP_CHO_OUTPOST) Then Return False
	EndIf
	Return Leveler_HandInFormalAtKayao()
EndFunc

; Final Formal Introduction hand-in. Kayao Accept is 0x17, not the 0x813E07 reward packet.
Func Leveler_HandInFormalAtKayao($a_b_LoadSkills = True)
	If Not Leveler_WaitUntilMapReady() Then Return False
	If Leveler_FormalIntroductionTurnedIn() Then
		Out("[Step] Formal Introduction already turned in at Guardsman Kayao")
		Leveler_MarkQuestDone($QUEST_FORMAL_INTRO)
		If $a_b_LoadSkills Then Return Leveler_ReapplyZhaoDiSkillBar()
		Return True
	EndIf
	If Map_GetMapID() <> $MAP_CHO_OUTPOST Or Not Map_GetInstanceInfo("IsOutpost") Then
		If Not Leveler_Travel($MAP_CHO_OUTPOST) Then Return False
	EndIf
	If Not Leveler_WaitUntilMapReady() Then Return False
	Leveler_SetPacifist()
	Leveler_LogQuestState($QUEST_FORMAL_INTRO, "Formal Introduction")
	Out("[Step] Guardsman Kayao at " & Round($KAYAO_CHO_X) & ", " & Round($KAYAO_CHO_Y) & ": send 0x17 to Accept")
	If Not Leveler_MoveTo($KAYAO_CHO_X, $KAYAO_CHO_Y, False) Then Return False
	Local $l_i_Kayao = Leveler_GetAgentByName("Kayao")
	If $l_i_Kayao = 0 Then $l_i_Kayao = Leveler_GetNearestNPCAt($KAYAO_CHO_X, $KAYAO_CHO_Y, 400)
	If $l_i_Kayao = 0 Then
		Out("[Step] Guardsman Kayao not found")
		Return False
	EndIf
	If Not Leveler_TalkAndDialog($l_i_Kayao, $DIALOG_FORMAL_KAYAO_ACCEPT) Then Return False
	Sleep(600)
	If Leveler_QuestInLog($QUEST_FORMAL_INTRO) Then
		Ui_Dialog($DIALOG_FORMAL_COMPLETE)
		Sleep(500)
		Ui_Dialog($DIALOG_FORMAL_KAYAO_ACCEPT)
		Sleep(800)
	EndIf
	If Leveler_QuestInLog($QUEST_FORMAL_INTRO) Then
		Out("[Step] Formal Introduction is still in the log after Kayao Accept. Retrying step.")
		Return False
	EndIf
	Leveler_MarkQuestDone($QUEST_FORMAL_INTRO)
	Out("[Step] Formal Introduction handed in at Guardsman Kayao")
	If $a_b_LoadSkills Then Return Leveler_ReapplyZhaoDiSkillBar()
	; No Agent_CancelAction here. ACTION_CANCEL just before Enter Challenge disconnects.
	Sleep(800)
	Return True
EndFunc

; Put Zhao Di skills back on the bar after a trainer or map load.
Func Leveler_ReapplyZhaoDiSkillBar()
	Out("[Step] Loading the monastery trainer skill bar")
	If Not Leveler_EquipTrainerSkills(False) Then
		Out("[Step] Monastery skill bar was not applied")
		Return False
	EndIf
	Return True
EndFunc

#EndRegion Shing Jea Monastery

#Region Shing Jea Island
; Formal Introduction through Zen Daijun.

; Finish Formal Introduction and travel to Minister Cho's Estate.
Func Leveler_Step_ToChosEstate()
	$g_s_CurrentHeader = "To Minister Cho's Estate"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Not Leveler_WaitUntilMapReady() Then Return False
	If Map_IsMapUnlocked($MAP_CHO_OUTPOST) Then
		If Map_GetMapID() <> $MAP_CHO_OUTPOST Or Not Map_GetInstanceInfo("IsOutpost") Then
			Out("[Step] Cho's Estate is unlocked. Map-traveling instead of walking Sunqua.")
			If Not Leveler_Travel($MAP_CHO_OUTPOST) Then Return False
		EndIf
		Return Leveler_HandInFormalAtKayao(False)
	EndIf
	If Map_GetMapID() = $MAP_CHO_OUTPOST And Map_GetInstanceInfo("IsOutpost") Then
		Return Leveler_HandInFormalAtKayao(False)
	EndIf
	If Map_GetMapID() = $MAP_SUNQUA_VALE Then
		Leveler_SetPacifist()
		If Not Leveler_NearSunquaTogoStart() Then
			Out("[Step] Not at Togo start; skipping Togo and going to Guardsman Zui")
			Return Leveler_TalkToGuardsmanZui()
		EndIf
		Return Leveler_TalkToSunquaTogo()
	EndIf

	If Map_GetMapID() <> $MAP_SHING_JEA Then
		If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
	EndIf
	Leveler_SetPacifist()
	If Not Leveler_EnsureFormingPartyHenchmen() Then Return False
	If Not Leveler_MoveAndExit(-14961, 11453, $MAP_SUNQUA_VALE, False) Then Return False
	Leveler_SetPacifist()
	Return Leveler_TalkToSunquaTogo()
EndFunc

; Mark the Cho mission step done after the instance.
Func Leveler_MarkChoMissionComplete()
	$g_ab_StepDone[$LEVELER_STEP_CHO_MISSION] = True
	Out("[Step] Minister Cho's Estate complete. Arrived in Ran Musu Gardens.")
	Return True
EndFunc

; Enter and complete Minister Cho's Estate, then exit to Ran Musu.
Func Leveler_Step_ChosMission()
	$g_s_CurrentHeader = "Minister Cho's Estate Mission"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Not Leveler_WaitUntilMapReady() Then Return False
	If Map_GetMapID() = $MAP_RAN_MUSU Then Return Leveler_MarkChoMissionComplete()
	If Map_GetMapID() = $MAP_CHO_OUTPOST And Not Map_GetInstanceInfo("IsOutpost") Then
		Out("[Step] Already inside Minister Cho's Estate")
	Else
		If Map_GetMapID() <> $MAP_CHO_OUTPOST Or Not Map_GetInstanceInfo("IsOutpost") Then
			If Leveler_MissionPortalMap($MAP_CHO_OUTPOST, Map_GetMapID()) Then
				If Not Leveler_ReturnToMissionOutpost($MAP_CHO_OUTPOST) Then Return False
			Else
				If Not Leveler_Travel($MAP_CHO_OUTPOST) Then Return False
			EndIf
		EndIf
		If Not Leveler_WaitUntilMapReady() Then Return False
		If Not Leveler_FormalIntroductionTurnedIn() Then
			Out("[Step] Formal Introduction must be handed in at Kayao before the mission")
			If Not Leveler_HandInFormalAtKayao(False) Then Return False
			Sleep(1200)
		EndIf
		; Stage 1: henchmen. Skill bar is already set — do not reload it.
		Out("[Step] Add henchmen, then zone out and back before the mission")
		If Not Leveler_EnsureFormingPartyHenchmen(False) Then Return False
		; Stage 2: portal round-trip. Party packets plus Enter Challenge in this instance 007.
		If Not Leveler_SettlePartyForMission($MAP_CHO_OUTPOST) Then Return False
		; Stage 3: native Ui_EnterChallenge. Do not add or remove henchmen after the portal.
		If Not Leveler_EnterMission("Minister Cho's Estate", $MAP_CHO_OUTPOST) Then Return False
	EndIf
	If Not Leveler_WaitUntilMapReady() Then Return False
	Leveler_EnsurePathfinder()
	; Cho keeps the outpost map id. Cache only after the instance is explorable.
	If Not Leveler_CacheUtilityAIForMap(Map_GetMapID()) Then Return False
	If Leveler_IsWiped() Then Return False

	If Not Leveler_MoveTo(6220.76, -7360.73, True) Then Return False
	If Not Leveler_MoveTo(5523.95, -7746.41, True) Then Return False
	If Not Leveler_WaitCombat(15000) Then Return False
	If Not Leveler_MoveTo(591.21, -9071.10, True) Then Return False
	If Not Leveler_WaitCombat(30000) Then Return False
	If Not Leveler_MoveTo(4889, -5043, True) Then Return False ; Map Tutorial
	If Not Leveler_MoveTo(4268.49, -3621.66, True) Then Return False
	If Not Leveler_WaitCombat(20000) Then Return False
	If Not Leveler_MoveTo(6216, -1108, True) Then Return False ; Bridge Corner
	; Mid-bridge points so Pathfinder keeps the elevated layer (Map_MoveLayer).
	If Not Leveler_MoveTo(4800, -400, True) Then Return False
	If Not Leveler_MoveTo(3600, 100, True) Then Return False
	If Not Leveler_MoveTo(2617, 642, True) Then Return False ; Past Bridge
	If Not Leveler_MoveTo(1706.90, 1711.44, True) Then Return False
	If Not Leveler_WaitCombat(30000) Then Return False
	If Not Leveler_MoveTo(333.32, 1124.44, True) Then Return False
	If Not Leveler_MoveTo(-3337.14, -4741.27, True) Then Return False
	If Not Leveler_WaitCombat(35000) Then Return False
	If Not Leveler_PrepareCombatAI() Then Return False
	If Not Leveler_MoveTo(-4661.99, -6285.81, True) Then Return False
	If Not Leveler_MoveTo(-7454, -7384, True) Then Return False ; Zoo Entrance
	If Not Leveler_MoveTo(-9138, -4191, True) Then Return False ; First Zoo Fight
	If Not Leveler_MoveTo(-7109, -25, True) Then Return False ; Bridge Waypoint
	If Not Leveler_MoveTo(-7250, 1100, True) Then Return False ; Zoo bridge mid
	If Not Leveler_MoveTo(-7443, 2243, True) Then Return False ; Zoo Exit
	If Not Leveler_WaitCombat(5000) Then Return False
	If Not Leveler_MoveTo(-16924, 2445, True) Then Return False ; Final Destination
	If Not Leveler_InteractNpcAt(-17031, 2448, True) Then
		Local $l_i_Npc = Leveler_GetNearestNPC(400)
		If $l_i_Npc <> 0 Then Agent_GoNPC($l_i_Npc)
	EndIf
	If Not Map_WaitMapLoading($MAP_RAN_MUSU) And Map_GetMapID() <> $MAP_RAN_MUSU Then Return False
	If Map_GetMapID() <> $MAP_RAN_MUSU Then Return False
	Return Leveler_MarkChoMissionComplete()
EndFunc

; Wait until Raitahn Nem is present for Lost Treasure.
Func Leveler_WaitForRaitahnNem($a_i_Timeout = 20000)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return 0
		Local $l_i_Npc = Leveler_GetAgentByModel($MODEL_RAITAHN_NEM)
		If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetNearestNPCAt(14363.00, 19499.00, 600)
		If $l_i_Npc <> 0 Then Return $l_i_Npc
		Sleep(250)
	WEnd
	Return 0
EndFunc

; Walk to Raitahn Nem, accept #346 in his dialog, then wait until it is in the log.
; Do not send ActiveQuest / RequestInfos / leave the outpost until that happens.
Func Leveler_PickupLostTreasure()
	If Leveler_HasQuest($QUEST_LOST_TREASURE) Then Return True
	If Leveler_LostTreasureAlreadyDone() Then
		Leveler_MarkQuestDone($QUEST_LOST_TREASURE, True)
		Return True
	EndIf
	If Map_GetMapID() <> $MAP_RAN_MUSU Then
		If Not Leveler_Travel($MAP_RAN_MUSU) Then Return False
	EndIf
	If Not Leveler_WaitUntilMapReady() Then Return False
	If Not Map_GetInstanceInfo("IsOutpost") Then Return False
	Sleep(1500)

	Leveler_SetPacifist()
	Out("[Step] Walk to Raitahn Nem in Ran Musu Gardens")
	Local $l_i_Npc = Leveler_WaitForRaitahnNem()
	If $l_i_Npc = 0 Then
		Out("[Step] Raitahn Nem is not in Ran Musu yet")
		Return False
	EndIf

	Local $l_f_X = Agent_GetAgentInfo($l_i_Npc, "X")
	Local $l_f_Y = Agent_GetAgentInfo($l_i_Npc, "Y")
	If Not Leveler_MoveDirect($l_f_X, $l_f_Y) Then Return False

	Local $l_i_Attempt
	For $l_i_Attempt = 1 To 2
		If $g_b_LevelerPaused Then Return False
		If Leveler_HasQuest($QUEST_LOST_TREASURE) Then ExitLoop

		$l_i_Npc = Leveler_WaitForRaitahnNem(8000)
		If $l_i_Npc = 0 Then ContinueLoop
		Out("[Step] Talk to Raitahn Nem and accept Lost Treasure")
		If Not Leveler_TalkAndDialog($l_i_Npc, $DIALOG_LOST_TREASURE_ACCEPT) Then
			Sleep(500)
			ContinueLoop
		EndIf

		Local $l_h_Wait = TimerInit()
		While TimerDiff($l_h_Wait) < 2500
			If Leveler_HasQuest($QUEST_LOST_TREASURE) Then ExitLoop 2
			Sleep(200)
		WEnd

		; Accept is not in his dialog. Lost Treasure is already finished.
		Leveler_MarkQuestDone($QUEST_LOST_TREASURE, True)
		Leveler_LogQuestState($QUEST_LOST_TREASURE, "Lost Treasure")
		Out("[Step] Raitahn Nem has no Lost Treasure accept. Treating as completed.")
		Return True
	Next

	If Not Leveler_HasQuest($QUEST_LOST_TREASURE) Then
		Leveler_LogQuestState($QUEST_LOST_TREASURE, "Lost Treasure")
		Out("[Step] Lost Treasure was not offered yet. Will retry pickup.")
		Return False
	EndIf

	Agent_CancelAction()
	Sleep(400)
	Ui_ActiveQuest($QUEST_LOST_TREASURE)
	Leveler_LogQuestState($QUEST_LOST_TREASURE, "Lost Treasure")
	Out("[Step] Lost Treasure is active in the quest log")
	Return True
EndFunc

; Select Lost Treasure in the Progress list after a restart.
Func Leveler_ShowLostTreasureStepOnGui()
	$g_s_CurrentHeader = "Quest: Lost Treasure"
	$g_i_Step = $LEVELER_STEP_ATTR_1
	$g_ab_StepDone[$LEVELER_STEP_ATTR_1] = False
	$g_ab_StepDone[$LEVELER_STEP_TENGU] = Leveler_WarningTheTenguDone()
	Leveler_RefreshStepList($LEVELER_STEP_ATTR_1)
EndFunc

; Select Warning the Tengu in the Progress list.
Func Leveler_ShowTenguStepOnGui()
	$g_s_CurrentHeader = "Quest: Warning the Tengu"
	$g_i_Step = $LEVELER_STEP_TENGU
	$g_ab_StepDone[$LEVELER_STEP_ATTR_1] = True
	$g_ab_StepDone[$LEVELER_STEP_TENGU] = False
	Leveler_RefreshStepList($LEVELER_STEP_TENGU)
EndFunc

; Walk to one coordinate, logging an optional label.
Func Leveler_WalkPoint($a_f_X, $a_f_Y, $a_b_Combat = False, $a_s_Label = "")
	If $a_s_Label <> "" Then Out("[Path] " & $a_s_Label & " " & Round($a_f_X) & ", " & Round($a_f_Y))
	If Not Leveler_MoveTo($a_f_X, $a_f_Y, $a_b_Combat) Then
		Out("[Path] Failed to reach " & Round($a_f_X) & ", " & Round($a_f_Y))
		Return False
	EndIf
	Return True
EndFunc

; Keep talking until the quest leaves the log. Do not skip because IsCompleted is set.
Func Leveler_ForceCompleteDialog($a_i_QuestID, $a_f_X, $a_f_Y, $a_i_Dialog, $a_i_NpcModel = 0, $a_s_NpcName = "")
	Out("[Quest] Complete #" & $a_i_QuestID & " dialog 0x" & Hex($a_i_Dialog, 6))
	Local $l_b_Talked = False
	Local $l_i_Attempt
	For $l_i_Attempt = 1 To 10
		If $g_b_LevelerPaused Then Return False
		If Not Leveler_HasQuest($a_i_QuestID) And Not Leveler_QuestReadyForReward($a_i_QuestID) Then
			Leveler_MarkQuestDone($a_i_QuestID)
			Out("[Quest] #" & $a_i_QuestID & " is out of the log")
			Return True
		EndIf
		If $a_f_X <> 0 Or $a_f_Y <> 0 Then
			If Not Leveler_MoveTo($a_f_X, $a_f_Y, Leveler_ShouldFightHere()) Then Sleep(300)
		EndIf
		Local $l_i_Npc = 0
		If $a_s_NpcName <> "" Then $l_i_Npc = Leveler_GetAgentByName($a_s_NpcName)
		If $l_i_Npc = 0 Then $l_i_Npc = Leveler_ResolveTalkNpc($a_f_X, $a_f_Y, $a_i_NpcModel)
		If $l_i_Npc = 0 Then
			Out("[Quest] No NPC for complete #" & $a_i_QuestID & " attempt " & $l_i_Attempt)
			Sleep(500)
			ContinueLoop
		EndIf
		Out("[Quest] Talk to model " & Agent_GetAgentInfo($l_i_Npc, "PlayerNumber") & " for #" & $a_i_QuestID)
		Agent_ChangeTarget($l_i_Npc)
		Sleep(200)
		Agent_GoNPC($l_i_Npc)
		Local $l_h_Reach = TimerInit()
		While TimerDiff($l_h_Reach) < 5000
			If Agent_GetDistance($l_i_Npc) < $LEVELER_ARRIVE_RANGE Then ExitLoop
			Sleep(100)
		WEnd
		Sleep(800)
		If $a_i_Dialog <> 0 Then Ui_Dialog($a_i_Dialog)
		Sleep(400)
		Ui_RewardQuest($a_i_QuestID)
		Sleep(400)
		If $a_i_Dialog <> 0 Then Ui_Dialog($a_i_Dialog)
		Sleep(900)
		$l_b_Talked = True
		If Not Leveler_HasQuest($a_i_QuestID) Then
			Leveler_MarkQuestDone($a_i_QuestID)
			Out("[Quest] #" & $a_i_QuestID & " handed in")
			Return True
		EndIf
		If Leveler_FinishIfCompleteUnavailable($a_i_QuestID, $a_i_NpcModel) Then Return True
	Next
	If $l_b_Talked And Leveler_FinishIfCompleteUnavailable($a_i_QuestID, $a_i_NpcModel) Then Return True
	Out("[Quest] #" & $a_i_QuestID & " is still in the log after complete dialogs")
	Return False
EndFunc

; Hand in Lost Treasure at 20660.90, -9207.07 with dialog 0x17. Used after the escort or after a disconnect.
Func Leveler_HandInLostTreasureAtNem()
	If Not Leveler_QuestNeedsHandIn($QUEST_LOST_TREASURE) Then
		Leveler_MarkQuestDone($QUEST_LOST_TREASURE)
		Return True
	EndIf
	If Not Leveler_WaitUntilMapReady() Then Return False
	If Map_GetMapID() <> $MAP_CHO_EXPLORABLE Then Return False
	If Agent_GetDistanceToXY($LOST_CHO_END_X, $LOST_CHO_END_Y) >= $LEVELER_ARRIVE_RANGE Then
		If Not Leveler_WalkPoint($LOST_CHO_END_X, $LOST_CHO_END_Y, True, "Raitahn Nem final") Then Return False
	EndIf
	If Not Leveler_WaitOutOfCombat() Then Return False
	Out("[Path] Lost Treasure complete at " & Round($LOST_CHO_END_X) & ", " & Round($LOST_CHO_END_Y) & " with dialog 0x17")
	If Not Leveler_ForceCompleteDialog($QUEST_LOST_TREASURE, $LOST_CHO_END_X, $LOST_CHO_END_Y, $DIALOG_LOST_TREASURE_COMPLETE, $MODEL_LOST_TREASURE_GUARD, "Nem") Then Return False
	If Map_GetMapID() = $MAP_CHO_EXPLORABLE Then
		If Not Leveler_Travel($MAP_RAN_MUSU) Then Leveler_LeaveChoExplorableToRanMusu()
	EndIf
	Out("[Path] Lost Treasure complete dialog taken at the end of the route")
	Return True
EndFunc

; Finish Lost Treasure at Raitahn Nem, including a late hand-in.
Func Leveler_CompleteLostTreasureAtNem()
	If Not Leveler_QuestNeedsHandIn($QUEST_LOST_TREASURE) Then
		Leveler_MarkQuestDone($QUEST_LOST_TREASURE)
		Return True
	EndIf
	Leveler_ShowLostTreasureStepOnGui()
	If Not Leveler_WaitUntilMapReady() Then Return False

	If Leveler_NearLostTreasureHandIn() Then
		Out("[Path] Already at Raitahn Nem's final location after an interrupt. Handing in Lost Treasure with 0x17.")
		Return Leveler_HandInLostTreasureAtNem()
	EndIf

	Out("[Path] Lost Treasure pickup and complete. Final dialog is at the end of Raitahn Nem's path.")

	If Map_GetMapID() <> $MAP_CHO_EXPLORABLE Then
		If Map_GetMapID() <> $MAP_RAN_MUSU Then
			If Not Leveler_Travel($MAP_RAN_MUSU) Then Return False
		EndIf
		If Not Leveler_WaitUntilMapReady() Then Return False
		Leveler_SetPacifist()
		If Not Leveler_WalkPoint($LOST_TOWN_APPROACH_X, $LOST_TOWN_APPROACH_Y, False, "Ran Musu approach") Then Return False
		Leveler_PrepareForBattle()
		Leveler_SetPacifist()
		If Not Leveler_WalkPoint($LOST_TOWN_PATH1_X, $LOST_TOWN_PATH1_Y, False, "Ran Musu path 1") Then Return False
		If Not Leveler_WalkPoint($LOST_TOWN_PATH2_X, $LOST_TOWN_PATH2_Y, False, "Ran Musu path 2") Then Return False
		If Not Leveler_WalkPoint($LOST_TOWN_PATH3_X, $LOST_TOWN_PATH3_Y, False, "Ran Musu path 3") Then Return False
		Out("[Path] Exit Ran Musu into Minister Cho's Estate")
		If Not Leveler_MoveAndExit($LOST_TOWN_PORTAL_X, $LOST_TOWN_PORTAL_Y, $MAP_CHO_EXPLORABLE, False) Then Return False
	EndIf

	If Not Leveler_WaitUntilMapReady() Then Return False
	If Not Leveler_EquipTrainerSkills(False) Then Return False
	Sleep(2000)
	; The trainer bar just changed. The cache from map entry is for the previous bar.
	If Not Leveler_CacheUtilityAIForMap(Map_GetMapID()) Then Return False

	Local $l_b_PastStart = Agent_GetDistanceToXY($LOST_CHO_START_X, $LOST_CHO_START_Y) > 3500
	Local $l_i_Nem = Leveler_GetAgentByModel($MODEL_LOST_TREASURE_GUARD)
	If $l_i_Nem <> 0 Then
		Local $l_f_NemX = Agent_GetAgentInfo($l_i_Nem, "X")
		Local $l_f_NemY = Agent_GetAgentInfo($l_i_Nem, "Y")
		If Sqrt(($l_f_NemX - $LOST_CHO_START_X) ^ 2 + ($l_f_NemY - $LOST_CHO_START_Y) ^ 2) > 3500 Then $l_b_PastStart = True
	EndIf

	If Not $l_b_PastStart And Not Leveler_QuestReadyForReward($QUEST_LOST_TREASURE) Then
		If Not Leveler_WalkPoint($LOST_CHO_START_X, $LOST_CHO_START_Y, True, "Lost Treasure start") Then Return False
		Out("[Path] Minister Cho's Estate dialog on Raitahn Nem")
		Leveler_QuestLoop($QUEST_LOST_TREASURE, 0, 0, $DIALOG_LOST_TREASURE_STEP, "step", $MODEL_LOST_TREASURE_GUARD)
		Sleep(5000)
	Else
		Out("[Path] Cho start dialog already done. Following Raitahn Nem to the end.")
	EndIf

	If Leveler_GetAgentByModel($MODEL_LOST_TREASURE_GUARD) = 0 Then
		Out("[Path] Waiting for Raitahn Nem")
		Local $l_h_WaitNem = TimerInit()
		While TimerDiff($l_h_WaitNem) < 30000
			If Leveler_GetAgentByModel($MODEL_LOST_TREASURE_GUARD) <> 0 Then ExitLoop
			Leveler_CombatTick()
			Sleep(400)
		WEnd
	EndIf

	If Not Leveler_FollowLostTreasurePath() Then Return False
	Return Leveler_HandInLostTreasureAtNem()
EndFunc

; Accept #339 from Ang the Tengu in Ran Musu. Dialog 0x815301.
Func Leveler_AcceptTenguAtAng()
	If Leveler_HasQuest($QUEST_WARNING_TENGU) Then Return True
	If Leveler_WarningTheTenguDone() Then
		Leveler_MarkQuestDone($QUEST_WARNING_TENGU, True)
		Return True
	EndIf
	Out("[Path] Talk to Ang the Tengu and accept Warning the Tengu (0x815301)")
	If Not Leveler_WalkPoint($TENGU_ANG_X, $TENGU_ANG_Y, False, "Ang in Ran Musu") Then Return False
	Local $l_i_Npc = Leveler_GetAgentByName("Ang")
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetNearestNPCAt($TENGU_ANG_X, $TENGU_ANG_Y, 400)
	If $l_i_Npc = 0 Then
		Out("[Path] Ang the Tengu was not found")
		Return False
	EndIf
	If Not Leveler_TalkAndDialog($l_i_Npc, $DIALOG_TENGU_ACCEPT) Then Return False
	Local $l_h_Wait = TimerInit()
	While TimerDiff($l_h_Wait) < 4000
		If Leveler_HasQuest($QUEST_WARNING_TENGU) Then
			Ui_ActiveQuest($QUEST_WARNING_TENGU)
			Out("[Path] Warning the Tengu accepted at Ang")
			Return True
		EndIf
		Sleep(200)
	WEnd
	Leveler_MarkQuestDone($QUEST_WARNING_TENGU, True)
	Out("[Path] Ang has no Warning the Tengu accept. Treating as completed.")
	Return True
EndFunc

; First Soar talk updates #339 (0x815304) so the Afflicted spawn / complete is offered.
Func Leveler_UpdateTenguAtSoar()
	If Not Leveler_HasQuest($QUEST_WARNING_TENGU) Then Return True
	If Leveler_QuestReadyForReward($QUEST_WARNING_TENGU) Then Return True
	Out("[Path] Update Warning the Tengu at Soar Honorclaw (0x815304)")
	If Not Leveler_WalkPoint($TENGU_SOAR_X, $TENGU_SOAR_Y, True, "Soar Honorclaw") Then Return False
	If Not Leveler_WaitOutOfCombat() Then Return False
	If Not Leveler_QuestLoop($QUEST_WARNING_TENGU, $TENGU_SOAR_X, $TENGU_SOAR_Y, $DIALOG_TENGU_STEP, "step", 0) Then
		Out("[Path] Soar update dialog did not apply. Continuing to the Afflicted.")
	EndIf
	Return True
EndFunc

; Reward #339 at Soar. Dialog 0x815307.
Func Leveler_HandInTenguAtSoar()
	Out("[Path] Hand in Warning the Tengu at Soar Honorclaw (0x815307)")
	Leveler_ShowTenguStepOnGui()
	If Not Leveler_WalkPoint($TENGU_SOAR_X, $TENGU_SOAR_Y, True, "Soar Honorclaw") Then Return False
	If Not Leveler_WaitOutOfCombat() Then Return False
	If Not Leveler_HasQuest($QUEST_WARNING_TENGU) And Not Leveler_QuestReadyForReward($QUEST_WARNING_TENGU) Then
		If Leveler_WarningTheTenguDone() Then Return True
		Out("[Path] Warning the Tengu is not in the log. Need the accept at Ang first.")
		Return False
	EndIf
	If Not Leveler_ForceCompleteDialog($QUEST_WARNING_TENGU, $TENGU_SOAR_X, $TENGU_SOAR_Y, $DIALOG_TENGU_COMPLETE, 0, "Soar") Then Return False
	$g_b_LostTreasureToTenguOnce = True
	Return True
EndFunc

; If already at Soar, stay and hand in. Otherwise run Ran Musu -> Kinya -> Soar.
Func Leveler_RunRanMusuToTenguHandIn()
	Leveler_ShowTenguStepOnGui()
	If Not Leveler_WaitUntilMapReady() Then Return False

	If Map_GetMapID() = $MAP_KINYA And Agent_GetDistanceToXY($TENGU_SOAR_X, $TENGU_SOAR_Y) < 2500 Then
		Out("[Path] Already at Soar Honorclaw.")
		If Leveler_QuestReadyForReward($QUEST_WARNING_TENGU) Then
			If Not Leveler_HandInTenguAtSoar() Then Return False
		Else
			If Not Leveler_UpdateTenguAtSoar() Then Return False
			If Not Leveler_WalkPoint($TENGU_AFFLICTED_X, $TENGU_AFFLICTED_Y, True, "Afflicted") Then Return False
			If Not Leveler_WaitOutOfCombat() Then Return False
			If Not Leveler_HandInTenguAtSoar() Then Return False
		EndIf
		If Leveler_HasQuest($QUEST_LOST_TREASURE) Or Leveler_QuestReadyForReward($QUEST_LOST_TREASURE) Then
			If Not Leveler_CompleteLostTreasureAtNem() Then Return False
		EndIf
		Return True
	EndIf

	If Leveler_ShouldResumeExplorable($QUEST_WARNING_TENGU) Then
		Out("[Path] Warning the Tengu is in the log and map " & Map_GetMapID() & " is not an outpost. Resuming from here.")
		If Map_GetMapID() = $MAP_KINYA Then
			If Not Leveler_CacheUtilityAIForMap($MAP_KINYA) Then Return False
			If Not Leveler_UpdateTenguAtSoar() Then Return False
			If Not Leveler_WalkPoint($TENGU_AFFLICTED_X, $TENGU_AFFLICTED_Y, True, "Afflicted") Then Return False
			If Not Leveler_WaitOutOfCombat() Then Return False
			If Not Leveler_HandInTenguAtSoar() Then Return False
			Return True
		EndIf
	EndIf

	If Leveler_HasQuest($QUEST_LOST_TREASURE) Or Leveler_QuestReadyForReward($QUEST_LOST_TREASURE) Then
		If Not Leveler_CompleteLostTreasureAtNem() Then Return False
	EndIf

	Out("[Path] Running Warning the Tengu: Ran Musu Gardens to Soar Honorclaw")
	If Map_GetMapID() = $MAP_CHO_EXPLORABLE Then
		Out("[Path] Leaving Cho explorable for Ran Musu Gardens")
		If Not Leveler_Travel($MAP_RAN_MUSU) Then
			If Not Leveler_LeaveChoExplorableToRanMusu() Then Return False
		EndIf
	EndIf
	If Map_GetMapID() <> $MAP_RAN_MUSU Then
		If Not Leveler_Travel($MAP_RAN_MUSU) Then Return False
	EndIf
	If Not Leveler_WaitUntilMapReady() Then Return False

	Leveler_SetPacifist()
	If Not Leveler_AcceptTenguAtAng() Then Return False
	If Not Leveler_HasQuest($QUEST_WARNING_TENGU) Then Return True
	Leveler_PrepareForBattle()
	Out("[Path] Leave Ran Musu for Kinya Province")
	If Not Leveler_MoveAndExit($TENGU_PORTAL_X, $TENGU_PORTAL_Y, $MAP_KINYA, True) Then Return False
	If Not Leveler_WaitUntilMapReady() Then Return False
	If Not Leveler_EquipTrainerSkills(False) Then Return False
	Sleep(1500)
	If Not Leveler_CacheUtilityAIForMap($MAP_KINYA) Then Return False

	If Not Leveler_WalkPoint($TENGU_KINYA_START_X, $TENGU_KINYA_START_Y, True, "Kinya start") Then Return False
	If Not Leveler_UpdateTenguAtSoar() Then Return False
	If Not Leveler_WalkPoint($TENGU_AFFLICTED_X, $TENGU_AFFLICTED_Y, True, "Afflicted") Then Return False
	If Not Leveler_WaitOutOfCombat() Then Return False
	If Not Leveler_HandInTenguAtSoar() Then Return False
	Return True
EndFunc

; Run Lost Treasure: pickup, escort, and 0x17 hand-in at Raitahn Nem.
Func Leveler_Step_LostTreasure()
	Leveler_ShowLostTreasureStepOnGui()
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Not Leveler_WaitUntilMapReady() Then Return False
	If Leveler_NearLostTreasureHandIn() And Leveler_QuestNeedsHandIn($QUEST_LOST_TREASURE) Then
		Out("[Step] Already at Raitahn Nem's final location. Skipping the escort and handing in with 0x17.")
		Return Leveler_HandInLostTreasureAtNem()
	EndIf
	If Leveler_LostTreasureAlreadyDone() Then
		Leveler_MarkQuestDone($QUEST_LOST_TREASURE, True)
		Out("[Step] Lost Treasure already completed. Moving on.")
		Return True
	EndIf
	If Not Leveler_QuestNeedsHandIn($QUEST_LOST_TREASURE) Then
		If Not Leveler_PickupLostTreasure() Then Return False
		If Not Leveler_QuestNeedsHandIn($QUEST_LOST_TREASURE) Then
			Leveler_MarkQuestDone($QUEST_LOST_TREASURE, True)
			Out("[Step] Lost Treasure accept is not available. Moving on.")
			Return True
		EndIf
	EndIf
	If Not Leveler_QuestNeedsHandIn($QUEST_LOST_TREASURE) Then Return False
	Return Leveler_CompleteLostTreasureAtNem()
EndFunc

; Run Warning the Tengu from Ran Musu through Kinya to Soar.
Func Leveler_Step_WarningTheTengu()
	$g_s_CurrentHeader = "Quest: Warning the Tengu"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_WarningTheTenguDone() Then
		Leveler_MarkQuestDone($QUEST_WARNING_TENGU)
		Leveler_LogQuestState($QUEST_WARNING_TENGU, "Warning the Tengu")
		Out("[Step] Warning the Tengu already completed. Skipping to The Threat Grows.")
		Return True
	EndIf
	Return Leveler_RunRanMusuToTenguHandIn()
EndFunc

; Accept, complete, and chain Threat Grows into Journey of the Master.
Func Leveler_Step_TheThreatGrows()
	$g_s_CurrentHeader = "Quest: The Threat Grows"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Not Leveler_QuestNeedsHandIn($QUEST_THREAT_GROWS) And (Leveler_HasQuest($QUEST_JOURNEY_MASTER) Or Leveler_QuestNeedsHandIn($QUEST_JOURNEY_MASTER) Or Leveler_QuestNeedsHandIn($QUEST_ROAD_LESS)) Then
		Leveler_MarkQuestDone($QUEST_THREAT_GROWS)
		Out("[Step] The Threat Grows already handed in. Continuing to The Road Less Traveled.")
		Return True
	EndIf
	If Leveler_IsQuestDone($QUEST_THREAT_GROWS) And (Leveler_IsQuestDone($QUEST_JOURNEY_MASTER) Or Leveler_HasQuest($QUEST_JOURNEY_MASTER)) Then
		Out("[Step] The Threat Grows already completed")
		Return True
	EndIf

	Local $l_b_Resume = Leveler_ShouldResumeExplorable($QUEST_THREAT_GROWS) Or Leveler_ShouldResumeExplorable($QUEST_JOURNEY_MASTER)
	If $l_b_Resume Then
		Out("[Step] The Threat Grows is in the log and map " & Map_GetMapID() & " is not an outpost. Resuming from here.")
	EndIf

	If Not $l_b_Resume And Not Leveler_HasQuest($QUEST_THREAT_GROWS) And Not Leveler_HasQuest($QUEST_JOURNEY_MASTER) Then
		If Map_GetMapID() <> $MAP_KINYA Then
			If Not Leveler_Travel($MAP_RAN_MUSU) Then Return False
			Leveler_PrepareForBattle()
			If Not Leveler_MoveAndExit(14730, 15176, $MAP_KINYA, True) Then Return False
		EndIf
		If Not Leveler_QuestLoop($QUEST_THREAT_GROWS, -1023, 4844, $DIALOG_THREAT_ACCEPT, "accept") Then Return False
	EndIf

	Local $l_i_Map = Map_GetMapID()
	If $l_i_Map = $MAP_PANJIANG Then
		Out("[Step] Already in Panjiang Peninsula. Going to Sister Tai.")
	ElseIf $l_i_Map = $MAP_TSUMEI Then
		Leveler_PrepareForBattle()
		If Not Leveler_MoveAndExit(-11600, -17400, $MAP_PANJIANG, True) Then Return False
	ElseIf $l_i_Map = $MAP_SUNQUA_VALE Then
		Out("[Step] Resuming in Sunqua Vale. Continuing to Tsumei Village.")
		Leveler_SetPacifist()
		If Not Leveler_MoveTo(18245.78, -9448.29, False) Then Return False
		If Not Leveler_MoveAndExit(-4842, -13267, $MAP_TSUMEI, False) Then Return False
		Leveler_PrepareForBattle()
		If Not Leveler_MoveAndExit(-11600, -17400, $MAP_PANJIANG, True) Then Return False
	ElseIf $l_i_Map = $MAP_KINYA Then
		Out("[Step] The Threat Grows is in the log in Kinya. Continuing to Tsumei via Shing Jea.")
		If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
		Leveler_PrepareForBattle()
		If Not Leveler_MoveAndExit(-14961, 11453, $MAP_SUNQUA_VALE, True) Then Return False
		Leveler_SetPacifist()
		If Not Leveler_MoveTo(18245.78, -9448.29, False) Then Return False
		If Not Leveler_MoveAndExit(-4842, -13267, $MAP_TSUMEI, False) Then Return False
		Leveler_PrepareForBattle()
		If Not Leveler_MoveAndExit(-11600, -17400, $MAP_PANJIANG, True) Then Return False
	ElseIf $l_b_Resume Then
		Out("[Step] Staying on explorable map " & $l_i_Map & " to finish The Threat Grows")
	Else
		If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
		Leveler_PrepareForBattle()
		If Not Leveler_MoveAndExit(-14961, 11453, $MAP_SUNQUA_VALE, True) Then Return False
		Leveler_SetPacifist()
		If Not Leveler_MoveTo(18245.78, -9448.29, False) Then Return False
		If Not Leveler_MoveAndExit(-4842, -13267, $MAP_TSUMEI, False) Then Return False
		Leveler_PrepareForBattle()
		If Not Leveler_MoveAndExit(-11600, -17400, $MAP_PANJIANG, True) Then Return False
	EndIf

	If Not Leveler_MoveTo(10077.84, 8047.69, True) Then Return False
	If Not Leveler_WaitUntilModelHasQuest($MODEL_SISTER_TAI) Then Return False
	Leveler_SetPacifist()
	If Not Leveler_QuestLoop($QUEST_THREAT_GROWS, 0, 0, $DIALOG_THREAT_COMPLETE, "complete", $MODEL_SISTER_TAI) Then Return False
	If Not Leveler_QuestLoop($QUEST_JOURNEY_MASTER, 0, 0, $DIALOG_JOURNEY_ACCEPT, "accept", $MODEL_SISTER_TAI) Then Return False
	Out("[Step] The Threat Grows complete. Accepted Journey of the Master.")
	Return True
EndFunc

; Guard Tsukaro at the Linnok gate. The Road Less Traveled (0x815604),
; "We have been trained well..." (0x800008), "Let's Go!" (0x800009), then "Yes." (0x80000B).
; QuestLoop skips this when #342 is already IsCompleted. Send the IDs after arriving and stopping.
Func Leveler_TalkToGuardTsukaro()
	If Map_GetMapID() = $MAP_SAOSHANG Then Return True
	Leveler_SetPacifist()
	If Leveler_HasQuest($QUEST_ROAD_LESS) Then Ui_ActiveQuest($QUEST_ROAD_LESS)
	Out("[Step] Walking to Guard Tsukaro at " & Round($TSUKARO_LINNOK_X) & ", " & Round($TSUKARO_LINNOK_Y))
	Leveler_MoveTo($TSUKARO_LINNOK_X, $TSUKARO_LINNOK_Y, False)
	If Map_GetMapID() = $MAP_SAOSHANG Then Return True

	Local $l_i_Attempt
	For $l_i_Attempt = 1 To 5
		If $g_b_LevelerPaused Then Return False
		If Map_GetMapID() = $MAP_SAOSHANG Then Return True
		If Map_GetMapID() <> $MAP_LINNOK And Map_GetMapID() <> $MAP_SHING_JEA Then
			Out("[Step] Left Linnok after Tsukaro, map " & Map_GetMapID())
			Return Map_WaitMapLoading($MAP_SAOSHANG)
		EndIf

		Local $l_i_Npc = Leveler_GetTsukaro()
		If $l_i_Npc = 0 Then
			Out("[Step] Guard Tsukaro not found, attempt " & $l_i_Attempt)
			Leveler_MoveTo($TSUKARO_LINNOK_X, $TSUKARO_LINNOK_Y, False)
			Sleep(400)
			ContinueLoop
		EndIf

		If Agent_GetDistance($l_i_Npc) >= 150 Then
			Local $l_h_Reach = TimerInit()
			While TimerDiff($l_h_Reach) < 5000 And Agent_GetDistance($l_i_Npc) >= 150
				If $g_b_LevelerPaused Then Return False
				Map_Move(Agent_GetAgentInfo($l_i_Npc, "X"), Agent_GetAgentInfo($l_i_Npc, "Y"), 10)
				Sleep(150)
			WEnd
		EndIf
		Agent_CancelAction()
		Sleep(400)

		Out("[Step] Guard Tsukaro: 0x815604, 0x800008, Let's Go! 0x800009, Yes. 0x80000B")
		Agent_ChangeTarget($l_i_Npc)
		Sleep(150)
		Agent_GoNPC($l_i_Npc)
		Sleep(1000)
		Ui_Dialog($DIALOG_ROAD_TSUKARO_TALK)
		Sleep(350)
		Ui_Dialog($DIALOG_ROAD_TSUKARO_GO)
		Sleep(350)
		Ui_Dialog($DIALOG_ROAD_TSUKARO_LETS_GO)
		Sleep(350)
		Ui_Dialog($DIALOG_ROAD_TSUKARO_YES)

		Local $l_h_Wait = TimerInit()
		While TimerDiff($l_h_Wait) < 8000
			If Map_GetMapID() = $MAP_SAOSHANG Then Return True
			If Map_GetInstanceInfo("IsLoading") Then Return Map_WaitMapLoading($MAP_SAOSHANG)
			If Game_GetGameInfo("IsCinematic") Then Return Map_WaitMapLoading($MAP_SAOSHANG)
			Sleep(200)
		WEnd
		If Map_GetMapID() = $MAP_SAOSHANG Then Return True
	Next

	If Map_GetMapID() = $MAP_SAOSHANG Then Return True
	Out("[Step] Waiting for Saoshang Trail after Tsukaro dialogs")
	Return Map_WaitMapLoading($MAP_SAOSHANG)
EndFunc

; Run Road Less Traveled through Linnok / Tsukaro and hand in at Seitung.
Func Leveler_Step_TheRoadLessTraveled()
	$g_s_CurrentHeader = "Quest: The Road Less Traveled"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_RoadLessTraveledDone() Then
		Out("[Step] The Road Less Traveled already handed in at Seitung Harbor")
		Return True
	EndIf
	Leveler_LogQuestState($QUEST_JOURNEY_MASTER, "Journey of the Master")
	Leveler_LogQuestState($QUEST_ROAD_LESS, "The Road Less Traveled")

	; Journey of the Master (#341) hands in at Togo in Linnok, then pick up The Road Less Traveled (#342).
	; Henchmen can only be added in town. Form the party in Shing Jea, walk into Linnok with it, then Tsukaro.
	If Map_GetMapID() <> $MAP_SAOSHANG And Map_GetMapID() <> $MAP_SEITUNG Then
		If Map_GetMapID() <> $MAP_SHING_JEA Or Not Map_GetInstanceInfo("IsOutpost") Then
			Out("[Step] Traveling to Shing Jea Monastery to form a party")
			If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
		EndIf
		If Not Map_GetInstanceInfo("IsOutpost") Then Return False
		Out("[Step] Forming the party in Shing Jea, then entering Linnok Courtyard")
		$g_b_CombatMode = True
		Ui_SetDifficulty(False)
		Local $l_ai_Hench = Leveler_FormingPartyHenchIDs()
		Leveler_AddHenchmanList($l_ai_Hench)
		Out("[Step] Walking to Linnok Courtyard with the party")
		If Not Leveler_MoveAndExit(-3480, 9460, $MAP_LINNOK, False) Then Return False
	EndIf

	If Map_GetMapID() = $MAP_LINNOK Then
		Local $l_i_Togo = Leveler_TogoModel()
		If Leveler_HasQuest($QUEST_JOURNEY_MASTER) Then
			Out("[Step] Handing in Journey of the Master at Master Togo")
			If Not Leveler_QuestLoop($QUEST_JOURNEY_MASTER, -92, 9217, $DIALOG_JOURNEY_COMPLETE, "complete", $l_i_Togo) Then Return False
		Else
			Out("[Step] Journey of the Master is already handed in")
		EndIf
		If Not Leveler_HasQuest($QUEST_ROAD_LESS) Then
			Out("[Step] Picking up The Road Less Traveled from Master Togo")
			If Not Leveler_QuestLoop($QUEST_ROAD_LESS, -92, 9217, $DIALOG_ROAD_ACCEPT, "accept", $l_i_Togo) Then Return False
		Else
			Out("[Step] The Road Less Traveled is already in the log")
		EndIf
		Out("[Step] Speaking to Guard Tsukaro to enter Saoshang Trail")
		If Not Leveler_TalkToGuardTsukaro() Then Return False
		If Map_GetMapID() <> $MAP_SAOSHANG Then
			If Not Map_WaitMapLoading($MAP_SAOSHANG) Then Return False
		EndIf
	EndIf

	If Map_GetMapID() = $MAP_SAOSHANG Then
		If Not Leveler_WaitUntilMapReady() Then Return False
		Out("[Step] Saoshang Trail. Caching UtilityAI, then fighting to Seitung Harbor.")
		If Not Leveler_CacheUtilityAIForMap($MAP_SAOSHANG) Then Return False
		If Not Leveler_QuestLoop($QUEST_ROAD_LESS, 1254, 10875, $DIALOG_ROAD_STEP2, "step") Then Return False
		If Not Leveler_MoveAndExit(16600, 13150, $MAP_SEITUNG, True) Then Return False
	EndIf

	If Map_GetMapID() <> $MAP_SEITUNG Then
		If Not Leveler_Travel($MAP_SEITUNG) Then Return False
	EndIf
	Leveler_SetPacifist()
	Leveler_MoveTo(16852, 12812, False)
	If Leveler_HasQuest($QUEST_ROAD_LESS) Or Leveler_QuestReadyForReward($QUEST_ROAD_LESS) Then
		If Not Leveler_QuestLoop($QUEST_ROAD_LESS, 16435, 12047, $DIALOG_ROAD_COMPLETE, "complete") Then Return False
	EndIf
	If Leveler_QuestNeedsHandIn($QUEST_ROAD_LESS) Or Leveler_HasQuest($QUEST_JOURNEY_MASTER) Then
		Out("[Step] The Road Less Traveled is not handed in yet")
		Return False
	EndIf
	Leveler_MarkQuestDone($QUEST_ROAD_LESS)
	Out("[Step] The Road Less Traveled complete. Arrived in Seitung Harbor.")
	Return True
EndFunc

; Buy mats and craft Seitung Harbor armor.
Func Leveler_Step_CraftSeitungArmor()
	$g_s_CurrentHeader = "Craft Seitung Armor"
	Out("=== " & $g_s_CurrentHeader & " ===")
	Local $l_ai_Pieces = Leveler_GetSeitungPieces()
	Out("[Craft] Profession " & Leveler_PrimaryProfession() & "  Gold " & Item_GetInventoryInfo("GoldCharacter") & "  First piece " & $l_ai_Pieces[0][0])
	If Leveler_ArmorSetEquipped($l_ai_Pieces) Then
		Out("[Step] Seitung armor is already equipped")
		Return True
	EndIf
	If Leveler_ArmorSetOwned($l_ai_Pieces) Then
		Out("[Step] Seitung armor already crafted. Equipping it.")
		Return Leveler_EquipArmorPieces($l_ai_Pieces)
	EndIf

	; Buy Seitung mats at the Shing Jea common-material trader, then craft in Seitung.
	If Not Leveler_SeitungMaterialsReady() Then
		If Not Leveler_Travel($MAP_SHING_JEA) Then Return False
		Leveler_SetPacifist()
		Item_WithdrawGold(15000)
		Sleep(400)
		Out("[Craft] Gold after withdraw: " & Item_GetInventoryInfo("GoldCharacter"))
		If Not Leveler_MoveTo(-10896.94, 10807.54, False) Then Return False
		If Not Leveler_InteractNpcAt(-10614.00, 10996.00, False) Then Return False
		Sleep(800)
		If Not Leveler_BuySeitungMaterials() Then Return False
		If Not Leveler_SeitungMaterialsReady() Then
			Out("[Craft] Materials still short after buying. Staying in Shing Jea.")
			Return False
		EndIf
	Else
		Out("[Craft] Seitung materials already in inventory")
	EndIf

	If Not Leveler_Travel($MAP_SEITUNG) Then Return False
	Leveler_SetPacifist()
	If Not Leveler_MoveTo(19823.66, 9547.78, False) Then Return False
	If Not Leveler_InteractNpcAt(20508.00, 9497.00, False) Then Return False
	If Not Leveler_CraftSeitungArmor() Then Return False
	If Not Leveler_ArmorSetEquipped($l_ai_Pieces) Then
		Out("[Step] Seitung armor was not equipped after crafting")
		Return False
	EndIf
	Return True
EndFunc

; Destroy leftover monastery armor after Seitung is equipped.
Func Leveler_Step_DestroyMonastery()
	$g_s_CurrentHeader = "Destroy Monastery Armor"
	Out("=== " & $g_s_CurrentHeader & " ===")
	Return Leveler_DestroyMonasteryArmor()
EndFunc

; Walk Jaya Bluffs / Haiju Lagoon to Zen Daijun.
Func Leveler_Step_ToZenDaijun()
	$g_s_CurrentHeader = "To Zen Daijun"
	Out("=== " & $g_s_CurrentHeader & " ===")
	Local $l_i_Map = Map_GetMapID()
	If $l_i_Map = $MAP_ZEN_OP And Map_GetInstanceInfo("IsOutpost") Then
		Out("[Step] Already at Zen Daijun")
		Return True
	EndIf

	If $l_i_Map <> $MAP_JAYA And $l_i_Map <> $MAP_HAIJU Then
		If Not Leveler_Travel($MAP_SEITUNG) Then Return False
		Leveler_PrepareForBattle()
		Agent_CancelAction()
		If Not Leveler_WaitUntilMapReady() Then Return False
		Sleep(800)
		Out("[Step] Pathfinding Seitung Harbor → Jaya Bluffs")
		If Not Leveler_PathToExit(16777, 17540, $MAP_JAYA, False) Then Return False
	EndIf

	If Map_GetMapID() = $MAP_JAYA Then
		If Not Leveler_CacheUtilityAIForMap($MAP_JAYA) Then Return False
		Out("[Step] Pathfinding Jaya Bluffs → Haiju Lagoon")
		If Not Leveler_PathToExit(23616, 1587, $MAP_HAIJU, True) Then Return False
	EndIf

	If Map_GetMapID() = $MAP_HAIJU Then
		If Not Leveler_CacheUtilityAIForMap($MAP_HAIJU) Then Return False
		Out("[Step] Pathfinding Haiju Lagoon → Zen Daijun")
		If Not Leveler_MoveTo(16489, -22213, True) Then
			If Map_GetMapID() = $MAP_ZEN_OP Then Return True
			Out("[Step] Pathfinder did not reach the Zen Daijun entrance")
			Return False
		EndIf
		If Map_GetMapID() = $MAP_ZEN_OP Then Return True
		Leveler_MoveAndDialog(16489, -22213, $DIALOG_FORMAL_SKIP, True)
		If Map_GetMapID() <> $MAP_ZEN_OP Then
			If Not Leveler_MoveAndExit(16489, -22213, $MAP_ZEN_OP, True) Then Return False
		EndIf
	EndIf

	If Map_GetMapID() <> $MAP_ZEN_OP Then Return False
	Out("[Step] Arrived at Zen Daijun")
	Return True
EndFunc

; Enter and complete Zen Daijun, then leave toward the docks.
Func Leveler_Step_ZenDaijunMission()
	$g_s_CurrentHeader = "Zen Daijun Mission"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Not Leveler_WaitUntilMapReady() Then Return False
	If Leveler_InMissionInstance($MAP_ZEN_EXP) Then
		Out("[Step] Already inside Zen Daijun")
	Else
		If Map_GetMapID() <> $MAP_ZEN_OP Or Not Map_GetInstanceInfo("IsOutpost") Then
			If Leveler_MissionPortalMap($MAP_ZEN_OP, Map_GetMapID()) Then
				If Not Leveler_ReturnToMissionOutpost($MAP_ZEN_OP) Then Return False
			Else
				If Not Leveler_Travel($MAP_ZEN_OP) Then Return False
			EndIf
		EndIf
		If Not Leveler_WaitUntilMapReady() Then Return False
		; Stage 1: henchmen. Skill bar is already set — do not reload it.
		Out("[Step] Add henchmen, then zone out and back before the mission")
		If Not Leveler_PrepareMissionParty() Then Return False
		; Stage 2: portal round-trip. Party packets plus Enter Challenge in this instance 007.
		If Not Leveler_SettlePartyForMission($MAP_ZEN_OP) Then Return False
		; Stage 3: native Ui_EnterChallenge. Do not add or remove henchmen after the portal.
		If Not Leveler_EnterMission("Zen Daijun", $MAP_ZEN_OP) Then Return False
	EndIf
	If Not Leveler_WaitUntilMapReady() Then Return False
	Leveler_EnsurePathfinder()
	; Zen can load as 213, 246, or 258. Cache whichever instance is actually explorable.
	If Not Leveler_CacheUtilityAIForMap(Map_GetMapID()) Then Return False
	If Leveler_IsWiped() Then Return False

	$g_b_SpiritRiftWatch = True
	$g_h_RiftCooldown = TimerInit()
	$g_b_CombatMode = True

	If Not Leveler_MoveTo(15120.68, 10456.73, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	Sleep(15000)
	If Not Leveler_MoveTo(11990.38, 10782.05, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	Sleep(10000)
	If Not Leveler_MoveTo(10161.92, 9751.41, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(9723.10, 7968.76, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_WaitOutOfCombat() Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_InteractGadgetAt(9632.00, 8058.00, True) Then
		Out("[Step] Gadget interact failed; continuing the path")
	EndIf
	If Not Leveler_MoveTo(9412.15, 7257.83, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(9183.47, 6653.42, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(8966.42, 6203.29, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(3510.94, 2724.63, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(2120.18, 1690.91, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(928.27, 2782.67, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(744.67, 4187.17, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(242.27, 6558.48, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(-4565.76, 8326.51, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(-5374.88, 8626.30, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(-10291.65, 8519.68, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(-11009.76, 6292.73, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(-12762.20, 6112.31, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(-14029.90, 3699.97, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(-13243.47, 1253.06, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(-11907.05, 28.87, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(-11306.09, 802.47, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	Sleep(5000)
	If Not Leveler_MoveTo(-10255.23, 178.48, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	If Not Leveler_MoveTo(-9068.41, -553.94, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	Sleep(5000)
	If Not Leveler_MoveTo(-7949.79, -1376.02, True) Then
		$g_b_SpiritRiftWatch = False
		Return False
	EndIf
	Leveler_MoveTo(-7688.63, -1538.34, True)
	$g_b_SpiritRiftWatch = False
	Out("[Step] Zen Daijun complete. Skipping cinematic and waiting for the next outpost")
	If Not Leveler_WaitMissionOutpost() Then Return False
	Out("[Step] Zen Daijun complete. Arrived on map " & Map_GetMapID())
	Return True
EndFunc

#EndRegion Shing Jea Island

#Region Kaineng
; Marketplace through Mox.

; Travel from Zen Daijun to The Marketplace.
Func Leveler_Step_ToMarketplace()
	$g_s_CurrentHeader = "To Marketplace"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Map_GetMapID() = $MAP_MARKETPLACE And Map_GetInstanceInfo("IsOutpost") Then
		Out("[Step] Already at The Marketplace")
		Return True
	EndIf

	If Map_GetMapID() <> $MAP_KAINENG_DOCKS Then
		If Not Leveler_Travel($MAP_SEITUNG) Then Return False
		If Not Leveler_HasQuest($QUEST_MASTERS_BURDEN) Then
			If Not Leveler_QuestLoop($QUEST_MASTERS_BURDEN, 16927, 9004, $DIALOG_BURDEN_ACCEPT, "accept") Then Return False
		EndIf
		If Not Leveler_QuestLoop($QUEST_MASTERS_BURDEN, 16927, 9004, $DIALOG_GENERIC_TALK, "step") Then
			If Map_GetMapID() <> $MAP_KAINENG_DOCKS Then Map_WaitMapLoading($MAP_KAINENG_DOCKS)
		EndIf
		If Map_GetMapID() <> $MAP_KAINENG_DOCKS Then
			If Not Map_WaitMapLoading($MAP_KAINENG_DOCKS) Then Return False
		EndIf
	EndIf

	If Not Leveler_QuestLoop($QUEST_MASTERS_BURDEN, 9955, 20033, $DIALOG_BURDEN_STEP2, "step") Then Return False
	If Not Leveler_MoveAndExit(12003, 18529, $MAP_MARKETPLACE, False) Then Return False
	Out("[Step] Arrived at The Marketplace")
	Return True
EndFunc

; Walk Bukdek / Wajjun to Kaineng Center.
Func Leveler_Step_ToKainengCenter()
	$g_s_CurrentHeader = "To Kaineng Center"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Map_GetMapID() = $MAP_KAINENG And Map_GetInstanceInfo("IsOutpost") Then
		Out("[Step] Already in Kaineng Center")
		Return True
	EndIf

	If Map_GetMapID() <> $MAP_BUKDEK Then
		If Not Leveler_Travel($MAP_MARKETPLACE) Then Return False
		Leveler_PrepareForBattle()
		If Not Leveler_MoveAndExit(16640, 19882, $MAP_BUKDEK, True) Then Return False
	Else
		Leveler_PrepareForBattle()
	EndIf

	If Not Leveler_MoveTo(-10254.0, -1759.0, True) Then Return False
	If Not Leveler_MoveTo(-10332.0, 1442.0, True) Then Return False
	If Not Leveler_MoveTo(-10965.0, 9309.0, True) Then Return False
	If Not Leveler_MoveTo(-9467.0, 14207.0, True) Then Return False
	If Not Leveler_MoveTo(-8601.28, 17419.64, True) Then Return False
	If Not Leveler_MoveTo(-6857.17, 19098.28, True) Then Return False
	If Not Leveler_MoveAndExit(-6706, 20388, $MAP_KAINENG, True) Then Return False
	Out("[Step] Arrived in Kaineng Center")
	Return True
EndFunc

; Buy Cry of Frustration, Power Drain, and Backfire at Kaineng.
Func Leveler_Step_CompleteSkillsTraining()
	$g_s_CurrentHeader = "Complete Skills Training"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_Skills2Unlocked() Then
		Out("[Step] Cry of Frustration and Power Drain already acquired")
		Return Leveler_EquipTrainerSkills()
	EndIf
	If Map_GetMapID() <> $MAP_KAINENG Or Not Map_GetInstanceInfo("IsOutpost") Then
		If Not Leveler_Travel($MAP_KAINENG) Then Return False
	EndIf
	Leveler_SetPacifist()
	If Not Leveler_BuyKainengInterrupts() Then Return False
	Out("[Step] Learnt Cry=" & World_IsSkillLearnt($SKILL_CRY_OF_FRUSTRATION) & " Drain=" & World_IsSkillLearnt($SKILL_POWER_DRAIN))
	If Not Leveler_Skills2Unlocked() Then
		Out("[Step] Michiko skills were not all learnt. Staying on the trainer.")
		Return False
	EndIf
	Out("[Step] Cry of Frustration and Power Drain learnt from Michiko")
	Return True
EndFunc

; Buy mats and craft Kaineng max armor.
Func Leveler_Step_CraftMaxArmor()
	$g_s_CurrentHeader = "Craft Max Armor"
	Out("=== " & $g_s_CurrentHeader & " ===")
	Local $l_ai_Pieces = Leveler_GetMaxArmorPieces()
	If Leveler_ArmorSetEquipped($l_ai_Pieces) Then
		Out("[Step] Max armor is already equipped")
		Return True
	EndIf
	If Leveler_ArmorSetOwned($l_ai_Pieces) Then
		Out("[Step] Max armor already crafted. Equipping it.")
		Return Leveler_EquipArmorPieces($l_ai_Pieces)
	EndIf

	If Not Leveler_Travel($MAP_KAINENG) Then Return False
	Leveler_SetPacifist()
	If Not Leveler_InterruptSkillsUnlocked() Then Leveler_BuyKainengInterrupts()
	If Not Leveler_MoveTo(1592.00, -796.00, False) Then Return False
	Item_WithdrawGold(20000)
	Sleep(400)
	Out("[Craft] Gold after withdraw: " & Item_GetInventoryInfo("GoldCharacter"))
	If Not Leveler_InteractNpcAt(1592.00, -796.00, False) Then Return False
	If Not Leveler_BuyMaxArmorMaterials(True) Then Return False
	Sleep(1500)

	Local $l_ai_RareM, $l_ai_RareC
	Leveler_GetMaxArmorMatNeeds(False, $l_ai_RareM, $l_ai_RareC)
	If UBound($l_ai_RareM) > 0 Then
		If Not Leveler_InteractNpcAt(1495.00, -1315.00, False) Then Return False
		If Not Leveler_BuyMaxArmorMaterials(False) Then Return False
		Sleep(2000)
	EndIf

	Local $l_f_X, $l_f_Y
	Leveler_GetMaxArmorCrafter($l_f_X, $l_f_Y)
	If Not Leveler_MoveTo($l_f_X, $l_f_Y, False) Then Return False
	If Not Leveler_InteractNpcAt($l_f_X, $l_f_Y, False) Then Return False
	Sleep(1000)
	If Not Leveler_CraftMaxArmor() Then Return False
	If Not Leveler_ArmorSetEquipped($l_ai_Pieces) Then
		Out("[Step] Max armor was not equipped after crafting")
		Return False
	EndIf
	Out("[Step] Max armor crafted and equipped")
	Return True
EndFunc

; Destroy leftover Seitung armor after max armor is on.
Func Leveler_Step_DestroySeitung()
	$g_s_CurrentHeader = "Destroy Seitung Armor"
	Out("=== " & $g_s_CurrentHeader & " ===")
	Return Leveler_DestroySeitungArmor()
EndFunc

; Run The Search For A Cure.
Func Leveler_Step_SearchForACure()
	$g_s_CurrentHeader = "Quest: The Search For A Cure"
	$g_b_CureStepLocked = True
	Out("=== " & $g_s_CurrentHeader & " ===")
	Leveler_LogQuestState($QUEST_SEARCH_CURE, "The Search For A Cure")
	If Leveler_SearchCureDone() Then
		Out("[Step] The Search For A Cure already completed")
		Return Leveler_AcceptBrotherTosai()
	EndIf

	; Mox unlock is after this chain. If Mox can join, Cure / Tosai are past / unavailable.
	If Leveler_MoxOrOliasAvailable() Then
		Out("[Step] Mox/Olias available — ignoring The Search For A Cure pickup")
		Leveler_MarkQuestDone($QUEST_SEARCH_CURE)
		$g_ab_StepDone[$LEVELER_STEP_CURE] = True
		Return True
	EndIf

	If Not Leveler_HasQuest($QUEST_SEARCH_CURE) Then
		If Not Leveler_Travel($MAP_KAINENG) Then Return False
		; Re-check in outpost: AddHero only works here.
		If Leveler_MoxOrOliasAvailable() Then
			Out("[Step] Mox/Olias available — ignoring The Search For A Cure pickup")
			Leveler_MarkQuestDone($QUEST_SEARCH_CURE)
			$g_ab_StepDone[$LEVELER_STEP_CURE] = True
			Return True
		EndIf
		; Imperial Agent Hanjo gives #336 — required before Seek out Brother Tosai.
		Out("[Step] Speaking to Imperial Agent Hanjo for The Search for a Cure")
		If Not Leveler_QuestLoop($QUEST_SEARCH_CURE, $HANJO_KAINENG_X, $HANJO_KAINENG_Y, $DIALOG_CURE_ACCEPT, "accept") Then
			; Mid-game: quest unavailable. Fresh characters must keep retrying Hanjo.
			If Leveler_MoxOrOliasAvailable() Or Leveler_QuestFinished($QUEST_SEARCH_CURE) Or Leveler_HasQuest($QUEST_BROTHER_TOSAI) Then
				Out("[Step] The Search For A Cure unavailable — treating as past and moving on")
				Leveler_MarkQuestDone($QUEST_SEARCH_CURE)
				$g_ab_StepDone[$LEVELER_STEP_CURE] = True
				Return Leveler_AcceptBrotherTosai()
			EndIf
			Out("[Step] Could not accept The Search For A Cure from Hanjo")
			Return False
		EndIf
		If Not Leveler_HasQuest($QUEST_SEARCH_CURE) Then
			If Leveler_MoxOrOliasAvailable() Or Leveler_QuestFinished($QUEST_SEARCH_CURE) Or Leveler_HasQuest($QUEST_BROTHER_TOSAI) Then
				Out("[Step] The Search For A Cure was not picked up — treating as past")
				Leveler_MarkQuestDone($QUEST_SEARCH_CURE)
				$g_ab_StepDone[$LEVELER_STEP_CURE] = True
				Return Leveler_AcceptBrotherTosai()
			EndIf
			Out("[Step] The Search For A Cure did not enter the log after talking to Hanjo")
			Return False
		EndIf
	EndIf

	If Leveler_ShouldResumeExplorable($QUEST_SEARCH_CURE) Then
		Out("[Step] The Search For A Cure is in the log and map " & Map_GetMapID() & " is not an outpost. Resuming from here.")
	EndIf

	If Leveler_QuestReadyForReward($QUEST_SEARCH_CURE) Then
		If Not Leveler_Travel($MAP_KAINENG) Then Return False
		If Not Leveler_QuestLoop($QUEST_SEARCH_CURE, $BUJO_KAINENG_X, $BUJO_KAINENG_Y, $DIALOG_CURE_COMPLETE, "complete") Then Return False
		If Leveler_HasIncompleteQuest($QUEST_SEARCH_CURE) Then
			Out("[Step] The Search For A Cure is still in the log after the complete dialog")
			Return False
		EndIf
		Out("[Step] The Search For A Cure complete")
		Return Leveler_AcceptBrotherTosai()
	EndIf

	If Map_GetMapID() = $MAP_KAINENG Then
		; Bujo advances #336 after Hanjo sends you to him.
		If Not Leveler_QuestLoop($QUEST_SEARCH_CURE, $BUJO_KAINENG_X, $BUJO_KAINENG_Y, $DIALOG_CURE_STEP, "step") Then Return False
	EndIf

	If Map_GetMapID() <> $MAP_WAJJUN Then
		If Leveler_ShouldResumeExplorable($QUEST_SEARCH_CURE) Then
			Out("[Step] Staying on map " & Map_GetMapID() & " to finish The Search For A Cure")
		Else
			If Not Leveler_GoToWajjun() Then Return False
		EndIf
	EndIf

	If Not Leveler_MoveTo(10350.00, 14100.00, True) Then Return False
	If Not Leveler_MoveTo(8300.00, 14100.00, True) Then Return False
	Leveler_LootNearby($MODEL_CURE_LOOT, 2000, 8000)
	Sleep(5000)

	If Not Leveler_Travel($MAP_KAINENG) Then Return False
	If Not Leveler_QuestLoop($QUEST_SEARCH_CURE, $BUJO_KAINENG_X, $BUJO_KAINENG_Y, $DIALOG_CURE_COMPLETE, "complete") Then
		If Not Leveler_HasIncompleteQuest($QUEST_SEARCH_CURE) Then
			Out("[Step] The Search For A Cure is no longer in the log. Treating the hand-in as done.")
			Leveler_MarkQuestDone($QUEST_SEARCH_CURE)
			Return Leveler_AcceptBrotherTosai()
		EndIf
		Return False
	EndIf
	If Leveler_QuestNeedsHandIn($QUEST_SEARCH_CURE) Or Leveler_HasIncompleteQuest($QUEST_SEARCH_CURE) Then
		Out("[Step] The Search For A Cure is still in the log")
		Return False
	EndIf
	Out("[Step] The Search For A Cure complete")
	Return Leveler_AcceptBrotherTosai()
EndFunc

; Run A Master's Burden and abandon leftover Brother Tosai.
Func Leveler_Step_AMastersBurden()
	$g_s_CurrentHeader = "Quest: A Master's Burden"
	Out("=== " & $g_s_CurrentHeader & " ===")
	Leveler_LogQuestState($QUEST_MASTERS_BURDEN, "A Master's Burden")
	If Leveler_MastersBurdenDone() Then
		Out("[Step] A Master's Burden already completed")
		Return True
	EndIf

	; To Marketplace accepts #349 in Seitung. Recover here if that was skipped.
	If Not Leveler_HasQuest($QUEST_MASTERS_BURDEN) Then
		If Not Leveler_Travel($MAP_SEITUNG) Then Return False
		If Not Leveler_QuestLoop($QUEST_MASTERS_BURDEN, 16927, 9004, $DIALOG_BURDEN_ACCEPT, "accept") Then Return False
	EndIf

	; Reward-ready: hand in at Kaineng Docks.
	If Leveler_QuestReadyForReward($QUEST_MASTERS_BURDEN) Then
		Return Leveler_MastersBurdenHandIn()
	EndIf

	; Marketplace → Wajjun path → docks hand-in.
	; Seek out Brother Tosai comes later after Imperial Agent Hanjo / Search for a Cure.
	Ui_ActiveQuest($QUEST_MASTERS_BURDEN)
	Sleep(300)

	If Map_GetMapID() <> $MAP_WAJJUN Then
		If Not Leveler_GoToWajjun() Then Return False
	Else
		Leveler_PrepareForBattle()
	EndIf

	If Not Leveler_WaitUntilMapReady() Then Return False
	If Not Leveler_CacheUtilityAIForMap($MAP_WAJJUN) Then Return False

	If Not Leveler_MoveTo(10033.88, 13838.59, True) Then Return False
	If Not Leveler_MoveTo(11637.23, 11837.92, True) Then Return False
	If Not Leveler_MoveTo(10007.72, 10951.80, True) Then Return False
	If Not Leveler_MoveTo(8200.78, 12134.04, True) Then Return False
	If Not Leveler_MoveTo(8133.31, 7629.99, True) Then Return False
	If Not Leveler_MoveTo(5329.09, 7626.73, True) Then Return False
	If Not Leveler_MoveTo(4145.20, 6584.09, True) Then Return False
	If Not Leveler_MoveTo(-1663.82, 7113.72, True) Then Return False
	If Not Leveler_QuestLoop($QUEST_MASTERS_BURDEN, -1893.00, 6922.00, $DIALOG_BURDEN_STEP2, "step", $MODEL_BROTHER_TOSAI) Then Return False
	If Not Leveler_MoveTo(4207.15, 6226.59, True) Then Return False
	If Not Leveler_MoveTo(4944.20, 3398.03, True) Then Return False
	If Not Leveler_MoveTo(4401.08, 618.24, True) Then Return False
	If Not Leveler_MoveTo(5802.95, -2295.56, True) Then Return False
	If Not Leveler_MoveTo(4671.93, -5007.46, True) Then Return False
	If Not Leveler_MoveTo(10774.00, -6636.00, True) Then Return False
	If Not Leveler_QuestLoop($QUEST_MASTERS_BURDEN, 10774.00, -6636.00, $DIALOG_BURDEN_STEP2, "step", $MODEL_BURDEN_NPC) Then Return False

	Return Leveler_MastersBurdenHandIn()
EndFunc

; Marketplace → Kaineng Docks hand-in for #349.
Func Leveler_MastersBurdenHandIn()
	If Map_GetMapID() <> $MAP_KAINENG_DOCKS Then
		If Not Leveler_Travel($MAP_MARKETPLACE) Then Return False
		If Not Leveler_MoveTo(12250, 18236, False) Then Return False
		If Not Leveler_MoveTo(10343, 20329, False) Then Return False
		If Not Map_WaitMapLoading($MAP_KAINENG_DOCKS) Then Return False
	EndIf
	If Not Leveler_QuestLoop($QUEST_MASTERS_BURDEN, 9950.00, 20033.00, $DIALOG_BURDEN_COMPLETE, "complete") Then Return False
	If Leveler_QuestNeedsHandIn($QUEST_MASTERS_BURDEN) Or Leveler_HasIncompleteQuest($QUEST_MASTERS_BURDEN) Then
		Out("[Step] A Master's Burden is still in the log")
		Return False
	EndIf
	Leveler_MarkQuestDone($QUEST_MASTERS_BURDEN)
	Out("[Step] A Master's Burden complete")
	Return True
EndFunc

; After The Search for a Cure (Hanjo → Bujo): accept Seek out Brother Tosai (#337) from Bujo.
Func Leveler_AcceptBrotherTosai()
	If Leveler_HasQuest($QUEST_BROTHER_TOSAI) Or Leveler_IsQuestDone($QUEST_BROTHER_TOSAI) Then
		Out("[Step] Seek out Brother Tosai already accepted or done")
		Return True
	EndIf
	Out("[Step] Accepting Seek out Brother Tosai from Bujo (after Hanjo / Search for a Cure)")
	If Map_GetMapID() <> $MAP_KAINENG Or Not Map_GetInstanceInfo("IsOutpost") Then
		If Not Leveler_Travel($MAP_KAINENG) Then Return False
	EndIf
	If Not Leveler_QuestLoop($QUEST_BROTHER_TOSAI, $BUJO_KAINENG_X, $BUJO_KAINENG_Y, $DIALOG_TOSAI_ACCEPT, "accept") Then Return False
	If Not Leveler_HasQuest($QUEST_BROTHER_TOSAI) And Not Leveler_IsQuestDone($QUEST_BROTHER_TOSAI) Then
		Out("[Step] Seek out Brother Tosai did not enter the log")
		Return False
	EndIf
	Out("[Step] Seek out Brother Tosai accepted")
	Return True
EndFunc

; Unlock Mox in Bukdek Byway and return to Kaineng.
Func Leveler_Step_UnlockMox()
	$g_s_CurrentHeader = "Unlock Mox"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_HasMoxUnlocked() Then
		Out("[Step] Mox is already unlocked")
		Return True
	EndIf
	If Leveler_ConfirmMoxInHeroList() Then
		Out("[Step] Mox is already on the hero list")
		Return True
	EndIf
	If Not Leveler_Travel($MAP_KAINENG) Then Return False
	Leveler_PrepareForBattle()
	If Not Leveler_MoveAndExit(3243, -4911, $MAP_BUKDEK, True) Then Return False
	If Not Leveler_MoveAndDialog(-5803.48, 18951.70, $DIALOG_UNLOCK_MOX, True) Then Return False
	Sleep(1000)
	If Not Leveler_Travel($MAP_KAINENG) Then Return False
	If Not Leveler_ConfirmMoxInHeroList() Then Return False
	Out("[Step] Mox unlocked and verified in the hero list")
	Return True
EndFunc

#EndRegion Kaineng

#Region Eye Of The North
; Boreal Station through the Auspicious Beginnings farm.

; Take I Feel the Earth Move and walk the Tunnels to Boreal Station.
Func Leveler_Step_ToBorealStation()
	$g_s_CurrentHeader = "To Boreal Station"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Not Leveler_HasMoxUnlocked() Then
		Out("[Step] Mox is not unlocked. Finish Unlock Mox before Boreal.")
		Return False
	EndIf
	If Map_GetMapID() = $MAP_BOREAL And Map_GetInstanceInfo("IsOutpost") Then
		Out("[Step] Already at Boreal Station")
		Return True
	EndIf

	If Map_GetMapID() <> $MAP_TUNNELS Then
		If Not Leveler_Travel($MAP_KAINENG) Then Return False
		Leveler_MoveTo(3444.90, -1728.31, False)
		If Not Leveler_HasQuest($QUEST_EARTH_MOVE) Then
			If Not Leveler_QuestLoop($QUEST_EARTH_MOVE, 3747.00, -2174.00, $DIALOG_EARTH_ACCEPT, "accept") Then Return False
		EndIf
		Leveler_MoveTo(3444.90, -1728.31, False)
		Leveler_PrepareForBattle()
		If Not Leveler_MoveAndExit(3243, -4911, $MAP_BUKDEK, True) Then Return False
		If Not Leveler_QuestLoop($QUEST_EARTH_MOVE, -10103.00, 16493.00, $DIALOG_GENERIC_TALK, "step") Then
			If Map_GetMapID() <> $MAP_TUNNELS Then Map_WaitMapLoading($MAP_TUNNELS, -1, 45000)
		EndIf
		If Map_GetMapID() <> $MAP_TUNNELS Then
			If Not Map_WaitMapLoading($MAP_TUNNELS, -1, 45000) Then Return False
		EndIf
	EndIf

	If Map_GetMapID() = $MAP_TUNNELS Then
		If Not Leveler_WaitUntilMapReady() Then Return False
	EndIf

	If Not Leveler_MoveTo(16738.77, 3046.05, True) Then Return False
	If Not Leveler_MoveTo(13028.36, 6146.36, True) Then Return False
	If Not Leveler_MoveTo(10968.19, 9623.72, True) Then Return False
	If Not Leveler_MoveTo(3918.55, 10383.79, True) Then Return False
	If Not Leveler_MoveTo(8435, 14378, True) Then Return False
	If Not Leveler_MoveTo(10134, 16742, True) Then Return False
	Sleep(3000)
	Leveler_SetPacifist()
	Leveler_SetHeroesBehavior(2)
	Out("[Step] Avoiding Destroyers. Running to the Boreal portal.")
	Local $l_af_Run[4][2] = [[4523.25, 15448.03], [-43.80, 18365.45], [-10234.92, 16691.96], [-17917.68, 18480.57]]
	Local $i
	For $i = 0 To 3
		If Map_GetMapID() = $MAP_BOREAL Then ExitLoop
		If Not Leveler_RunTo($l_af_Run[$i][0], $l_af_Run[$i][1]) Then
			Leveler_SetHeroesBehavior(0)
			Return False
		EndIf
	Next
	If Map_GetMapID() <> $MAP_BOREAL Then
		If Not Leveler_RunTo(-18775, 19097) Then
			Leveler_SetHeroesBehavior(0)
			Return False
		EndIf
		Local $l_i_StartMap = Map_GetMapID()
		For $i = 1 To 10
			If Map_GetMapID() <> $l_i_StartMap Then ExitLoop
			Map_MoveLayer(-18775, 19097, Agent_GetAgentInfo(-2, "Plane"))
			Sleep(400)
		Next
		If Map_GetMapID() <> $MAP_BOREAL Then
			Sleep(8000)
			If Not Map_WaitMapLoading($MAP_BOREAL, -1, 20000) Then
				Leveler_SetHeroesBehavior(0)
				Return False
			EndIf
		EndIf
	EndIf
	Leveler_SetHeroesBehavior(0)
	Out("[Step] Arrived at Boreal Station")
	Return True
EndFunc

; Walk Ice Cliff Chasms from Boreal into Eye of the North.
Func Leveler_Step_ToEyeOfTheNorth()
	$g_s_CurrentHeader = "To Eye of the North"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Map_GetMapID() = $MAP_HOM Then
		Out("[Step] Already in the Hall of Monuments")
		Return True
	EndIf
	If Map_GetMapID() = $MAP_EOTN And Map_GetInstanceInfo("IsOutpost") Then
		Out("[Step] At Eye of the North. Walking into the Hall of Monuments.")
		Return Leveler_EnterHallOfMonuments()
	EndIf

	If Map_GetMapID() <> $MAP_ICE_CLIFF Then
		If Not Leveler_Travel($MAP_BOREAL) Then Return False
		Leveler_PrepareForBattle()
		If Not Leveler_MoveAndExit(4684, -27869, $MAP_ICE_CLIFF, True) Then Return False
	Else
		Leveler_PrepareForBattle()
	EndIf

	If Not Leveler_MoveTo(3579.07, -22007.27, True) Then Return False
	Sleep(15000)
	If Leveler_GetAgentByModel($MODEL_DESTROYERS_NPC) <> 0 Then
		If Not Leveler_QuestLoop($QUEST_AGAINST_DESTROYERS, 0, 0, $DIALOG_DESTROYERS_STEP1, "step", $MODEL_DESTROYERS_NPC) Then
			Out("[Step] Against the Destroyers step 1 dialog failed; continuing if the quest is already in the log")
		EndIf
	EndIf
	If Not Leveler_HasQuest($QUEST_AGAINST_DESTROYERS) Then
		Out("[Step] Against the Destroyers is not in the log yet; the Hall of Monuments step will retry it")
	EndIf
	If Not Leveler_MoveTo(3743.31, -15862.36, True) Then Return False
	If Not Leveler_MoveTo(3607.21, -6937.32, True) Then Return False
	If Not Leveler_MoveTo(2557.23, -275.97, True) Then Return False
	If Not Leveler_MoveAndExit(-641.25, 2069.27, $MAP_EOTN, True) Then Return False
	Out("[Step] Arrived at Eye of the North. Entering the Hall of Monuments.")
	Return Leveler_EnterHallOfMonuments()
EndFunc

; Eye of the North outpost. Python walks (-4416.39, 4932.36) then the portal (-5198, 5595).
Func Leveler_EnterHallOfMonuments()
	If Map_GetMapID() = $MAP_HOM Then Return True
	If Map_GetMapID() <> $MAP_EOTN Then
		If Not Leveler_Travel($MAP_EOTN) Then Return False
	EndIf
	Leveler_SetPacifist()
	Out("[Step] Pathing to the Hall of Monuments portal")
	If Map_GetMapID() <> $MAP_HOM Then Leveler_OutpostMove(-4416.39, 4932.36, $MAP_HOM)
	If Map_GetMapID() = $MAP_HOM Then Return True

	Local $l_i_Attempt
	For $l_i_Attempt = 1 To 8
		If Map_GetMapID() = $MAP_HOM Then Return True
		Map_Move(-5198.00, 5595.00, 0)
		If Map_WaitMapLoading($MAP_HOM, -1, 4000) Then Return True
	Next
	If Map_GetMapID() = $MAP_HOM Then Return True
	Out("[Step] Failed to enter the Hall of Monuments from Eye of the North")
	Return False
EndFunc

; Unlock the Hall of Monuments pool and take Keiran's Bow.
Func Leveler_Step_UnlockEotnPool()
	$g_s_CurrentHeader = "Unlock Eye of the North Pool"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_ReachedGunnarsHold() Then
		Out("[Step] Character has entered Gunnar's Hold. Eye of the North pool is complete.")
		Return True
	EndIf
	If Leveler_HomHeroesTalked() Or Leveler_EotnPoolReady() Then
		Out("[Step] Hall of Monuments hero dialogs are done. Unlock Eye of the North Pool is complete.")
		Return True
	EndIf
	If Leveler_HasQuest($QUEST_AGAINST_DESTROYERS) Then
		Out("[Step] Against the Destroyers is in the log. Going to the Hall of Monuments.")
	Else
		Out("[Step] Against the Destroyers is not in the log yet. Pathing to the Hall of Monuments.")
	EndIf

	If Not Leveler_EnterHallOfMonuments() Then Return False

	Leveler_SetPacifist()
	; Gwen 6021 at -6583, 6672. Pool gadget 5959 is next to her — 0x63D then 0x63F.
	Out("[Step] Talking to Gwen")
	Leveler_MoveTo($GWEN_HOM_X, $GWEN_HOM_Y, False)
	If Not Leveler_TalkModel($MODEL_GWEN, $DIALOG_POOL_CINEMATIC) Then
		Leveler_MoveAndDialog($GWEN_HOM_X, $GWEN_HOM_Y, $DIALOG_POOL_CINEMATIC, False, $MODEL_GWEN)
	EndIf

	Out("[Step] Looking deep into the scrying pool")
	If Not Leveler_UseScryingPool() Then
		Out("[Step] Eye of the North pool dialog failed")
		Return False
	EndIf
	; Cinematic starts after 0x63F. Skip if already known, then talk to Gwen, Ogden, and Vekk.
	Leveler_WaitCinematic()
	If Map_GetMapID() <> $MAP_HOM Then Map_WaitMapLoading($MAP_HOM, -1, 30000)
	Sleep(500)

	Leveler_TalkHomHero($MODEL_GWEN, $GWEN_HOM_X, $GWEN_HOM_Y, $DIALOG_GWEN_TAPESTRY, "Gwen")
	Leveler_TalkHomHero($MODEL_GWEN, $GWEN_HOM_X, $GWEN_HOM_Y, $DIALOG_VANGUARD_STEP, "Gwen")
	If Not Leveler_HasKeiranBow() Then
		Leveler_TalkHomHero($MODEL_GWEN, $GWEN_HOM_X, $GWEN_HOM_Y, $DIALOG_KEIRAN_BOW, "Gwen")
	EndIf
	Leveler_TalkHomHero($MODEL_OGDEN, $OGDEN_HOM_X, $OGDEN_HOM_Y, $DIALOG_OGDEN_ALLIES, "Ogden Stonehealer")
	Leveler_TalkHomHero($MODEL_VEKK, $VEKK_HOM_X, $VEKK_HOM_Y, $DIALOG_VEKK_ASURA, "Vekk")

	Local $l_i_Bow = Item_FindItemByModelID($MODEL_KEIRAN_BOW)
	If $l_i_Bow <> 0 Then Item_EquipItem($l_i_Bow)
	If Not Leveler_HomHeroesTalked() Then
		Out("[Step] HoM hero quests are not all in the log yet. Retrying hero dialogs next pass.")
		Return False
	EndIf
	Leveler_MarkQuestDone($QUEST_AGAINST_DESTROYERS)

	Out("[Step] Leaving the Hall of Monuments")
	If Map_GetMapID() = $MAP_HOM Then
		If Not Leveler_Travel($MAP_EOTN) Then Return False
	EndIf
	If Map_GetMapID() <> $MAP_EOTN Then
		Out("[Step] Failed to reach Eye of the North from the Hall of Monuments")
		Return False
	EndIf
	If Not Leveler_TalkJoraOnIceCliff() Then Return False
	If Not Leveler_Step_ToGunnarsHold() Then Return False
	Out("[Step] Eye of the North pool unlocked. Tracking the Nornbear is in the log.")
	Return True
EndFunc

; Remaining uses on this kit model. Value is uses times the kit's value-per-use.
Func Leveler_ModelUses($a_i_Model, $a_f_ValuePerUse)
	If $a_f_ValuePerUse <= 0 Then Return 0
	Local $l_av_Inv = Item_GetInventoryArray()
	If Not IsArray($l_av_Inv) Then Return 0
	Local $l_i_Uses = 0
	Local $i
	For $i = 0 To UBound($l_av_Inv) - 1
		If $l_av_Inv[$i][$GC_I_INVENTORY_MODELID] <> $a_i_Model Then ContinueLoop
		$l_i_Uses += Int($l_av_Inv[$i][$GC_I_INVENTORY_VALUE] / $a_f_ValuePerUse)
	Next
	Return $l_i_Uses
EndFunc

; Remaining identification uses, or 999 when the infinite kit is owned.
Func Leveler_IdentifyKitUses()
	If Leveler_CountModel($GC_I_MODELID_INFINITE_IDENTIFICATION_KIT, False) > 0 Then Return 999
	Return Leveler_ModelUses($GC_I_MODELID_IDENTIFICATION_KIT, 2) + Leveler_ModelUses($GC_I_MODELID_SUPERIOR_IDENTIFICATION_KIT, 2.5)
EndFunc

; Remaining salvage uses, or 999 when the infinite kit is owned.
Func Leveler_SalvageKitUses()
	If Leveler_CountModel($GC_I_MODELID_INFINITE_SALVAGE_KIT, False) > 0 Then Return 999
	Return Leveler_ModelUses($GC_I_MODELID_SALVAGE_KIT, 2) _
			+ Leveler_ModelUses($GC_I_MODELID_EXPERT_SALVAGE_KIT, 8) _
			+ Leveler_ModelUses($GC_I_MODELID_SUPERIOR_SALVAGE_KIT, 10) _
			+ Leveler_ModelUses($GC_I_MODELID_CHARR_SALVAGE_KIT, 1) _
			+ Leveler_ModelUses($GC_I_MODELID_PERFECT_SALVAGE_KIT, 10)
EndFunc

; Buy one basic kit from the open Eye of the North merchant.
Func Leveler_BuyFarmKit($a_i_Model, $a_s_Label)
	Local $l_i_Bag, $l_i_Slot
	If Not Leveler_FindEmptyInventorySlot($l_i_Bag, $l_i_Slot) Then
		Out("[Farm] No empty bag slot for a " & $a_s_Label)
		Return False
	EndIf
	If Not Leveler_WaitForCrafterOffer($a_i_Model) Then
		Out("[Farm] Merchant is not selling " & $a_s_Label & " (model " & $a_i_Model & ")")
		Return False
	EndIf
	If Not Leveler_EnsureCharacterGold($KIT_GOLD_COST) Then
		Out("[Farm] Need " & $KIT_GOLD_COST & " gold for a " & $a_s_Label)
		Return False
	EndIf
	Local $l_i_Before = Leveler_CountModel($a_i_Model, False)
	Out("[Farm] Buying " & $a_s_Label & " (model " & $a_i_Model & ")")
	If Not Merchant_BuyItem($a_i_Model, 1, False) Then
		Out("[Farm] Buy failed for " & $a_s_Label)
		Return False
	EndIf
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < 4000
		Sleep(250)
		If Leveler_CountModel($a_i_Model, False) > $l_i_Before Then Return True
	WEnd
	Out("[Farm] " & $a_s_Label & " did not arrive in the bags")
	Return False
EndFunc

; Travel to Eye of the North and buy kits when identify or salvage uses are low.
Func Leveler_RestockFarmKits()
	Local $l_i_Id = Leveler_IdentifyKitUses()
	Local $l_i_Salvage = Leveler_SalvageKitUses()
	If $l_i_Id >= $FARM_KIT_MIN_USES And $l_i_Salvage >= $FARM_KIT_MIN_USES Then
		Out("[Farm] Kits ready (identify " & $l_i_Id & " uses, salvage " & $l_i_Salvage & " uses)")
		Return True
	EndIf

	Out("[Farm] Identify " & $l_i_Id & " uses, salvage " & $l_i_Salvage & " uses. Traveling to Eye of the North for kits.")
	Party_LeaveGroup(True)
	Sleep(400)
	If Map_GetInstanceInfo("IsLoading") Then
		If Not Leveler_WaitUntilMapReady() Then Return False
	EndIf
	If Not Leveler_Travel($MAP_EOTN) Then Return False

	Leveler_OutpostMove($EOTN_MERCHANT_X, $EOTN_MERCHANT_Y)
	Local $l_b_Open = False
	Local $l_i_Try
	For $l_i_Try = 1 To 3
		If Not Leveler_InteractNpcAt($EOTN_MERCHANT_X, $EOTN_MERCHANT_Y, False) Then
			Out("[Farm] Failed to reach the Eye of the North merchant (try " & $l_i_Try & ")")
			ContinueLoop
		EndIf
		If Leveler_WaitForMerchantWindow(5000) Then
			$l_b_Open = True
			ExitLoop
		EndIf
		Sleep(400)
	Next
	If Not $l_b_Open Then
		Out("[Farm] Eye of the North merchant window did not open")
		Return False
	EndIf

	If $l_i_Id < $FARM_KIT_MIN_USES Then
		If Not Leveler_BuyFarmKit($GC_I_MODELID_IDENTIFICATION_KIT, "Identification Kit") Then Return False
	EndIf
	If $l_i_Salvage < $FARM_KIT_MIN_USES Then
		If Not Leveler_BuyFarmKit($GC_I_MODELID_SALVAGE_KIT, "Salvage Kit") Then Return False
	EndIf
	Out("[Farm] Kits bought. Identify " & Leveler_IdentifyKitUses() & " uses, salvage " & Leveler_SalvageKitUses() & " uses.")
	Return True
EndFunc

; Repeat Kilroy Punch-Out Extravaganza until the character is level 20.
Func Leveler_Step_FarmUntil20()
	$g_s_CurrentHeader = "Farm Until Level 20"
	Local $l_i_Level = Leveler_PlayerLevel()
	If $l_i_Level >= 20 Then
		$g_b_FarmMode = True
		$g_b_KilroyMode = True
		If Leveler_IsPunchoutMap() And Agent_GetAgentInfo(-2, "CurrentEnergy") <= 0 Then
			Leveler_HandleKilroyDeath()
			Return False
		EndIf
		If Not Leveler_LeaveFarmAtLevel20() Then Return False
		Out("[Farm] Already level " & $l_i_Level)
		Return True
	EndIf

	$g_b_FarmMode = True
	$g_b_KilroyMode = True
	Out("=== " & $g_s_CurrentHeader & " (level " & $l_i_Level & ") via Kilroy Punch-Out Extravaganza ===")

	If Map_GetMapID() = $MAP_FRONIS Then
		If Not Leveler_RunFronisInstance() Then Return False
	Else
		If Not Leveler_RestockFarmKits() Then Return False
		If Not Leveler_HandleFronisOutpost() Then Return False
		If Map_GetMapID() = $MAP_FRONIS Then
			If Not Leveler_RunFronisInstance() Then Return False
		EndIf
	EndIf

	$l_i_Level = Leveler_PlayerLevel()
	Out("[Farm] End-of-run level: " & $l_i_Level)
	If $l_i_Level >= 20 Then Return Leveler_LeaveFarmAtLevel20()
	Return False
EndFunc

; Level 20 ends the farm. Leave Fronis or Kilroy, then the dispatcher advances.
Func Leveler_LeaveFarmAtLevel20()
	If Leveler_PlayerLevel() < 20 Then Return False
	If $g_b_KilroyRecovery Or (Leveler_IsPunchoutMap() And Agent_GetAgentInfo(-2, "CurrentEnergy") <= 0) Then Return False
	Local $l_i_Level = Leveler_PlayerLevel()
	Out("[Farm] Level " & $l_i_Level & ". Leaving the punch-out instance for the next step.")
	$g_b_FarmMode = False
	$g_b_KilroyMode = False
	If Map_GetMapID() = $MAP_FRONIS Or Map_GetMapID() = $MAP_KILROY Then
		If Map_GetInstanceInfo("IsLoading") Then
			If Not Leveler_WaitUntilMapReady() Then Return False
		EndIf
		If Map_GetMapID() = $MAP_FRONIS Or Map_GetMapID() = $MAP_KILROY Then
			If Not Leveler_Travel($MAP_GUNNAR) Then Return False
		EndIf
	EndIf
	Return True
EndFunc

; Walk to Kilroy Stonekin and open his dialog. Returns the agent id, or 0.
Func Leveler_OpenKilroy()
	If Map_GetInstanceInfo("IsLoading") Then Return 0
	Leveler_MoveTo($KILROY_NPC_X, $KILROY_NPC_Y, False)
	Local $l_i_Npc = Leveler_GetAgentByModel($MODEL_KILROY)
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetNearestNPCAt($KILROY_NPC_X, $KILROY_NPC_Y, 500)
	If $l_i_Npc = 0 Then $l_i_Npc = Leveler_GetAgentByName("Kilroy")
	If $l_i_Npc = 0 Then
		Out("[Farm] Kilroy Stonekin not found")
		Return 0
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
		Out("[Farm] Could not reach Kilroy Stonekin")
		Return 0
	EndIf
	Sleep(700)
	Return $l_i_Npc
EndFunc

; Game_Dialog sends the packet immediately. Up to three IDs, one open conversation.
Func Leveler_SendKilroyDialogs($a_s_Label, $a_i_Dialog1, $a_i_Dialog2 = 0, $a_i_Dialog3 = 0)
	If Leveler_OpenKilroy() = 0 Then Return False
	Out($a_s_Label)
	Game_Dialog($a_i_Dialog1)
	Sleep(500)
	If $a_i_Dialog2 <> 0 Then
		Game_Dialog($a_i_Dialog2)
		Sleep(500)
	EndIf
	If $a_i_Dialog3 <> 0 Then
		Game_Dialog($a_i_Dialog3)
		Sleep(500)
	EndIf
	Return True
EndFunc

; Punch-Out Extravaganza: intro 0x835803, accept 0x835801, enter 0x85, while Kilroy's dialog is open.
Func Leveler_HandleFronisOutpost()
	If Map_GetMapID() <> $MAP_GUNNAR Then
		If Not Leveler_Travel($MAP_GUNNAR) Then Return False
	EndIf
	Ui_SetDifficulty(False)
	Party_LeaveGroup(True)
	Sleep(400)
	Leveler_MoveTo($KILROY_NPC_X, $KILROY_NPC_Y, False)
	If Leveler_QuestReadyForReward($QUEST_PUNCH_EXTRAVAGANZA) Or Quest_GetQuestInfo($QUEST_PUNCH_EXTRAVAGANZA, "IsCompleted") Then
		Out("[Farm] Claiming Punch-Out Extravaganza reward")
		If Not Leveler_SendKilroyDialogs("[Farm] Reward dialogs 0x835803 then 0x835807", $DIALOG_FRONIS_INTRO, $DIALOG_FRONIS_REWARD) Then Return False
		Sleep(800)
		; The quest is offered again only after a district change.
		Out("[Farm] Punch-Out handed in. Swapping district so the quest is available again.")
		If Map_GetInstanceInfo("IsLoading") Then
			If Not Leveler_WaitOutpostSettled($MAP_GUNNAR) Then Return False
		EndIf
		If Not Leveler_Travel($MAP_GUNNAR, True) Then Return False
		If Not Leveler_WaitOutpostSettled($MAP_GUNNAR) Then Return False
		Leveler_MoveTo($KILROY_NPC_X, $KILROY_NPC_Y, False)
	EndIf

	Local $l_i_Try
	For $l_i_Try = 1 To 3
		If $g_b_LevelerPaused Then Return False
		If Map_GetMapID() = $MAP_FRONIS Or Map_GetInstanceInfo("IsLoading") Then ExitLoop
		If Not Leveler_SendKilroyDialogs("[Farm] Pickup 0x835801 and enter 0x85", $DIALOG_FRONIS_INTRO, $DIALOG_FRONIS_ACCEPT, $DIALOG_FRONIS_ENTER) Then
			Sleep(500)
			ContinueLoop
		EndIf
		Local $l_h_Wait = TimerInit()
		While Map_GetMapID() = $MAP_GUNNAR And Not Map_GetInstanceInfo("IsLoading") And TimerDiff($l_h_Wait) < 5000
			If $g_b_LevelerPaused Then Return False
			Sleep(200)
		WEnd
		If Map_GetMapID() <> $MAP_GUNNAR Or Map_GetInstanceInfo("IsLoading") Then ExitLoop
		Out("[Farm] Still in Gunnar's Hold. Sending the Fronis enter dialog again.")
		If Not Leveler_SendKilroyDialogs("[Farm] Enter dialog 0x85", $DIALOG_FRONIS_INTRO, $DIALOG_FRONIS_ENTER) Then
			Sleep(500)
			ContinueLoop
		EndIf
		$l_h_Wait = TimerInit()
		While Map_GetMapID() = $MAP_GUNNAR And Not Map_GetInstanceInfo("IsLoading") And TimerDiff($l_h_Wait) < 5000
			If $g_b_LevelerPaused Then Return False
			Sleep(200)
		WEnd
		If Map_GetMapID() <> $MAP_GUNNAR Or Map_GetInstanceInfo("IsLoading") Then ExitLoop
	Next

	If Not Leveler_WaitPunchoutInstance($MAP_FRONIS, 20000) Then
		Out("[Farm] Fronis Irontoe's Lair did not load")
		Return False
	EndIf
	Return True
EndFunc

; Clear Fronis Irontoe's Lair, take the chest, and return the Punch-Out reward.
Func Leveler_RunFronisInstance()
	If Map_GetMapID() <> $MAP_FRONIS Then Return False
	$g_b_CombatMode = True
	$g_b_KilroyMode = True
	If Not Leveler_WaitPunchoutInstance($MAP_FRONIS) Then Return False
	Out("[Farm] Fronis loaded. Equipping brass knuckles.")
	If Not Leveler_EquipBrassKnuckles() Then Return False
	If Not Leveler_MoveTo($FRONIS_START_X, $FRONIS_START_Y, True) Then Return False
	If Not Leveler_PrepareKilroyCombat() Then Return False
	Leveler_WaitOutOfCombat(30000)
	Leveler_LootNearby(0, 1500, 4000)

	Local $l_af_Path[10][2] = [ _
			[-15115.72, -15375.61], _
			[-11299.54, -16402.40], _
			[-7284.53, -16235.58], _
			[-4397.42, -16123.15], _
			[-1385.20, -14400.23], _
			[505.33, -14073.99], _
			[2959.12, -15991.76], _
			[5740.82, -15543.48], _
			[7157.02, -15755.44], _
			[12249.79, -16291.74] _
			]
	Local $i
	For $i = 0 To UBound($l_af_Path) - 1
		If $g_b_LevelerPaused Then Return False
		If Leveler_LeaveFarmAtLevel20() Then Return True
		If Leveler_IsWiped() And Not $g_b_KilroyMode Then Return False
		If $g_b_KilroyMode Then Leveler_HandleKilroyDeath()
		Out("[Farm] Fronis waypoint " & ($i + 1) & "/10")
		If Not Leveler_MoveTo($l_af_Path[$i][0], $l_af_Path[$i][1], True) Then
			If Leveler_PlayerLevel() >= 20 Then Return Leveler_LeaveFarmAtLevel20()
			If Map_GetMapID() <> $MAP_FRONIS Then Return True
		EndIf
		If Leveler_LeaveFarmAtLevel20() Then Return True
		Leveler_WaitOutOfCombat(30000)
		If Leveler_LeaveFarmAtLevel20() Then Return True
		Leveler_LootNearby(0, 1200, 3000)
		Local $l_h_Rest = TimerInit()
		While Agent_GetAgentInfo(-2, "HP") < 0.95 And TimerDiff($l_h_Rest) < 20000
			If $g_b_LevelerPaused Then Return False
			If $g_b_KilroyMode Then Leveler_HandleKilroyDeath()
			Sleep(400)
		WEnd
	Next

	If Leveler_LeaveFarmAtLevel20() Then Return True
	Out("[Farm] Opening the Fronis chest")
	Local $l_i_Chest = Leveler_GetNearestGadgetAt($FRONIS_CHEST_X, $FRONIS_CHEST_Y, 800)
	If $l_i_Chest <> 0 Then
		Leveler_MoveTo(Agent_GetAgentInfo($l_i_Chest, "X"), Agent_GetAgentInfo($l_i_Chest, "Y"), True)
		Local $l_h_Chest = TimerInit()
		While TimerDiff($l_h_Chest) < 5000
			If $g_b_KilroyMode Then Leveler_HandleKilroyDeath()
			Agent_GoSignpost($l_i_Chest)
			Sleep(800)
		WEnd
	EndIf
	Leveler_LootNearby(0, 2000, 10000)
	Out("[Farm] Fronis run finished. Returning to Gunnar's Hold.")
	If Not Leveler_Travel($MAP_GUNNAR) Then Return False
	Return True
EndFunc

#EndRegion Eye Of The North

#Region Post 20
; An Unwelcome Guest through remaining secondaries.

; Walk Seitung Harbor to Zunraa's shrine.
Func Leveler_SeitungZunraaPath()
	Local $l_af_Path[5][2] = [ _
			[16602.23, 11612.10], _
			[16886.80, 9577.24], _
			[16940.28, 9860.90], _
			[19243.22, 9093.26], _
			[19840.55, 7956.64] _
			]
	If Not Leveler_FollowCoords($l_af_Path, False) Then Return False
	If Not Leveler_InteractGadgetAt(19642.00, 7386.00, False) Then Return False
	Return Leveler_WaitMs(5000)
EndFunc

; Run An Unwelcome Guest (attribute quest 2) in Zen Daijun explorable.
Func Leveler_Step_AnUnwelcomeGuest()
	$g_s_CurrentHeader = "Quest: An Unwelcome Guest"
	Out("=== " & $g_s_CurrentHeader & " ===")
	$g_b_FarmMode = False
	$g_b_KilroyMode = False
	If Leveler_ReachedGunnarsHold() Then
		Out("[Step] Character has entered Gunnar's Hold. An Unwelcome Guest is complete.")
		Return True
	EndIf
	If Leveler_HasIncompleteQuest($QUEST_OLIAS) Or Leveler_OliasReadyToTurnIn() Then
		Out("[Step] Olias is in the log. Not returning to Seitung Harbor for An Unwelcome Guest.")
		Return True
	EndIf

	If Leveler_SkipIfQuestDone($QUEST_UNWELCOME, "An Unwelcome Guest") Then Return True
	If Leveler_ShouldResumeExplorable($QUEST_UNWELCOME) Then
		Out("[Step] An Unwelcome Guest is in the log and map " & Map_GetMapID() & " is not an outpost. Resuming from here.")
	EndIf

	If Map_GetMapID() <> $MAP_ZEN_EXP Then
		If Not Leveler_Travel($MAP_SEITUNG) Then Return False
		Party_LeaveGroup(True)
		Sleep(400)
		If Not Leveler_SeitungZunraaPath() Then Return False
		If Not Leveler_HasQuest($QUEST_UNWELCOME) Then
			If Not Leveler_QuestLoop($QUEST_UNWELCOME, 0, 0, $DIALOG_UNWELCOME_ACCEPT, "accept", $MODEL_ZUNRAA) Then Return False
		EndIf
		; Heroes are not unlocked yet. Seitung fills the party with henchmen only.
		Leveler_PrepareForBattle()
		If Not Leveler_MoveAndDialog(20350.00, 9087.00, $DIALOG_ZEN_SKIP, False) Then Return False
		If Not Leveler_WaitForMap($MAP_ZEN_EXP, 30000) Then Return False
	EndIf

	; PrepareForBattle caches in Seitung Harbor. Cache_SkillBar refuses an outpost, so that
	; call returns without binding CanUse. The new Zen Daijun instance has to be cached
	; after it is explorable, or the fight walks in with an empty skill cache.
	If Not Leveler_WaitUntilMapReady() Then Return False
	Out("[Step] Zen Daijun explorable. Caching UtilityAI for An Unwelcome Guest.")
	If Not Leveler_CacheUtilityAIForMap($MAP_ZEN_EXP) Then Return False
	$g_b_CombatMode = True
	Local $l_af_Out[11][2] = [ _
			[-13959.50, 6375.26], _
			[-14567.47, 1775.31], _
			[-12310.05, 2417.60], _
			[-12071.83, 294.29], _
			[-9972.85, 4141.29], _
			[-9331.86, 7932.66], _
			[-6353.09, 9385.63], _
			[247.80, 12070.21], _
			[-8180.59, 12189.97], _
			[-9540.45, 7760.86], _
			[-5038.08, 2977.42] _
			]
	If Not Leveler_FollowCoords($l_af_Out, True) Then Return False
	If Not Leveler_InteractGadgetAt(-4862.00, 3005.00, True) Then Return False
	If Not Leveler_MoveTo(-9643.93, 7759.69, True) Then Return False
	If Not Leveler_WaitMs(5000) Then Return False

	$g_b_CombatMode = False
	If Not Leveler_MoveTo(-8294.21, 10061.62, False) Then Return False
	If Not Leveler_CombatBurst(5000) Then Return False
	If Not Leveler_MoveTo(-6473.26, 8771.21, False) Then Return False
	If Not Leveler_CombatBurst(5000) Then Return False
	If Not Leveler_MoveTo(-6365.32, 10234.20, False) Then Return False
	If Not Leveler_CombatBurst(5000) Then Return False
	$g_b_CombatMode = True
	If Not Leveler_MoveTo(-8655.04, -769.98, True) Then Return False
	If Not Leveler_WaitMs(5000) Then Return False

	$g_b_CombatMode = False
	If Not Leveler_MoveTo(-6744.75, -1842.97, False) Then Return False
	If Not Leveler_CombatBurst(10000) Then Return False
	If Not Leveler_MoveTo(-7720.80, -905.19, False) Then Return False
	If Not Leveler_CombatBurst(5000) Then Return False
	$g_b_CombatMode = True

	Local $l_af_Return[13][2] = [ _
			[-5016.76, -8800.93], _
			[3268.68, -6118.96], _
			[3808.16, -830.31], _
			[536.95, 2452.17], _
			[599.18, 12088.79], _
			[3605.82, 2336.79], _
			[5509.49, 1978.54], _
			[11313.49, 3755.03], _
			[12442.71, 8301.94], _
			[8133.23, 7540.54], _
			[15029.96, 10187.60], _
			[14062.33, 13088.72], _
			[11775.22, 11310.60] _
			]
	If Not Leveler_FollowCoords($l_af_Return, True) Then Return False
	If Not Leveler_InteractGadgetAt(11665, 11386, True) Then Return False

	$g_b_CombatMode = False
	If Not Leveler_MoveTo(12954.96, 9288.47, False) Then Return False
	If Not Leveler_CombatBurst(5000) Then Return False
	If Not Leveler_MoveTo(12507.05, 11450.91, False) Then Return False
	If Not Leveler_CombatBurst(5000) Then Return False
	$g_b_CombatMode = True
	If Not Leveler_MoveTo(7709.06, 4550.47, True) Then Return False
	If Not Leveler_WaitMs(5000) Then Return False

	$g_b_CombatMode = False
	If Not Leveler_MoveTo(9334.25, 5746.98, False) Then Return False
	If Not Leveler_CombatBurst(5000) Then Return False
	If Not Leveler_MoveTo(7554.94, 6159.84, False) Then Return False
	If Not Leveler_CombatBurst(5000) Then Return False
	If Not Leveler_MoveTo(9242.30, 6127.45, False) Then Return False
	If Not Leveler_CombatBurst(5000) Then Return False
	$g_b_CombatMode = True
	If Not Leveler_MoveTo(4855.66, 1521.21, True) Then Return False
	If Not Leveler_InteractGadgetAt(4754, 1451, True) Then Return False
	If Not Leveler_MoveTo(2958.13, 6410.57, True) Then Return False

	$g_b_CombatMode = False
	If Not Leveler_MoveTo(2683.69, 8036.28, False) Then Return False
	If Not Leveler_CombatBurst(8000) Then Return False
	If Not Leveler_MoveTo(3366.55, -5996.11, False) Then Return False
	If Not Leveler_CombatBurst(10000) Then Return False
	If Not Leveler_MoveTo(1866.87, -5454.60, False) Then Return False
	If Not Leveler_CombatBurst(5000) Then Return False
	If Not Leveler_MoveTo(3322.93, -5703.29, False) Then Return False
	If Not Leveler_CombatBurst(5000) Then Return False
	If Not Leveler_MoveTo(1855.78, -5376.80, False) Then Return False
	If Not Leveler_CombatBurst(5000) Then Return False
	$g_b_CombatMode = True
	If Not Leveler_MoveTo(-8655.04, -769.98, True) Then Return False
	If Not Leveler_MoveTo(-7453.22, -1483.71, True) Then Return False
	If Not Leveler_WaitOutOfCombat(120000) Then Return False

	If Not Leveler_Travel($MAP_SEITUNG) Then Return False
	Leveler_SetPacifist()
	If Not Leveler_SeitungZunraaPath() Then Return False
	Leveler_TalkModel($MODEL_ZUNRAA, $DIALOG_UNWELCOME_COMPLETE)
	If Not Leveler_QuestLoop($QUEST_UNWELCOME, 0, 0, $DIALOG_UNWELCOME_COMPLETE, "complete", $MODEL_ZUNRAA) Then Return False
	Out("[Step] An Unwelcome Guest complete")
	Return True
EndFunc

; Walk Eye of the North -> Ice Cliff -> Norrhart into Gunnar's Hold.
Func Leveler_Step_ToGunnarsHold()
	$g_s_CurrentHeader = "To Gunnar's Hold"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_ReachedGunnarsHold() Then
		Out("[Step] Already at Gunnar's Hold")
		Return True
	EndIf
	If Map_GetMapID() = $MAP_GUNNAR And Map_GetInstanceInfo("IsOutpost") Then
		If Leveler_HasNornbearTracking() Then
			Out("[Step] Already at Gunnar's Hold with Tracking the Nornbear")
			Return True
		EndIf
		Out("[Step] At Gunnar's Hold but Tracking the Nornbear is missing. Returning to Ice Cliff Chasms for Jora.")
		If Not Leveler_ExitEotnToIceCliff() Then Return False
	EndIf

	If Map_GetMapID() <> $MAP_ICE_CLIFF And Map_GetMapID() <> $MAP_NORRHART Then
		If Not Leveler_ExitEotnToIceCliff() Then Return False
	EndIf

	If Map_GetMapID() = $MAP_ICE_CLIFF Then
		$g_b_CombatMode = True
		If Not Leveler_TalkJoraOnIceCliff() Then Return False
		Out("[Step] Tracking the Nornbear is in the quest log. Continuing to Gunnar's Hold.")
		Local $l_af_Ice[4][2] = [ _
				[2548.84, 7266.08], _
				[1233.76, 13803.42], _
				[978.88, 21837.26], _
				[-4031.0, 27872.0] _
				]
		Leveler_FollowCoords($l_af_Ice, True)
		If Not Leveler_WaitForMap($MAP_NORRHART, 45000) Then Return False
	EndIf

	$g_b_CombatMode = True
	If Not Leveler_MoveTo(14546.0, -6043.0, True) Then Return False
	If Not Leveler_MoveAndExit(15578, -6548, $MAP_GUNNAR, True) Then Return False
	If Not Leveler_HasNornbearTracking() Then
		Out("[Step] Arrived at Gunnar's Hold without Tracking the Nornbear")
		Return False
	EndIf
	Out("[Step] Arrived at Gunnar's Hold with Tracking the Nornbear")
	Return True
EndFunc

; AU3 Module_34: MoveAndFight to arena, then wait until map 703 ends.
Func Leveler_FinishPunchClownFight()
	Local Const $l_f_ArenaX = 19290.50
	Local Const $l_f_ArenaY = -11552.23

	Out("[Step] Fighting Punch the Clown. Staying in the instance until it ends.")
	$g_b_CombatMode = True
	If Not Leveler_PrepareKilroyCombat() Then Return False

	; One walk to the arena — do not restart MoveAndFight every half-second.
	Leveler_MoveAndFight($l_f_ArenaX, $l_f_ArenaY)

	Local $l_h_Timer = TimerInit()
	While Map_GetMapID() = $MAP_KILROY And Not Map_GetInstanceInfo("IsLoading") And TimerDiff($l_h_Timer) < 120000
		If $g_b_LevelerPaused Then Return False
		; The instance unloads as soon as the clown dies. A move or skill during that load crashes the client.
		If Leveler_KilroyFoeCount(1500) > 0 Then
			Leveler_HandleKilroyDeath()
			Leveler_KilroyCombatTick(1500, True)
		EndIf
		Sleep(100)
	WEnd

	If Map_GetInstanceInfo("IsLoading") Or Map_GetMapID() <> $MAP_KILROY Then
		Out("[Step] Punch the Clown ended. Waiting for Gunnar's Hold to finish loading.")
		Return Leveler_WaitOutpostSettled($MAP_GUNNAR)
	EndIf
	If Leveler_QuestReadyForReward($QUEST_PUNCH_CLOWN) Then Return Leveler_WaitOutpostSettled($MAP_GUNNAR)
	Out("[Step] Punch the Clown fight timed out.")
	Return False
EndFunc

; Punch the Clown returns to Gunnar on its own. Do not Map_TravelTo while that load is in progress.
Func Leveler_WaitOutpostSettled($a_i_MapID, $a_i_Timeout = 60000)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		If $g_b_LevelerPaused Then Return False
		If Map_GetMapID() = $a_i_MapID And Map_GetInstanceInfo("IsOutpost") And Leveler_ClientIsReady() Then
			Sleep(1500)
			If Map_GetMapID() = $a_i_MapID And Leveler_ClientIsReady() And Not Map_GetInstanceInfo("IsLoading") Then Return True
		EndIf
		Sleep(200)
	WEnd
	Return Map_GetMapID() = $a_i_MapID And Map_GetInstanceInfo("IsOutpost") And Leveler_ClientIsReady()
EndFunc

; One Punch the Clown dialog. A map change runs the clown fight. Staying in Gunnar's Hold means it is already done.
Func Leveler_Step_UnlockKilroy()
	$g_s_CurrentHeader = "Unlock Kilroy Stonekin"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If $g_b_PunchClownSettled Or Leveler_SkipIfQuestDone($QUEST_PUNCH_CLOWN, "Punch the Clown") Then Return True

	$g_b_CombatMode = True
	$g_b_KilroyMode = True

	If Map_GetMapID() = $MAP_KILROY Or (Map_GetInstanceInfo("IsLoading") And Map_GetMapID() <> $MAP_GUNNAR And Map_GetMapID() <> $MAP_FRONIS) Then
		Out("[Step] Already in Punch the Clown. Finishing the fight.")
		If Not Leveler_RunPunchClownInstance() Then
			$g_b_KilroyMode = False
			Return False
		EndIf
		Leveler_SettlePunchClown()
		$g_b_KilroyMode = False
		Out("[Step] Punch the Clown finished. It will not be started again.")
		Return True
	EndIf

	If Not Leveler_Travel($MAP_GUNNAR) Then
		$g_b_KilroyMode = False
		Return False
	EndIf

	Local $l_i_Before = Map_GetMapID()
	Local $l_b_Sent = False
	If Not Leveler_HasQuest($QUEST_PUNCH_CLOWN) Then
		$l_b_Sent = Leveler_SendKilroyDialogs("[Step] Punch the Clown dialog once (0x835A01, 0x84)", $DIALOG_PUNCH_ACCEPT, $DIALOG_GENERIC_TALK)
	Else
		$l_b_Sent = Leveler_SendKilroyDialogs("[Step] Punch the Clown dialog once (0x84)", $DIALOG_GENERIC_TALK)
	EndIf
	If Not $l_b_Sent Then
		$g_b_KilroyMode = False
		Return False
	EndIf

	Local $l_h_Wait = TimerInit()
	While Map_GetMapID() = $l_i_Before And Not Map_GetInstanceInfo("IsLoading") And TimerDiff($l_h_Wait) < 8000
		If $g_b_LevelerPaused Then
			$g_b_KilroyMode = False
			Return False
		EndIf
		Sleep(200)
	WEnd

	If Map_GetMapID() <> $l_i_Before Or Map_GetInstanceInfo("IsLoading") Then
		Out("[Step] Punch the Clown instance changed. Running the clown fight.")
		If Not Leveler_RunPunchClownInstance() Then
			$g_b_KilroyMode = False
			Return False
		EndIf
		Leveler_SettlePunchClown()
		$g_b_KilroyMode = False
		Out("[Step] Punch the Clown finished. It will not be started again.")
		Return True
	EndIf

	Out("[Step] Still in Gunnar's Hold. Punch the Clown is already complete. Starting Punch-Out.")
	Leveler_SettlePunchClown()
	$g_b_FarmMode = True
	If Not Leveler_HandleFronisOutpost() Then
		$g_b_KilroyMode = False
		Return False
	EndIf
	If Map_GetMapID() = $MAP_FRONIS Then
		If Not Leveler_RunFronisInstance() Then
			$g_b_KilroyMode = False
			Return False
		EndIf
	EndIf
	$g_b_KilroyMode = False
	Out("[Step] Punch-Out run finished. Punch the Clown will not be started again.")
	Return True
EndFunc

; Fight Punch the Clown, then hand the quest back in Gunnar's Hold.
Func Leveler_RunPunchClownInstance()
	If Not Leveler_WaitKilroyInstance() And Map_GetMapID() <> $MAP_KILROY Then
		Out("[Step] Punch the Clown map did not load")
		Return False
	EndIf
	Out("[Step] Equipping brass knuckles (24897)")
	If Not Leveler_EquipBrassKnuckles() Then Return False
	Sleep(3000)
	If Not Leveler_PrepareKilroyCombat() Then
		Out("[Step] Brawling skill cache failed after equipping knuckles")
		Return False
	EndIf
	If Not Leveler_FinishPunchClownFight() Then Return False
	If Not Leveler_WaitOutpostSettled($MAP_GUNNAR) Then
		If Not Leveler_ClientIsReady() Or Map_GetInstanceInfo("IsLoading") Then
			Out("[Step] Gunnar's Hold did not finish loading after Punch the Clown")
			Return False
		EndIf
		If Map_GetMapID() <> $MAP_GUNNAR Then
			If Not Leveler_Travel($MAP_GUNNAR) Then Return False
		EndIf
	EndIf
	If Leveler_HasQuest($QUEST_PUNCH_CLOWN) Then
		Leveler_QuestLoop($QUEST_PUNCH_CLOWN, 17341.00, -4796.00, $DIALOG_PUNCH_COMPLETE, "complete")
	EndIf
	Sleep(800)
	If Leveler_ClientIsReady() And Not Map_GetInstanceInfo("IsLoading") Then Leveler_EquipModel($MODEL_KEIRAN_BOW)
	Return True
EndFunc

; Take Chaos in Kryta from Kaineng and travel to Lion's Arch.
Func Leveler_Step_ToLionsArch()
	$g_s_CurrentHeader = "To Lion's Arch"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Map_GetMapID() = $MAP_LIONS_ARCH And Map_GetInstanceInfo("IsOutpost") And Leveler_IsQuestDone($QUEST_CHAOS_KRYTA) Then
		Out("[Step] Already in Lion's Arch")
		Return True
	EndIf

	If Map_GetMapID() <> $MAP_BEJUNKAN And Map_GetMapID() <> $MAP_LIONS_GATE And Map_GetMapID() <> $MAP_LIONS_ARCH Then
		If Not Leveler_Travel($MAP_KAINENG) Then Return False
		Leveler_SetPacifist()
		Local $l_af_Kc[4][2] = [ _
				[3049.35, -2020.75], _
				[2739.30, -3710.67], _
				[-648.30, -3493.72], _
				[-1661.91, -636.09] _
				]
		If Not Leveler_FollowCoords($l_af_Kc, False) Then Return False
		If Not Leveler_HasQuest($QUEST_CHAOS_KRYTA) Then
			If Not Leveler_QuestLoop($QUEST_CHAOS_KRYTA, -1006.97, -817.63, $DIALOG_CHAOS_ACCEPT, "accept") Then Return False
		EndIf
		If Not Leveler_MoveAndExit(-2439, 1732, $MAP_BEJUNKAN, False) Then Return False
	EndIf

	If Map_GetMapID() = $MAP_BEJUNKAN Then
		Local $l_af_Pier[5][2] = [ _
				[-2995.68, 2077.20], _
				[-6938.10, 4286.61], _
				[-6064.40, 5300.26], _
				[-2396.20, 5260.67], _
				[-5031.77, 6001.52] _
				]
		If Not Leveler_FollowCoords($l_af_Pier, False) Then Return False
		If Not Leveler_MoveTo(-5626.17, 7017.33, False) Then Return False
		If Not Leveler_QuestLoop($QUEST_CHAOS_KRYTA, 0, 0, $DIALOG_CHAOS_STEP1, "step", $MODEL_CHAOS_STEP1) Then
			If Map_GetMapID() = $MAP_BEJUNKAN Then Return False
		EndIf
		If Map_GetMapID() = $MAP_BEJUNKAN Then
			If Not Leveler_MoveTo(-4661.13, 7479.86, False) Then Return False
			If Not Leveler_QuestLoop($QUEST_CHAOS_KRYTA, 0, 0, $DIALOG_GENERIC_TALK, "step", $MODEL_CHAOS_STEP2) Then
				If Map_GetMapID() = $MAP_BEJUNKAN Then Return False
			EndIf
		EndIf
		If Not Leveler_WaitForMap($MAP_LIONS_GATE, 45000) And Map_GetMapID() <> $MAP_LIONS_ARCH Then Return False
	EndIf

	If Map_GetMapID() = $MAP_LIONS_GATE Then
		If Not Leveler_MoveTo(-1181, 1038, False) Then Return False
		If Not Leveler_QuestLoop($QUEST_CHAOS_KRYTA, 0, 0, $DIALOG_CHAOS_STEP3, "step", $MODEL_CHAOS_STEP3) Then
			If Map_GetMapID() = $MAP_LIONS_GATE Then Return False
		EndIf
	EndIf

	If Not Leveler_Travel($MAP_LIONS_ARCH) Then Return False
	If Leveler_HasQuest($QUEST_CHAOS_KRYTA) Then
		If Not Leveler_QuestLoop($QUEST_CHAOS_KRYTA, 328.00, 9594.00, $DIALOG_CHAOS_COMPLETE, "complete") Then Return False
	EndIf
	Out("[Step] Arrived at Lion's Arch")
	Return True
EndFunc

; Take Sunspears in Cantha and travel to Kamadan.
Func Leveler_Step_ToKamadan()
	$g_s_CurrentHeader = "To Kamadan"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If (Map_GetMapID() = $MAP_KAMADAN Or Map_GetMapID() = $MAP_SUN_DOCKS) And Leveler_IsQuestDone($QUEST_SUNSPEARS_CANTHA) Then
		Out("[Step] Sunspears in Cantha already complete")
		Return True
	EndIf

	If Map_GetMapID() <> $MAP_BEJUNKAN And Map_GetMapID() <> $MAP_KC_SUNSPEARS And Map_GetMapID() <> $MAP_SUN_DOCKS Then
		If Not Leveler_Travel($MAP_KAINENG) Then Return False
		Local $l_ai_Hench[3] = [2, 12, 9]
		Leveler_PrepareHeroTeam($l_ai_Hench)
		Local $l_af_Kc[4][2] = [ _
				[3049.35, -2020.75], _
				[2739.30, -3710.67], _
				[-648.30, -3493.72], _
				[-1661.91, -636.09] _
				]
		If Not Leveler_FollowCoords($l_af_Kc, False) Then Return False
		If Not Leveler_HasQuest($QUEST_SUNSPEARS_CANTHA) Then
			If Not Leveler_QuestLoop($QUEST_SUNSPEARS_CANTHA, -1131.99, 818.35, $DIALOG_SUNSPEARS_ACCEPT, "accept") Then Return False
		EndIf
		If Not Leveler_MoveAndExit(-2439, 1732, $MAP_BEJUNKAN, False) Then Return False
	EndIf

	If Map_GetMapID() = $MAP_BEJUNKAN Then
		Local $l_af_Pier[5][2] = [ _
				[-2995.68, 2077.20], _
				[-6938.10, 4286.61], _
				[-6064.40, 5300.26], _
				[-2396.20, 5260.67], _
				[-5031.77, 6001.52] _
				]
		If Not Leveler_FollowCoords($l_af_Pier, False) Then Return False
		If Not Leveler_MoveTo(-5899.57, 7240.19, False) Then Return False
		If Not Leveler_QuestLoop($QUEST_SUNSPEARS_CANTHA, 0, 0, $DIALOG_SUNSPEARS_STEP1, "step", $MODEL_SUNSPEARS_NPC, $DIALOG_SUNSPEARS_MULTI) Then
			If Map_GetMapID() = $MAP_BEJUNKAN Then Return False
		EndIf
		If Not Leveler_WaitForMap($MAP_KC_SUNSPEARS, 45000) And Map_GetMapID() <> $MAP_KC_SUNSPEARS Then Return False
	EndIf

	If Map_GetMapID() = $MAP_KC_SUNSPEARS Then
		$g_b_CombatMode = True
		Local $l_af_A[3][2] = [[-1712.16, -700.23], [-907.97, -2862.29], [742.42, -4167.73]]
		If Not Leveler_FollowCoords($l_af_A, True) Then Return False
		If Not Leveler_WaitMs(10000) Then Return False
		Local $l_af_B[3][2] = [[1352.94, -3694.75], [2547.49, -3667.82], [2541.67, -2582.88]]
		If Not Leveler_FollowCoords($l_af_B, True) Then Return False
		If Not Leveler_WaitMs(10000) Then Return False
		If Not Leveler_MoveTo(1990.27, -1636.21, True) Then Return False
		If Not Leveler_WaitMs(15000) Then Return False
		Local $l_af_C[2][2] = [[2651.48, -3750.63], [3355.63, -2151.82]]
		If Not Leveler_FollowCoords($l_af_C, True) Then Return False
		If Not Leveler_WaitMs(10000) Then Return False
		If Not Leveler_MoveTo(4565.37, -1630.73, True) Then Return False
		If Not Leveler_WaitMs(15000) Then Return False
		Local $l_af_D[3][2] = [[2951.07, -723.50], [2875.84, 488.42], [1354.73, 583.06]]
		If Not Leveler_FollowCoords($l_af_D, True) Then Return False
		If Not Leveler_WaitForMap($MAP_BEJUNKAN, 45000) Then Return False
	EndIf

	If Map_GetMapID() = $MAP_BEJUNKAN Then
		If Not Leveler_WaitMs(2000) Then Return False
		If Not Leveler_QuestLoop($QUEST_SUNSPEARS_CANTHA, 0, 0, $DIALOG_GENERIC_TALK, "step", $MODEL_SUNSPEARS_NPC) Then
			If Map_GetMapID() = $MAP_BEJUNKAN Then Return False
		EndIf
		If Not Leveler_WaitForMap($MAP_SUN_DOCKS, 45000) Then Return False
	EndIf

	If Map_GetMapID() = $MAP_SUN_DOCKS Then
		If Not Leveler_WaitMs(2000) Then Return False
		If Not Leveler_QuestLoop($QUEST_SUNSPEARS_CANTHA, 0, 0, $DIALOG_SUNSPEARS_COMPLETE, "complete", $MODEL_SUNSPEARS_COMPLETE) Then Return False
	EndIf
	Out("[Step] Arrived toward Kamadan")
	Return True
EndFunc

; Unlock Consulate Docks from Kamadan.
Func Leveler_Step_ToConsulateDocks()
	$g_s_CurrentHeader = "To Consulate Docks"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Map_GetMapID() = $MAP_DOCKS And Map_GetInstanceInfo("IsOutpost") Then
		Out("[Step] Already at Consulate Docks")
		Return True
	EndIf

	If Map_GetMapID() <> $MAP_CONSULATE Then
		If Not Leveler_Travel($MAP_KAINENG) Then Return False
		Party_LeaveGroup(True)
		Sleep(300)
		If Not Leveler_Travel($MAP_KAMADAN) Then Return False
		If Not Leveler_MoveTo(-8075.89, 14592.47, False) Then Return False
		If Not Leveler_MoveTo(-6743.29, 16663.21, False) Then Return False
		If Not Leveler_MoveAndExit(-5271.00, 16740.00, $MAP_CONSULATE, False) Then Return False
	EndIf

	If Not Leveler_MoveAndDialog(-4631.86, 16711.79, $DIALOG_UNLOCK_DOCKS, False) Then Return False
	If Not Leveler_WaitForMap($MAP_DOCKS, 30000) Then Return False
	Out("[Step] Arrived at Consulate Docks")
	Return True
EndFunc

; Already in Lion's Arch with the quest in the log: walk to Figo and continue. Do not go to the docks or Kamadan.
Func Leveler_OliasContinueAtFigo()
	If Map_GetMapID() = $MAP_LIONS_ARCH And Leveler_IsOutpost() And Leveler_HasQuest($QUEST_OLIAS) And Not Leveler_QuestReadyForReward($QUEST_OLIAS) Then
		Return True
	EndIf
	Return False
EndFunc

; Open Figo and send 0x84 while that window is open. Same ID as the Python leveler step.
; Ui_Dialog only queues the packet, so the window was already closed when the ID went out.
Func Leveler_SendLionguardFigoDialogs($a_f_X, $a_f_Y)
	Local $l_i_Figo = Leveler_GetAgentByName("Figo")
	If $l_i_Figo = 0 Then $l_i_Figo = Leveler_ResolveTalkNpc($a_f_X, $a_f_Y)
	If $l_i_Figo = 0 Then
		Out("[Step] Lionguard Figo not found")
		Return False
	EndIf
	Agent_ChangeTarget($l_i_Figo)
	Sleep(150)
	Agent_GoNPC($l_i_Figo)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < 5000
		If Agent_GetDistance($l_i_Figo) < $LEVELER_ARRIVE_RANGE Then ExitLoop
		Sleep(100)
	WEnd
	If Agent_GetDistance($l_i_Figo) >= $LEVELER_ARRIVE_RANGE Then
		Out("[Step] Could not reach Lionguard Figo")
		Return False
	EndIf
	Sleep(400)
	Out("[Step] Lionguard Figo dialog 0x84")
	Game_Dialog($DIALOG_OLIAS_FIGO)
	Sleep(400)
	Return True
EndFunc

; Walk to Lionguard Figo and send 0x84.
Func Leveler_TalkToLionguardFigo()
	Local $l_f_FigoX = -1137.00
	Local $l_f_FigoY = 2501.00
	Out("[Step] Walking to Lionguard Figo to continue All for One and One for Justice.")
	If Map_GetMapID() <> $MAP_LIONS_ARCH Then
		Party_LeaveGroup(True)
		Sleep(300)
		If Not Leveler_Travel($MAP_LIONS_ARCH) Then Return False
	EndIf
	Party_LeaveGroup(True)
	Sleep(300)
	Local $l_ai_Hench[1] = [1]
	Leveler_PrepareHeroTeam($l_ai_Hench)
	If Map_GetMapID() = $MAP_LIONS_ARCH And Agent_GetDistanceToXY($l_f_FigoX, $l_f_FigoY) < 600 Then
		Out("[Step] Already near Lionguard Figo. Skipping the walk.")
	Else
		If Not Leveler_MoveTo(1413.11, 9255.51, False) Then Return False
		If Not Leveler_MoveTo(242.96, 6130.82, False) Then Return False
		If Not Leveler_MoveTo($l_f_FigoX, $l_f_FigoY, False) Then Return False
	EndIf
	If Not Leveler_SendLionguardFigoDialogs($l_f_FigoX, $l_f_FigoY) Then
		If Map_GetMapID() = $MAP_LIONS_ARCH Then Return False
	EndIf
	If Not Leveler_WaitForMap($MAP_BLOODSTONE_FEN, 45000) And Map_GetMapID() <> $MAP_BLOODSTONE_FEN Then Return False
	Return True
EndFunc

; Run the Olias unlock quest from Consulate Docks.
Func Leveler_Step_UnlockOlias()
	$g_s_CurrentHeader = "Unlock Olias"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Leveler_HasOliasUnlocked() Then
		Out("[Step] Olias is already on the hero list")
		Return True
	EndIf
	If Leveler_SkipIfQuestDone($QUEST_OLIAS, "All for One and One for Justice") Then
		If Leveler_ConfirmOliasInHeroList() Then Return True
	EndIf

	If Leveler_OliasContinueAtFigo() Then
		Out("[Step] Already in Lion's Arch. All for One and One for Justice is in the quest log.")
		If Not Leveler_TalkToLionguardFigo() Then Return False
	Else
		If Leveler_OliasReadyToTurnIn() Or Map_GetMapID() = $MAP_KAMADAN Then
			Return Leveler_OliasReturnToKamadan()
		EndIf

		If Not Leveler_HasQuest($QUEST_OLIAS) Then
			If Not Leveler_Travel($MAP_DOCKS) Then Return False
			If Not Leveler_QuestLoop($QUEST_OLIAS, -2367.00, 16796.00, $DIALOG_OLIAS_ACCEPT, "accept") Then Return False
		EndIf

		If Map_GetMapID() <> $MAP_BLOODSTONE_FEN Then
			If Not Leveler_TalkToLionguardFigo() Then Return False
		EndIf
	EndIf

	If Map_GetMapID() = $MAP_BLOODSTONE_FEN Then
		If Not Leveler_WaitMs(3000) Then Return False
		If Not Leveler_QuestLoop($QUEST_OLIAS, 5117.00, 10515.00, $DIALOG_OLIAS_STEP2, "step") Then
			Out("[Step] Olias step 2 dialog failed; continuing the path")
		EndIf
		$g_b_CombatMode = True
		If Not Leveler_MoveTo(8518.10, 9309.66, True) Then Return False
		If Not Leveler_MoveTo(8067.40, 5703.23, True) Then Return False
		If Not Leveler_MoveTo(5657.20, 4485.55, True) Then Return False
		If Not Leveler_MoveTo(4461.65, -710.88, True) Then Return False
		If Not Leveler_MoveTo(10750, 2100, True) Then Return False
		Leveler_WaitMs(20000)
		$g_b_OliasFenDone = True
		If Map_GetMapID() = $MAP_BLOODSTONE_FEN Then
			If Not Leveler_WaitForMap($MAP_LIONS_ARCH, 60000) Then
				Out("[Step] Bloodstone Fen did not dump to Lion's Arch. Traveling to Kamadan anyway.")
			EndIf
		EndIf
	EndIf

	Return Leveler_OliasReturnToKamadan()
EndFunc

; Travel to Kamadan and hand in All for One and One for Justice.
Func Leveler_OliasReturnToKamadan()
	$g_b_OliasFenDone = True
	$g_b_CombatMode = False
	Out("[Step] Quest updated. Returning to Kamadan.")
	If Map_GetMapID() = $MAP_BLOODSTONE_FEN Then
		If Not Leveler_WaitForMap($MAP_LIONS_ARCH, 30000) Then
			Out("[Step] Leaving Bloodstone Fen to travel to Kamadan")
		EndIf
	EndIf
	Party_LeaveGroup(True)
	Sleep(300)
	If Not Leveler_Travel($MAP_KAMADAN) Then Return False
	If Not Leveler_MoveTo(-8149.02, 14900.65, False) Then Return False
	If Not Leveler_QuestLoop($QUEST_OLIAS, -6480.00, 16331.00, $DIALOG_OLIAS_COMPLETE, "complete") Then Return False
	; The reward can still be closing. Party packets during that window 007.
	Leveler_WaitOutpostSettled($MAP_KAMADAN, 20000)
	If Not Leveler_ConfirmOliasInHeroList() Then Return False
	Out("[Step] Olias unlocked")
	Return True
EndFunc

; Dialog IDs used at the Great Temple to unlock remaining secondaries.
Func Leveler_UnlockTrainerDialogs()
	Local $l_i_Prof = Leveler_PrimaryProfession()
	Local $l_ai_All[10] = [ _
			$DIALOG_PROF_WARRIOR, _
			$DIALOG_PROF_RANGER, _
			$DIALOG_PROF_MONK, _
			$DIALOG_PROF_NECRO, _
			$DIALOG_PROF_MESMER, _
			$DIALOG_PROF_ELE, _
			$DIALOG_PROF_ASSASSIN, _
			$DIALOG_PROF_RIT, _
			$DIALOG_PROF_PARA, _
			$DIALOG_PROF_DERV _
			]
	Local $l_ai_Skip[10] = [ _
			$GC_I_PROFESSION_WARRIOR, _
			$GC_I_PROFESSION_RANGER, _
			$GC_I_PROFESSION_MONK, _
			$GC_I_PROFESSION_NECROMANCER, _
			$GC_I_PROFESSION_MESMER, _
			$GC_I_PROFESSION_ELEMENTALIST, _
			$GC_I_PROFESSION_ASSASSIN, _
			$GC_I_PROFESSION_RITUALIST, _
			$GC_I_PROFESSION_PARAGON, _
			$GC_I_PROFESSION_DERVISH _
			]
	Local $i
	For $i = 0 To 9
		If $l_ai_Skip[$i] = $l_i_Prof Then ContinueLoop
		Leveler_TalkModel($MODEL_GTOB_TRAINER, $l_ai_All[$i])
		Sleep(400)
	Next
	Return True
EndFunc

; Unlock leftover secondary professions at the Great Temple of Balthazar.
Func Leveler_Step_UnlockSecondaryProfs()
	$g_s_CurrentHeader = "Unlock Remaining Secondary Professions"
	Out("=== " & $g_s_CurrentHeader & " ===")
	If Not Leveler_WantsAllSecondaries() Then
		Out("[Step] Unlock All Secondary Professions is off. Not spending gold at the trainers.")
		Return True
	EndIf
	If Leveler_RemainingSecondariesUnlocked() Then
		Out("[Step] All professions are already available to select")
		Return True
	EndIf
	If Not Leveler_Travel($MAP_GTOB) Then Return False
	Item_WithdrawGold(5000)
	Sleep(400)
	If Not Leveler_MoveTo(-5540.40, -5733.11, False) Then Return False
	If Not Leveler_MoveTo(-3151.22, -7255.13, False) Then Return False
	Leveler_UnlockTrainerDialogs()
	Sleep(1500)
	If Leveler_RemainingSecondariesUnlocked() Then
		Out("[Step] All professions including Paragon and Dervish are available to select")
	Else
		$g_b_SecondaryProfsTalked = True
		Out("[Step] Secondary profession trainers talked")
	EndIf
	Return True
EndFunc

#EndRegion Post 20
