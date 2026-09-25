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
- Map formation shortcuts to CMaNGOS follow-distance commands: `follow near`, `follow far`, `follow reset` and `follow auto`.
- Map loot and gathering controls to `collect` commands.
- Map crowd control to `neutralize`.
- Adapt individual actions for loot collection, revival through `follow`, selling, quest fetching, spell listing and equipment information.
- Make the food/drink button prepare a `use` command so an item can be shift-clicked into chat.
- Mark buffing as automatic because classic CMaNGOS Playerbot does not expose the original strategy toggle.

See [CHANGELOG.md](CHANGELOG.md) for the detailed command mappings.

## Usage notes

- `/bot` toggles the bot roster.
- Click a bot portrait or its name area to pin the individual control panel.
- Click the same bot again to close its panel.
- Group controls use party chat, or raid chat while in a raid.
- The food/drink action requires shift-clicking the desired item link and pressing Enter because CMaNGOS requires an explicit item link.

## Known limitations

Many class strategy buttons in the original interface target ike3 aiPlayerbot strategies such as `co`, `nc`, `formation`, `stance`, `rti` and `save mana`. Classic CMaNGOS Playerbot does not provide direct equivalents for all of them. Unsupported strategy controls will be redesigned progressively rather than pretending that they work.

Planned research includes convenient controls for bot level synchronization, level-appropriate equipment, talent reset and talent-spec selection where the server exposes suitable commands.

## Original addon

Original project: <https://github.com/ike3/mangosbot-addon>

This fork keeps the upstream project untouched and tracks it as the source of the original WoW UI.
