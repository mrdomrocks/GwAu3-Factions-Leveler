#include-once

; Step indices, maps, quests, dialogs, models, and runtime state for the Factions leveler.

#Region Steps
; GUI / dispatcher order from Monastery Overlook through remaining secondaries.
Global Const $LEVELER_STEP_OVERLOOK = 0
Global Const $LEVELER_STEP_PARTY = 1
Global Const $LEVELER_STEP_SECONDARY = 2
Global Const $LEVELER_STEP_XUNLAI = 3
Global Const $LEVELER_STEP_WEAPON = 4
Global Const $LEVELER_STEP_ARMOR = 5
Global Const $LEVELER_STEP_DESTROY = 6
Global Const $LEVELER_STEP_BAGS = 7
Global Const $LEVELER_STEP_SKILLS = 8
Global Const $LEVELER_STEP_TO_CHO = 9
Global Const $LEVELER_STEP_CHO_MISSION = 10
Global Const $LEVELER_STEP_ATTR_1 = 11 ; Lost Treasure (historical ATTR name kept for step index stability)
Global Const $LEVELER_STEP_TENGU = 12
Global Const $LEVELER_STEP_THREAT = 13
Global Const $LEVELER_STEP_ROAD = 14
Global Const $LEVELER_STEP_SEITUNG = 15
Global Const $LEVELER_STEP_DESTROY_MON = 16
Global Const $LEVELER_STEP_TO_ZEN = 17
Global Const $LEVELER_STEP_ZEN_MISSION = 18
Global Const $LEVELER_STEP_ATTR_2 = 19 ; An Unwelcome Guest, Seitung Harbor / Zen Daijun
Global Const $LEVELER_STEP_TO_MARKET = 20
Global Const $LEVELER_STEP_BURDEN = 21
Global Const $LEVELER_STEP_TO_KC = 22
Global Const $LEVELER_STEP_SKILLS2 = 23
Global Const $LEVELER_STEP_MAX_ARMOR = 24
Global Const $LEVELER_STEP_DESTROY_SEITUNG = 25
Global Const $LEVELER_STEP_CURE = 26
Global Const $LEVELER_STEP_UNLOCK_MOX = 27
Global Const $LEVELER_STEP_TO_BOREAL = 28
Global Const $LEVELER_STEP_TO_EOTN = 29
Global Const $LEVELER_STEP_EOTN_POOL = 30
Global Const $LEVELER_STEP_TO_GUNNAR = 31
Global Const $LEVELER_STEP_KILROY = 32
Global Const $LEVELER_STEP_FARM_20 = 33
Global Const $LEVELER_STEP_TO_LA = 34
Global Const $LEVELER_STEP_TO_KAMADAN = 35
Global Const $LEVELER_STEP_TO_DOCKS = 36
Global Const $LEVELER_STEP_UNLOCK_OLIAS = 37
Global Const $LEVELER_STEP_UNLOCK_PROFS = 38
Global Const $LEVELER_STEP_DONE = 39
Global Const $LEVELER_STEP_COUNT = 40

Global $g_as_StepNames[$LEVELER_STEP_COUNT] = [ _
		"Exit Monastery Overlook", _
		"Quest: Forming A Party", _
		"Unlock Secondary Profession", _
		"Unlock Xunlai Storage", _
		"Craft Weapon", _
		"Craft Monastery Armor", _
		"Destroy Starter Armor", _
		"Extend Inventory", _
		"Unlock Skills Trainer", _
		"To Minister Cho's Estate", _
		"Minister Cho's Estate Mission", _
		"Quest: Lost Treasure", _
		"Quest: Warning the Tengu", _
		"Quest: The Threat Grows", _
		"Quest: The Road Less Traveled", _
		"Craft Seitung Armor", _
		"Destroy Monastery Armor", _
		"To Zen Daijun", _
		"Zen Daijun Mission", _
		"Quest: An Unwelcome Guest", _
		"To Marketplace", _
		"Quest: A Master's Burden", _
		"To Kaineng Center", _
		"Complete Skills Training", _
		"Craft Max Armor", _
		"Destroy Seitung Armor", _
		"Quest: The Search For A Cure", _
		"Unlock Mox", _
		"To Boreal Station", _
		"To Eye of the North", _
		"Unlock Eye of the North Pool", _
		"To Gunnar's Hold", _
		"Unlock Kilroy Stonekin", _
		"Farm Until Level 20", _
		"To Lion's Arch", _
		"To Kamadan", _
		"To Consulate Docks", _
		"Unlock Olias", _
		"Unlock Remaining Secondary Professions", _
		"Done" _
		]
Global $g_ab_StepDone[$LEVELER_STEP_COUNT]
#EndRegion Steps

#Region Maps
; Outposts and explorables this run travels (GwAu3 map labels).
Global Const $MAP_MONASTERY_OVERLOOK = 212 ; Monastery Overlook
Global Const $MAP_SHING_JEA = 242 ; Shing Jea Monastery
Global Const $MAP_SUNQUA_VALE = 238 ; Sunqua Vale
Global Const $MAP_LINNOK = 252 ; Linnok Courtyard
Global Const $MAP_CHO_OUTPOST = 214 ; Minister Cho's Estate (mission outpost)
Global Const $MAP_RAN_MUSU = 251 ; Ran Musu Gardens
Global Const $MAP_CHO_EXPLORABLE = 245 ; Minister Cho's Estate (explorable)
Global Const $MAP_CHO_MISSION = 257 ; Minister Cho's Estate (mission area)
Global Const $MAP_KINYA = 236 ; Kinya Province
Global Const $MAP_TSUMEI = 249 ; Tsumei Village
Global Const $MAP_PANJIANG = 235 ; Panjiang Peninsula
Global Const $MAP_SAOSHANG = 313 ; Saoshang Trail
Global Const $MAP_SEITUNG = 250 ; Seitung Harbor
Global Const $MAP_JAYA = 196 ; Jaya Bluffs
Global Const $MAP_HAIJU = 237 ; Haiju Lagoon
Global Const $MAP_ZEN_OP = 213 ; Zen Daijun (mission outpost)
Global Const $MAP_ZEN_EXP = 246 ; Zen Daijun (explorable / Unwelcome Guest)
Global Const $MAP_ZEN_MISSION = 258 ; Zen Daijun (mission area)
Global Const $MAP_KAINENG_DOCKS = 302 ; Kaineng Docks
Global Const $MAP_MARKETPLACE = 303 ; The Marketplace
Global Const $MAP_BUKDEK = 240 ; Bukdek Byway
Global Const $MAP_WAJJUN = 239 ; Wajjun Bazaar
Global Const $MAP_KAINENG = 194 ; Kaineng Center
Global Const $MAP_TUNNELS = 692 ; Tunnels Below Cantha
Global Const $MAP_BOREAL = 675 ; Boreal Station
Global Const $MAP_ICE_CLIFF = 499 ; Ice Cliff Chasms
Global Const $MAP_EOTN = 642 ; Eye of the North
Global Const $MAP_HOM = 646 ; Hall of Monuments
Global Const $MAP_AB = 849 ; Auspicious Beginnings
Global Const $MAP_NORRHART = 548 ; Norrhart Domains
Global Const $MAP_GUNNAR = 644 ; Gunnar's Hold
Global Const $MAP_KILROY = 703 ; Kilroy's Punchout Training
Global Const $MAP_FRONIS = 704 ; Fronis Irontoe's Lair
Global Const $MAP_LIONS_ARCH = 55 ; Lion's Arch
Global Const $MAP_BEJUNKAN = 290 ; Bejunkan Pier
Global Const $MAP_LIONS_GATE = 415 ; Lion's Gate
Global Const $MAP_KC_SUNSPEARS = 400 ; Kaineng Center (Sunspears in Cantha)
Global Const $MAP_KAMADAN = 449 ; Kamadan, Jewel of Istan
Global Const $MAP_SUN_DOCKS = 543 ; Sun Docks
Global Const $MAP_CONSULATE = 429 ; Consulate
Global Const $MAP_DOCKS = 493 ; Consulate Docks
Global Const $MAP_BLOODSTONE_FEN = 471 ; Bloodstone Fen
Global Const $MAP_GTOB = 248 ; Great Temple of Balthazar
; The Purveyor. Dialog 0x8D grants the infinite salvage and identification kits.
Global Const $PURVEYOR_X = -6937.35
Global Const $PURVEYOR_Y = -4997.84
Global Const $DIALOG_PURVEYOR_KITS = 0x8D
Global Const $MAP_LONGEYE = 650 ; Longeye's Ledge

#EndRegion Maps

#Region Quests
; Story and unlock quest IDs (GwAu3 quest labels).
Global Const $QUEST_FORMING_A_PARTY = 440 ; Forming a Party
Global Const $QUEST_SECONDARY = 317 ; Choose Your Secondary Profession
Global Const $QUEST_FORMAL_INTRO = 318 ; A Formal Introduction
Global Const $QUEST_LOST_TREASURE = 346 ; Lost Treasure
Global Const $QUEST_WARNING_TENGU = 339 ; Warning the Tengu
Global Const $QUEST_THREAT_GROWS = 340 ; The Threat Grows
Global Const $QUEST_JOURNEY_MASTER = 341 ; Journey to the Master
Global Const $QUEST_ROAD_LESS = 342 ; The Road Less Traveled
Global Const $QUEST_MASTERS_BURDEN = 349 ; A Master's Burden
Global Const $QUEST_SEARCH_CURE = 336 ; The Search for a Cure
Global Const $QUEST_BROTHER_TOSAI = 337 ; Seek out Brother Tosai
Global Const $QUEST_EARTH_MOVE = 821 ; I Feel the Earth Move Under Cantha's Feet
Global Const $QUEST_AGAINST_DESTROYERS = 913 ; Against the Destroyers
Global Const $QUEST_MISSING_VANGUARD = 793 ; The Missing Vanguard
Global Const $QUEST_NORTHERN_ALLIES = 905 ; Northern Allies
Global Const $QUEST_KNOWLEDGEABLE_ASURA = 915 ; The Knowledgeable Asura
Global Const $QUEST_UNWELCOME = 348 ; An Unwelcome Guest
Global Const $QUEST_NORNBEAR = 808 ; Tracking the Nornbear
Global Const $QUEST_PUNCH_CLOWN = 858 ; Punch the Clown
Global Const $QUEST_PUNCH_EXTRAVAGANZA = 856 ; Kilroy Stonekin's Punch-Out Extravaganza!
Global Const $QUEST_CHAOS_KRYTA = 479 ; Chaos in Kryta
Global Const $QUEST_SUNSPEARS_CANTHA = 724 ; Sunspears in Cantha
Global Const $QUEST_OLIAS = 782 ; All for One and One for Justice

#EndRegion Quests

#Region Dialogs
; Ui_Dialog values for accept / update / reward.
Global Const $DIALOG_EXIT_OVERLOOK = 0x85
Global Const $DIALOG_GENERIC_TALK = 0x84
Global Const $DIALOG_FORMING_ACCEPT = 0x81B801
Global Const $DIALOG_FORMING_COMPLETE = 0x81B807
Global Const $DIALOG_SECONDARY_MESMER = 0x813D08
Global Const $DIALOG_SECONDARY_OTHER = 0x813D0E
Global Const $DIALOG_SECONDARY_COMPLETE = 0x813D07
Global Const $DIALOG_FORMAL_ACCEPT = 0x813E01
Global Const $DIALOG_FORMAL_STEP = 0x813E04
Global Const $DIALOG_FORMAL_TOGO_TALK = 0x15
Global Const $DIALOG_FORMAL_TOGO_DONE = 0x18
Global Const $DIALOG_FORMAL_ZUI = 0x800008
Global Const $DIALOG_FORMAL_ZUI_2 = 0x800009
Global Const $DIALOG_FORMAL_ZUI_2_TALK = 0x19
Global Const $DIALOG_FORMAL_SKIP = 0x80000B
Global Const $DIALOG_FORMAL_COMPLETE = 0x813E07
Global Const $DIALOG_FORMAL_KAYAO_ACCEPT = 0x17
Global Const $TOGO_SUNQUA_X = 20007.00
Global Const $TOGO_SUNQUA_Y = -7747.00
Global Const $ZUI_SUNQUA_X = 6637.00
Global Const $ZUI_SUNQUA_Y = 16147.00
Global Const $KAYAO_CHO_X = 7884.00
Global Const $KAYAO_CHO_Y = -10029.00
Global Const $DIALOG_XUNLAI_1 = 0x800001
Global Const $DIALOG_XUNLAI_2 = 0x800002
Global Const $DIALOG_LOST_TREASURE_ACCEPT = 0x815A01
Global Const $DIALOG_LOST_TREASURE_STEP = 0x815A04
Global Const $DIALOG_LOST_TREASURE_COMPLETE = 0x17
Global Const $DIALOG_TENGU_ACCEPT = 0x815301
Global Const $DIALOG_TENGU_STEP = 0x815304
Global Const $DIALOG_TENGU_COMPLETE = 0x815307
#EndRegion Dialogs

#Region Waypoints
; Lost Treasure path in Ran Musu and Cho explorable.
Global Const $LOST_TOWN_APPROACH_X = 16184.75
Global Const $LOST_TOWN_APPROACH_Y = 19001.78
Global Const $LOST_TOWN_PATH1_X = 13713.27
Global Const $LOST_TOWN_PATH1_Y = 18504.61
Global Const $LOST_TOWN_PATH2_X = 14576.15
Global Const $LOST_TOWN_PATH2_Y = 17817.62
Global Const $LOST_TOWN_PATH3_X = 15824.60
Global Const $LOST_TOWN_PATH3_Y = 18817.90
Global Const $LOST_TOWN_PORTAL_X = 17005
Global Const $LOST_TOWN_PORTAL_Y = 19787
Global Const $LOST_CHO_START_X = -17979.38
Global Const $LOST_CHO_START_Y = -493.08
Global Const $LOST_CHO_END_X = 20660.90
Global Const $LOST_CHO_END_Y = -9207.07
Global Const $LOST_CHO_END_RANGE = 2500
; Warning the Tengu.
Global Const $TENGU_ANG_X = 15846
Global Const $TENGU_ANG_Y = 19013
Global Const $TENGU_PORTAL_X = 14730
Global Const $TENGU_PORTAL_Y = 15176
Global Const $TENGU_KINYA_START_X = 1429
Global Const $TENGU_KINYA_START_Y = 12768
Global Const $TENGU_SOAR_X = -1023
Global Const $TENGU_SOAR_Y = 4844
Global Const $TENGU_AFFLICTED_X = -5011
Global Const $TENGU_AFFLICTED_Y = 732
#EndRegion Waypoints

#Region Unlocks
; Threat Grows through GToB profession trainers.
Global Const $DIALOG_THREAT_ACCEPT = 0x815401
Global Const $DIALOG_THREAT_COMPLETE = 0x815407
Global Const $DIALOG_JOURNEY_ACCEPT = 0x815501
Global Const $DIALOG_JOURNEY_COMPLETE = 0x815507
Global Const $DIALOG_ROAD_ACCEPT = 0x815601
Global Const $DIALOG_ROAD_TSUKARO_TALK = 0x815604 ; Same value as $DIALOG_ROAD_STEP2
Global Const $DIALOG_ROAD_TSUKARO_GO = 0x800008
Global Const $DIALOG_ROAD_TSUKARO_LETS_GO = 0x800009
Global Const $DIALOG_ROAD_TSUKARO_YES = 0x80000B
Global Const $DIALOG_ROAD_STEP2 = 0x815604 ; Alias of $DIALOG_ROAD_TSUKARO_TALK
Global Const $DIALOG_ROAD_COMPLETE = 0x815607
Global Const $TSUKARO_LINNOK_X = 538.00
Global Const $TSUKARO_LINNOK_Y = 10125.00
Global Const $DIALOG_BURDEN_ACCEPT = 0x815D01
Global Const $DIALOG_BURDEN_STEP2 = 0x815D04
Global Const $DIALOG_BURDEN_COMPLETE = 0x815D07
Global Const $DIALOG_CURE_ACCEPT = 0x815001
Global Const $DIALOG_CURE_STEP = 0x815004
Global Const $DIALOG_CURE_COMPLETE = 0x815007
; Imperial Agent Hanjo (Kaineng) gives The Search for a Cure.
Global Const $HANJO_KAINENG_X = 3772.00
Global Const $HANJO_KAINENG_Y = -961.00
; Bujo (Kaineng) gives Seek out Brother Tosai after Cure is done.
Global Const $BUJO_KAINENG_X = 1784.00
Global Const $BUJO_KAINENG_Y = 991.00
Global Const $DIALOG_TOSAI_ACCEPT = 0x815101
Global Const $DIALOG_UNLOCK_MOX = 0x85
Global Const $DIALOG_EARTH_ACCEPT = 0x833501
Global Const $DIALOG_DESTROYERS_STEP1 = 0x839104
Global Const $DIALOG_POOL_CINEMATIC = 0x800001
; Look deep into the pool.
Global Const $DIALOG_POOL_LOOK_DEEP = 0x63D
; I'll keep my eyes open. I don't want to miss anything.
Global Const $DIALOG_POOL_EYES_OPEN = 0x63F
Global Const $DIALOG_GWEN_TAPESTRY = 0x89
Global Const $DIALOG_VANGUARD_STEP = 0x831904
Global Const $DIALOG_KEIRAN_BOW = 0x8A
Global Const $DIALOG_OGDEN_ALLIES = 0x838904
Global Const $DIALOG_VEKK_ASURA = 0x839304
Global Const $DIALOG_UNWELCOME_ACCEPT = 0x815C01
Global Const $DIALOG_UNWELCOME_COMPLETE = 0x815C07
Global Const $DIALOG_ZEN_SKIP = 0x80000B
Global Const $DIALOG_NORNBEAR_ACCEPT = 0x832801
Global Const $DIALOG_PUNCH_ACCEPT = 0x835A01
Global Const $DIALOG_PUNCH_COMPLETE = 0x835A07
Global Const $DIALOG_FRONIS_INTRO = 0x835803
Global Const $DIALOG_FRONIS_ACCEPT = 0x835801
Global Const $DIALOG_FRONIS_ENTER = 0x85
Global Const $DIALOG_FRONIS_REWARD = 0x835807
Global Const $KILROY_NPC_X = 17341.00
Global Const $KILROY_NPC_Y = -4796.00
Global Const $MODEL_KILROY = 858 ; Kilroy Stonekin
Global Const $FRONIS_START_X = -16919.56
Global Const $FRONIS_START_Y = -13485.12
Global Const $FRONIS_CHEST_X = 13275.00
Global Const $FRONIS_CHEST_Y = -16039.00
Global Const $DIALOG_CHAOS_ACCEPT = 0x81DF01
Global Const $DIALOG_CHAOS_STEP1 = 0x81DF04
Global Const $DIALOG_CHAOS_STEP3 = 0x85
Global Const $DIALOG_CHAOS_COMPLETE = 0x81DF07
Global Const $DIALOG_SUNSPEARS_ACCEPT = 0x82D401
Global Const $DIALOG_SUNSPEARS_STEP1 = 0x82D404
Global Const $DIALOG_SUNSPEARS_MULTI = 0x87
Global Const $DIALOG_SUNSPEARS_COMPLETE = 0x82D407
Global Const $DIALOG_UNLOCK_DOCKS = 0x85
Global Const $DIALOG_OLIAS_ACCEPT = 0x830E01
Global Const $DIALOG_OLIAS_STEP2 = 0x830E04
Global Const $DIALOG_OLIAS_FIGO = 0x84
Global Const $DIALOG_OLIAS_COMPLETE = 0x830E07
Global Const $DIALOG_PROF_WARRIOR = 0x184
Global Const $DIALOG_PROF_RANGER = 0x284
Global Const $DIALOG_PROF_MONK = 0x384
Global Const $DIALOG_PROF_NECRO = 0x484
Global Const $DIALOG_PROF_MESMER = 0x584
Global Const $DIALOG_PROF_ELE = 0x684
Global Const $DIALOG_PROF_ASSASSIN = 0x784
Global Const $DIALOG_PROF_RIT = 0x884
Global Const $DIALOG_PROF_PARA = 0x984
Global Const $DIALOG_PROF_DERV = 0xA84

#EndRegion Unlocks

#Region NPC Models
Global Const $MODEL_TOGO_1 = 3078
Global Const $MODEL_TOGO_2 = 3081
Global Const $MODEL_TOGO_3 = 3120
Global Const $MODEL_TOGO_4 = 3215
Global Const $MODEL_XUNLAI = 283
; Raitahn Nem. Same model in Ran Musu Gardens and Cho explorable.
Global Const $MODEL_LOST_TREASURE_GUARD = 3093
Global Const $MODEL_RAITAHN_NEM = 3093
Global Const $MODEL_SISTER_TAI = 3367
Global Const $MODEL_BROTHER_TOSAI = 3171
Global Const $MODEL_BURDEN_NPC = 3307
Global Const $MODEL_CURE_LOOT = 6496
Global Const $MODEL_DESTROYERS_NPC = 6034 ; Same model as Jora at Ice Cliff
Global Const $MODEL_JORA = 6034 ; Alias of $MODEL_DESTROYERS_NPC
Global Const $MODEL_JORA_ALT = 6374
Global Const $JORA_ICE_CLIFF_X = 2825.00
Global Const $JORA_ICE_CLIFF_Y = -481.00
Global Const $MODEL_GWEN = 6021
Global Const $MODEL_EOTN_POOL = 5959
Global Const $GWEN_HOM_X = -6583.00
Global Const $GWEN_HOM_Y = 6672.00
Global Const $EOTN_POOL_X = -6662.00
Global Const $EOTN_POOL_Y = 6234.60
Global Const $EOTN_POOL_TILE_X = -6662.00
Global Const $EOTN_POOL_TILE_Y = 6584.00
; Eye of the North general merchant. Sells identification kits and salvage kits.
Global Const $EOTN_MERCHANT_X = -2700.00
Global Const $EOTN_MERCHANT_Y = 1075.00
Global Const $FARM_KIT_MIN_USES = 10
Global Const $KIT_GOLD_COST = 100
Global Const $OGDEN_HOM_X = -6133.41
Global Const $OGDEN_HOM_Y = 5717.30
Global Const $VEKK_HOM_X = -5626.80
Global Const $VEKK_HOM_Y = 6259.57
Global Const $MODEL_OGDEN = 5983
Global Const $MODEL_VEKK = 5964
Global Const $MODEL_KEIRAN_BOW = 35829
Global Const $MODEL_ZUNRAA = 4009
Global Const $MODEL_CHAOS_STEP1 = 3267
Global Const $MODEL_CHAOS_STEP2 = 2020
Global Const $MODEL_CHAOS_STEP3 = 2011
Global Const $MODEL_SUNSPEARS_NPC = 4914
Global Const $MODEL_SUNSPEARS_COMPLETE = 4829
Global Const $MODEL_GTOB_TRAINER = 201
Global Const $MODEL_BRASS_KNUCKLES = 24897
; Michiko [Skills] in Kaineng Center — end of the street path from spawn.
Global Const $MODEL_MICHIKO = 3295
Global Const $MICHIKO_KAINENG_X = 413.00
Global Const $MICHIKO_KAINENG_Y = 1312.00

; Merchant bags (Bag = 35, Belt_Pouch = 34; reward pouch = 33)
Global Const $MODEL_BAG = 35
Global Const $MODEL_BELT_POUCH = 34
Global Const $MODEL_BELT_POUCH_REWARD = 33

#EndRegion NPC Models

#Region Skills And Items
; Zhao Di (Shing Jea Monastery) Mesmer skills. Cry of Frustration is NOT here.
Global Const $SKILL_ENERGY_BURN = 42
Global Const $SKILL_LEECH_SIGNET = 61
Global Const $SKILL_SIGNET_OF_DISRUPTION = 860
; Michiko in Kaineng: Cry of Frustration and Power Drain.
Global Const $SKILL_CRY_OF_FRUSTRATION = 57
Global Const $SKILL_POWER_DRAIN = 25
Global Const $SKILL_SPIRIT_RIFT = 910

; Weapon / armor gold.
Global Const $MODEL_CLAIRVOYANT_STAFF = 11647
; Paid from the Choose Your Secondary Profession (#317) complete reward, not storage.
Global Const $XUNLAI_GOLD_COST = 50
Global Const $XUNLAI_X = -3825.09
Global Const $XUNLAI_Y = 10386.81
; Common-mat trader lots plus Hiroyuki's 100g staff fee. Withdraw this much (or all storage).
Global Const $WEAPON_WITHDRAW_GOLD = 5000
Global Const $WEAPON_GOLD_COST = 100
Global Const $MONASTERY_ARMOR_GOLD = 20
Global Const $SEITUNG_ARMOR_GOLD = 200
Global Const $MAX_ARMOR_GOLD = 1000

#EndRegion Skills And Items

#Region Movement
; Arrive / aggro ranges used by pathing and combat.
Global Const $LEVELER_ARRIVE_RANGE = 200
Global Const $LEVELER_AGGRO = 1320
Global Const $LEVELER_FIGHT_RANGE_OUT = 3500
Global Const $LEVELER_AREA_RANGE = 322
Global Const $LEVELER_SPIRIT_RANGE = 2500

#EndRegion Movement

#Region Quest Flags
; Sticky during a run; rebuilt on Refresh.
Global Enum $LEVELER_Q_FORMING, $LEVELER_Q_SECONDARY, $LEVELER_Q_FORMAL, $LEVELER_Q_LOST, _
		$LEVELER_Q_TENGU, $LEVELER_Q_THREAT, $LEVELER_Q_JOURNEY, $LEVELER_Q_ROAD, _
		$LEVELER_Q_CURE, $LEVELER_Q_TOSAI, $LEVELER_Q_BURDEN, $LEVELER_Q_EARTH, _
		$LEVELER_Q_DESTROYERS, $LEVELER_Q_VANGUARD, $LEVELER_Q_ALLIES, $LEVELER_Q_ASURA, _
		$LEVELER_Q_UNWELCOME, $LEVELER_Q_NORNBEAR, $LEVELER_Q_PUNCH, $LEVELER_Q_CHAOS, _
		$LEVELER_Q_SUNSPEARS, $LEVELER_Q_OLIAS, $LEVELER_Q_COUNT
Global $g_ab_QuestDone[$LEVELER_Q_COUNT]

#EndRegion Quest Flags

#Region Runtime State
; Active step index in the GUI / dispatcher.
Global $g_i_Step = $LEVELER_STEP_OVERLOOK
; When True, the loop runs Leveler_StatusCheck and starts at the first incomplete step.
Global $g_b_NeedStatusCheck = False
Global $g_b_LevelerPaused = False
Global $g_b_LevelerFailed = False
; True while pathing / fighting in explorables that need UtilityAI.
Global $g_b_CombatMode = False
; Watch for spirit rift / farm-loop side effects.
Global $g_b_SpiritRiftWatch = False
; Level-20 Auspicious Beginnings farm loop.
Global $g_b_FarmMode = False
; Kilroy punch-out / Fronis fight loop.
Global $g_b_KilroyMode = False
; Set after the one Punch the Clown dialog. Stops that dialog from being sent again.
Global $g_b_PunchClownSettled = False
Global $g_h_RiftCooldown = 0
; Current step title shown in the GUI / logs.
Global $g_s_CurrentHeader = ""
; UtilityAI skill-bar cache is valid for $g_i_LastUAIMap.
Global $g_b_UAIReady = False
Global $g_i_LastUAIMap = 0
; Punch-out slots resolved from UtilityAI Cache_SkillBar (STAND UP + fight order).
Global $g_i_KilroyStandUpSlot = 8
; [0]=count, [1..n]=slots in Punch_Out cast order (1,2,3,5,6,4).
Global $g_ai_KilroyFightSlots[7]
; Energy at 0 starts Stand Up. Skill 8 stays on until energy is 100% of the current maximum.
Global $g_b_KilroyRecovery = False
; Client disconnect / lost map detected this run.
Global $g_b_ConnectionLost = False
; Map ID where the Zen template was already applied this run.
Global $g_i_ZenBarLoadedMap = 0
; One Zen Daijun → Seitung Harbor → Zen Daijun bounce before mission henchmen.
Global $g_b_ZenSeitungBounceDone = False
; One-time recovery after a completed Lost Treasure restart: path Cho -> Ran Musu -> Tengu.
Global $g_b_LostTreasureToTenguOnce = False
; Set on Start only. Stay in an explorable after a client/script restart; do not block the next quest.
Global $g_b_ExplorableResume = False
; Once The Search for a Cure is the live step, a status check must not rewind earlier.
Global $g_b_CureStepLocked = False
; Sticky after this character has entered Gunnar's Hold.
Global $g_b_ReachedGunnar = False
; GUI option. One trip to The Purveyor once the Great Temple of Balthazar is unlocked.
Global $g_h_InfKitCheckbox = 0
; GUI option. Off unless ticked: trainer unlocks cost gold the character may not have.
Global $g_h_UnlockProfsCheckbox = 0
Global $g_b_InfKitsClaimed = False
Global $g_i_InfKitTravelFails = 0
Global $g_b_InfKitsNoSpace = False
; Sticky after Bloodstone Fen for All for One and One for Justice.
Global $g_b_OliasFenDone = False
; Sticky after Olias is in the party or can be added.
Global $g_b_OliasUnlocked = False
; Sticky after the Bukdek dialog actually puts Mox on the hero list.
Global $g_b_MoxUnlocked = False
; Sticky after this character pays the Xunlai agent. Not the same as account Storage1Ptr.
Global $g_b_XunlaiUnlocked = False
; Sticky after GToB trainer dialogs.
Global $g_b_SecondaryProfsTalked = False
#EndRegion Runtime State
