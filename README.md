# Mangosbot Addon 1.12.1 Fixed

A community-maintained fork of [ike3/mangosbot-addon](https://github.com/ike3/mangosbot-addon), based on its `1.12` branch and adapted for the classic CMaNGOS Playerbot command interface.

The original addon was designed around the private `#a`/addon-message protocol used by a different aiPlayerbot implementation. Classic CMaNGOS Playerbot listens for ordinary whispers and party or raid chat instead. This fork replaces the incompatible command transport and makes the most useful controls work with a WoW 1.12.1 client.

## Installation

Copy the repository contents to:

```text
World of Warcraft\Interface\AddOns\mangosbot
```

Enable out-of-date addons if the client requests it. Enter the world and use `/bot` to open the bot roster.

## Current fixes

- Send group commands through normal `PARTY` or `RAID` chat instead of `SendAddonMessage`.
- Send individual commands as normal whispers to the selected bot.
- Send multi-command actions as separate, rate-limited messages.
- Keep the roster-selected bot as the command target even when the player targets another unit.
- Open the individual control panel immediately from the bot portrait or the bot row/header.
- Keep the individual panel pinned while targets change or ordinary CMaNGOS replies arrive.
- Close the individual panel only when the same bot is selected again.
- Remove unsupported aiPlayerbot strategy-state queries from panel initialization.
- Map core movement actions to CMaNGOS commands: `follow`, `stay`, passive follow, attack and pull.
- Map formation shortcuts to the native CMaNGOS `formation` commands.
- Map loot and gathering controls to `collect` commands.
- Map crowd control to `neutralize`.
- Adapt individual actions for loot collection, revival through `follow`, selling, quest fetching, spell listing and equipment information.
- Make the food/drink button prepare a `use` command so an item can be shift-clicked into chat.
- Mark buffing as automatic because classic CMaNGOS Playerbot does not expose the original strategy toggle.
- Add clearly labelled individual-bot controls for level matching, specialization-aware gear generation, talent listing, talent selection and talent reset.
- Parse the server's live `talents list` response and present the available builds in a selectable menu.
- Recalculate bot stats after applying or resetting talents.
- Add a persistent `Replies: ON/OFF` control and remove the legacy `#a nc ?` follow-up messages that flooded chat.

See [CHANGELOG.md](CHANGELOG.md) for the detailed command mappings.

## Usage notes

- `/bot` toggles the bot roster.
- Click a bot portrait or its name area to pin the individual control panel.
- Click the same bot again to close its panel.
- Use `List Talents` to fetch the selected bot's builds; the specialization menu opens when the reply is received.
- Use `Gear` again after changing specialization so CMaNGOS can generate equipment for the new role.
- `Replies: OFF` hides routine bot command replies while the addon continues to process talent-list responses.
- Group controls use party chat, or raid chat while in a raid.
- The food/drink action requires shift-clicking the desired item link and pressing Enter because CMaNGOS requires an explicit item link.

## Known limitations

Many class strategy buttons in the original interface target legacy strategies for which current CMaNGOS may not provide exact equivalents. Unsupported strategy controls will be redesigned progressively rather than pretending that they work.

## Original addon

Original project: <https://github.com/ike3/mangosbot-addon>

This fork keeps the upstream project untouched and tracks it as the source of the original WoW UI.
