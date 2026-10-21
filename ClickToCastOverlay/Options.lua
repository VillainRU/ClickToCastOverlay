local _, A = ...
local RU = A.RU
local function L(ru, en) return RU and ru or en end
local title = "Click to cast overlay"
function A.CreateOptions()
    local db = A.db
    local panel = CreateFrame("Frame")
    panel.name = title
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(610, 850)
    scroll:SetScrollChild(content)
    local heading = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 16, -16)
    heading:SetText(title)
    local desc = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", 16, -46)
    desc:SetWidth(570)
    desc:SetJustifyH("LEFT")
    desc:SetText(L("Удерживай Ctrl, Shift или Alt: слева ЛКМ, справа ПКМ.\nИсточник назначений выбирается ниже.",
        "Hold Ctrl, Shift or Alt: left icon = LMB, right icon = RMB.\nSelect the binding source below."))
    local refreshers = {}
    local function Check(label, key, y)
        local b = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        b:SetPoint("TOPLEFT", 16, y)
        b.Text:SetText(label)
        b:SetScript("OnClick", function(self) db[key] = self:GetChecked(); A.Apply() end)
        refreshers[#refreshers + 1] = function() b:SetChecked(db[key]) end
        return b
    end
    Check(L("Включить оверлей", "Enable overlay"), "enabled", -86)
    Check(L("Подписи ЛКМ / ПКМ", "LMB / RMB labels"), "labels", -118)
    Check(L("Закрепить окно (сними для перемещения)", "Lock window (uncheck to move)"), "locked", -150)
    Check(L("Показывать кулдаун на иконках", "Show cooldowns on icons"), "cooldowns", -182)
    local sourceTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sourceTitle:SetPoint("TOPLEFT", 20, -226)
    sourceTitle:SetText(L("Источник Click Casting", "Click Casting source"))
    for i, item in ipairs({ { "blizzard", "Blizzard" }, { "ellesmere", "EllesmereUI" } }) do
        local value = item[1]
        local b = CreateFrame("CheckButton", nil, content, "UIRadioButtonTemplate")
        b:SetPoint("TOPLEFT", 22 + (i - 1) * 170, -252)
        b.text:SetText(item[2])
        b:SetScript("OnClick", function()
            db.source = value
            A.Apply()
            for _, refresh in ipairs(refreshers) do refresh() end
        end)
        refreshers[#refreshers + 1] = function() b:SetChecked(db.source == value) end
    end
    local status = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", 20, -282)
    status:SetWidth(570)
    status:SetJustifyH("LEFT")
    function A.RefreshSourceStatus()
        local messages = {
            blizzard = L("Читаются сохранённые назначения Blizzard.", "Reading saved Blizzard bindings."),
            ready = L("Читаются активные назначения EllesmereUI для кликов по союзным фреймам.", "Reading active EllesmereUI bindings for clicks on friendly frames."),
            missing = L("Модуль EllesmereUI RaidFrames не загружен. Назначения недоступны.", "EllesmereUI RaidFrames is not loaded. Bindings unavailable."),
            incompatible = L("Эта версия EllesmereUI не предоставляет нужный API.", "This EllesmereUI version does not expose the required API."),
            disabled = L("Собственный Click Casting EllesmereUI выключен. Назначения недоступны.", "EllesmereUI Click Casting is disabled. Bindings unavailable."),
            error = L("Не удалось прочитать назначения выбранного источника.", "Unable to read the selected binding source."),
            missingBlizzard = L("API Blizzard Click Casting недоступен.", "Blizzard Click Casting API unavailable."),
        }
        status:SetText(messages[A.sourceStatus] or "")
    end
    local modeTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    modeTitle:SetPoint("TOPLEFT", 20, -348)
    modeTitle:SetText(L("Расположение", "Placement"))
    local modes = { { "window", L("Отдельное окно", "Movable window") }, { "cursor", L("У курсора", "At cursor") }, { "frames", L("На фрейме под курсором", "Hovered ally frame") } }
    for i, item in ipairs(modes) do
        local value = item[1]
        local b = CreateFrame("CheckButton", nil, content, "UIRadioButtonTemplate")
        b:SetPoint("TOPLEFT", 22, -374 - (i - 1) * 28)
        b.text:SetText(item[2])
        b:SetScript("OnClick", function()
            db.mode = value
            for _, refresh in ipairs(refreshers) do refresh() end
            A.Apply()
        end)
        refreshers[#refreshers + 1] = function() b:SetChecked(db.mode == value) end
    end
    local function Slider(label, key, lo, hi, y)
        local s = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", 28, y)
        s:SetWidth(290)
        s:SetMinMaxValues(lo, hi)
        s:SetValueStep(1)
        s:SetObeyStepOnDrag(true)
        s.Low:SetText(tostring(lo))
        s.High:SetText(tostring(hi))
        s:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value + 0.5)
            db[key] = value
            self.Text:SetText(label .. ": " .. value)
            A.Apply()
        end)
        refreshers[#refreshers + 1] = function()
            s:SetValue(db[key])
            s.Text:SetText(label .. ": " .. db[key])
        end
    end
    Slider(L("Размер иконок", "Icon size"), "size", 20, 80, -490)
    Slider(L("Промежуток", "Icon gap"), "gap", 0, 30, -548)
    Slider(L("Смещение X: курсор / фрейм", "Offset X: cursor / frame"), "offsetX", -150, 150, -606)
    Slider(L("Смещение Y: курсор / фрейм", "Offset Y: cursor / frame"), "offsetY", -150, 150, -664)
    local function Button(text, x, action)
        local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        b:SetSize(164, 26)
        b:SetPoint("TOPLEFT", x, -710)
        b:SetText(text)
        b:SetScript("OnClick", action)
    end
    Button(L("Предпросмотр", "Toggle preview"), 20, A.TogglePreview)
    Button(L("Сброс настроек", "Reset settings"), 194, function()
        for key, value in pairs(A.defaults) do db[key] = value end
        for _, refresh in ipairs(refreshers) do refresh() end
        A.Apply()
    end)
    local note = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 20, -754)
    note:SetWidth(570)
    note:SetJustifyH("LEFT")
    note:SetText(L("Пустое назначение: иконка скрыта. Макрос: сохранённая иконка.\nКулдаун: заклинания, предметы и распознанные WoW макросы.\nУмные действия EllesmereUI: только иконка, без кулдауна.\nНесколько модификаторов: оверлей скрыт. /ctco — настройки.\nEllesmereUI: UnitFrames / RaidFrames; hover-only исключены.",
        "Empty binding: icon hidden. Macro: its saved icon.\nCooldowns: spells, items and macros resolved by WoW.\nEllesmereUI smart actions: icon only, no cooldown.\nMultiple modifiers: overlay hidden. /ctco opens settings.\nEllesmereUI: UnitFrames / RaidFrames; hover-only excluded."))
    panel:SetScript("OnShow", function()
        for _, refresh in ipairs(refreshers) do refresh() end
        A.ReadProfile()
    end)
    local category = Settings.RegisterCanvasLayoutCategory(panel, title)
    Settings.RegisterAddOnCategory(category)
    A.category = category
end

SLASH_CLICKTOCASTOVERLAY1 = "/ctco"
SLASH_CLICKTOCASTOVERLAY2 = "/clicktocastoverlay"
SlashCmdList.CLICKTOCASTOVERLAY = function(msg)
    local db = A.db
    if not db then return end
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "lock" then db.locked = true; A.Apply()
    elseif msg == "unlock" then db.mode = "window"; db.locked = false; A.Apply()
    elseif msg == "test" then A.TogglePreview()
    elseif msg == "blizzard" or msg == "ellesmere" then db.source = msg; A.Apply()
    elseif msg == "refresh" then A.ReadProfile(); A.Update()
    elseif msg == "window" or msg == "cursor" or msg == "frames" then db.mode = msg; A.Apply()
    elseif msg == "reset" then
        for key, value in pairs(A.defaults) do db[key] = value end
        A.Apply()
    else Settings.OpenToCategory(A.category:GetID()) end
end
