# Changelog

## 0.2.10 - 2026-09-25

### Maintenance bar background

- Applied the black backdrop colour after creating the backdrop, preventing the WoW 1.12 client from resetting the compact maintenance bar to white.
- Replaced the chat-derived backdrop fill with an independent solid-black texture so chat transparency settings cannot affect the bar.
- Rebuilt the maintenance row with the exact backdrop structure used by the addon's original black toolbars, removing the incompatible fill texture.

## 0.2.9 - 2026-09-25

### Compact maintenance bar and roster state

- Moved all six maintenance icons to one black toolbar in this order: Reset Talents, List Talents, Choose Spec, Match Level, Gear and Replies.
- Removed the unused second maintenance row and reclaimed its vertical space.
- Preserved each bot's known strategies, formation, mana level and other UI state when reopening the general roster.

## 0.2.8 - 2026-09-25

### Maintenance icon rendering

- Rendered maintenance textures through child frames, matching the original toolbar implementation required by the WoW 1.12 client.
- Changed maintenance textures to the `ARTWORK` layer and classic backslash addon paths so they remain above the panel background.

## 0.2.7 - 2026-09-25

### Maintenance icons and project identity

- Replaced the six maintenance text buttons with compact `.tga` icon controls while retaining descriptive tooltips.
- Added dedicated icon assets for Match Level, Gear, Replies, Reset Talents, List Talents and Choose Spec.
- Changed the Replies icon border to indicate ON/OFF state.
- Renamed the project from `Fixed` to `Enhanced` to reflect its expanded scope.

## 0.2.6 - 2026-09-25

### Control-state feedback

- Made formations mutually exclusive: selecting one clears the other formation highlights and leaves only the active formation green.
- Changed one-shot group actions to flash red for 1.5 seconds and then return to their normal state.
- Kept genuinely persistent strategies, including the loot toggle, as green ON/OFF controls.

## 0.2.5 - 2026-09-25

### Complete talent build parsing

- Accepted named talent builds without a `pve` or `pvp` prefix, including warrior variants such as `arms axes`, `fury slam` and `furyprot`.
- Accepted the trailing period used by the server after the final point distribution.
- Increased the no-response fallback from five to fifteen seconds for slower bot replies.

## 0.2.4 - 2026-09-25

### Panel activation

- Removed automatic individual-panel opening when targeting a bot in the game world.
- Individual panels now open only by clicking that bot in the general roster.

### Talent list reliability

- Replaced the fixed one-second talent-list timeout with per-bot response collection that finishes after the reply becomes quiet.
- Accumulated multi-part talent replies and parsed comma-separated builds across the complete response.
- Made `Choose Spec` wait for an in-progress list and open the menu automatically when loading finishes.
- Made `Choose Spec` request the list itself when no cached builds are available.

## 0.2.3 - 2026-09-25

### Bot panels and talents

- Added one independently movable control panel per selected bot instead of reusing a single global panel.
- Reordered maintenance controls to `Match Level | Gear | Replies` and `Reset Talents | List Talents | Choose Spec`.
- Removed residual `|h` hyperlink markers from talent replies and converted talent distributions to the accepted `0-0-0` command format.

### Group controls

- Added `pet passive` plus `pet follow` or `pet stay` to group movement/passive commands so hunter and warlock pets disengage.
- Changed the group loot button from a one-shot collection action to the persistent `nc ~loot` strategy toggle.
- Kept individual save-mana state attached to each bot panel instead of sharing one set of highlighted controls.
- Made strategy buttons true ON/OFF controls whose green state is no longer cleared by unrelated bot acknowledgements.

## 0.2.2 - 2026-09-25

### Talent controls

- Changed `List Talents` so it only refreshes the cached specialization list; it no longer opens the selection menu.
- Stripped WoW colour and hyperlink escape sequences from parsed talent names before sending a selection back to the bot.
- Kept `Choose Spec` as the only control that opens the specialization menu.

### Chat and individual state

- Extended `Replies: OFF` to hide the local echo of outgoing bot whispers.
- Made the individual `save mana` controls store and display their level per bot while continuing to whisper only the selected bot.

## 0.2.1 - 2026-09-25

### Bot maintenance and talents

- Added labelled `Match Level`, `Gear`, `List Talents`, `Choose Spec` and `Reset Talents` controls to the individual bot panel.
- Added `.bot init <name>` integration for matching a bot to the player's level.
- Added `.bot gear <name>` integration for specialization-aware equipment generation.
- Added dynamic parsing of `talents list` replies received through whisper, party, raid or guild chat.
- Added a talent-build menu that sends `talents <build name>` to the selected bot.
- Added `.reset stats <name>` after talent selection and talent reset.
- Added `.reset talents <name>` support.

### Chat reply control

- Added a persistent `Replies: ON/OFF` button; routine bot replies are hidden by default.
- Removed incompatible automatic `#a nc ?`, formation, stance, loot, raid-target and mana follow-up queries.
- Kept talent-list parsing active even while replies are hidden.

### Formations

- Replaced the incorrect `follow near`, `follow far`, `follow reset` and `follow auto` mappings with `formation near`, `formation melee`, `formation arrow`, `formation far` and `formation chaos`.

## 0.1.0 - Initial CMaNGOS compatibility fixes

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
| Near formation | `formation near` |
| Melee formation | `formation melee` |
| Arrow formation | `formation arrow` |
| Far formation | `formation far` |
| Free formation | `formation chaos` |
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
