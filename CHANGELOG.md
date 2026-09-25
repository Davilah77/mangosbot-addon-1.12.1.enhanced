# Changelog

## Unreleased

### CMaNGOS command transport

- Replaced party and raid `SendAddonMessage` calls with ordinary `SendChatMessage` calls.
- Replaced batched commands separated by `\\` with individual messages delayed by 0.2 seconds.
- Removed the accidental transmission of button tooltip text as a party command.
- Made an explicitly selected roster bot take precedence over the current world target.

### Individual bot panel

- Added immediate local panel initialization instead of waiting for unsupported aiPlayerbot strategy replies.
- Made the full bot row/header selectable in addition to the small class portrait.
- Added class-aware panel coloring and toolbar visibility for roster-selected bots.
- Prevented target changes from clearing the selected bot or closing its panel.
- Prevented unrelated or ordinary CMaNGOS whispers from closing the panel.
- Kept manual toggle behavior: selecting the same bot again closes the panel.

### CMaNGOS command mappings

| Original action | CMaNGOS command |
| --- | --- |
| Follow | `follow` |
| Stay | `stay` |
| Run away / passive follow | `orders combat passive`, then `follow` |
| Passive | `orders combat passive` |
| Attack target | `attack` |
| Pull target | `pull` |
| Near / melee formation | `follow near` |
| Arrow/default formation | `follow reset` |
| Far formation | `follow far` |
| Free/automatic distance | `follow auto` |
| Loot everything | `collect combat loot profession quest` |
| Enable looting | `collect combat loot quest` |
| Gather profession objects | `collect profession objects` |
| Crowd control | `neutralize` |
| Revive/return | `follow` |
| Sell vendor items | `sell all` |
| Accept available quests | `quest fetch` |
| List spells | `spells` |
| Show auto-equip state | `equip info` |

### Food, drink and automatic features

- Changed the food/drink action to prepare `/w BOT use`, `/p use` or `/ra use` for insertion of an item link.
- Changed the buff button to explain that buffing is automatic in classic CMaNGOS Playerbot.

### Validation

- Validated the modified addon with Lua 5.3 syntax loading.
- Verified the core command and panel fixes in a WoW 1.12.1 CMaNGOS environment.
