local addonName, A = ...
_G.ClickToCastOverlay = A
local RU = GetLocale() == "ruRU"
A.RU = RU
A.defaults = { enabled = true, source = "blizzard", mode = "window", size = 38, gap = 6,
    offsetX = 24, offsetY = 20, x = 0, y = -160, labels = true, locked = true, cooldowns = true }
local db, overlay, mover
local bindings = {}
local elapsed, profileElapsed, cooldownElapsed = 0, 0, 0
local preview = false
local activeKey
local function Public(value)
    return not (issecretvalue and issecretvalue(value))
end
local function Say(text)
    print("|cff59d9ffClick to cast overlay:|r " .. text)
end
A.Say = Say

-- Pure lookup: never falls back to another modifier's binding.
function A.FindBinding(profile, button, modifiers)
    for _, entry in ipairs(profile or {}) do
        if entry.button == button and entry.modifiers == modifiers then return entry end
    end
end

-- EllesmereUI exposes the resolved spec/global profile through its raid module.
-- Read its runtime projection without changing saved settings or secure frames.
function A.ReadEllesmereProfile()
    local modules = EllesmereUI and EllesmereUI._ModuleNS
    local ns = modules and modules.EllesmereUIRaidFrames
    if not ns then return {}, "missing" end
    if type(ns.CC_GetActiveBindings) ~= "function" or type(ns.CC_GetBindingIcon) ~= "function"
        or type(ns.CC_GetClickCastDB) ~= "function" or type(ns.CC_GetBindingUnitType) ~= "function" then
        return {}, "incompatible"
    end
    local config = ns.CC_GetClickCastDB()
    if not config or not config.enabled then return {}, "disabled" end
    local result = {}
    for _, entry in ipairs(ns.CC_GetActiveBindings() or {}) do
        -- Hover-only key bindings are not clicks on unit frames.
        if entry.enabled ~= false and (not entry.hovercast or entry.hovercast == "both")
            and not (entry.oocOnly and InCombatLockdown()) then
            local prefix, number = (entry.key or ""):match("^(%u+)%-BUTTON([12])$")
            if prefix == "CTRL" or prefix == "SHIFT" or prefix == "ALT" then
                -- Merged item/spell actions keep separate friendly/enemy halves.
                local action = entry.type == "reaction" and entry.friendlyAction or entry
                if action then
                    local reaction = ns.CC_GetBindingUnitType(action)
                    if reaction ~= "harmful" and reaction ~= "none"
                        and action.type ~= "target" and action.type ~= "menu" then
                        result[#result + 1] = {
                            button = number == "1" and "LeftButton" or "RightButton",
                            modifiers = prefix,
                            overlayIcon = ns.CC_GetBindingIcon(action),
                            overlayAction = action,
                        }
                    end
                end
            end
        end
    end
    return result, "ready"
end

local function ReadProfile()
    bindings = {}
    if db and db.source == "ellesmere" then
        local ok, profile, status = pcall(A.ReadEllesmereProfile)
        if ok then bindings = profile; A.sourceStatus = status
        else A.sourceStatus = "error" end
    elseif C_ClickBindings and C_ClickBindings.GetProfileInfo then
        local ok, profile = pcall(C_ClickBindings.GetProfileInfo)
        if ok and type(profile) == "table" then bindings = profile; A.sourceStatus = "blizzard"
        else A.sourceStatus = "error" end
    else
        A.sourceStatus = "missingBlizzard"
    end
    activeKey = nil
    if A.RefreshSourceStatus then A.RefreshSourceStatus() end
end
A.ReadProfile = ReadProfile

local function GetModifiers()
    local count = (IsControlKeyDown() and 1 or 0) + (IsShiftKeyDown() and 1 or 0)
        + (IsAltKeyDown() and 1 or 0)
    if count ~= 1 then return nil end
    if db and db.source == "ellesmere" then
        if IsControlKeyDown() then return "CTRL" end
        if IsShiftKeyDown() then return "SHIFT" end
        return "ALT"
    end
    -- Blizzard owns the modifier bit mask; do not hardcode bit values.
    if MakeModifiers then return MakeModifiers() end
    if C_ClickBindings and C_ClickBindings.MakeModifiers then return C_ClickBindings.MakeModifiers() end
end

local function IconFor(entry)
    if not entry then return nil end
    if entry.overlayIcon then return entry.overlayIcon end
    local kind = Enum.ClickBindingType
    if entry.type == kind.Spell or entry.type == kind.PetAction then
        local id = entry.actionID
        if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
            id = C_SpellBook.FindSpellOverrideByID(id) or id
        end
        local info = C_Spell.GetSpellInfo(id)
        return info and info.iconID
    elseif entry.type == kind.Macro then
        local _, icon = GetMacroInfo(entry.actionID)
        return icon
    end
end

local function SetIcon(icon, entry, sample)
    local texture = sample or IconFor(entry)
    icon.entry = entry
    icon.texture:SetTexture(texture)
    icon:SetShown(texture ~= nil)
    icon.texture:SetDesaturated(not texture)
    icon.texture:SetAlpha(texture and 1 or 0.3)
    icon.empty:SetShown(not texture)
end

-- Resolve only explicit spell/item assignments or the action reported by WoW
-- for a saved macro. Never parse conditional macro text or guess smart actions.
local function CooldownAction(entry)
    local action = entry.overlayAction
    local spell, item, macro
    if action then
        if action.type == "spell" then spell = action.spellID or action.spell
        elseif action.type == "macro" then macro = action.macroName
        elseif action.type == "item" then
            item = action.itemSlot and GetInventoryItemID("player", action.itemSlot)
                or action.itemID or action.itemName
        elseif action.type == "trinket1" or action.type == "trinket2" then
            item = GetInventoryItemID("player", action.type == "trinket1" and 13 or 14)
        end
    elseif entry.type == Enum.ClickBindingType.Spell or entry.type == Enum.ClickBindingType.PetAction then
        spell = entry.actionID
    elseif entry.type == Enum.ClickBindingType.Macro then macro = entry.actionID end
    if macro then
        spell = GetMacroSpell and GetMacroSpell(macro)
        if not spell and GetMacroItem then local _, link = GetMacroItem(macro); item = link end
    end
    if spell and C_SpellBook and C_SpellBook.FindSpellOverrideByID then
        spell = C_SpellBook.FindSpellOverrideByID(spell) or spell
    end
    return spell, item
end

local function UpdateCooldown(icon)
    local cd = icon.cooldown
    if not db.cooldowns or not icon.entry or not icon:IsShown() then cd:Clear(); cd:Hide(); return end
    local ok = pcall(function()
        local spell, item = CooldownAction(icon.entry)
        if spell and C_Spell.GetSpellCooldownDuration and cd.SetCooldownFromDurationObject then
            -- Pass opaque durations straight to the widget: no secret arithmetic
            -- or comparisons in combat. Ignore the global cooldown.
            local duration = C_Spell.GetSpellChargeDuration and C_Spell.GetSpellChargeDuration(spell)
                or C_Spell.GetSpellCooldownDuration(spell, true)
            if duration then cd:Show(); cd:SetCooldownFromDurationObject(duration); return end
        elseif item and C_Item and C_Item.GetItemCooldown then
            local start, duration = C_Item.GetItemCooldown(item)
            cd:Show(); cd:SetCooldown(start, duration); return
        end
        cd:Clear(); cd:Hide()
    end)
    if not ok then cd:Clear(); cd:Hide() end
end

function A.UpdateCooldowns()
    if not overlay or not overlay:IsShown() then return end
    UpdateCooldown(overlay.left)
    UpdateCooldown(overlay.right)
end

local function MakeIcon(parent, label)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:EnableMouse(false)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.025, 0.035, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.25, 0.65, 0.85, 1)
    frame.texture = frame:CreateTexture(nil, "ARTWORK")
    frame.texture:SetPoint("TOPLEFT", 2, -2)
    frame.texture:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetPoint("TOPLEFT", 2, -2)
    frame.cooldown:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.cooldown:EnableMouse(false)
    frame.cooldown:SetDrawEdge(false)
    frame.cooldown:SetDrawBling(false)
    frame.cooldown:SetHideCountdownNumbers(false)
    frame.cooldown:Hide()
    frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.empty:SetPoint("CENTER")
    frame.empty:SetText("—")
    frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.label:SetPoint("BOTTOM", 0, 2)
    frame.label:SetText(label)
    return frame
end

-- GetMouseFoci includes child regions. Walk their parents to the actual unit button.
-- No hooks, attributes, or scripts are installed on protected unit frames.
local function FindAllyFrame()
    for _, focus in ipairs(GetMouseFoci() or {}) do
        local frame = focus
        for _ = 1, 12 do
            if not frame or frame == UIParent then break end
            if frame.IsForbidden and frame:IsForbidden() then break end
            if frame.GetAttribute and not frame:GetAttribute("useparent-unit") then
                local ok, unit = pcall(frame.GetAttribute, frame, "unit")
                if ok and Public(unit) and type(unit) == "string" then
                    local group = unit == "player" or unit == "pet" or unit:match("^party%d+$")
                        or unit:match("^raid%d+$") or unit:match("^partypet%d+$") or unit:match("^raidpet%d+$")
                    if group then return frame end
                    local success, friendly = pcall(UnitCanAssist, "player", unit)
                    if success and Public(friendly) and friendly then return frame end
                end
            end
            frame = frame.GetParent and frame:GetParent()
        end
    end
end

local function Position(mode)
    overlay:ClearAllPoints()
    if mode == "cursor" then
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        overlay:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + db.offsetX, y / scale + db.offsetY)
    elseif mode == "frames" then
        local frame = FindAllyFrame()
        if not frame then return false end
        local x, y = frame:GetCenter()
        if not Public(x) or not Public(y) or not x or not y then return false end
        local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        -- Absolute coordinates avoid anchoring our frame to a protected unit button.
        overlay:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * scale + db.offsetX, y * scale + db.offsetY)
    else
        overlay:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
    end
    return true
end

function A.Update()
    if not db or not overlay then return end
    if not db.enabled then overlay:Hide(); return end
    local modifiers = GetModifiers()
    local moving = not db.locked and db.mode == "window"
    if not modifiers and not preview and not moving then overlay:Hide(); return end
    if not Position(db.mode) then overlay:Hide(); return end
    local key = modifiers or "preview"
    local changed = activeKey ~= key
    if changed then
        if modifiers then
            SetIcon(overlay.left, A.FindBinding(bindings, "LeftButton", modifiers))
            SetIcon(overlay.right, A.FindBinding(bindings, "RightButton", modifiers))
        else
            SetIcon(overlay.left, nil, 135940)
            SetIcon(overlay.right, nil, 135964)
        end
        activeKey = key
    end
    overlay:Show()
    if changed then A.UpdateCooldowns() end
end

function A.Apply()
    if not overlay then return end
    overlay:SetSize(db.size * 2 + db.gap, db.size)
    for _, icon in ipairs({ overlay.left, overlay.right }) do
        icon:SetSize(db.size, db.size)
        icon.label:SetShown(db.labels)
    end
    overlay.left:SetPoint("LEFT")
    overlay.right:SetPoint("RIGHT")
    mover:ClearAllPoints()
    mover:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
    mover:SetSize(db.size * 2 + db.gap + 12, db.size + 30)
    ReadProfile()
    mover:SetShown(db.enabled and db.mode == "window" and not db.locked)
    activeKey = nil
    A.Update()
end

function A.TogglePreview()
    preview = not preview
    A.Update()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= addonName then return end
        ClickToCastOverlayDB = type(ClickToCastOverlayDB) == "table" and ClickToCastOverlayDB or {}
        db = ClickToCastOverlayDB
        for key, value in pairs(A.defaults) do
            if type(db[key]) ~= type(value) then db[key] = value end
        end
        if db.source ~= "blizzard" and db.source ~= "ellesmere" then db.source = "blizzard" end
        if db.mode ~= "window" and db.mode ~= "cursor" and db.mode ~= "frames" then db.mode = "window" end
        for key, limits in pairs({ size = {20, 80}, gap = {0, 30}, offsetX = {-300, 300}, offsetY = {-300, 300}, x = {-5000, 5000}, y = {-5000, 5000} }) do
            if db[key] ~= db[key] then db[key] = A.defaults[key] end
            db[key] = math.max(limits[1], math.min(limits[2], db[key]))
        end
        A.db = db
        overlay = CreateFrame("Frame", "ClickToCastOverlayDisplay", UIParent)
        overlay:SetFrameStrata("TOOLTIP")
        overlay:EnableMouse(false)
        overlay.left = MakeIcon(overlay, RU and "ЛКМ" or "LMB")
        overlay.right = MakeIcon(overlay, RU and "ПКМ" or "RMB")
        mover = CreateFrame("Frame", "ClickToCastOverlayMover", UIParent, "BackdropTemplate")
        mover:SetFrameStrata("DIALOG")
        mover:SetMovable(true)
        mover:SetClampedToScreen(true)
        mover:EnableMouse(true)
        mover:RegisterForDrag("LeftButton")
        mover:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        mover:SetBackdropColor(0.05, 0.15, 0.2, 0.85)
        mover:SetBackdropBorderColor(0.3, 0.8, 1, 1)
        local title = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        title:SetPoint("TOP", 0, -3)
        title:SetText(RU and "Перетащи меня" or "Drag me")
        mover:SetScript("OnDragStart", function(self) self:StartMoving() end)
        mover:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local x, y = self:GetCenter()
            local cx, cy = UIParent:GetCenter()
            db.x, db.y = x - cx, y - cy
            A.Apply()
        end)
        -- The mover has its own anchor so overlay repositioning cannot interrupt a drag.
        mover:SetScript("OnUpdate", function(self)
            local x, y = self:GetCenter()
            local cx, cy = UIParent:GetCenter()
            db.x, db.y = x - cx, y - cy
        end)
        A.CreateOptions()
        for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_SPECIALIZATION_CHANGED", "SPELLS_CHANGED", "UPDATE_MACROS", "MODIFIER_STATE_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "GROUP_ROSTER_UPDATE", "PLAYER_EQUIPMENT_CHANGED" }) do driver:RegisterEvent(ev) end
        ReadProfile()
        A.Apply()
        driver:SetScript("OnUpdate", function(_, dt)
            profileElapsed = profileElapsed + dt
            -- Both sources may update without a public profile-changed event.
            if profileElapsed >= 1 then profileElapsed = 0; ReadProfile() end
            elapsed = elapsed + dt
            if elapsed >= 0.02 then elapsed = 0; A.Update() end
            cooldownElapsed = cooldownElapsed + dt
            if cooldownElapsed >= 0.1 then cooldownElapsed = 0; A.UpdateCooldowns() end
        end)
        if not C_ClickBindings then Say(RU and "API Click Casting недоступен в этом клиенте." or "Click Casting API is unavailable.") end
    elseif event == "MODIFIER_STATE_CHANGED" then
        A.Update()
    else
        ReadProfile()
        A.Update()
    end
end)
