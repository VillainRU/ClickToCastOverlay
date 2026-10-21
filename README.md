# Click to cast overlay

See your left- and right-click spell assignments while holding **Ctrl**, **Shift**, or **Alt**.

Click to cast overlay displays two ability icons: **left-click on the left, right-click on the right**. Choose Blizzard's built-in Click Casting bindings or EllesmereUI's own Click Casting bindings as the source.

## Three display modes

- **Movable window:** place the icon pair wherever you want and lock it in place.
- **At the cursor:** keep the icons beside your mouse pointer.
- **Hovered friendly unit frame:** show the icons over the friendly frame under your cursor. Supports Blizzard frames and EllesmereUI UnitFrames / RaidFrames.

## Features

- Reads your existing bindings; no need to enter spell assignments again.
- Shows bindings for one held modifier: Ctrl, Shift, or Alt.
- Optional cooldown swipe and countdown, enabled by default.
- Spell cooldowns, recharge timers, items, and macros resolved by WoW; spell GCD excluded.
- Adjustable icon size, spacing, labels, and cursor/frame offsets.
- Account-wide saved settings and window position.
- Preview mode for positioning the overlay.
- Click-through display when the window is locked.
- Russian and English interface.

## Getting started

1. Configure your bindings in Blizzard Click Casting or EllesmereUI.
2. Type **`/ctco`** to open the addon settings.
3. Select the binding source and display mode.
4. Hold Ctrl, Shift, or Alt to see the assigned icons.

For the movable window, uncheck **Lock window**, drag it into position, then lock it again before playing.

## EllesmereUI support

EllesmereUI is **optional**. Blizzard mode works without it.

To use EllesmereUI as the binding source, its **RaidFrames module must be loaded** and its own **Click Casting must be enabled**. The overlay reads the active specialization and global bindings resolved by EllesmereUI.

This source displays **friendly unit-frame click bindings**, including the friendly side of combined friendly/enemy assignments. Hover-only keyboard bindings are excluded. Out-of-combat-only assignments are hidden during combat. If the source is unavailable or disabled, the settings panel explains why.

The integration uses EllesmereUI's exposed runtime functions. Compatibility has been checked against the installed EllesmereUI 9.5.5 source; changes to those functions may require an update.

## Commands

- `/ctco` — open settings
- `/ctco blizzard` — select Blizzard bindings
- `/ctco ellesmere` — select EllesmereUI bindings
- `/ctco window`, `/ctco cursor`, `/ctco frames` — select display mode
- `/ctco unlock`, `/ctco lock` — unlock or lock the movable window
- `/ctco test` — toggle preview mode
- `/ctco refresh` — refresh bindings
- `/ctco reset` — restore defaults

Cooldowns are available for explicit spell/item assignments and saved macros whose action WoW can resolve. Smart EllesmereUI actions have an icon only; their cooldown is not guessed.

## Current limitations

- Multiple held modifiers are not supported; normal display is hidden for combinations such as Ctrl+Shift.
- Empty and target/menu assignments are hidden without a question mark.
- Macro icons represent the saved assignment; the addon does not predict conditional macro branches.
- Icons identify bindings and optionally display cooldowns. They do not indicate range, spell availability, or buffs currently on a target.
- Restricted unit-frame information may prevent frame-mode display.

## Initial beta

The supplied screenshots show the settings panel and overlay in-game with Blizzard bindings. Automated Lua checks cover both source adapters and display logic. Combat behavior and the EllesmereUI binding source still need in-game validation; please report issues with the source, display mode, game version, and full Lua error when available.

**Games:** World of Warcraft Retail and WoW Forever 1.60.1. Download the file for your game: Retail 1.2.0 or Forever 1.2.0-forever (Interface 16001). Other Classic editions are not supported.

The Forever package has been checked against the Forever API source and automated Lua tests; in-game Forever and combat validation are still pending.

**License:** MIT.

**Source and issue reports:** https://github.com/VillainRU/ClickToCastOverlay

## Development

Requires Python 3 and Lua 5.1 or LuaJIT. Run commands from the repository root:

```sh
luajit tests/test_addon.lua
python3 scripts/build.py
luajit tests/test_addon.lua dist/retail/ClickToCastOverlay
luajit tests/test_addon.lua dist/forever/ClickToCastOverlay
```

Builds use the same Core.lua and Options.lua. Only the Interface/version metadata differs: Retail 120105 / 1.2.0; Forever 16001 / 1.2.0-forever. Build outputs are in dist/ and are not committed. Tests emulate WoW APIs; they do not replace in-game testing.

[Русская инструкция](docs/README-ruRU.md)
