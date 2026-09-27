#include-once

; Hench invite lists and party prep for missions / Forming A Party.
; Preferred IDs are per-outpost party-window slots (1-based). Invites use Ui_AddNPC.

#Region Henchmen

; Prefer PartyContext HenchmenCount; fall back when the array size is stale.
Func Leveler_HenchmanCount()
	Local $l_i_Count = Party_GetPartyContextInfo("HenchmenCount")
	If $l_i_Count > 0 Then Return $l_i_Count
	$l_i_Count = Party_GetMyPartyInfo("ArrayHenchmanPartyMemberSize")
	If $l_i_Count > 0 Then Return $l_i_Count
	If Party_GetMyPartyHenchmanInfo(1, "AgentID") <> 0 Then Return 1
	Return 0
EndFunc

; Shing Jea Monastery / Seitung roster: 1 Lukas, 2 Yuun, 3 Taya, 4 Kisai, 5 Mai, 6 Aeson
Func Leveler_FormingPartyHenchIDs()
	; Yuun, Mai, Lukas — party of 4 for Forming A Party
	Local $l_ai_Hench[3] = [2, 5, 1]
	Return $l_ai_Hench
EndFunc

; Preferred henchman slot list for this map. Slots are 1-based party-window ids.
Func Leveler_HenchmenForMap($a_i_Map = 0)
	If $a_i_Map = 0 Then $a_i_Map = Map_GetMapID()
	Local $l_i_Max = Map_GetCurrentAreaInfo("MaxPartySize")

	; Shing Jea Monastery / Seitung: 1 Lukas, 2 Yuun, 3 Taya, 4 Kisai, 5 Mai, 6 Aeson
	If $a_i_Map = $MAP_SEITUNG Then
		; Yuun, Taya, Lukas, Aeson, Mai
		Local $l_ai_Seitung[5] = [2, 3, 1, 6, 5]
		Return $l_ai_Seitung
	EndIf

	; Zen Daijun: 1 Talon, 2 Zho, 3 Sister Tai, 4 Su, 5 Lo Sha, 6 Kai Ying, 7 Panaku, 8 Professor Gai
	If $a_i_Map = $MAP_ZEN_OP Then
		; Lo Sha, Sister Tai, Professor Gai, Su, Kai Ying
		Local $l_ai_Zen[5] = [5, 3, 8, 4, 6]
		Return $l_ai_Zen
	EndIf

	; Marketplace: 1 Talon, 2 Zho, 3 Sister Tai, 4 Su, 5 Lo Sha, 6 Vhang, 7 Kai Ying, 8 Panaku, 9 Professor Gai
	If $a_i_Map = $MAP_MARKETPLACE Then
		; Vhang, Professor Gai, Lo Sha, Talon, Su, Kai Ying, Sister Tai
		Local $l_ai_Market[7] = [6, 9, 5, 1, 4, 7, 3]
		Return $l_ai_Market
	EndIf

	; Kaineng Center: 1 Devona, 2 Talon, 3 Aidan, 4 Zho, 5 Sister Tai, 6 Eve, 7 Su, 8 Lo Sha, 9 Vhang, 10 Kai Ying, 11 Panaku, 12 Professor Gai
	If $a_i_Map = $MAP_KAINENG Then
		; Talon, Kai Ying, Zho, Lo Sha, Su, Vhang, Professor Gai
		Local $l_ai_Kc[7] = [2, 10, 4, 8, 7, 9, 12]
		Return $l_ai_Kc
	EndIf

	; EotN hench order: 1 Devona, 2 Talon, 3 Aidan, 4 Zho, 5 Lina, 6 Mhenlo, 7 Eve, 8 Lo Sha, 9 Cynn, 10 Herta
	If $a_i_Map = $MAP_BOREAL Then
		; Eve, Cynn, Talon, Aidan, Zho, Mhenlo, Lina
		Local $l_ai_Boreal[7] = [7, 9, 2, 3, 4, 6, 5]
		Return $l_ai_Boreal
	EndIf
	If $a_i_Map = $MAP_EOTN Or $a_i_Map = $MAP_HOM Then
		; Talon, Aidan, Lina, Mhenlo, Eve, Cynn, Herta
		Local $l_ai_Eotn[7] = [2, 3, 5, 6, 7, 9, 10]
		Return $l_ai_Eotn
	EndIf
	If $a_i_Map = $MAP_GUNNAR Then
		; Zho, Lina, Mhenlo
		Local $l_ai_Gunnar[3] = [4, 5, 6]
		Return $l_ai_Gunnar
	EndIf
	If $a_i_Map = $MAP_LONGEYE Then
		; Mhenlo, Zho, Lo Sha
		Local $l_ai_Longeye[3] = [6, 4, 8]
		Return $l_ai_Longeye
	EndIf

	If $a_i_Map = $MAP_LIONS_ARCH Then
		; Single invite slot for the short LA travel
		Local $l_ai_La[1] = [1]
		Return $l_ai_La
	EndIf
	If $a_i_Map = $MAP_KAMADAN Then
		; Party-window invite slots used for Kamadan travel
		Local $l_ai_Kamadan[3] = [2, 12, 9]
		Return $l_ai_Kamadan
	EndIf
	If $l_i_Max > 4 Then
		; Default large-party EotN-style fill
		Local $l_ai_Large[7] = [2, 3, 5, 6, 7, 9, 10]
		Return $l_ai_Large
	EndIf

	; Default small party: same as Forming A Party (Yuun, Mai, Lukas)
	Local $l_ai_Small[3] = [2, 5, 1]
	Return $l_ai_Small
EndFunc

; Invite via Ui_AddNPC (Party Formation) using the map's preferred slot IDs.
Func Leveler_AddHenchmanList(ByRef $a_ai_Hench)
	Local $i
	Local $l_s_List = ""
	For $i = 0 To UBound($a_ai_Hench) - 1
		If $i > 0 Then $l_s_List &= ", "
		$l_s_List &= $a_ai_Hench[$i]
		Ui_AddNPC($a_ai_Hench[$i])
		Sleep(250)
	Next
	Sleep(500)
	Out("[Party] Invited henchmen via Ui_AddNPC " & $l_s_List)
	Return True
EndFunc

; True when Forming A Party already has its three henchmen.
Func Leveler_HasFormingPartyHenchmen()
	Return Leveler_HenchmanCount() >= 3
EndFunc

; $a_b_LeaveFirst False before Enter Challenge — Party_LeaveGroup + Enter disconnects.
Func Leveler_EnsureFormingPartyHenchmen($a_b_LeaveFirst = True)
	If Leveler_HasFormingPartyHenchmen() Then
		Out("[Party] Forming A Party henchmen are already in the party (" & Leveler_HenchmanCount() & ")")
		Return True
	EndIf
	Local $l_ai_Hench = Leveler_FormingPartyHenchIDs()
	If $a_b_LeaveFirst Then
		Party_LeaveGroup(True)
		Sleep(500)
	EndIf
	Leveler_AddHenchmanList($l_ai_Hench)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < 5000
		If Leveler_HasFormingPartyHenchmen() Then ExitLoop
		Sleep(250)
	WEnd
	If Leveler_HasFormingPartyHenchmen() Then
		Out("[Party] Forming A Party henchmen ready (" & Leveler_HenchmanCount() & ")")
		Return True
	EndIf
	Out("[Party] Forming A Party needs 3 henchmen (2, 5, 1); have " & Leveler_HenchmanCount() & ". Retrying.")
	Return False
EndFunc

; Always Party_LeaveGroup, then invite the map's hench list.
; Skipping Leave when HenchmanCount looks full left new characters without henchmen
; when the count API was stale, which breaks Forming A Party.
Func Leveler_PrepareForBattle()
	$g_b_CombatMode = True
	$g_b_UAIReady = False
	Leveler_EquipSkillBar()
	Ui_SetDifficulty(False)

	Local $l_ai_Want = Leveler_HenchmenForMap()
	Party_LeaveGroup(True)
	Sleep(800)
	Leveler_AddHenchmanList($l_ai_Want)
	Out("[Party] Henchmen in party: " & Leveler_HenchmanCount() & "/" & UBound($l_ai_Want))

	Leveler_PrepareCombatAI()
	Return True
EndFunc

; Add missing mission henchmen without leaving the party (Enter Challenge path).
Func Leveler_PrepareMissionParty()
	$g_b_CombatMode = True
	Local $l_ai_Want = Leveler_HenchmenForMap()
	Local $l_i_Want = UBound($l_ai_Want)
	If Leveler_HenchmanCount() < $l_i_Want Then
		; Do not Party_LeaveGroup here. Kick + Enter Mission disconnects.
		Leveler_AddHenchmanList($l_ai_Want)
		Local $l_h_Timer = TimerInit()
		While TimerDiff($l_h_Timer) < 5000
			If Leveler_HenchmanCount() >= $l_i_Want Then ExitLoop
			Sleep(250)
		WEnd
		Out("[Party] Henchmen in party: " & Leveler_HenchmanCount() & "/" & $l_i_Want)
	Else
		Out("[Party] Mission henchmen already in the party")
	EndIf
	Return True
EndFunc

#EndRegion Henchmen
