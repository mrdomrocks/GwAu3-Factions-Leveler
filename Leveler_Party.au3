#include-once

; Character profession flags, hero unlocks, and UtilityAI cache.

#Region Profession

; Return the character primary profession ID (1-10).
Func Leveler_PrimaryProfession()
	Local $l_i_Prof = Agent_GetAgentInfo(-2, "Primary")
	If $l_i_Prof >= 1 And $l_i_Prof <= 10 Then Return $l_i_Prof
	Return Party_GetPartyProfessionInfo(-2, "Primary")
EndFunc

; Return the assigned secondary profession ID, or 0 if unset.
Func Leveler_SecondaryProfession()
	Local $l_i_Prof = Agent_GetAgentInfo(-2, "Secondary")
	If $l_i_Prof >= 1 And $l_i_Prof <= 10 Then Return $l_i_Prof
	$l_i_Prof = Party_GetPartyProfessionInfo(-2, "Secondary")
	If $l_i_Prof >= 1 And $l_i_Prof <= 10 Then Return $l_i_Prof
	Return 0
EndFunc

; Profession ID 1-10 means it is assigned. #317 may still be in the log.
Func Leveler_HasSecondaryProfession()
	Local $l_i_Prof = Leveler_SecondaryProfession()
	Return $l_i_Prof >= 1 And $l_i_Prof <= 10
EndFunc

; True when primary profession is Mesmer.
Func Leveler_IsMesmer()
	Return Leveler_PrimaryProfession() = $GC_I_PROFESSION_MESMER
EndFunc

; Bitmask of professions this character can select (PartyProfession.unlocked_professions).
Func Leveler_UnlockedProfessionFlags()
	Local $l_i_MyID = Agent_GetMyID()
	Local $l_i_Primary = Agent_GetAgentInfo(-2, "Primary")
	Local $l_i_Secondary = Agent_GetAgentInfo(-2, "Secondary")
	Local $l_p_Ptr = World_GetWorldInfo("PartyProfessionArray")
	Local $l_i_Size = World_GetWorldInfo("PartyProfessionArraySize")
	If $l_p_Ptr = 0 Then Return 0
	If $l_i_Size <= 0 Then $l_i_Size = 1
	Local $l_i_Fallback = 0
	Local $i
	For $i = 0 To $l_i_Size - 1
		Local $l_p_Entry = $l_p_Ptr + ($i * 0x14)
		Local $l_i_Agent = Memory_Read($l_p_Entry, "dword")
		Local $l_i_Flags = Memory_Read($l_p_Entry + 0xC, "dword")
		If $l_i_Agent = $l_i_MyID Then Return $l_i_Flags
		If Memory_Read($l_p_Entry + 0x4, "dword") = $l_i_Primary And Memory_Read($l_p_Entry + 0x8, "dword") = $l_i_Secondary And $l_i_Flags <> 0 Then $l_i_Fallback = $l_i_Flags
	Next
	Return $l_i_Fallback
EndFunc

; Accept both 1<<profession and 1<<(profession-1) bit layouts.
Func Leveler_ProfessionBitOn($a_i_Flags, $a_i_Prof)
	If $a_i_Prof < $GC_I_PROFESSION_WARRIOR Or $a_i_Prof > $GC_I_PROFESSION_DERVISH Then Return False
	If BitAND($a_i_Flags, BitShift(1, -$a_i_Prof)) <> 0 Then Return True
	If BitAND($a_i_Flags, BitShift(1, -($a_i_Prof - 1))) <> 0 Then Return True
	Return False
EndFunc

; How many of the ten professions are set in the unlock bitfield.
Func Leveler_ProfessionUnlockCount($a_i_Flags)
	Local $l_i_Count = 0
	Local $i
	For $i = $GC_I_PROFESSION_WARRIOR To $GC_I_PROFESSION_DERVISH
		If Leveler_ProfessionBitOn($a_i_Flags, $i) Then $l_i_Count += 1
	Next
	Return $l_i_Count
EndFunc

; True only when the GUI tick box for buying every remaining secondary is checked.
Func Leveler_WantsAllSecondaries()
	If $g_h_UnlockProfsCheckbox = 0 Then Return False
	Return GetChecked($g_h_UnlockProfsCheckbox)
EndFunc

; GToB trainers unlock every secondary, including Paragon and Dervish.
Func Leveler_RemainingSecondariesUnlocked()
	If $g_b_SecondaryProfsTalked Then Return True
	Local $l_i_Flags = Leveler_UnlockedProfessionFlags()
	If $l_i_Flags = 0 Then Return False
	Local $i
	For $i = $GC_I_PROFESSION_WARRIOR To $GC_I_PROFESSION_DERVISH
		If Not Leveler_ProfessionBitOn($l_i_Flags, $i) Then Return False
	Next
	$g_b_SecondaryProfsTalked = True
	Return True
EndFunc

#EndRegion Profession

#Region Heroes

; How many heroes are in the current party.
Func Leveler_HeroCount()
	Local $l_i_Count = Party_GetPartyContextInfo("HeroCount")
	If $l_i_Count > 0 Then Return $l_i_Count
	Return Party_GetMyPartyInfo("ArrayHeroPartyMemberSize")
EndFunc

; True when this hero id is already in the party.
Func Leveler_PartyHasHero($a_i_HeroID)
	If $a_i_HeroID <= 0 Then Return False
	Local $l_i_Count = Leveler_HeroCount()
	Local $i
	For $i = 1 To $l_i_Count
		If Party_GetMyPartyHeroInfo($i, "HeroID") = $a_i_HeroID Then Return True
	Next
	Return False
EndFunc

; True if Mox is in the party, can be added, or this character already reached EotN.
Func Leveler_HasMoxUnlocked()
	If $g_b_MoxUnlocked Then Return True
	If Leveler_PartyHasHero($GC_I_HERO_ID_MOX) Then
		$g_b_MoxUnlocked = True
		Return True
	EndIf
	If Leveler_IsOutpost() Then
		Party_AddHero($GC_I_HERO_ID_MOX)
		Sleep(800)
		If Leveler_PartyHasHero($GC_I_HERO_ID_MOX) Then
			$g_b_MoxUnlocked = True
			Return True
		EndIf
	EndIf
	Local $l_i_Map = Map_GetMapID()
	If Map_IsMapUnlocked($MAP_EOTN) Or $l_i_Map = $MAP_EOTN Or $l_i_Map = $MAP_HOM Or $l_i_Map = $MAP_BOREAL Or $l_i_Map = $MAP_ICE_CLIFF Then
		$g_b_MoxUnlocked = True
		Return True
	EndIf
	If Leveler_HasIncompleteQuest($QUEST_AGAINST_DESTROYERS) Then
		$g_b_MoxUnlocked = True
		Return True
	EndIf
	Return False
EndFunc

; Add Mox. Stay False if the Bukdek dialog did not unlock him.
Func Leveler_ConfirmMoxInHeroList()
	If Leveler_HasMoxUnlocked() Then
		Out("[Step] Mox is already on the hero list")
		Return True
	EndIf
	Party_LeaveGroup(True)
	Sleep(500)
	Party_AddHero($GC_I_HERO_ID_MOX)
	Sleep(1500)
	If Leveler_PartyHasHero($GC_I_HERO_ID_MOX) Then
		$g_b_MoxUnlocked = True
		Out("[Step] Mox is in the hero list")
		Return True
	EndIf
	Out("[Step] Mox is not in the hero list after the unlock dialog")
	Return False
EndFunc

; Cure / Burden stay open until Mox or Olias can actually join the party.
Func Leveler_MoxOrOliasAvailable()
	If Leveler_PartyHasHero($GC_I_HERO_ID_MOX) Then
		$g_b_MoxUnlocked = True
		Return True
	EndIf
	If Leveler_PartyHasHero($GC_I_HERO_ID_OLIAS) Then
		$g_b_OliasUnlocked = True
		Return True
	EndIf
	If Not Leveler_IsOutpost() Then Return False
	Party_AddHero($GC_I_HERO_ID_MOX)
	Sleep(800)
	If Leveler_PartyHasHero($GC_I_HERO_ID_MOX) Then
		$g_b_MoxUnlocked = True
		Return True
	EndIf
	Party_AddHero($GC_I_HERO_ID_OLIAS)
	Sleep(800)
	If Leveler_PartyHasHero($GC_I_HERO_ID_OLIAS) Then
		$g_b_OliasUnlocked = True
		Return True
	EndIf
	Return False
EndFunc

; True if Olias is already in the party or can be added in this outpost.
Func Leveler_HasOliasUnlocked()
	If $g_b_OliasUnlocked Then Return True
	If Leveler_PartyHasHero($GC_I_HERO_ID_OLIAS) Then
		$g_b_OliasUnlocked = True
		Return True
	EndIf
	If Not Leveler_IsOutpost() Then Return False
	Party_AddHero($GC_I_HERO_ID_OLIAS)
	Sleep(800)
	If Leveler_PartyHasHero($GC_I_HERO_ID_OLIAS) Then
		$g_b_OliasUnlocked = True
		Return True
	EndIf
	Return False
EndFunc

; Add Olias. Stay False if the Kamadan reward did not unlock him.
Func Leveler_ConfirmOliasInHeroList()
	If Leveler_HasOliasUnlocked() Then
		Out("[Step] Olias is already on the hero list")
		Return True
	EndIf
	If Not Leveler_IsOutpost() Then Return False
	Party_LeaveGroup(True)
	Sleep(500)
	Party_AddHero($GC_I_HERO_ID_OLIAS)
	Sleep(1500)
	If Leveler_PartyHasHero($GC_I_HERO_ID_OLIAS) Then
		$g_b_OliasUnlocked = True
		Out("[Step] Olias is in the hero list")
		Return True
	EndIf
	Out("[Step] Olias is not in the hero list after the unlock dialog")
	Return False
EndFunc

; Add Gwen, Vekk, Ogden, and Mox and load their bars.
Func Leveler_AddHeroTeam($a_b_Olias = False)
	Local $l_i_Fourth = $GC_I_HERO_ID_MOX
	Local $l_s_FourthBar = "OgCikys8wchuD4xb5VAAAAAA"
	Local $l_s_FourthName = "MOX"
	If $a_b_Olias Then
		$l_i_Fourth = $GC_I_HERO_ID_OLIAS
		$l_s_FourthBar = "OAhjQoGYIP3hhWVVaO5EeDTqNA"
		$l_s_FourthName = "Olias"
	EndIf
	Local $l_ai_Heroes[4] = [$GC_I_HERO_ID_GWEN, $GC_I_HERO_ID_VEKK, $GC_I_HERO_ID_OGDEN_STONEHEALER, $l_i_Fourth]
	Local $l_as_Bars[4] = [ _
			"OQhkAsC8gFKgGckjHFRUGCA", _
			"OgVDI8gsCawROeUEtZIA", _
			"OwUUMsG/E4GgMnZskzkIZQAA", _
			$l_s_FourthBar _
			]
	Local $i
	For $i = 0 To 3
		Party_AddHero($l_ai_Heroes[$i])
		Sleep(250)
	Next
	Sleep(800)
	For $i = 0 To 3
		Attribute_LoadSkillTemplate($l_as_Bars[$i], $i + 1)
		Sleep(400)
		Party_SetHeroAggression($i + 1, 1)
	Next
	Out("[Party] Added Gwen, Vekk, Ogden, " & $l_s_FourthName)
	Return True
EndFunc

; Leave the group, equip the player bar, add the hero team, then optional henchmen.
Func Leveler_PrepareHeroTeam($a_ai_Hench = 0, $a_b_Olias = False)
	$g_b_CombatMode = True
	$g_b_UAIReady = False
	Leveler_EquipSkillBar()
	Party_LeaveGroup(True)
	Sleep(400)
	Leveler_AddHeroTeam($a_b_Olias)
	If IsArray($a_ai_Hench) Then Leveler_AddHenchmanList($a_ai_Hench)
	Return True
EndFunc

#EndRegion Heroes

#Region UtilityAI

; Cache the UtilityAI skill bar for this explorable map.
Func Leveler_PrepareCombatAI()
	$g_b_CombatMode = True
	Local $l_i_Map = Map_GetMapID()
	If $l_i_Map <> $g_i_LastUAIMap Then $g_b_UAIReady = False
	If Not Leveler_ShouldFightHere() Then
		$g_b_UAIReady = False
		Return True
	EndIf
	If $g_b_UAIReady And $g_i_LastUAIMap = $l_i_Map Then Return True
	If Not Leveler_CacheSkillBarNow() Then
		Out("[Combat] Cache_SkillBar failed on map " & $l_i_Map)
		Return False
	EndIf
	$g_i_LastUAIMap = $l_i_Map
	$g_b_UAIReady = True
	Out("[Combat] UtilityAI skill bar cached on map " & $l_i_Map)
	Return True
EndFunc

; Cache when this instance can fight. Outposts skip. Punch-out caches after the brawling bar arrives.
; A town or mission lobby clears the flag even when it keeps the explorable's map id,
; so the next visit to that id is cached again.
Func Leveler_CacheIfFightMap()
	If Leveler_IsPunchoutMap() Then Return True
	Local $l_i_Map = Map_GetMapID()
	If $l_i_Map <> $g_i_LastUAIMap Then $g_b_UAIReady = False
	If Not Leveler_ShouldFightHere() Then
		$g_b_UAIReady = False
		Return True
	EndIf
	If $g_b_UAIReady And $g_i_LastUAIMap = $l_i_Map Then Return True
	Out("[Combat] Caching UtilityAI for explorable map " & $l_i_Map)
	Return Leveler_CacheUtilityAIForMap($l_i_Map)
EndFunc

; After a map load the old instance cache is invalid. Wait until this map can fight, then recache.
Func Leveler_CacheUtilityAIForMap($a_i_MapID)
	$g_b_CombatMode = True
	$g_b_UAIReady = False
	$g_i_LastUAIMap = 0
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < 15000
		If $g_b_LevelerPaused Then Return False
		If Map_GetMapID() = $a_i_MapID And Not Map_GetInstanceInfo("IsLoading") And Leveler_ShouldFightHere() Then ExitLoop
		Sleep(200)
	WEnd
	If Map_GetMapID() <> $a_i_MapID Then
		Out("[Combat] Wanted map " & $a_i_MapID & " for UtilityAI, now " & Map_GetMapID())
		Return False
	EndIf
	If Not Leveler_ShouldFightHere() Then
		Out("[Combat] Map " & $a_i_MapID & " is not ready for UtilityAI yet")
		Return False
	EndIf
	If Not Leveler_CacheSkillBarNow() Then
		Out("[Combat] Cache_SkillBar failed on map " & $a_i_MapID)
		Return False
	EndIf
	$g_i_LastUAIMap = $a_i_MapID
	$g_b_UAIReady = True
	Out("[Combat] UtilityAI skill bar cached on map " & $a_i_MapID)
	Return True
EndFunc

; Cache UtilityAI skill bar. Fronis is a dungeon, so its instance type is not always Explorable.
; Cache_SkillBar() refuses that and leaves CanUse_Brawling* unbound, so the fight never starts.
Func Leveler_CacheSkillBarNow()
	If Map_GetInstanceInfo("IsLoading") Then Return False
	If Map_GetInstanceInfo("IsExplorable") Then Return Cache_SkillBar()
	If Not Leveler_IsPunchoutMap() Then Return False
	UAI_CacheSkillBar()
	Local $i
	For $i = 1 To 8
		$g_as_BestTargetCache[$i] = UAI_GetBestTargetFunc($i)
		$g_as_CanUseCache[$i] = UAI_GetCanUseFunc($i)
	Next
	If $g_b_CacheWeaponSet Then UAI_DetermineWeaponSets()
	Return True
EndFunc

; Turn combat mode off so pathing does not fight.
Func Leveler_SetPacifist()
	$g_b_CombatMode = False
	Return True
EndFunc

#EndRegion UtilityAI
