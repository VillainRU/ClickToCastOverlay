local frames = {}
local function object()
    local o = { scripts = {}, shown = true, width = 100, height = 40, x = 500, y = 400, attrs = {}, scale = 1 }
    function o:SetScript(k,v) self.scripts[k]=v end
    function o:RegisterEvent() end
    function o:CreateTexture() return object() end
    function o:CreateFontString() return object() end
    function o:GetFrameLevel() return 1 end
    function o:SetDrawSwipe(v) self.drawSwipe=v end
    function o:SetCountdownFont(v) self.countdownFont=v end
    function o:Clear() self.durationObject=nil;self.cooldownStart=nil;self.cooldownDuration=nil end
    function o:SetCooldownFromDurationObject(value) self.durationObject=value end
    function o:SetCooldown(start,duration) self.cooldownStart=start;self.cooldownDuration=duration end
    function o:SetTexture(t) self.textureValue=t end
    function o:SetText(t) self.textValue=t end
    function o:SetSize(w,h) self.width=w;self.height=h end
    function o:SetWidth(w) self.width=w end
    function o:SetPoint(...) self.point={...} end
    function o:ClearAllPoints() end
    function o:Show() self.shown=true end
    function o:Hide() self.shown=false end
    function o:SetShown(b) self.shown=not not b end
    function o:IsShown() return self.shown end
    function o:GetCenter() return self.x,self.y end
    function o:GetEffectiveScale() return self.scale end
    function o:GetAttribute(k) return self.attrs[k] end
    function o:GetParent() return self.parent end
    function o:IsForbidden() return self.forbidden end
    function o:SetChecked(v) self.checked=v end
    function o:GetChecked() return self.checked end
    function o:SetValue(v) self.value=v;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end end
    for _,k in ipairs({'SetFrameLevel','SetSwipeColor','SetDrawEdge','SetDrawBling','SetHideCountdownNumbers','SetScrollChild','EnableMouse','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetDesaturated','SetAlpha','SetTexCoord','SetFrameStrata','SetMovable','SetClampedToScreen','RegisterForDrag','StartMoving','StopMovingOrSizing','SetJustifyH','SetMinMaxValues','SetValueStep','SetObeyStepOnDrag'}) do o[k]=function() end end
    return o
end
UIParent=object(); UIParent.x=960;UIParent.y=540
function CreateFrame(kind,name,parent,template)
    local o=object();o.parent=parent
    if template=='UICheckButtonTemplate' then o.Text=object() end
    if template=='UIRadioButtonTemplate' then o.text=object() end
    if template=='OptionsSliderTemplate' then o.Text=object();o.Low=object();o.High=object() end
    frames[#frames+1]=o
    if name then _G[name]=o end
    return o
end
function GetLocale() return 'ruRU' end
local ctrl,shift,alt=false,false,false
function IsControlKeyDown() return ctrl end
function IsShiftKeyDown() return shift end
function IsAltKeyDown() return alt end
function MakeModifiers() return (ctrl and 2 or 0)+(shift and 1 or 0)+(alt and 4 or 0) end
local secret={}
function issecretvalue(v) return v==secret end
Enum={ClickBindingType={Spell=1,Macro=2,Interaction=3,PetAction=4}}
local profile={}
C_ClickBindings={GetProfileInfo=function() return profile end}
C_SpellBook={FindSpellOverrideByID=function(id) return id+1000 end}
C_Spell={GetSpellInfo=function(id) return {iconID=id+5000} end}
function GetMacroInfo(id) return 'macro',id+8000 end
local foci={}
function GetMouseFoci() return foci end
function UnitCanAssist(_,unit) return unit=='friend' end
function GetCursorPosition() return 400,300 end
SlashCmdList={}
Settings={RegisterCanvasLayoutCategory=function(panel) return {GetID=function() return 1 end} end, RegisterAddOnCategory=function() end,OpenToCategory=function() end}
local A={}
assert(loadfile((arg[1] or 'ClickToCastOverlay') .. '/Core.lua'))('ClickToCastOverlay',A)
assert(loadfile((arg[1] or 'ClickToCastOverlay') .. '/Options.lua'))('ClickToCastOverlay',A)
local driver=frames[1]
driver.scripts.OnEvent(driver,'ADDON_LOADED','ClickToCastOverlay')
local overlay=ClickToCastOverlayDisplay
assert(not overlay.shown,'hidden without modifiers')
profile={{button='LeftButton',modifiers=2,type=1,actionID=10},{button='RightButton',modifiers=2,type=1,actionID=20},{button='LeftButton',modifiers=1,type=2,actionID=8},{button='RightButton',modifiers=4,type=1,actionID=30}}
A.ReadProfile();ctrl=true;A.Update()
assert(overlay.shown and overlay.left.texture.textureValue==6010 and overlay.right.texture.textureValue==6020,'ctrl pair')
ctrl=false;shift=true;A.Update()
assert(overlay.left.texture.textureValue==8008 and overlay.right.empty.shown,'shift macro + empty')
shift=false;alt=true;A.Update()
assert(overlay.left.empty.shown and overlay.right.texture.textureValue==6030,'alt pair')
ctrl=true;A.Update();assert(not overlay.shown,'multiple modifiers hidden')
ctrl=false;alt=false;A.Update();assert(not overlay.shown,'release hides')
ctrl=true;A.db.mode='cursor';A.Apply()
assert(overlay.point[4]==424 and overlay.point[5]==320,'cursor offset')
A.db.mode='frames';A.Apply();assert(not overlay.shown,'no hovered frame')
local ally=object();ally.attrs.unit='party1';ally.parent=UIParent
local child=object();child.attrs.unit='party1';child.attrs['useparent-unit']=true;child.parent=ally;child.x=8;child.y=9
foci={child};A.Update();assert(overlay.shown and overlay.point[4]==524,'parent unit frame selected')
local enemy=object();enemy.attrs.unit='enemy';enemy.parent=UIParent;foci={enemy};A.Update();assert(not overlay.shown,'enemy hidden')
enemy.attrs.unit=secret;A.Update();assert(not overlay.shown,'secret unit safe')
enemy.forbidden=true;A.Update();assert(not overlay.shown,'forbidden frame safe')
foci={ally};ally.x=secret;A.Update();assert(not overlay.shown,'secret geometry safe');ally.x=500
A.db.enabled=false;A.Apply();assert(not overlay.shown,'disabled hides')
A.db.enabled=true;ctrl=false
SlashCmdList.CLICKTOCASTOVERLAY('unlock');assert(overlay.shown and ClickToCastOverlayMover.shown,'move preview')
SlashCmdList.CLICKTOCASTOVERLAY('lock');assert(not overlay.shown and not ClickToCastOverlayMover.shown,'lock preview hides')
SlashCmdList.CLICKTOCASTOVERLAY('test');assert(overlay.shown,'explicit preview')
SlashCmdList.CLICKTOCASTOVERLAY('test');assert(not overlay.shown,'preview off')
for _,f in ipairs(frames) do if f.scripts.OnShow then f.scripts.OnShow(f) end end
print('PASS: addon load, options, Ctrl/Shift/Alt, empty/macro, multi-modifier, release, cursor, frame parents, enemy, secrets, forbidden frames, disable, move/lock, preview')
local combat=false
function InCombatLockdown() return combat end
SlashCmdList.CLICKTOCASTOVERLAY('ellesmere')
assert(A.db.source=='ellesmere' and A.sourceStatus=='missing','missing EUI is explicit')
ctrl=true;A.Update();assert(overlay.left.empty.shown and overlay.right.empty.shown,'missing EUI never falls back to Blizzard')
local euiEnabled=true
local entries={
 {key='CTRL-BUTTON1',type='spell',icon=9001,hoverFriendly=true},
 {key='CTRL-BUTTON2',type='spell',icon=9002,hovercast=true},
 {key='CTRL-BUTTON2',type='spell',icon=9003,hoverFriendly=false,hoverEnemy=true},
 {key='CTRL-BUTTON2',type='macro',icon=9004},
 {key='SHIFT-BUTTON1',type='reaction',friendlyAction={type='item',icon=9010},harmfulAction={type='spell',icon=9999}},
 {key='SHIFT-BUTTON2',type='spell',icon=9011,oocOnly=true},
 {key='ALT-BUTTON1',type='spell',icon=9012,hovercast='both'},
 {key='ALT-BUTTON2',type='menu',icon=9013},
 {key='CTRL-SHIFT-BUTTON1',type='spell',icon=9014},
}
local ns={
 CC_GetClickCastDB=function() return {enabled=euiEnabled} end,
 CC_GetActiveBindings=function() return entries end,
 CC_GetBindingIcon=function(b) return b.icon end,
 CC_GetBindingUnitType=function(b)
  if b.hoverFriendly==false and b.hoverEnemy==true then return 'harmful' end
  if b.hoverFriendly==false and b.hoverEnemy==false then return 'none' end
  return 'friendly'
 end,
}
EllesmereUI={_ModuleNS={EllesmereUIRaidFrames=ns}}
A.Apply();assert(A.sourceStatus=='ready','late EUI loading')
assert(overlay.left.texture.textureValue==9001 and overlay.right.texture.textureValue==9004,'ctrl EUI ignores hover-only and enemy branch')
ctrl=false;shift=true;A.Update()
assert(overlay.left.texture.textureValue==9010 and overlay.right.texture.textureValue==9011,'reaction uses friendly action and ooc binding visible')
combat=true;driver.scripts.OnEvent(driver,'PLAYER_REGEN_DISABLED');A.Update()
assert(overlay.right.empty.shown,'ooc-only hidden in combat')
combat=false;driver.scripts.OnEvent(driver,'PLAYER_REGEN_ENABLED');A.Update()
assert(overlay.right.texture.textureValue==9011,'ooc returns after combat')
shift=false;alt=true;A.Update()
assert(overlay.left.texture.textureValue==9012 and overlay.right.empty.shown,'both path and interaction')
alt=false;ctrl=true;shift=true;A.Update();assert(not overlay.shown,'EUI multiple modifiers hidden')
shift=false;euiEnabled=false;A.ReadProfile();A.Update()
assert(A.sourceStatus=='disabled' and overlay.left.empty.shown,'disabled EUI clears stale bindings')
euiEnabled=true;ns.CC_GetActiveBindings=function() error('test API failure') end
A.ReadProfile();assert(A.sourceStatus=='error','API failure contained')
ns.CC_GetBindingIcon=nil;A.ReadProfile();assert(A.sourceStatus=='incompatible','incompatible EUI reported')
SlashCmdList.CLICKTOCASTOVERLAY('blizzard');A.Update()
assert(A.sourceStatus=='blizzard' and overlay.left.texture.textureValue==6010,'switch back to Blizzard')
print('PASS: EUI source selection, missing/disabled/incompatible/error, late load, frame path, allied reaction, macro, combat-only gate, no native fallback, switch to Blizzard')

-- Use opaque objects to ensure the implementation never reads cooldown numbers.
local duration={}; local recharge={}
local spellCalls={}
C_Spell.GetSpellCooldownDuration=function(id,ignoreGCD) spellCalls[#spellCalls+1]={id,ignoreGCD};return duration end
C_Spell.GetSpellChargeDuration=function() return nil end
A.db.mode='window';ctrl=true;shift=false;alt=false;A.Apply()
assert(A.db.cooldowns==true and overlay.left.cooldown.durationObject==duration,'cooldowns enabled by default')
assert(spellCalls[#spellCalls][1]==1020 and spellCalls[#spellCalls][2]==true,'override spell and ignore GCD')
A.db.cooldowns=false;A.Apply();assert(not overlay.left.cooldown.shown and not overlay.left.cooldown.durationObject,'toggle clears cooldown')
A.db.cooldowns=true;A.Apply()
C_Spell.GetSpellChargeDuration=function() return recharge end
A.UpdateCooldowns();assert(overlay.left.chargeCooldown.durationObject==recharge and overlay.left.cooldown.durationObject==duration,'charge and ordinary timers independent')
C_Spell.GetSpellChargeDuration=function() return nil end
local replacement={};duration=replacement
A.UpdateCooldowns();assert(overlay.left.cooldown.durationObject==replacement,'same modifier refreshes cooldown')
ctrl=false;alt=true;A.Update();assert(not overlay.left.shown and overlay.left.texture.textureValue==nil,'empty slot hidden without question mark')
assert(not overlay.left.cooldown.shown,'empty cooldown hidden')
alt=false;shift=true
function GetMacroSpell() return 42 end
A.Update();assert(overlay.left.cooldown.durationObject==replacement,'WoW-resolved macro cooldown')
assert(not overlay.right.shown,'other empty slot hidden')
C_Spell.GetSpellCooldownDuration=function() error('restricted API') end
A.UpdateCooldowns();assert(not overlay.left.cooldown.shown,'unavailable cooldown clears safely')
C_Spell.GetSpellCooldownDuration=function() return replacement end
ns.CC_GetBindingIcon=function(b) return b.icon end
local actions={{key='CTRL-BUTTON1',type='spell',spellID=73,icon=9100},{key='CTRL-BUTTON2',type='item',itemSlot=13,icon=9200}}
ns.CC_GetActiveBindings=function() return actions end
function GetInventoryItemID(_,slot) assert(slot==13);return 123 end
C_Item={GetItemCooldown=function(item) assert(item==123);return 10,30 end}
shift=false;ctrl=true;SlashCmdList.CLICKTOCASTOVERLAY('ellesmere');A.UpdateCooldowns()
assert(overlay.left.cooldown.durationObject==replacement,'EUI spell cooldown')
assert(overlay.right.cooldown.cooldownDuration==30,'EUI item cooldown')
actions[1]={key='CTRL-BUTTON1',type='external',icon=9300};A.ReadProfile();A.Update()
assert(overlay.left.shown and not overlay.left.cooldown.shown,'smart EUI action has no guessed timer')
actions={};A.ReadProfile();A.Update()
assert(not overlay.left.shown and not overlay.right.shown,'both empty slots hidden')
ctrl=false;A.Update();assert(not overlay.shown,'modifier release still hides overlay')
print('PASS: cooldown default/toggle, spell override, ignore GCD, opaque durations, recharge, refresh, macro, item, smart actions, error cleanup, empty-slot hiding')

-- An empty charge duration must never swallow a real spell cooldown.
ctrl=true;shift=false;alt=false;SlashCmdList.CLICKTOCASTOVERLAY('blizzard')
C_Spell.GetSpellChargeDuration=function() return {} end
A.UpdateCooldowns()
assert(overlay.left.cooldown.durationObject==replacement,'empty recharge object does not replace ordinary cooldown')
C_Spell.GetSpellChargeDuration=function() error('charge API rejected noncharge spell') end
A.UpdateCooldowns()
assert(overlay.left.cooldown.durationObject==replacement and not overlay.left.chargeCooldown.shown,'charge error preserves main cooldown')
C_Spell.GetSpellCooldown=function() return {startTime=10,duration=120,isOnGCD=false} end
A.UpdateCooldowns()
assert(overlay.left.cooldown.cooldownStart==10 and overlay.left.cooldown.cooldownDuration==120 and overlay.left.cooldown.shown,'public numeric cooldown fallback')
C_Spell.GetSpellCooldown=function() return {startTime=secret,duration=secret,isOnGCD=secret} end
A.UpdateCooldowns()
assert(overlay.left.cooldown.durationObject==replacement,'restricted numeric values use opaque object')
C_Spell.GetSpellCooldown=function() return {startTime=10,duration=1.5,isOnGCD=true} end
A.UpdateCooldowns();assert(not overlay.left.cooldown.shown,'public GCD excluded')
assert(overlay.left.cooldown.drawSwipe==true and overlay.left.cooldown.countdownFont=='GameFontNormalLarge','explicit visible swipe and font')
print('PASS: zero recharge isolation, independent charge errors, numeric and secret paths, visible swipe/font')
