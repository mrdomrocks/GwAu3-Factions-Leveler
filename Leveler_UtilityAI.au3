#include-once

; Leveler combat on top of UtilityAI. The API plugin is left unchanged.
; Pathfinder still calls UAI_Fight, so movement passes aggro -1 and fights here.

Global $g_b_LevelerPathCombat = False

; True while skillbar+0xB0 says a bar skill is activating.
Func UAI_GetIsCasting()
	If $g_p_StaticSkillbarPtr = 0 Then Return False
	Return Memory_Read($g_p_StaticSkillbarPtr + 0xB0) <> 0
EndFunc

; The API dynamic cache is wiped and reread from $g_p_StaticSkillbarPtr.
; That pointer moves on knockdown, and a failed read leaves every slot at 0, so UAI_CanUse refuses the bar.
; Re-find the bar and copy adrenaline and recharge with the same offsets as Skill_GetSkillbarInfo.
Func Leveler_UAI_RefreshSkillCache()
	If Map_GetInstanceInfo("IsLoading") Then Return False
	If Not Leveler_RebindSkillbarPtr() Then Return False

	Local $l_p_Bar = $g_p_StaticSkillbarPtr
	Local $l_i_Timer = Utils_MakeInt32(Skill_GetSkillTimer())
	Local $l_b_BarChanged = False
	Local $i

	For $i = 1 To 8
		Local $l_i_LiveID = Memory_Read($l_p_Bar + 0x10 + (($i - 1) * 0x14), "dword")
		If $l_i_LiveID = 0 Then ContinueLoop
		If UAI_GetStaticSkillInfo($i, $GC_UAI_STATIC_SKILL_SkillID) <> $l_i_LiveID Then
			$l_b_BarChanged = True
			ExitLoop
		EndIf
	Next

	If $l_b_BarChanged Then
		If Not Leveler_CacheSkillBarNow() Then Return False
		If Not Leveler_RebindSkillbarPtr() Then Return False
		$l_p_Bar = $g_p_StaticSkillbarPtr
		If $g_b_KilroyMode Or $g_b_FarmMode Or Leveler_IsPunchoutMap() Then Leveler_ResolveKilroySlotsFromCache()
		Out("[Combat] Skill bar changed. UtilityAI skill cache rebuilt.")
	EndIf

	For $i = 1 To 8
		Local $l_i_Off = ($i - 1) * 0x14
		Local $l_i_LiveID = Memory_Read($l_p_Bar + 0x10 + $l_i_Off, "dword")
		; A downed bar can read empty. Keep the last good slot instead of zeroing it.
		If $l_i_LiveID = 0 Then ContinueLoop

		Local $l_i_AdrenA = Memory_Read($l_p_Bar + 0x4 + $l_i_Off, "dword")
		Local $l_i_AdrenB = Memory_Read($l_p_Bar + 0x8 + $l_i_Off, "dword")
		; CanUse only reads the first adrenaline field. Some bars keep the count in the second.
		Local $l_i_Adren = $l_i_AdrenA
		If $l_i_Adren = 0 And $l_i_AdrenB > 0 And $l_i_AdrenB <= 1000 Then $l_i_Adren = $l_i_AdrenB

		$g_amx2_DynamicSkillCache[$i][$GC_UAI_DYNAMIC_SKILL_Adrenaline] = $l_i_Adren
		$g_amx2_DynamicSkillCache[$i][$GC_UAI_DYNAMIC_SKILL_AdrenalineB] = $l_i_AdrenB
		$g_amx2_DynamicSkillCache[$i][$GC_UAI_DYNAMIC_SKILL_SkillID] = $l_i_LiveID
		$g_amx2_DynamicSkillCache[$i][$GC_UAI_DYNAMIC_SKILL_Event] = Memory_Read($l_p_Bar + 0x14 + $l_i_Off, "dword")

		Local $l_i_Stamp = Memory_Read($l_p_Bar + 0xC + $l_i_Off, "dword")
		If $l_i_Stamp = 0 Then
			$g_amx2_DynamicSkillCache[$i][$GC_UAI_DYNAMIC_SKILL_IsRecharged] = True
			$g_amx2_DynamicSkillCache[$i][$GC_UAI_DYNAMIC_SKILL_RechargeTime] = 0
		Else
			Local $l_i_Left = Utils_MakeInt32($l_i_Stamp) - $l_i_Timer
			If $l_i_Left <= 0 Then
				$g_amx2_DynamicSkillCache[$i][$GC_UAI_DYNAMIC_SKILL_IsRecharged] = True
				$g_amx2_DynamicSkillCache[$i][$GC_UAI_DYNAMIC_SKILL_RechargeTime] = 0
			Else
				$g_amx2_DynamicSkillCache[$i][$GC_UAI_DYNAMIC_SKILL_IsRecharged] = False
				$g_amx2_DynamicSkillCache[$i][$GC_UAI_DYNAMIC_SKILL_RechargeTime] = $l_i_Left
			EndIf
		EndIf

		; A zero cost makes an adrenaline skill look like a cooldown skill, so the finisher never waits for adrenaline.
		Local $l_i_Need = Skill_GetSkillInfo($l_i_LiveID, "Adrenaline")
		If $l_i_Need <> 0 And UAI_GetStaticSkillInfo($i, $GC_UAI_STATIC_SKILL_Adrenaline) <> $l_i_Need Then
			$g_amx2_StaticSkillCache[$i][$GC_UAI_STATIC_SKILL_Adrenaline] = $l_i_Need
		EndIf
	Next
	Return True
EndFunc

; Pathfinder tick. Spirit rifts, then the leveler fight instead of the API UAI_Fight.
Func Leveler_PathCombat()
	If $g_b_SpiritRiftWatch Then Leveler_InterruptSpiritRifts()
	If Not $g_b_LevelerPathCombat Then Return
	If Not Leveler_ShouldFightHere() Then Return
	Leveler_UAI_Fight(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), $LEVELER_AGGRO, $LEVELER_FIGHT_RANGE_OUT)
EndFunc

; Fight until the aggro pack is clear, the party wipes, or the map changes.
Func Leveler_UAI_Fight($a_f_x, $a_f_y, $a_f_AggroRange = 1320, $a_f_MaxDistanceToXY = 3500)
	$g_i_BestTarget = 0
	$g_i_ForceTarget = 0
	$g_i_AttackTarget = 0
	$g_i_LastCalledTarget = 0

	Local $l_i_MyOldMap = Map_GetMapID()
	Local $l_i_MapLoadingOld = Map_GetInstanceInfo("Type")

	Do
		If Agent_GetDistanceToXY($a_f_x, $a_f_y) > $a_f_AggroRange Then ExitLoop
		Leveler_UAI_UseSkills($a_f_x, $a_f_y, $a_f_AggroRange, $a_f_MaxDistanceToXY)
	Until UAI_CountEnemyInPartyAggroRange($a_f_AggroRange) = 0 Or Agent_GetAgentInfo(-2, "IsDead") Or Party_IsWiped() Or Map_GetMapID() <> $l_i_MyOldMap Or Map_GetInstanceInfo("Type") <> $l_i_MapLoadingOld

	Return True
EndFunc

; One pass of the bar. Skills fire before auto-attack.
Func Leveler_UAI_UseSkills($a_f_x, $a_f_y, $a_f_AggroRange = 1320, $a_f_MaxDistanceToXY = 3500)
	For $skillSlot = 1 To 8
		If UAI_GetStaticSkillInfo($skillSlot, $GC_UAI_STATIC_SKILL_SkillID) = 0 Then ContinueLoop
		If $g_b_SkillChanged = True And Cache_EndFormChangeBuild($skillSlot) Then $g_b_SkillChanged = False

		UAI_UpdateAgentCache($a_f_AggroRange)
		Leveler_UAI_RefreshSkillCache()

		If Not UAI_IsEnemyInPartyAggroRange($a_f_AggroRange) Then ExitLoop
		If UAI_GetPlayerInfo($GC_UAI_AGENT_IsDead) Or UAI_GetPlayerInfo($GC_UAI_AGENT_IsKnockedDown) Or Map_GetInstanceInfo("Type") <> $GC_I_MAP_TYPE_EXPLORABLE Then ExitLoop

		If $a_f_MaxDistanceToXY <> 0 And Agent_GetDistanceToXY($a_f_x, $a_f_y) > $a_f_MaxDistanceToXY Then ExitLoop

		If Not UAI_IsAgentInRange(-2, $a_f_AggroRange, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsNotAvoided") _
				And Agent_GetDistanceToXY($a_f_x, $a_f_y) <= $a_f_AggroRange Then
			Local $l_i_PartyRangeEnemy = UAI_GetNearestEnemyInPartyRange($a_f_AggroRange)
			If $l_i_PartyRangeEnemy <> 0 Then
				Map_Move(UAI_GetAgentInfoByID($l_i_PartyRangeEnemy, $GC_UAI_AGENT_X), UAI_GetAgentInfoByID($l_i_PartyRangeEnemy, $GC_UAI_AGENT_Y), 0)
				Sleep(500)
			EndIf
			ExitLoop
		EndIf

		If $g_b_CacheWeaponSet Then UAI_ShouldSwitchWeaponSet()

		Local $l_b_UsedSkill = False
		If Leveler_UAI_PrioritySkills($a_f_AggroRange) Then
			$l_b_UsedSkill = True
			Local $l_i_UsedSlot = @extended
			If $l_i_UsedSlot = $skillSlot Then
				Sleep(128)
				ContinueLoop
			EndIf
			UAI_UpdateAgentCache($a_f_AggroRange)
			Leveler_UAI_RefreshSkillCache()
		EndIf

		UAI_DropBundle($a_f_AggroRange)

		If Leveler_UAI_TryUseSkill($skillSlot, $a_f_AggroRange) Then $l_b_UsedSkill = True

		; After skills. A new Attack packet restarts the swing, so adrenaline builds and the hit never lands.
		If Not $l_b_UsedSkill Then
			If UAI_CanAutoAttack() Then
				Leveler_UAI_AutoAttack($a_f_AggroRange)
			Else
				If UAI_GetPlayerInfo($GC_UAI_AGENT_IsAttacking) Then Core_ControlAction($GC_I_CONTROL_ACTION_CANCEL_ACTION)
			EndIf
		EndIf

		Sleep(128)
	Next

	Return True
EndFunc

; Try the priority slots before the rest of the bar.
Func Leveler_UAI_PrioritySkills($a_f_AggroRange = 1320)
	For $i = 1 To $g_ai_PrioritySlots[0]
		Local $l_i_SkillSlot = $g_ai_PrioritySlots[$i]
		If Leveler_UAI_TryUseSkill($l_i_SkillSlot, $a_f_AggroRange) Then Return SetExtended($l_i_SkillSlot, True)
	Next
	Return False
EndFunc

; Cast one slot when its CanUse check and target are both valid.
Func Leveler_UAI_TryUseSkill($a_i_Slot, $a_f_AggroRange = 1320)
	Leveler_UAI_RefreshSkillCache()
	If Not UAI_CanUse($a_i_Slot) Then Return False

	$g_i_BestTarget = Call($g_as_BestTargetCache[$a_i_Slot], $a_f_AggroRange)
	Local $l_b_OverrideForceTarget = (@extended = $GC_I_UAI_OVERRIDE_FORCE_TARGET)
	If Not $l_b_OverrideForceTarget And $g_i_ForceTarget <> 0 And UAI_GetAgentInfoByID($g_i_BestTarget, $GC_UAI_AGENT_Allegiance) = $GC_I_ALLEGIANCE_ENEMY Then
		$g_i_BestTarget = $g_i_ForceTarget
	EndIf

	If $g_i_BestTarget = 0 Then Return False
	If Not UAI_Filter_IsNotAvoided($g_i_BestTarget) Then Return False

	$g_b_CanUseSkill = Call($g_as_CanUseCache[$a_i_Slot])
	If Not ($g_b_CanUseSkill And Agent_GetDistance($g_i_BestTarget) < $a_f_AggroRange) Then Return False

	Leveler_UAI_UseSkillEx($a_i_Slot, $g_i_BestTarget, $a_f_AggroRange)
	If Cache_FormChangeBuild($a_i_Slot) Then $g_b_SkillChanged = True

	Return True
EndFunc

; Wait until idle, send the skill, and wait out a real cast.
Func Leveler_UAI_UseSkillEx($a_i_SkillSlot, $a_i_AgentID = -2, $a_f_AggroRange = 1320)
	Local $l_i_MyID = Agent_GetMyID()
	If $a_i_AgentID <> $l_i_MyID Then Agent_ChangeTarget($a_i_AgentID)

	If $g_b_CacheWeaponSet Then UAI_GetBestWeaponSetBySkillSlot($a_i_SkillSlot)

	If $g_i_TargetMode = $GC_UAI_TARGET_MODE_CALL Then
		Local $l_i_Target = $a_i_AgentID
		If $g_i_ForceTarget <> 0 Then $l_i_Target = $g_i_ForceTarget
		If $l_i_Target <> 0 And $l_i_Target <> $l_i_MyID And $l_i_Target <> $g_i_LastCalledTarget Then
			Agent_CallTarget($l_i_Target)
			$g_i_LastCalledTarget = $l_i_Target
		EndIf
	EndIf

	Local $l_i_SkillID = UAI_GetStaticSkillInfo($a_i_SkillSlot, $GC_UAI_STATIC_SKILL_SkillID)
	Local $l_i_SkillType = UAI_GetStaticSkillInfo($a_i_SkillSlot, $GC_UAI_STATIC_SKILL_SkillType)
	Local $l_i_ActivationTime = UAI_GetStaticSkillInfo($a_i_SkillSlot, $GC_UAI_STATIC_SKILL_Activation)
	Local $l_i_Special = UAI_GetStaticSkillInfo($a_i_SkillSlot, $GC_UAI_STATIC_SKILL_Special)
	Local $l_b_IsRes = (BitAND($l_i_Special, $GC_I_SKILL_SPECIAL_FLAG_RESURRECTION) <> 0)
	Local $l_b_IsSpell = ($l_i_SkillType = $GC_I_SKILL_TYPE_SPELL Or $l_i_SkillType = $GC_I_SKILL_TYPE_HEX Or $l_i_SkillType = $GC_I_SKILL_TYPE_ENCHANTMENT _
			Or $l_i_SkillType = $GC_I_SKILL_TYPE_WARD Or $l_i_SkillType = $GC_I_SKILL_TYPE_WELL Or $l_i_SkillType = $GC_I_SKILL_TYPE_WEAPON_SPELL _
			Or $l_i_SkillType = $GC_I_SKILL_TYPE_ITEM_SPELL)
	; Zero-activation attacks never set the cast-start flag. Tracking them waits out the timeout.
	Local $l_b_InstantCast = ($l_b_IsSpell And (UAI_PlayerHasEffect($GC_I_SKILL_ID_GLYPH_OF_SACRIFICE) Or UAI_PlayerHasEffect($GC_I_SKILL_ID_GLYPH_OF_ESSENCE))) _
			Or ($l_i_ActivationTime = 0)
	Local $l_b_TrackInstantCast = ($l_b_InstantCast And $l_i_SkillType <> $GC_I_SKILL_TYPE_SHOUT And $l_i_SkillType <> $GC_I_SKILL_TYPE_STANCE And $l_i_SkillType <> $GC_I_SKILL_TYPE_ATTACK)

	Local $l_h_Idle = TimerInit()
	While Not Leveler_UAI_GetIsIdle($l_i_MyID)
		If Not Leveler_UAI_TargetIsValid($a_i_AgentID, $l_b_IsRes) Then Return False
		UAI_UpdateAgentCache($a_f_AggroRange)
		Leveler_UAI_RefreshSkillCache()
		If Not UAI_CanUse($a_i_SkillSlot) Then Return False
		If TimerDiff($l_h_Idle) > 5000 Then Return False
		Sleep(32)
	WEnd

	If $l_b_InstantCast Then
		Skill_UseSkill($a_i_SkillSlot, $a_i_AgentID)
		If $l_b_TrackInstantCast Then
			Local $l_h_CastStart = TimerInit()
			While Not Leveler_UAI_GetIsCastingSkill($l_i_MyID, 0)
				If Not Leveler_UAI_TargetIsValid($a_i_AgentID, $l_b_IsRes) Then Return False
				UAI_UpdateAgentCache($a_f_AggroRange)
				Leveler_UAI_RefreshSkillCache()
				If Not UAI_CanUse($a_i_SkillSlot) Then Return False
				If TimerDiff($l_h_CastStart) > 1000 Then Return False
			WEnd
		EndIf
	Else
		Skill_UseSkill($a_i_SkillSlot, $a_i_AgentID)
		Local $l_h_CastStart = TimerInit()
		While Not Leveler_UAI_GetIsCastingSkill($l_i_MyID, $l_i_SkillID)
			If Not Leveler_UAI_TargetIsValid($a_i_AgentID, $l_b_IsRes) Then Return False
			UAI_UpdateAgentCache($a_f_AggroRange)
			Leveler_UAI_RefreshSkillCache()
			If Not UAI_CanUse($a_i_SkillSlot) Then Return False
			If TimerDiff($l_h_CastStart) > 5000 Then Return False
			Sleep(32)
		WEnd
	EndIf

	If Not $l_b_InstantCast Then
		Local $l_f_AggroRangeSq = $a_f_AggroRange * $a_f_AggroRange
		Local $l_f_CastEndTimeout = ($l_i_SkillType = $GC_I_SKILL_TYPE_ATTACK ? (4.05 * 1000) * 1.05 : ($l_i_ActivationTime * 1000) * 2.55)
		Local $l_h_CastEnd = TimerInit()

		While Leveler_UAI_GetIsCastingSkill($l_i_MyID, $l_i_SkillID) And Not Agent_GetAgentInfo($l_i_MyID, "IsKnockedDown")
			If Not Leveler_UAI_TargetIsValid($a_i_AgentID, $l_b_IsRes) Then
				Core_ControlAction($GC_I_CONTROL_ACTION_CANCEL_ACTION)
				ExitLoop
			EndIf
			If Agent_GetDistanceSq($a_i_AgentID) > $l_f_AggroRangeSq Then ExitLoop
			If TimerDiff($l_h_CastEnd) > $l_f_CastEndTimeout Then ExitLoop
			Sleep(32)
		WEnd
	EndIf

	Return True
EndFunc

; A resurrection skill wants a dead target. Every other skill wants a living one.
Func Leveler_UAI_TargetIsValid($a_i_AgentID, $a_b_IsRes)
	Local $l_b_Dead = Agent_GetAgentInfo($a_i_AgentID, "IsDead")
	Return ($a_b_IsRes ? $l_b_Dead : Not $l_b_Dead)
EndFunc

; True during a weapon swing. That swing is not a bar-skill cast.
Func Leveler_UAI_IsWeaponSwing($a_i_AgentID)
	Local $l_i_State = Agent_GetAgentInfo($a_i_AgentID, "ModelState")
	Return $l_i_State = 0x40 Or $l_i_State = 0x60 Or $l_i_State = 0x440 Or $l_i_State = 0x460
EndFunc

; Idle for the next skill. A weapon swing does not block the bar.
Func Leveler_UAI_GetIsIdle($a_i_AgentID)
	; 0xB0 is read through the skillbar pointer. Re-find the bar before trusting it.
	Leveler_UAI_RefreshSkillCache()
	; A weapon swing is not a skill-bar cast. Waiting on it makes every skill time out.
	If Leveler_UAI_IsWeaponSwing($a_i_AgentID) Then Return True
	If $g_p_StaticSkillbarPtr = 0 Then Return Agent_GetAgentInfo($a_i_AgentID, "Skill") = 0
	If Memory_Read($g_p_StaticSkillbarPtr + 0xB0) = 0 Then Return True
	Local $l_i_Skill = Agent_GetAgentInfo($a_i_AgentID, "Skill")
	If $l_i_Skill = 0 Or $l_i_Skill = $GC_I_SKILL_ID_STAND_UP Then Return True
	Local $i
	For $i = 1 To 8
		If UAI_GetStaticSkillInfo($i, $GC_UAI_STATIC_SKILL_SkillID) <> $l_i_Skill Then ContinueLoop
		Return UAI_GetStaticSkillInfo($i, $GC_UAI_STATIC_SKILL_Activation) = 0
	Next
	Return True
EndFunc

; True while skillbar+0xB0 is set and the agent is using this skill id.
Func Leveler_UAI_GetIsCastingSkill($a_i_AgentID, $a_i_SkillID)
	Return (Memory_Read($g_p_StaticSkillbarPtr + 0xB0) <> 0 And Agent_GetAgentInfo($a_i_AgentID, "Skill") = $a_i_SkillID)
EndFunc

; Start one weapon attack. Do not resend it while that swing is already going.
Func Leveler_UAI_AutoAttack($a_f_AggroRange)
	Local $l_i_AttackTarget = 0

	If $g_i_ForceTarget <> 0 Then
		$l_i_AttackTarget = $g_i_ForceTarget
	ElseIf $g_i_AttackTarget <> 0 And Not UAI_GetAgentInfoByID($g_i_AttackTarget, $GC_UAI_AGENT_IsDead) Then
		$l_i_AttackTarget = $g_i_AttackTarget
	Else
		$l_i_AttackTarget = UAI_GetNearestAgent(-2, $a_f_AggroRange, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsNotAvoided")
	EndIf

	; Re-sending Attack restarts the swing. Adrenaline ticks and the hit never lands.
	If $l_i_AttackTarget <> 0 Then
		Local $l_i_TargetID = Agent_ConvertID($l_i_AttackTarget)
		If Not Leveler_UAI_IsWeaponSwing(-2) Or Agent_GetCurrentTarget() <> $l_i_TargetID Then
			Agent_Attack($l_i_AttackTarget, False)
		EndIf
	EndIf
	$g_i_AttackTarget = $l_i_AttackTarget

	If $g_i_LastCalledTarget = 0 And $g_i_TargetMode = $GC_UAI_TARGET_MODE_CALL Then
		Agent_CallTarget($l_i_AttackTarget)
		$g_i_LastCalledTarget = $l_i_AttackTarget
	EndIf
EndFunc
