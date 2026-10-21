# 1.3.0 — Text appearance

- Add independent appearance controls for cooldown numbers and LMB/RMB labels: font, size, outline, colour, nine anchor points and X/Y offsets.
- Include Blizzard fonts and fonts registered with optional LibSharedMedia (including those supplied by EllesmereUI). Fall back to the locale default when an optional font is missing.
- Add a cooldown-number visibility toggle without disabling the cooldown swipe.
- Show sample countdown text in preview; colour changes apply immediately and Cancel restores the previous colour.
- Preserve existing settings while adding validated defaults for the new controls.

Automated checks pass for Retail and Forever. In-game styling validation is pending.

# 1.2.1 — Cooldown display fixes

- Keep spell cooldown and charge recharge on independent widgets: empty recharge objects or charge API errors no longer clear the spell timer.
- Use public numeric cooldown data when available, with opaque duration objects for restricted combat values. Continue excluding the global cooldown.
- Explicitly set swipe visibility, colour, frame level and countdown font on overlay icons.
- Add `/ctco debug` to report the last resolved action, timer path and cooldown error.

Automated regression checks pass for Retail and Forever. The user confirmed cooldowns display in-game on Retail after this fix.

# 1.2.0 — Cooldowns and empty-slot display

- Add Show cooldowns on icons to settings, enabled by default.
- Show the native cooldown swipe and countdown for explicit spell bindings (including recharge timers), items and macros resolved by WoW.
- Exclude spell GCD. Pass opaque spell duration objects directly to the cooldown widget for restricted combat data.
- Preserve EllesmereUI friendly-action metadata for cooldown lookup; do not guess cooldowns for smart actions.
- Hide empty and target/menu slots instead of showing a question mark.
- Update cooldowns while the modifier remains held and clear stale timers after source/setting changes.

Available as separate Retail 1.2.0 and Forever 1.2.0-forever packages. Automated Lua checks pass for both. In-game cooldown rendering and combat validation remain pending.
