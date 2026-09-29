#include-once

; Profession skill templates and trainer-bar load.
; Mid and level-20 bars assume Mesmer secondary (Domination / Inspiration).
; Equipment piece IDs live in Leveler_Craft.au3.

#Region Templates

Global Const $LEVELER_BAR_STARTER = 0
Global Const $LEVELER_BAR_INTERRUPT = 1
Global Const $LEVELER_BAR_INSPIRE = 2
; Mesmer bar used from Zen Daijun until Kaineng. Primary must match the character.
; Illusion 7, Domination 6: Signet of Disruption, Leech Signet, Conjure Phantasm,
; Ether Feast, Empathy, Backfire, Shatter Hex. Apply the template; do not check slots.
Global Const $LEVELER_BAR_ZEN = 3

; Return the profession skill-template code for starter, interrupt, or inspire.
Func Leveler_ProfessionSkillBar($a_i_Kind, $a_i_Prof = 0)
	If $a_i_Prof = 0 Then $a_i_Prof = Leveler_PrimaryProfession()
	Switch $a_i_Kind
		Case $LEVELER_BAR_STARTER
			Switch $a_i_Prof
				Case $GC_I_PROFESSION_WARRIOR
					Return "OQAAAAAAAAAAAAAA"
				Case $GC_I_PROFESSION_RANGER
					Return "OgAAAAAAAAAAAAAA"
				Case $GC_I_PROFESSION_MONK
					Return "OwAAAAAAAAAAAAAA"
				Case $GC_I_PROFESSION_NECROMANCER
					Return "OABAAAAAAAAAAAAA"
				Case $GC_I_PROFESSION_MESMER
					Return "OQBAAAAAAAAAAAAA"
				Case $GC_I_PROFESSION_ELEMENTALIST
					Return "OgBAAAAAAAAAAAAA"
				Case $GC_I_PROFESSION_RITUALIST
					Return "OACAAAAAAAAAAAAA"
				Case $GC_I_PROFESSION_ASSASSIN
					Return "OwBAAAAAAAAAAAAA"
			EndSwitch
			Return "OQAAAAAAAAAAAAAA"
		Case $LEVELER_BAR_INTERRUPT
			; Domination 12: Cry of Frustration, Power Drain, Signet of Disruption
			Switch $a_i_Prof
				Case $GC_I_PROFESSION_WARRIOR
					Return "OQUBIskDcdG0DaAKUECA"
				Case $GC_I_PROFESSION_RANGER
					Return "OgUBIskDcdG0DaAKUECA"
				Case $GC_I_PROFESSION_MONK
					Return "OwUBIskDcdG0DaAKUECA"
				Case $GC_I_PROFESSION_NECROMANCER
					Return "OAVBIskDcdG0DaAKUECA"
				Case $GC_I_PROFESSION_MESMER
					Return "OQBBIskDcdG0DaAKUECA"
				Case $GC_I_PROFESSION_ELEMENTALIST
					Return "OgVBIskDcdG0DaAKUECA"
				Case $GC_I_PROFESSION_RITUALIST
					Return "OAWBIskDcdG0DaAKUECA"
				Case $GC_I_PROFESSION_ASSASSIN
					Return "OwVBIskDcdG0DaAKUECA"
			EndSwitch
			Return "OQUBIskDcdG0DaAKUECA"
		Case $LEVELER_BAR_INSPIRE
			; Adds Inspiration for energy
			Switch $a_i_Prof
				Case $GC_I_PROFESSION_WARRIOR
					Return "OQUCErwSOw1ZQPoBoQRIA"
				Case $GC_I_PROFESSION_RANGER
					Return "OgUCErwSOw1ZQPoBoQRIA"
				Case $GC_I_PROFESSION_MONK
					Return "OwUCErwSOw1ZQPoBoQRIA"
				Case $GC_I_PROFESSION_NECROMANCER
					Return "OAVCErwSOw1ZQPoBoQRIA"
				Case $GC_I_PROFESSION_MESMER
					Return "OQBCErwSOw1ZQPoBoQRIA"
				Case $GC_I_PROFESSION_ELEMENTALIST
					Return "OgVCErwSOw1ZQPoBoQRIA"
				Case $GC_I_PROFESSION_RITUALIST
					Return "OAWCErwSOw1ZQPoBoQRIA"
				Case $GC_I_PROFESSION_ASSASSIN
					Return "OwVCErwSOw1ZQPoBoQRIA"
			EndSwitch
			Return "OQUCErwSOw1ZQPoBoQRIA"
		Case $LEVELER_BAR_ZEN
			; Same Mesmer skills. Only the primary profession byte changes.
			; Mesmer primary keeps the current secondary (template secondary 0).
			Switch $a_i_Prof
				Case $GC_I_PROFESSION_WARRIOR
					Return "OQUCEnYCX3DfAKoBcwQAAA"
				Case $GC_I_PROFESSION_RANGER
					Return "OgUCEnYCX3DfAKoBcwQAAA"
				Case $GC_I_PROFESSION_MONK
					Return "OwUCEnYCX3DfAKoBcwQAAA"
				Case $GC_I_PROFESSION_NECROMANCER
					Return "OAVCEnYCX3DfAKoBcwQAAA"
				Case $GC_I_PROFESSION_MESMER
					Return "OQBCEnYCX3DfAKoBcwQAAA"
				Case $GC_I_PROFESSION_ELEMENTALIST
					Return "OgVCEnYCX3DfAKoBcwQAAA"
				Case $GC_I_PROFESSION_ASSASSIN
					Return "OwVCEnYCX3DfAKoBcwQAAA"
				Case $GC_I_PROFESSION_RITUALIST
					Return "OAWCEnYCX3DfAKoBcwQAAA"
			EndSwitch
			Return ""
	EndSwitch
	Return ""
EndFunc

#EndRegion Templates

#Region Load

; Zen Daijun through the walk to Kaineng. Michiko changes the bar after this.
Func Leveler_UsesZenSkillBar()
	If Leveler_InterruptSkillsUnlocked() Then Return False
	If $g_i_Step >= $LEVELER_STEP_ZEN_MISSION And $g_i_Step < $LEVELER_STEP_SKILLS2 Then Return True
	Local $l_i_Map = Map_GetMapID()
	If $l_i_Map = $MAP_ZEN_OP Or $l_i_Map = $MAP_ZEN_EXP Then Return True
	If $l_i_Map = $MAP_MARKETPLACE Or $l_i_Map = $MAP_KAINENG_DOCKS Then Return True
	If $l_i_Map = $MAP_BUKDEK Or $l_i_Map = $MAP_WAJJUN Then Return True
	Return False
EndFunc

; Pick starter, interrupt, inspire, or Zen bar from learnt skills and level.
Func Leveler_CurrentSkillBarKind()
	Local $l_i_Level = Agent_GetAgentInfo(-2, "Level")
	If Leveler_InterruptSkillsUnlocked() Then
		If $l_i_Level >= 20 And Leveler_Skills2Unlocked() Then Return $LEVELER_BAR_INSPIRE
		Return $LEVELER_BAR_INTERRUPT
	EndIf
	If Leveler_UsesZenSkillBar() Then Return $LEVELER_BAR_ZEN
	Return $LEVELER_BAR_STARTER
EndFunc

; Load the profession template in an outpost. Skips the empty starter after Zhao Di.
Func Leveler_LoadProfessionSkillBar($a_i_Kind = -1)
	If $a_i_Kind < 0 Then $a_i_Kind = Leveler_CurrentSkillBarKind()
	If $a_i_Kind = $LEVELER_BAR_ZEN Then Return Leveler_LoadZenSkillBar()
	; Empty starter is Skill_LoadSkillBar(0,0,...). After Zhao Di that wipes the bar
	; and the SKILLBAR_LOAD packet right before EnterChallenge can disconnect.
	If $a_i_Kind = $LEVELER_BAR_STARTER And Leveler_ZhaoDiSkillsUnlocked() Then
		Out("[Skills] Skipping empty starter template; Zhao Di skills would be wiped")
		Return False
	EndIf
	If ($a_i_Kind = $LEVELER_BAR_INTERRUPT Or $a_i_Kind = $LEVELER_BAR_INSPIRE) And Not Leveler_InterruptSkillsUnlocked() Then
		Out("[Skills] Skipping interrupt template; Cry of Frustration / Power Drain are not learnt yet")
		Return False
	EndIf
	If Not Map_GetInstanceInfo("IsOutpost") Then
		Out("[Skills] Skill template can only be loaded in an outpost")
		Return False
	EndIf
	Local $l_s_Bar = Leveler_ProfessionSkillBar($a_i_Kind)
	If $l_s_Bar = "" Then Return False
	Out("[Skills] Loading profession " & Leveler_PrimaryProfession() & " bar kind " & $a_i_Kind)
	Local $l_b_Ok = Attribute_LoadSkillTemplate($l_s_Bar)
	Sleep(800)
	If $l_b_Ok Then Out("[Skills] Profession skill template loaded")
	If Not $l_b_Ok Then Out("[Skills] Profession skill template failed; will set trainer skills by slot")
	Return $l_b_Ok
EndFunc

; Load the Zen Daijun Mesmer bar for this character's primary. Do not use Skill_LoadSkillBar.
Func Leveler_LoadZenSkillBar()
	$g_b_UAIReady = False
	If Not Map_GetInstanceInfo("IsOutpost") Then Return True
	Local $l_i_Map = Map_GetMapID()
	Local $l_s_Bar = Leveler_ProfessionSkillBar($LEVELER_BAR_ZEN)
	If $l_s_Bar = "" Then
		Out("[Skills] No Zen skill template for profession " & Leveler_PrimaryProfession())
		Return False
	EndIf
	; Skip reload if the template is already on this map.
	If $g_i_ZenBarLoadedMap = $l_i_Map And Skill_GetSkillbarInfo(1, "SkillID") <> 0 Then
		Out("[Skills] Zen skill template already loaded on map " & $l_i_Map)
		Return True
	EndIf
	Out("[Skills] Loading skill template " & $l_s_Bar)
	Local $l_b_Ok = Attribute_LoadSkillTemplate($l_s_Bar)
	Sleep(800)
	If $l_b_Ok Then
		$g_i_ZenBarLoadedMap = $l_i_Map
		Out("[Skills] Zen skill template loaded for profession " & Leveler_PrimaryProfession())
	Else
		Out("[Skills] Zen skill template failed for profession " & Leveler_PrimaryProfession())
	EndIf
	Return $l_b_Ok
EndFunc

#EndRegion Load

#Region Skill Bar

; True when this character or the account already has the skill.
Func Leveler_SkillIsLearnt($a_i_SkillID)
	If World_IsSkillLearnt($a_i_SkillID) Then Return True
	Return Account_IsSkillUnlocked($a_i_SkillID)
EndFunc

; Poll until the skill shows as learnt, or the wait times out.
Func Leveler_WaitSkillLearnt($a_i_SkillID)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < 8000
		If Leveler_SkillIsLearnt($a_i_SkillID) Then Return True
		Sleep(250)
	WEnd
	Return Leveler_SkillIsLearnt($a_i_SkillID)
EndFunc

; Skill_GetSkillbarInfo only accepts slots 1-8, not skill IDs.
Func Leveler_BarHasSkill($a_i_SkillID)
	Local $i
	For $i = 1 To 8
		If Skill_GetSkillbarInfo($i, "SkillID") = $a_i_SkillID Then Return True
	Next
	Return False
EndFunc

; Put a learnt skill on a bar slot and wait until the bar shows it.
Func Leveler_PutSkillOnBar($a_i_Slot, $a_i_SkillID)
	If $a_i_SkillID = 0 Then Return True
	If Skill_GetSkillbarInfo($a_i_Slot, "SkillID") = $a_i_SkillID Then Return True
	If Not Leveler_WaitSkillLearnt($a_i_SkillID) Then
		Out("[Skills] Skill " & $a_i_SkillID & " is not learnt yet")
		Return False
	EndIf
	Local $i
	For $i = 1 To 6
		If Skill_GetSkillbarInfo($a_i_Slot, "SkillID") = $a_i_SkillID Then Return True
		Skill_SetSkillbarSkill($a_i_Slot, $a_i_SkillID)
		Local $l_h_Timer = TimerInit()
		While TimerDiff($l_h_Timer) < 2000
			Sleep(200)
			If Skill_GetSkillbarInfo($a_i_Slot, "SkillID") = $a_i_SkillID Then
				Out("[Skills] Slot " & $a_i_Slot & " = skill " & $a_i_SkillID)
				Return True
			EndIf
		WEnd
	Next
	Out("[Skills] Slot " & $a_i_Slot & " is " & Skill_GetSkillbarInfo($a_i_Slot, "SkillID") & ", wanted " & $a_i_SkillID)
	Return False
EndFunc

; Cancel the trainer dialog and step off so the window closes.
Func Leveler_CloseTrainerWindow()
	Agent_CancelAction()
	Sleep(300)
	Local $l_f_X = Agent_GetAgentInfo(-2, "X")
	Local $l_f_Y = Agent_GetAgentInfo(-2, "Y")
	Map_Move($l_f_X + 80, $l_f_Y + 80, 20)
	Sleep(700)
	Agent_CancelAction()
	Sleep(200)
EndFunc

; True when the current trainer set (Zhao Di or the interrupt set) is on the bar.
Func Leveler_TrainerSkillsOnBar()
	If Leveler_InterruptSkillsUnlocked() Then
		If Not Leveler_BarHasSkill($SKILL_CRY_OF_FRUSTRATION) Then Return False
		If Not Leveler_BarHasSkill($SKILL_POWER_DRAIN) Then Return False
		If Not Leveler_BarHasSkill($SKILL_SIGNET_OF_DISRUPTION) Then Return False
		Return True
	EndIf
	If Not Leveler_BarHasSkill($SKILL_SIGNET_OF_DISRUPTION) Then Return False
	If Not Leveler_BarHasSkill($SKILL_LEECH_SIGNET) Then Return False
	Return True
EndFunc

; Buy a skill from the open trainer when it is not already learnt.
Func Leveler_BuySkillIfNeeded($a_i_SkillID)
	If World_IsSkillLearnt($a_i_SkillID) Then Return True
	Skill_BuySkillByID($a_i_SkillID)
	If Leveler_WaitSkillLearnt($a_i_SkillID) Then Return True
	Out("[Skills] Could not learn skill " & $a_i_SkillID)
	Return False
EndFunc

; Monastery: SoD, Leech Signet, Energy Burn. Kaineng: Cry, Power Drain, SoD.
; $a_b_CloseTrainer False at Cho so we do not walk off Kayao.
Func Leveler_EquipTrainerSkills($a_b_CloseTrainer = True)
	$g_b_UAIReady = False
	If $a_b_CloseTrainer Then Leveler_CloseTrainerWindow()
	If Leveler_TrainerSkillsOnBar() Then
		Out("[Skills] Trainer skills are already on the bar")
		Return True
	EndIf

	If Leveler_InterruptSkillsUnlocked() Then
		Local $l_i_Kind = Leveler_CurrentSkillBarKind()
		If $l_i_Kind = $LEVELER_BAR_STARTER Then $l_i_Kind = $LEVELER_BAR_INTERRUPT
		Leveler_LoadProfessionSkillBar($l_i_Kind)
		Sleep(600)
		If Leveler_TrainerSkillsOnBar() Then Return True
		Leveler_PutSkillOnBar(1, $SKILL_CRY_OF_FRUSTRATION)
		Leveler_PutSkillOnBar(2, $SKILL_POWER_DRAIN)
		Leveler_PutSkillOnBar(3, $SKILL_SIGNET_OF_DISRUPTION)
		If Leveler_TrainerSkillsOnBar() Then Return True
		Out("[Skills] Interrupt skills are learnt but not all on the bar yet")
		Return False
	EndIf

	Local $l_i_Slot = 1
	If World_IsSkillLearnt($SKILL_SIGNET_OF_DISRUPTION) Then
		Leveler_PutSkillOnBar($l_i_Slot, $SKILL_SIGNET_OF_DISRUPTION)
		$l_i_Slot += 1
	EndIf
	If World_IsSkillLearnt($SKILL_LEECH_SIGNET) Then
		Leveler_PutSkillOnBar($l_i_Slot, $SKILL_LEECH_SIGNET)
		$l_i_Slot += 1
	EndIf
	If World_IsSkillLearnt($SKILL_ENERGY_BURN) Then Leveler_PutSkillOnBar($l_i_Slot, $SKILL_ENERGY_BURN)
	If Leveler_TrainerSkillsOnBar() Then Return True
	Out("[Skills] Zhao Di skills are not all on the bar yet. Slots: " & Skill_GetSkillbarInfo(1, "SkillID") & ", " & Skill_GetSkillbarInfo(2, "SkillID") & ", " & Skill_GetSkillbarInfo(3, "SkillID"))
	Return False
EndFunc

; In an outpost, load the profession bar and fill any missing trainer skills.
Func Leveler_EquipSkillBar()
	If Not Map_GetInstanceInfo("IsOutpost") Then Return True
	If Leveler_InterruptSkillsUnlocked() Then
		Leveler_LoadProfessionSkillBar()
		If Not Leveler_TrainerSkillsOnBar() Then Leveler_EquipTrainerSkills()
		Return True
	EndIf
	If Leveler_UsesZenSkillBar() Then Return Leveler_LoadZenSkillBar()
	If Leveler_ZhaoDiSkillsUnlocked() Then Return Leveler_EquipTrainerSkills()
	Leveler_LoadProfessionSkillBar($LEVELER_BAR_STARTER)
	Return True
EndFunc

#EndRegion Skill Bar
