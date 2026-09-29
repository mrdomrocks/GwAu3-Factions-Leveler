#include-once

; Progress flags, skip rules, and the GUI status check that picks the next step.

#Region Progress
; Gold on the character, not storage.
Func Leveler_CharacterGold()
	Return Item_GetInventoryInfo("GoldCharacter")
EndFunc

; Lost Treasure or later means this character already passed the monastery tutorial.
Func Leveler_HasPostXunlaiProgress()
	If Leveler_QuestProgress($QUEST_LOST_TREASURE) Then Return True
	If Leveler_HasLaterQuest() Then Return True
	Return False
EndFunc

; True after Formal Introduction is accepted or later tutorial progress exists.
Func Leveler_HasFormalOrLater()
	If Leveler_HasQuest($QUEST_FORMAL_INTRO) Then Return True
	If Leveler_QuestFinished($QUEST_FORMAL_INTRO) Then Return True
	If Leveler_HasPostXunlaiProgress() Then Return True
	; Skills / Cho happen after #318 is accepted. Do not send them back to Togo.
	If Leveler_HasSecondaryProfession() And Not Leveler_QuestInLog($QUEST_SECONDARY) And Leveler_ZhaoDiSkillsUnlocked() Then Return True
	Return False
EndFunc

; #317 gold is granted on Togo's complete dialog, not when the secondary is assigned.
; Once #317 has left the log the gold may already be spent on Xunlai / crafts.
Func Leveler_SecondaryRewardTaken()
	If Leveler_QuestInLog($QUEST_SECONDARY) Then Return False
	If Not Leveler_HasSecondaryProfession() Then Return False
	Return True
EndFunc

; Leave Unlock Secondary only after #317 is turned in and #318 is accepted or later.
Func Leveler_SecondaryStepReadyToLeave()
	If Not Leveler_HasSecondaryProfession() Then Return False
	If Leveler_QuestInLog($QUEST_SECONDARY) Then Return False
	If Not Leveler_HasFormalOrLater() Then Return False
	Return True
EndFunc

; Formal Introduction is finished only after Kayao's Accept removes it from the log.
Func Leveler_FormalIntroductionTurnedIn()
	If Leveler_QuestInLog($QUEST_FORMAL_INTRO) Then Return False
	If Leveler_HasPostXunlaiProgress() Then Return True
	If Quest_GetQuestInfo($QUEST_FORMAL_INTRO, "IsCompleted") Then Return True
	Local $l_i_Map = Map_GetMapID()
	If Leveler_HasSecondaryProfession() And ($l_i_Map = $MAP_CHO_OUTPOST Or $l_i_Map = $MAP_RAN_MUSU Or $l_i_Map = $MAP_CHO_EXPLORABLE) Then Return True
	Return False
EndFunc

; True when this quest is handed in (or its special-case finish check passes).
Func Leveler_QuestFinished($a_i_QuestID)
	If $a_i_QuestID = $QUEST_SECONDARY Then Return Leveler_SecondaryRewardTaken()
	If $a_i_QuestID = $QUEST_FORMAL_INTRO Then Return Leveler_FormalIntroductionTurnedIn()
	If $a_i_QuestID = $QUEST_ROAD_LESS Then Return Leveler_RoadLessTraveledDone()
	If $a_i_QuestID = $QUEST_SEARCH_CURE Then Return Leveler_SearchCureDone()
	If $a_i_QuestID = $QUEST_MASTERS_BURDEN Then Return Leveler_MastersBurdenDone()
	If Leveler_QuestNeedsHandIn($a_i_QuestID) Then Return False
	If Quest_GetQuestInfo($a_i_QuestID, "IsCompleted") Then Return True
	If Leveler_IsQuestDone($a_i_QuestID) Then Return True
	Return False
EndFunc

; Map a quest ID to its $LEVELER_Q_* flag index, or -1.
Func Leveler_QuestFlagIndex($a_i_QuestID)
	Switch $a_i_QuestID
		Case $QUEST_FORMING_A_PARTY
			Return $LEVELER_Q_FORMING
		Case $QUEST_SECONDARY
			Return $LEVELER_Q_SECONDARY
		Case $QUEST_FORMAL_INTRO
			Return $LEVELER_Q_FORMAL
		Case $QUEST_LOST_TREASURE
			Return $LEVELER_Q_LOST
		Case $QUEST_WARNING_TENGU
			Return $LEVELER_Q_TENGU
		Case $QUEST_THREAT_GROWS
			Return $LEVELER_Q_THREAT
		Case $QUEST_JOURNEY_MASTER
			Return $LEVELER_Q_JOURNEY
		Case $QUEST_ROAD_LESS
			Return $LEVELER_Q_ROAD
		Case $QUEST_SEARCH_CURE
			Return $LEVELER_Q_CURE
		Case $QUEST_BROTHER_TOSAI
			Return $LEVELER_Q_TOSAI
		Case $QUEST_MASTERS_BURDEN
			Return $LEVELER_Q_BURDEN
		Case $QUEST_EARTH_MOVE
			Return $LEVELER_Q_EARTH
		Case $QUEST_AGAINST_DESTROYERS
			Return $LEVELER_Q_DESTROYERS
		Case $QUEST_MISSING_VANGUARD
			Return $LEVELER_Q_VANGUARD
		Case $QUEST_NORTHERN_ALLIES
			Return $LEVELER_Q_ALLIES
		Case $QUEST_KNOWLEDGEABLE_ASURA
			Return $LEVELER_Q_ASURA
		Case $QUEST_UNWELCOME
			Return $LEVELER_Q_UNWELCOME
		Case $QUEST_NORNBEAR
			Return $LEVELER_Q_NORNBEAR
		Case $QUEST_PUNCH_CLOWN
			Return $LEVELER_Q_PUNCH
		Case $QUEST_CHAOS_KRYTA
			Return $LEVELER_Q_CHAOS
		Case $QUEST_SUNSPEARS_CANTHA
			Return $LEVELER_Q_SUNSPEARS
		Case $QUEST_OLIAS
			Return $LEVELER_Q_OLIAS
	EndSwitch
	Return -1
EndFunc

; Map a $LEVELER_Q_* flag index back to its quest ID.
Func Leveler_QuestIDFromFlag($a_i_Flag)
	Switch $a_i_Flag
		Case $LEVELER_Q_FORMING
			Return $QUEST_FORMING_A_PARTY
		Case $LEVELER_Q_SECONDARY
			Return $QUEST_SECONDARY
		Case $LEVELER_Q_FORMAL
			Return $QUEST_FORMAL_INTRO
		Case $LEVELER_Q_LOST
			Return $QUEST_LOST_TREASURE
		Case $LEVELER_Q_TENGU
			Return $QUEST_WARNING_TENGU
		Case $LEVELER_Q_THREAT
			Return $QUEST_THREAT_GROWS
		Case $LEVELER_Q_JOURNEY
			Return $QUEST_JOURNEY_MASTER
		Case $LEVELER_Q_ROAD
			Return $QUEST_ROAD_LESS
		Case $LEVELER_Q_CURE
			Return $QUEST_SEARCH_CURE
		Case $LEVELER_Q_TOSAI
			Return $QUEST_BROTHER_TOSAI
		Case $LEVELER_Q_BURDEN
			Return $QUEST_MASTERS_BURDEN
		Case $LEVELER_Q_EARTH
			Return $QUEST_EARTH_MOVE
		Case $LEVELER_Q_DESTROYERS
			Return $QUEST_AGAINST_DESTROYERS
		Case $LEVELER_Q_VANGUARD
			Return $QUEST_MISSING_VANGUARD
		Case $LEVELER_Q_ALLIES
			Return $QUEST_NORTHERN_ALLIES
		Case $LEVELER_Q_ASURA
			Return $QUEST_KNOWLEDGEABLE_ASURA
		Case $LEVELER_Q_UNWELCOME
			Return $QUEST_UNWELCOME
		Case $LEVELER_Q_NORNBEAR
			Return $QUEST_NORNBEAR
		Case $LEVELER_Q_PUNCH
			Return $QUEST_PUNCH_CLOWN
		Case $LEVELER_Q_CHAOS
			Return $QUEST_CHAOS_KRYTA
		Case $LEVELER_Q_SUNSPEARS
			Return $QUEST_SUNSPEARS_CANTHA
		Case $LEVELER_Q_OLIAS
			Return $QUEST_OLIAS
	EndSwitch
	Return 0
EndFunc

; True when the sticky run flag (or QuestFinished) says this quest is done.
Func Leveler_IsQuestDone($a_i_QuestID)
	Local $l_i_Flag = Leveler_QuestFlagIndex($a_i_QuestID)
	If $l_i_Flag < 0 Then Return Leveler_QuestFinished($a_i_QuestID)
	Return $g_ab_QuestDone[$l_i_Flag] = True
EndFunc

; Set the sticky flag if the quest is not still in the log.
Func Leveler_MarkQuestDone($a_i_QuestID, $a_b_Force = False)
	If Not $a_b_Force And Leveler_HasIncompleteQuest($a_i_QuestID) Then Return
	Local $l_i_Flag = Leveler_QuestFlagIndex($a_i_QuestID)
	If $l_i_Flag < 0 Then Return
	$g_ab_QuestDone[$l_i_Flag] = True
EndFunc

; Active or turned-in on THIS character. Do not use bare HasQuest leftovers.
Func Leveler_QuestProgress($a_i_QuestID)
	If Leveler_HasIncompleteQuest($a_i_QuestID) Then Return True
	If Leveler_QuestFinished($a_i_QuestID) Then Return True
	Return False
EndFunc

; Rebuild completion flags from the quest log. Only infer earlier quests from
; later quests that are still in progress or actually finished.
Func Leveler_RefreshQuestFlags($a_b_Reset = False)
	Local $i
	If $a_b_Reset Then
		For $i = 0 To $LEVELER_Q_COUNT - 1
			$g_ab_QuestDone[$i] = False
		Next
	EndIf

	For $i = 0 To $LEVELER_Q_COUNT - 1
		Local $l_i_QuestID = Leveler_QuestIDFromFlag($i)
		If $l_i_QuestID = 0 Then ContinueLoop
		If Leveler_HasIncompleteQuest($l_i_QuestID) Then
			$g_ab_QuestDone[$i] = False
		ElseIf Leveler_QuestFinished($l_i_QuestID) Then
			$g_ab_QuestDone[$i] = True
		EndIf
	Next

	If Leveler_SecondaryRewardTaken() Then
		Leveler_MarkQuestDone($QUEST_SECONDARY)
		Leveler_MarkQuestDone($QUEST_FORMING_A_PARTY)
	EndIf
	If Leveler_QuestProgress($QUEST_SECONDARY) Or Leveler_QuestProgress($QUEST_FORMAL_INTRO) Then
		Leveler_MarkQuestDone($QUEST_FORMING_A_PARTY)
	EndIf
	If Leveler_QuestProgress($QUEST_LOST_TREASURE) Or Leveler_HasLaterQuest() Then
		Leveler_MarkQuestDone($QUEST_FORMAL_INTRO)
		Leveler_MarkQuestDone($QUEST_SECONDARY)
		Leveler_MarkQuestDone($QUEST_FORMING_A_PARTY)
	EndIf
	If Not Leveler_QuestNeedsHandIn($QUEST_LOST_TREASURE) Then
		If Leveler_QuestProgress($QUEST_WARNING_TENGU) Or Leveler_QuestFinished($QUEST_WARNING_TENGU) Or Leveler_QuestProgress($QUEST_THREAT_GROWS) Or Leveler_QuestProgress($QUEST_JOURNEY_MASTER) Or Leveler_QuestProgress($QUEST_ROAD_LESS) Then
			Leveler_MarkQuestDone($QUEST_LOST_TREASURE)
		EndIf
	EndIf
	If Not Leveler_QuestNeedsHandIn($QUEST_WARNING_TENGU) Then
		If Leveler_QuestFinished($QUEST_WARNING_TENGU) Or Leveler_QuestProgress($QUEST_THREAT_GROWS) Or Leveler_QuestProgress($QUEST_JOURNEY_MASTER) Or Leveler_QuestProgress($QUEST_ROAD_LESS) Then
			Leveler_MarkQuestDone($QUEST_WARNING_TENGU)
		EndIf
	EndIf
	If Leveler_QuestProgress($QUEST_JOURNEY_MASTER) Or Leveler_QuestProgress($QUEST_ROAD_LESS) Then
		Leveler_MarkQuestDone($QUEST_THREAT_GROWS)
	EndIf
	If Leveler_QuestProgress($QUEST_ROAD_LESS) Then
		Leveler_MarkQuestDone($QUEST_JOURNEY_MASTER)
	EndIf
	If Leveler_HasIncompleteQuest($QUEST_BROTHER_TOSAI) Then
		; Seek out Brother Tosai is only offered after The Search for a Cure.
		Leveler_MarkQuestDone($QUEST_SEARCH_CURE)
	EndIf
	If Leveler_SearchCureDone() Then Leveler_MarkQuestDone($QUEST_SEARCH_CURE)
	If Leveler_MastersBurdenDone() Then
		Leveler_MarkQuestDone($QUEST_MASTERS_BURDEN)
	EndIf
	If Leveler_QuestFinished($QUEST_AGAINST_DESTROYERS) Then
		Leveler_MarkQuestDone($QUEST_EARTH_MOVE)
		Leveler_MarkQuestDone($QUEST_AGAINST_DESTROYERS)
	EndIf
	If Leveler_QuestProgress($QUEST_NORTHERN_ALLIES) Or Leveler_QuestProgress($QUEST_KNOWLEDGEABLE_ASURA) Then
		Leveler_MarkQuestDone($QUEST_MISSING_VANGUARD)
	EndIf
	If Leveler_QuestProgress($QUEST_KNOWLEDGEABLE_ASURA) Then
		Leveler_MarkQuestDone($QUEST_NORTHERN_ALLIES)
	EndIf
EndFunc

; Log a skip and return True when the named quest is already finished.
Func Leveler_SkipIfQuestDone($a_i_QuestID, $a_s_Name)
	If $a_i_QuestID = $QUEST_SEARCH_CURE And Leveler_SearchCureDone() Then
		Leveler_MarkQuestDone($QUEST_SEARCH_CURE)
		Out("[Step] " & $a_s_Name & " already completed")
		Return True
	EndIf
	If $a_i_QuestID = $QUEST_MASTERS_BURDEN And Leveler_MastersBurdenDone() Then
		Leveler_MarkQuestDone($QUEST_MASTERS_BURDEN)
		Out("[Step] " & $a_s_Name & " already completed")
		Return True
	EndIf
	If $a_i_QuestID = $QUEST_PUNCH_CLOWN And Leveler_PunchClownDone() Then
		Leveler_MarkQuestDone($QUEST_PUNCH_CLOWN)
		Out("[Step] " & $a_s_Name & " already completed")
		Return True
	EndIf
	If Leveler_HasIncompleteQuest($a_i_QuestID) Then Return False
	If Not Leveler_IsQuestDone($a_i_QuestID) And Not Leveler_QuestFinished($a_i_QuestID) Then Return False
	Leveler_MarkQuestDone($a_i_QuestID)
	Out("[Step] " & $a_s_Name & " already completed")
	Return True
EndFunc

; Search for a Cure (#336) from Imperial Agent Hanjo. Sticky flag or later proof only.
Func Leveler_SearchCureDone()
	If Leveler_HasIncompleteQuest($QUEST_SEARCH_CURE) Then Return False
	; Tosai (#337) is only offered after Cure — having it means Hanjo's quest is past.
	If Leveler_HasIncompleteQuest($QUEST_BROTHER_TOSAI) Then Return True
	If Leveler_IsQuestDone($QUEST_BROTHER_TOSAI) Then Return True
	; Quest log bit only. Leveler_QuestFinished(#336) calls this function.
	If Quest_GetQuestInfo($QUEST_SEARCH_CURE, "IsCompleted") Then Return True
	If Leveler_MoxOrOliasAvailable() Then Return True
	If $g_ab_QuestDone[$LEVELER_Q_CURE] Then Return True
	Return False
EndFunc

; Cure step requires Cure finished and Seek out Brother Tosai accepted (or mid-game skip).
Func Leveler_CureStepComplete()
	If Leveler_HasIncompleteQuest($QUEST_SEARCH_CURE) Then Return False
	If Leveler_HasQuest($QUEST_BROTHER_TOSAI) Then Return True
	If Leveler_IsQuestDone($QUEST_BROTHER_TOSAI) Then Return True
	If Leveler_MoxOrOliasAvailable() Then Return True
	Return False
EndFunc

; A Master's Burden (#349). Max armor equipped means this character is already past it.
Func Leveler_MastersBurdenDone()
	If Leveler_ArmorSetEquipped(Leveler_GetMaxArmorPieces()) Then Return True
	If Leveler_HasIncompleteQuest($QUEST_MASTERS_BURDEN) Then Return False
	; Quest log bit only. Leveler_QuestFinished(#349) calls this function.
	If Quest_GetQuestInfo($QUEST_MASTERS_BURDEN, "IsCompleted") Then Return True
	If Leveler_MoxOrOliasAvailable() Then Return True
	If $g_ab_QuestDone[$LEVELER_Q_BURDEN] Then Return True
	Return False
EndFunc

; Punch the Clown (#858). Settled means the one dialog already decided: instance entered and fought, or the map stayed and Punch-Out took over.
; Punch-Out Extravaganza (#856) is only in the log after Kilroy is unlocked.
Func Leveler_PunchClownDone()
	If $g_b_PunchClownSettled Then Return True
	If Leveler_HasQuest($QUEST_PUNCH_EXTRAVAGANZA) Then Return True
	If Leveler_HasIncompleteQuest($QUEST_PUNCH_CLOWN) Then Return False
	If Leveler_HasQuest($QUEST_PUNCH_CLOWN) Then Return False
	If Leveler_IsQuestDone($QUEST_PUNCH_CLOWN) Then Return True
	If Leveler_QuestFinished($QUEST_PUNCH_CLOWN) Then Return True
	Return False
EndFunc

; Mark Punch the Clown finished so it is not offered again this run.
Func Leveler_SettlePunchClown()
	$g_b_PunchClownSettled = True
	Leveler_MarkQuestDone($QUEST_PUNCH_CLOWN, True)
EndFunc

; Against the Destroyers is out of the log and Keiran's Bow is owned. HoM map unlock is not enough.
; Missing Vanguard + Northern Allies + Knowledgeable Asura in the log means HoM heroes are done.
Func Leveler_HomHeroQuestReady($a_i_QuestID)
	If Leveler_HasQuest($a_i_QuestID) Then Return True
	If Leveler_IsQuestDone($a_i_QuestID) Then Return True
	If Leveler_QuestFinished($a_i_QuestID) Then Return True
	Return False
EndFunc

; True when Missing Vanguard, Northern Allies, and Knowledgeable Asura are done.
Func Leveler_HomHeroesTalked()
	If Not Leveler_HomHeroQuestReady($QUEST_MISSING_VANGUARD) Then Return False
	If Not Leveler_HomHeroQuestReady($QUEST_NORTHERN_ALLIES) Then Return False
	If Not Leveler_HomHeroQuestReady($QUEST_KNOWLEDGEABLE_ASURA) Then Return False
	Return True
EndFunc

; True once this character has reached Gunnar's Hold or a later outpost.
Func Leveler_ReachedGunnarsHold()
	If $g_b_ReachedGunnar Then Return True
	Local $l_i_Map = Map_GetMapID()
	If $l_i_Map = $MAP_GUNNAR Or $l_i_Map = $MAP_KILROY Or $l_i_Map = $MAP_FRONIS Then
		$g_b_ReachedGunnar = True
		Return True
	EndIf
	; After leaving Gunnar (Lion's Arch / Kamadan / Olias), keep the sticky so
	; An Unwelcome Guest does not rewind to Seitung Harbor on Refresh.
	If $l_i_Map = $MAP_LIONS_ARCH Or $l_i_Map = $MAP_LIONS_GATE Or $l_i_Map = $MAP_BEJUNKAN Then
		$g_b_ReachedGunnar = True
		Return True
	EndIf
	If $l_i_Map = $MAP_KAMADAN Or $l_i_Map = $MAP_SUN_DOCKS Or $l_i_Map = $MAP_CONSULATE Or $l_i_Map = $MAP_DOCKS Or $l_i_Map = $MAP_BLOODSTONE_FEN Then
		$g_b_ReachedGunnar = True
		Return True
	EndIf
	If Leveler_HasIncompleteQuest($QUEST_OLIAS) Or Leveler_HasQuest($QUEST_OLIAS) Then
		$g_b_ReachedGunnar = True
		Return True
	EndIf
	If Leveler_HasIncompleteQuest($QUEST_CHAOS_KRYTA) Or Leveler_HasIncompleteQuest($QUEST_SUNSPEARS_CANTHA) Then
		$g_b_ReachedGunnar = True
		Return True
	EndIf
	If Map_IsMapUnlocked($MAP_GUNNAR) And (Map_IsMapUnlocked($MAP_LIONS_ARCH) Or Map_IsMapUnlocked($MAP_KAMADAN) Or Map_IsMapUnlocked($MAP_DOCKS)) Then
		$g_b_ReachedGunnar = True
		Return True
	EndIf
	Return False
EndFunc

; Unlock Eye of the North Pool is complete once the Hall dialogs are done, or Tracking the Nornbear is in the log.
Func Leveler_EotnPoolReady()
	If Leveler_ReachedGunnarsHold() Then Return True
	If Leveler_HomHeroesTalked() Then Return True
	If Leveler_HasNornbearTracking() Then Return True
	Return False
EndFunc

; An Unwelcome Guest is handed in, or the character is already past Seitung.
Func Leveler_UnwelcomeGuestDone()
	If Leveler_HasIncompleteQuest($QUEST_UNWELCOME) Then Return False
	If Leveler_ReachedGunnarsHold() Then Return True
	If Leveler_HasNornbearTracking() Then Return True
	If Leveler_IsQuestDone($QUEST_UNWELCOME) Then Return True
	If Leveler_QuestFinished($QUEST_UNWELCOME) Then Return True
	; Already past Gunnar / Kryta. Do not rewind to Seitung Harbor for Zunraa.
	If Map_IsMapUnlocked($MAP_GUNNAR) Or Map_IsMapUnlocked($MAP_LIONS_ARCH) Or Map_IsMapUnlocked($MAP_KAMADAN) Then Return True
	Return False
EndFunc

; Tracking the Nornbear must be in the log (or already finished) before Gunnar's Hold counts as done.
Func Leveler_HasNornbearTracking()
	If Leveler_HasQuest($QUEST_NORNBEAR) Then Return True
	If Leveler_IsQuestDone($QUEST_NORNBEAR) Then Return True
	If Leveler_QuestFinished($QUEST_NORNBEAR) Then Return True
	Return False
EndFunc

; True when the character is still on Monastery Overlook (or its variants).
Func Leveler_OnOverlook()
	Local $l_i_Map = Map_GetMapID()
	Return $l_i_Map = 212 Or $l_i_Map = 285 Or $l_i_Map = 416
EndFunc

; True when a Xunlai storage bag pointer is already valid.
Func Leveler_HasStorageAccess()
	If Item_GetBagPtr($GC_I_INVENTORY_STORAGE1) <> 0 Then Return True
	If Item_GetInventoryInfo("Storage1Ptr") <> 0 Then Return True
	Return False
EndFunc

; Character-specific Xunlai unlock. Storage bag pointers are ACCOUNT-wide once any
; character on the account has paid; they must not skip this step on a fresh char.
Func Leveler_XunlaiUnlocked()
	If $g_b_XunlaiUnlocked Then Return True
	; Past monastery crafts / later quests means this character already paid.
	If Leveler_HasCraftedWeapon() Then Return True
	If Leveler_HasMonasteryArmor() Then Return True
	If Leveler_HasSeitungArmor() Then Return True
	If Leveler_HasPostXunlaiProgress() Then Return True
	Return False
EndFunc

; Remember that this character has already paid for Xunlai storage.
Func Leveler_MarkXunlaiUnlocked()
	$g_b_XunlaiUnlocked = True
EndFunc

; Zhao Di in Shing Jea. Energy Burn is optional if a skill point was already spent.
Func Leveler_ZhaoDiSkillsUnlocked()
	If Not World_IsSkillLearnt($SKILL_SIGNET_OF_DISRUPTION) Then Return False
	If Not World_IsSkillLearnt($SKILL_LEECH_SIGNET) Then Return False
	Return True
EndFunc

; Cry of Frustration + Power Drain are sold at Xu Fengxia / Michiko, not Zhao Di.
Func Leveler_InterruptSkillsUnlocked()
	If Not World_IsSkillLearnt($SKILL_CRY_OF_FRUSTRATION) Then Return False
	If Not World_IsSkillLearnt($SKILL_POWER_DRAIN) Then Return False
	If Not World_IsSkillLearnt($SKILL_SIGNET_OF_DISRUPTION) Then Return False
	Return True
EndFunc

; True when Kaineng interrupt skills (and Backfire, if Mesmer) are learnt.
Func Leveler_Skills2Unlocked()
	Return Leveler_InterruptSkillsUnlocked()
EndFunc

; True when Tengu / Threat / Journey / Road is in progress.
Func Leveler_HasLaterQuest()
	If Leveler_HasQuest($QUEST_WARNING_TENGU) Or Leveler_HasIncompleteQuest($QUEST_WARNING_TENGU) Then Return True
	If Leveler_HasQuest($QUEST_THREAT_GROWS) Or Leveler_HasIncompleteQuest($QUEST_THREAT_GROWS) Then Return True
	If Leveler_HasQuest($QUEST_JOURNEY_MASTER) Or Leveler_HasIncompleteQuest($QUEST_JOURNEY_MASTER) Then Return True
	If Leveler_HasQuest($QUEST_ROAD_LESS) Or Leveler_HasIncompleteQuest($QUEST_ROAD_LESS) Then Return True
	Return False
EndFunc

; This character already left the Shing Jea armor crafter. Do not rerun monastery crafts.
Func Leveler_PastMonasteryArmor()
	If Leveler_HasMonasteryArmor() Then Return True
	If Leveler_HasSeitungArmor() Then Return True
	If Leveler_HasMaxArmor() Then Return True
	If Leveler_QuestProgress($QUEST_LOST_TREASURE) Then Return True
	If Leveler_HasLaterQuest() Then Return True
	If Leveler_IsQuestDone($QUEST_ROAD_LESS) Then Return True
	Local $l_i_Map = Map_GetMapID()
	If $l_i_Map = $MAP_SEITUNG Or $l_i_Map = $MAP_SAOSHANG Or $l_i_Map = $MAP_JAYA Or $l_i_Map = $MAP_HAIJU Or $l_i_Map = $MAP_ZEN_OP Then Return True
	If $l_i_Map = $MAP_KAINENG Or $l_i_Map = $MAP_MARKETPLACE Or $l_i_Map = $MAP_EOTN Or $l_i_Map = $MAP_HOM Or $l_i_Map = $MAP_BOREAL Then Return True
	If Map_IsMapUnlocked($MAP_KAINENG) Or Map_IsMapUnlocked($MAP_EOTN) Or Map_IsMapUnlocked($MAP_MARKETPLACE) Then Return True
	Return False
EndFunc

; The Road Less Traveled is done only after the Seitung Harbor hand-in. Journey still in the log is not enough.
Func Leveler_RoadLessTraveledDone()
	If Leveler_QuestNeedsHandIn($QUEST_ROAD_LESS) Then Return False
	If Leveler_HasQuest($QUEST_JOURNEY_MASTER) Then Return False
	If Leveler_QuestNeedsHandIn($QUEST_JOURNEY_MASTER) Then Return False
	If Map_GetMapID() = $MAP_PANJIANG Or Map_GetMapID() = $MAP_TSUMEI Or Map_GetMapID() = $MAP_SUNQUA_VALE Or Map_GetMapID() = $MAP_KINYA Then Return False
	If Map_IsMapUnlocked($MAP_SEITUNG) Then Return True
	If Map_GetMapID() = $MAP_SEITUNG And Map_GetInstanceInfo("IsOutpost") Then Return True
	Return False
EndFunc

; True when Lost Treasure is handed in or a later island quest is active.
Func Leveler_LostTreasureAlreadyDone()
	If Leveler_QuestNeedsHandIn($QUEST_LOST_TREASURE) Then Return False
	If Quest_GetQuestInfo($QUEST_LOST_TREASURE, "IsCompleted") Then Return True
	If Leveler_IsQuestDone($QUEST_LOST_TREASURE) Then Return True
	If Leveler_HasQuest($QUEST_WARNING_TENGU) Or Leveler_QuestFinished($QUEST_WARNING_TENGU) Then Return True
	If Leveler_QuestFinished($QUEST_THREAT_GROWS) Or Leveler_HasQuest($QUEST_THREAT_GROWS) Then Return True
	If Leveler_HasQuest($QUEST_JOURNEY_MASTER) Or Leveler_HasQuest($QUEST_ROAD_LESS) Then Return True
	Return False
EndFunc

; Empty log means not started. Do not treat that as handed in.
Func Leveler_WarningTheTenguDone()
	If Leveler_QuestNeedsHandIn($QUEST_WARNING_TENGU) Then Return False
	If Leveler_HasIncompleteQuest($QUEST_THREAT_GROWS) Then Return True
	If Leveler_HasIncompleteQuest($QUEST_JOURNEY_MASTER) Then Return True
	If Leveler_HasIncompleteQuest($QUEST_ROAD_LESS) Then Return True
	If Leveler_QuestFinished($QUEST_THREAT_GROWS) Then Return True
	If Map_IsMapUnlocked($MAP_SEITUNG) Then Return True
	Local $l_i_Map = Map_GetMapID()
	If $l_i_Map = $MAP_SEITUNG Or $l_i_Map = $MAP_TSUMEI Or $l_i_Map = $MAP_PANJIANG Then Return True
	If $l_i_Map = $MAP_SAOSHANG Or $l_i_Map = $MAP_JAYA Or $l_i_Map = $MAP_HAIJU Or $l_i_Map = $MAP_ZEN_OP Then Return True
	Return False
EndFunc

; Kaineng / Wajjun maps where The Search for a Cure is played.
Func Leveler_IsCureAreaMap($a_i_Map = -1)
	If $a_i_Map < 0 Then $a_i_Map = Map_GetMapID()
	Switch $a_i_Map
		Case $MAP_KAINENG, $MAP_WAJJUN, $MAP_BUKDEK, $MAP_KAINENG_DOCKS, $MAP_MARKETPLACE
			Return True
	EndSwitch
	Return False
EndFunc

; Towns that only exist after The Search for a Cure has been left behind.
Func Leveler_IsPastCureMap($a_i_Map = -1)
	If $a_i_Map < 0 Then $a_i_Map = Map_GetMapID()
	Switch $a_i_Map
		Case $MAP_BOREAL, $MAP_TUNNELS, $MAP_ICE_CLIFF, $MAP_EOTN, $MAP_HOM, $MAP_AB, $MAP_NORRHART, _
				$MAP_GUNNAR, $MAP_KILROY, $MAP_FRONIS, $MAP_LIONS_ARCH, $MAP_LIONS_GATE, $MAP_BEJUNKAN, _
				$MAP_KAMADAN, $MAP_SUN_DOCKS, $MAP_CONSULATE, $MAP_DOCKS, $MAP_KC_SUNSPEARS, $MAP_BLOODSTONE_FEN
			Return True
	EndSwitch
	Return False
EndFunc

; #336 is in the log, including reward-ready.
Func Leveler_Quest336Seen()
	If Leveler_HasIncompleteQuest($QUEST_SEARCH_CURE) Then Return True
	If Leveler_HasQuest($QUEST_SEARCH_CURE) Then Return True
	Return False
EndFunc

; Max armor is on and the Seitung set is gone, so Destroy Seitung is finished.
Func Leveler_MaxArmorPastSeitung()
	If Leveler_HasSeitungArmor() Then Return False
	If Leveler_ArmorSetEquipped(Leveler_GetMaxArmorPieces()) Then Return True
	If Leveler_HasMaxArmor() Then Return True
	Return False
EndFunc

; True when this character is already beyond The Search for a Cure.
Func Leveler_IsPastSearchCure($a_i_IncomingStep)
	If Leveler_Quest336Seen() Then Return False
	If $g_ab_StepDone[$LEVELER_STEP_CURE] Then Return True
	If Leveler_HasQuest($QUEST_BROTHER_TOSAI) Or Leveler_IsQuestDone($QUEST_BROTHER_TOSAI) Then Return True
	If $g_b_MoxUnlocked Or $g_b_OliasUnlocked Then Return True
	If $a_i_IncomingStep > $LEVELER_STEP_CURE And $a_i_IncomingStep < $LEVELER_STEP_COUNT Then Return True
	If Leveler_IsPastCureMap() Then Return True
	Return False
EndFunc

; True when a restart must stay on The Search for a Cure.
Func Leveler_IsAtSearchCure($a_i_IncomingStep)
	If Leveler_Quest336Seen() Then Return True
	If $g_b_CureStepLocked Then Return True
	If $a_i_IncomingStep = $LEVELER_STEP_CURE Then Return True
	If Leveler_IsCureAreaMap() And Leveler_MaxArmorPastSeitung() Then Return True
	Return False
EndFunc

; Last word in the status check. Earlier steps, including An Unwelcome Guest, stay closed.
Func Leveler_PinSearchForACure($a_i_IncomingStep)
	Local $l_i_Before
	If Leveler_IsPastSearchCure($a_i_IncomingStep) Then
		$g_b_CureStepLocked = False
		For $l_i_Before = 0 To $LEVELER_STEP_CURE
			$g_ab_StepDone[$l_i_Before] = True
		Next
		Leveler_MarkQuestDone($QUEST_UNWELCOME, True)
		Leveler_MarkQuestDone($QUEST_MASTERS_BURDEN, True)
		Out("[Status] Past The Search For A Cure. Earlier steps stay closed.")
		Return
	EndIf
	If Not Leveler_IsAtSearchCure($a_i_IncomingStep) Then Return
	$g_b_CureStepLocked = True
	For $l_i_Before = 0 To $LEVELER_STEP_CURE - 1
		$g_ab_StepDone[$l_i_Before] = True
	Next
	$g_ab_StepDone[$LEVELER_STEP_CURE] = False
	Leveler_MarkQuestDone($QUEST_UNWELCOME, True)
	Leveler_MarkQuestDone($QUEST_MASTERS_BURDEN, True)
	Out("[Status] Staying on The Search For A Cure. Earlier steps are locked behind this quest.")
EndFunc

; Quest log can still be empty on the first tick after attach.
Func Leveler_WaitForQuestLog()
	If World_GetWorldInfo("QuestLogSize") > 0 Then Return True
	Out("[Status] Quest log is empty. Waiting for it to load.")
	Local $l_h_Wait = TimerInit()
	While TimerDiff($l_h_Wait) < 2500
		Sleep(200)
		If World_GetWorldInfo("QuestLogSize") > 0 Then Return True
	WEnd
	Return False
EndFunc

#EndRegion Progress

#Region Status Check
; Brief inventory / quest / map check. Greys finished steps and returns the first incomplete one.
Func Leveler_StatusCheck()
	Out("[Status] Checking character progress...")
	Leveler_WaitForQuestLog()
	Local $l_i_IncomingStep = $g_i_Step
	Local $l_i_Map = Map_GetMapID()
	Local $l_b_Cho = Map_IsMapUnlocked($MAP_CHO_OUTPOST) Or $l_i_Map = $MAP_CHO_OUTPOST Or $l_i_Map = $MAP_CHO_MISSION
	Local $l_b_RanMusu = Map_IsMapUnlocked($MAP_RAN_MUSU) Or $l_i_Map = $MAP_RAN_MUSU Or $l_i_Map = $MAP_CHO_EXPLORABLE Or $l_i_Map = $MAP_KINYA
	Local $l_b_Seitung = Map_IsMapUnlocked($MAP_SEITUNG) Or $l_i_Map = $MAP_SEITUNG Or $l_i_Map = $MAP_SAOSHANG Or $l_i_Map = $MAP_JAYA Or $l_i_Map = $MAP_HAIJU Or $l_i_Map = $MAP_ZEN_OP
	Local $l_b_TsumeiPath = $l_i_Map = $MAP_TSUMEI Or $l_i_Map = $MAP_PANJIANG
	Local $l_b_ZenOp = Map_IsMapUnlocked($MAP_ZEN_OP) Or $l_i_Map = $MAP_ZEN_OP
	Local $l_b_ToZenPath = $l_i_Map = $MAP_JAYA Or $l_i_Map = $MAP_HAIJU
	Local $l_b_ShingJea = Map_IsMapUnlocked($MAP_SHING_JEA) Or $l_i_Map = $MAP_SHING_JEA Or $l_b_Cho Or $l_b_RanMusu Or $l_b_Seitung
	Local $l_b_SeitungArmor = Leveler_HasSeitungArmor()
	Local $l_b_Marketplace = Map_IsMapUnlocked($MAP_MARKETPLACE) Or $l_i_Map = $MAP_MARKETPLACE Or $l_i_Map = $MAP_KAINENG_DOCKS Or $l_i_Map = $MAP_BUKDEK Or $l_i_Map = $MAP_WAJJUN Or $l_i_Map = $MAP_KAINENG
	Local $l_b_Kaineng = Map_IsMapUnlocked($MAP_KAINENG) Or $l_i_Map = $MAP_KAINENG
	Local $l_b_MaxArmor = Leveler_HasMaxArmor()
	Local $l_b_Boreal = Map_IsMapUnlocked($MAP_BOREAL) Or $l_i_Map = $MAP_BOREAL Or $l_i_Map = $MAP_TUNNELS Or $l_i_Map = $MAP_ICE_CLIFF Or $l_i_Map = $MAP_EOTN Or $l_i_Map = $MAP_HOM Or $l_i_Map = $MAP_AB
	Local $l_b_Eotn = Map_IsMapUnlocked($MAP_EOTN) Or $l_i_Map = $MAP_EOTN Or $l_i_Map = $MAP_HOM Or $l_i_Map = $MAP_AB
	Local $l_b_Hom = Map_IsMapUnlocked($MAP_HOM) Or $l_i_Map = $MAP_HOM Or $l_i_Map = $MAP_AB
	Local $l_i_Level = Leveler_PlayerLevel()
	Local $l_b_Gunnar = Map_IsMapUnlocked($MAP_GUNNAR) Or $l_i_Map = $MAP_GUNNAR Or $l_i_Map = $MAP_NORRHART
	Local $l_b_Lions = Map_IsMapUnlocked($MAP_LIONS_ARCH) Or $l_i_Map = $MAP_LIONS_ARCH Or $l_i_Map = $MAP_LIONS_GATE
	Local $l_b_Kamadan = Map_IsMapUnlocked($MAP_KAMADAN) Or $l_i_Map = $MAP_KAMADAN Or $l_i_Map = $MAP_SUN_DOCKS Or $l_i_Map = $MAP_CONSULATE Or $l_i_Map = $MAP_DOCKS
	Local $l_b_Docks = Map_IsMapUnlocked($MAP_DOCKS) Or $l_i_Map = $MAP_DOCKS

	For $i = 0 To $LEVELER_STEP_COUNT - 1
		$g_ab_StepDone[$i] = False
	Next

	Leveler_RefreshQuestFlags(False)
	Local $l_i_QDone = 0
	For $i = 0 To $LEVELER_Q_COUNT - 1
		If $g_ab_QuestDone[$i] Then $l_i_QDone += 1
	Next
	Out("[Status] Quest flags: " & $l_i_QDone & "/" & $LEVELER_Q_COUNT & " complete")

	; Monastery tutorial is character-specific. Account map unlocks, storage
	; pointers, and account skill unlocks must not skip Secondary / Xunlai / craft.
	$g_ab_StepDone[$LEVELER_STEP_OVERLOOK] = $l_b_ShingJea And Not Leveler_OnOverlook()
	; Do not treat reward-ready (#440 still in the log) as done. QuestLogCompleted is IsCompleted,
	; which skipped Forming A Party and jumped to Secondary on a fresh character mid-hand-in.
	$g_ab_StepDone[$LEVELER_STEP_PARTY] = (Not Leveler_QuestNeedsHandIn($QUEST_FORMING_A_PARTY)) And (Leveler_IsQuestDone($QUEST_FORMING_A_PARTY) Or Leveler_QuestFinished($QUEST_FORMING_A_PARTY) Or Leveler_HasSecondaryProfession() Or Leveler_HasQuest($QUEST_SECONDARY) Or Leveler_HasQuest($QUEST_FORMAL_INTRO))
	$g_ab_StepDone[$LEVELER_STEP_SECONDARY] = Leveler_SecondaryStepReadyToLeave()
	Out("[Status] Profession " & Leveler_PrimaryProfession() & "/" & Leveler_SecondaryProfession() & "  Gold " & Leveler_CharacterGold() & "  Secondary step done=" & $g_ab_StepDone[$LEVELER_STEP_SECONDARY])
	$g_ab_StepDone[$LEVELER_STEP_XUNLAI] = Leveler_XunlaiUnlocked()
	; After Road / Seitung, do not send this character back to the monastery weapon/armor crafts.
	Local $l_b_PastMonArmor = Leveler_PastMonasteryArmor()
	$g_ab_StepDone[$LEVELER_STEP_WEAPON] = (Leveler_HasCraftedWeapon() And Leveler_IsModelEquipped($MODEL_CLAIRVOYANT_STAFF)) Or $l_b_PastMonArmor
	$g_ab_StepDone[$LEVELER_STEP_ARMOR] = Leveler_ArmorSetEquipped(Leveler_GetMonasteryPieces()) Or $l_b_PastMonArmor
	$g_ab_StepDone[$LEVELER_STEP_DESTROY] = (Not Leveler_HasStarterArmor() And (Leveler_HasMonasteryArmor() Or $l_b_SeitungArmor)) Or $l_b_PastMonArmor
	$g_ab_StepDone[$LEVELER_STEP_BAGS] = Leveler_HasExtendedBags()
	$g_ab_StepDone[$LEVELER_STEP_SKILLS] = Leveler_ZhaoDiSkillsUnlocked() Or Leveler_QuestProgress($QUEST_LOST_TREASURE) Or Leveler_HasLaterQuest()
	$g_ab_StepDone[$LEVELER_STEP_TO_CHO] = $l_b_RanMusu Or $l_b_Seitung Or ($l_b_Cho And Not Leveler_HasIncompleteQuest($QUEST_FORMAL_INTRO) And Leveler_FormalIntroductionTurnedIn())
	$g_ab_StepDone[$LEVELER_STEP_CHO_MISSION] = $l_b_RanMusu Or $l_b_Seitung Or $l_b_TsumeiPath

	$g_ab_StepDone[$LEVELER_STEP_ATTR_1] = Leveler_LostTreasureAlreadyDone()
	If Leveler_QuestNeedsHandIn($QUEST_WARNING_TENGU) Or Not Leveler_WarningTheTenguDone() Then
		$g_ab_StepDone[$LEVELER_STEP_TENGU] = False
	Else
		$g_ab_StepDone[$LEVELER_STEP_TENGU] = True
		Leveler_MarkQuestDone($QUEST_WARNING_TENGU)
	EndIf
	If Leveler_QuestNeedsHandIn($QUEST_LOST_TREASURE) And Leveler_NearLostTreasureHandIn() Then
		Out("[Status] Already at Raitahn Nem hand-in " & Round($LOST_CHO_END_X) & ", " & Round($LOST_CHO_END_Y) & ". Will send dialog 0x17 without replaying the escort.")
	EndIf
	Leveler_LogActiveQuests()
	If $g_b_ExplorableResume And Not Leveler_IsOutpost() And Map_GetInstanceInfo("IsExplorable") Then
		Out("[Status] Restart recovery: not in an outpost (map " & $l_i_Map & "). Will resume only if this map belongs to the current quest.")
	EndIf
	Out("[Status] Lost Treasure step done=" & $g_ab_StepDone[$LEVELER_STEP_ATTR_1] & "  Tengu step done=" & $g_ab_StepDone[$LEVELER_STEP_TENGU])
	If Leveler_QuestNeedsHandIn($QUEST_THREAT_GROWS) Then
		$g_ab_StepDone[$LEVELER_STEP_THREAT] = False
	ElseIf Leveler_HasQuest($QUEST_JOURNEY_MASTER) Or Leveler_QuestNeedsHandIn($QUEST_JOURNEY_MASTER) Or Leveler_QuestNeedsHandIn($QUEST_ROAD_LESS) Or $l_b_Seitung Then
		$g_ab_StepDone[$LEVELER_STEP_THREAT] = True
		Leveler_MarkQuestDone($QUEST_THREAT_GROWS)
	Else
		$g_ab_StepDone[$LEVELER_STEP_THREAT] = Leveler_IsQuestDone($QUEST_THREAT_GROWS) Or Leveler_QuestFinished($QUEST_THREAT_GROWS)
	EndIf
	If Leveler_QuestNeedsHandIn($QUEST_ROAD_LESS) Or Leveler_HasQuest($QUEST_JOURNEY_MASTER) Then
		$g_ab_StepDone[$LEVELER_STEP_ROAD] = False
	Else
		$g_ab_StepDone[$LEVELER_STEP_ROAD] = Leveler_RoadLessTraveledDone()
	EndIf
	$g_ab_StepDone[$LEVELER_STEP_SEITUNG] = Leveler_ArmorSetEquipped(Leveler_GetSeitungPieces()) Or $l_b_MaxArmor Or $l_b_Kaineng Or $l_b_Eotn Or $l_b_Gunnar Or $l_b_Lions Or $l_b_Kamadan
	If Not $g_ab_StepDone[$LEVELER_STEP_SEITUNG] And $g_ab_StepDone[$LEVELER_STEP_ROAD] Then
		Out("[Status] Road is handed in. Next armor craft is Seitung Harbor, not monastery.")
	EndIf
	; Owning Seitung pieces is not required. After max armor / Destroy Seitung those models are gone.
	If $l_b_MaxArmor Or $l_b_Kaineng Or $l_b_Eotn Or $l_b_Marketplace Then
		$g_ab_StepDone[$LEVELER_STEP_DESTROY_MON] = True
	Else
		$g_ab_StepDone[$LEVELER_STEP_DESTROY_MON] = (Not Leveler_HasMonasteryArmor()) And ($l_b_SeitungArmor Or $l_b_ZenOp Or $l_b_ToZenPath)
	EndIf
	$g_ab_StepDone[$LEVELER_STEP_TO_ZEN] = $l_b_ZenOp Or $l_b_ToZenPath
	$g_ab_StepDone[$LEVELER_STEP_ZEN_MISSION] = $l_b_Marketplace Or ($l_b_ZenOp And $l_i_Map = $MAP_SEITUNG And Map_GetInstanceInfo("IsOutpost") And Not $l_b_ToZenPath)
	$g_ab_StepDone[$LEVELER_STEP_TO_MARKET] = (Map_IsMapUnlocked($MAP_MARKETPLACE) Or $l_i_Map = $MAP_MARKETPLACE Or $l_b_Kaineng Or $l_i_Map = $MAP_BUKDEK Or $l_i_Map = $MAP_WAJJUN) And $l_i_Map <> $MAP_KAINENG_DOCKS
	$g_ab_StepDone[$LEVELER_STEP_BURDEN] = Leveler_MastersBurdenDone()
	$g_ab_StepDone[$LEVELER_STEP_TO_KC] = $l_b_Kaineng
	; Michiko in Kaineng Center. Zhao Di Leech Signet (61) must not skip this.
	$g_ab_StepDone[$LEVELER_STEP_SKILLS2] = Leveler_Skills2Unlocked()
	$g_ab_StepDone[$LEVELER_STEP_MAX_ARMOR] = Leveler_ArmorSetEquipped(Leveler_GetMaxArmorPieces())
	$g_ab_StepDone[$LEVELER_STEP_DESTROY_SEITUNG] = $g_ab_StepDone[$LEVELER_STEP_MAX_ARMOR] And Not $l_b_SeitungArmor
	$g_ab_StepDone[$LEVELER_STEP_CURE] = Leveler_CureStepComplete()
	; Mox: in the party, AddHero works, or this character already reached EotN.
	$g_ab_StepDone[$LEVELER_STEP_UNLOCK_MOX] = Leveler_HasMoxUnlocked()
	$g_ab_StepDone[$LEVELER_STEP_TO_BOREAL] = Leveler_HasMoxUnlocked() And (Map_IsMapUnlocked($MAP_BOREAL) Or $l_i_Map = $MAP_BOREAL Or $l_i_Map = $MAP_ICE_CLIFF Or $l_b_Eotn) And $l_i_Map <> $MAP_TUNNELS
	Out("[Status] DestroyMon=" & $g_ab_StepDone[$LEVELER_STEP_DESTROY_MON] & " Skills2=" & $g_ab_StepDone[$LEVELER_STEP_SKILLS2] & " MaxArmorEq=" & $g_ab_StepDone[$LEVELER_STEP_MAX_ARMOR] & " DestroySeitung=" & $g_ab_StepDone[$LEVELER_STEP_DESTROY_SEITUNG] & " Burden=" & $g_ab_StepDone[$LEVELER_STEP_BURDEN] & " Cure=" & $g_ab_StepDone[$LEVELER_STEP_CURE] & " Mox=" & $g_ab_StepDone[$LEVELER_STEP_UNLOCK_MOX])
	$g_ab_StepDone[$LEVELER_STEP_TO_EOTN] = $l_b_Eotn And $l_i_Map <> $MAP_ICE_CLIFF
	$g_ab_StepDone[$LEVELER_STEP_EOTN_POOL] = Leveler_EotnPoolReady()
	; Live EotN: Against the Destroyers in the log means Hall of Monuments next, not Seitung Unwelcome Guest.
	If Leveler_HasIncompleteQuest($QUEST_AGAINST_DESTROYERS) And Not Leveler_HomHeroesTalked() And Not Leveler_HasNornbearTracking() And ($l_i_Map = $MAP_EOTN Or $l_i_Map = $MAP_HOM) Then
		$g_ab_StepDone[$LEVELER_STEP_TO_EOTN] = True
		$g_ab_StepDone[$LEVELER_STEP_EOTN_POOL] = False
		Out("[Status] Against the Destroyers is in the log on map " & $l_i_Map & ". Next is Hall of Monuments, not Seitung.")
	EndIf
	If Leveler_ReachedGunnarsHold() Then
		$g_ab_StepDone[$LEVELER_STEP_EOTN_POOL] = True
		$g_ab_StepDone[$LEVELER_STEP_ATTR_2] = True
		$g_ab_StepDone[$LEVELER_STEP_TO_GUNNAR] = True
		Out("[Status] Character has entered Gunnar's Hold. Pool, An Unwelcome Guest, and To Gunnar's Hold are complete.")
	ElseIf Leveler_HomHeroesTalked() Then
		$g_ab_StepDone[$LEVELER_STEP_EOTN_POOL] = True
		Out("[Status] Hall of Monuments hero dialogs are done. Unlock Eye of the North Pool is complete.")
	EndIf
	If Leveler_HasNornbearTracking() Then
		$g_ab_StepDone[$LEVELER_STEP_TO_EOTN] = True
		$g_ab_StepDone[$LEVELER_STEP_EOTN_POOL] = True
		Out("[Status] Tracking the Nornbear is in the quest log. Eye of the North is unlocked.")
	EndIf
	If Not $g_ab_StepDone[$LEVELER_STEP_ATTR_2] Then $g_ab_StepDone[$LEVELER_STEP_ATTR_2] = Leveler_UnwelcomeGuestDone()
	If Not $g_ab_StepDone[$LEVELER_STEP_TO_GUNNAR] Then $g_ab_StepDone[$LEVELER_STEP_TO_GUNNAR] = Leveler_HasNornbearTracking() And Map_IsMapUnlocked($MAP_GUNNAR) And $l_i_Map <> $MAP_ICE_CLIFF And $l_i_Map <> $MAP_NORRHART And $l_i_Map <> $MAP_EOTN And $l_i_Map <> $MAP_HOM
	$g_ab_StepDone[$LEVELER_STEP_KILROY] = Leveler_PunchClownDone()
	$g_ab_StepDone[$LEVELER_STEP_FARM_20] = $l_i_Level >= 20
	Out("[Status] EotN Pool=" & $g_ab_StepDone[$LEVELER_STEP_EOTN_POOL] & " Unwelcome=" & $g_ab_StepDone[$LEVELER_STEP_ATTR_2] & " Gunnar/Nornbear=" & $g_ab_StepDone[$LEVELER_STEP_TO_GUNNAR] & " Kilroy=" & $g_ab_StepDone[$LEVELER_STEP_KILROY] & " Lvl20=" & $g_ab_StepDone[$LEVELER_STEP_FARM_20] & " Lvl=" & $l_i_Level)
	$g_ab_StepDone[$LEVELER_STEP_TO_LA] = $l_b_Lions And $l_i_Map <> $MAP_BEJUNKAN
	$g_ab_StepDone[$LEVELER_STEP_TO_KAMADAN] = $l_b_Kamadan
	$g_ab_StepDone[$LEVELER_STEP_TO_DOCKS] = $l_b_Docks
	$g_ab_StepDone[$LEVELER_STEP_UNLOCK_OLIAS] = Leveler_HasOliasUnlocked() Or (Leveler_IsQuestDone($QUEST_OLIAS) And Not Leveler_HasIncompleteQuest($QUEST_OLIAS))
	; Olias in the log / reward-ready means this character is past Unwelcome/Seitung.
	; Refresh must not pick An Unwelcome Guest (outpost Seitung Harbor) instead of Kamadan.
	If Not Leveler_HasOliasUnlocked() And (Leveler_HasIncompleteQuest($QUEST_OLIAS) Or Leveler_OliasReadyToTurnIn()) Then
		Local $l_i_BeforeOlias
		For $l_i_BeforeOlias = 0 To $LEVELER_STEP_UNLOCK_OLIAS - 1
			$g_ab_StepDone[$l_i_BeforeOlias] = True
		Next
		$g_ab_StepDone[$LEVELER_STEP_UNLOCK_OLIAS] = False
		Out("[Status] All for One and One for Justice needs Kamadan. Staying on Unlock Olias, not Seitung.")
	EndIf
	; Remaining secondaries are optional. Without the tick box, skip them so a broke character can finish.
	If Leveler_WantsAllSecondaries() Then
		$g_ab_StepDone[$LEVELER_STEP_UNLOCK_PROFS] = Leveler_RemainingSecondariesUnlocked()
	Else
		$g_ab_StepDone[$LEVELER_STEP_UNLOCK_PROFS] = True
	EndIf
	Out("[Status] Unlocked professions=0x" & Hex(Leveler_UnlockedProfessionFlags(), 8) & " (" & Leveler_ProfessionUnlockCount(Leveler_UnlockedProfessionFlags()) & "/10 selectable)  Secondaries done=" & $g_ab_StepDone[$LEVELER_STEP_UNLOCK_PROFS] & "  Unlock all=" & Leveler_WantsAllSecondaries())
	$g_ab_StepDone[$LEVELER_STEP_DONE] = $g_ab_StepDone[$LEVELER_STEP_UNLOCK_PROFS]
	If $g_ab_StepDone[$LEVELER_STEP_DONE] And Leveler_WantsAllSecondaries() Then Out("[Status] Remaining secondary professions unlocked. Leveler is done.")

	; No fill-forward. Account skills, storage pointers, and courtyard unlocks
	; must not mark the tutorial quests complete on a fresh character.
	; Cure pin is last so An Unwelcome Guest cannot reopen after the other rules.
	Leveler_PinSearchForACure($l_i_IncomingStep)

	Local $l_i_Next = Leveler_FirstIncompleteStep()
	Out("[Status] Map " & $l_i_Map & "  Next step: " & $l_i_Next & " — " & $g_as_StepNames[$l_i_Next])
	Leveler_RefreshStepList($l_i_Next)
	Return $l_i_Next
EndFunc

; Print Phase 1 quests that are still in the log.
Func Leveler_LogActiveQuests()
	Local $l_ai_Ids[8] = [$QUEST_FORMING_A_PARTY, $QUEST_SECONDARY, $QUEST_FORMAL_INTRO, $QUEST_LOST_TREASURE, $QUEST_WARNING_TENGU, $QUEST_THREAT_GROWS, $QUEST_JOURNEY_MASTER, $QUEST_ROAD_LESS]
	Local $l_as_Names[8] = ["Forming A Party", "Choose Secondary", "Formal Introduction", "Lost Treasure", "Warning the Tengu", "The Threat Grows", "Journey of the Master", "The Road Less Traveled"]
	Local $i
	Local $l_b_Any = False
	For $i = 0 To 7
		If Leveler_QuestInLog($l_ai_Ids[$i]) Then
			If Not $l_b_Any Then Out("[Status] Quests still in the log:")
			$l_b_Any = True
			Leveler_LogQuestState($l_ai_Ids[$i], $l_as_Names[$i])
		EndIf
	Next
	If Not $l_b_Any Then Out("[Status] No tracked quests are in the log")
EndFunc

; Lowest unfinished step index, skipping Vaettir when the profession does not need it.
Func Leveler_FirstIncompleteStep()
	For $i = 0 To $LEVELER_STEP_COUNT - 1
		If $g_ab_StepDone[$i] Then ContinueLoop
		Return $i
	Next
	Return $LEVELER_STEP_DONE
EndFunc

; Mark every step up to $a_i_LastDone complete and refresh the list.
Func Leveler_MarkStepsThrough($a_i_LastDone)
	If $a_i_LastDone < 0 Then Return
	For $i = 0 To $a_i_LastDone
		If $i < $LEVELER_STEP_COUNT Then $g_ab_StepDone[$i] = True
	Next
	Leveler_RefreshStepList($g_i_Step)
EndFunc

#EndRegion Status Check
