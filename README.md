# GwAu3 Factions Leveler

AutoIt3 conversion of the Py4GW **Factions Character Leveler**. The original widget was developed by **Apo** and **Wick** (Divinus) for [Py4GW](https://github.com/apoguita/Py4GW_Reforged). This script is a complete conversion of that route into GwAu3: Shing Jea through the post-20 unlocks, ending at the optional Great Temple secondary-profession trainers.

Quest coordinates, dialog ids, and step order follow `Widgets/Automation/Bots/Levelers/Factions/Factions Character Leveler.py`.

The main script is `Factions_Character_Leveler.au3`. It includes `../../API/_GwAu3.au3` and the Pathfinder plugin.

## Credit

- Original bot: Factions Character Leveler
- Developed by Apo and Wick (Divinus)
- Framework: Py4GW / Py4GW Reforged, by Apo (apoguita)

## Run

1. Launch Guild Wars and log the Factions character in.
2. Run `Factions_Character_Leveler.au3` with AutoIt3 x86.
3. Pick the character, click Start. Refresh re-detects the next incomplete step.

**Unlock All Secondary Professions** is off by default. Leave it off when gold is short. Tick it to pay the Great Temple trainers, including Paragon and Dervish.

**Inf Ident/Salvage Pick Up** claims the infinite kits from the Purveyor after the Great Temple can be traveled to.

**Auto Sell** is off by default. Tick it to sell merchant-sellable drops in town. Materials and equipped armor and weapons stay in the bags. Kits, bags, and quest items stay as well.

## Scope

1. Shing Jea start: secondary, Xunlai, weapon, monastery armor, bags, skills.
2. Island story: Minister Cho, Lost Treasure, Tengu quests, Seitung armor, Zen Daijun.
3. Kaineng: Marketplace, max armor, Search for a Cure, Master's Burden, Mox.
4. Eye of the North unlock, then Punch-Out Extravaganza to level 20. At level 20 the character leaves the instance and continues.
5. Post-20: An Unwelcome Guest, Gunnar's Hold, Punch the Clown, Lion's Arch, Kamadan, Consulate Docks, Olias, and the optional remaining secondaries.
