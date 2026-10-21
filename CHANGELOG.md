# 1.2.1 — Cooldown display fixes

- Keep spell cooldown and charge recharge on independent widgets: empty recharge objects or charge API errors no longer clear the spell timer.
- Use public numeric cooldown data when available, with opaque duration objects for restricted combat values. Continue excluding the global cooldown.
- Explicitly set swipe visibility, colour, frame level and countdown font on overlay icons.
- Add `/ctco debug` to report the last resolved action, timer path and cooldown error.

Automated regression checks pass for Retail and Forever. User-reported missing cooldown is under investigation; in-game confirmation is pending.

# 1.2.0 — Cooldowns and empty-slot display

- Add Show cooldowns on icons to settings, enabled by default.
- Show the native cooldown swipe and countdown for explicit spell bindings (including recharge timers), items and macros resolved by WoW.
- Exclude spell GCD. Pass opaque spell duration objects directly to the cooldown widget for restricted combat data.
- Preserve EllesmereUI friendly-action metadata for cooldown lookup; do not guess cooldowns for smart actions.
- Hide empty and target/menu slots instead of showing a question mark.
- Update cooldowns while the modifier remains held and clear stale timers after source/setting changes.

Available as separate Retail 1.2.0 and Forever 1.2.0-forever packages. Automated Lua checks pass for both. In-game cooldown rendering and combat validation remain pending.
