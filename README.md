# GwAu3 Factions Leveler V2

AutoIt3 conversion of the Py4GW **Factions Character Leveler**. The original widget was developed by **Apo** and **Wick** (Divinus) for [Py4GW](https://github.com/apoguita/Py4GW_Reforged). This script is a complete conversion of that route into GwAu3: Shing Jea through the post-20 unlocks, ending at the optional Great Temple secondary-profession trainers.

Quest coordinates, dialog ids, and step order follow `Widgets/Automation/Bots/Levelers/Factions/Factions Character Leveler.py`.

## Credit

- Original bot: Factions Character Leveler
- Developed by Apo and Wick (Divinus)
- Framework: Py4GW / Py4GW Reforged, by Apo (apoguita)

## Layout

| File | Purpose |
| --- | --- |
| `Factions_Character_Leveler.au3` | GUI, bot loop, Start / Pause |
| `Leveler_Const.au3` | Step indices, maps, quests, dialogs, models, runtime state |
| `Leveler_Move.au3` | Pathfinder, travel, NPC talk, combat waits, punch-out, wipe recover |
| `Leveler_Quest.au3` | Quest accept / update / reward dialogs |
| `Leveler_Prof.au3` | Skill templates and trainer-bar load |
| `Leveler_Henchman.au3` | Hench invite lists and party prep |
| `Leveler_Party.au3` | Profession flags, heroes, party checks |
| `Leveler_UtilityAI.au3` | Leveler combat. The UtilityAI plugin is left unchanged |
| `Leveler_Mission.au3` | Native `Ui_EnterChallenge` and post-mission outpost wait |
| `Leveler_Craft.au3` | Gold, Xunlai, weapons, armor, bags |
| `Leveler_Status.au3` | Progress flags and the GUI status check |
| `Leveler_Steps.au3` | Step dispatcher and campaign runners |

Lives in the GwAu3 checkout at `Scripts/GwAu3-Factions-Leveler-V2/`. The main script includes `../../API/_GwAu3.au3` and the Pathfinder plugin.

## Run

1. Launch Guild Wars and log the Factions character in.
2. Run `Factions_Character_Leveler.au3` with AutoIt3 x86.
3. Pick the character, click Start. Refresh re-detects the next incomplete step.

**Unlock All Secondary Professions** is off by default. Leave it off when gold is short. Tick it to pay the Great Temple trainers, including Paragon and Dervish.

**Inf Ident/Salvage Pick Up** claims the infinite kits from the Purveyor after the Great Temple can be traveled to.

## Scope

1. Shing Jea start: secondary, Xunlai, weapon, monastery armor, bags, skills.
2. Island story: Minister Cho, Lost Treasure, Tengu quests, Seitung armor, Zen Daijun.
3. Kaineng: Marketplace, max armor, Search for a Cure, Master's Burden, Mox.
4. Eye of the North unlock, then Punch-Out Extravaganza to level 20. At level 20 the character leaves the instance and continues.
5. Post-20: An Unwelcome Guest, Gunnar's Hold, Punch the Clown, Lion's Arch, Kamadan, Consulate Docks, Olias, and the optional remaining secondaries.
