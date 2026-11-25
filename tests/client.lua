unpack = table.unpack
math.atan2 = function(y,x) return math.atan(y,x) end
SlashCmdList, UISpecialFrames, frames, containers = {}, {}, {}, {}
RapiTwistDB = {x=0,y=-150,scale=1,locked=true}
combat = false
function InCombatLockdown() return combat end
function UnitClass() return "Paladín", "PALADIN" end
function GetCursorPosition() return 960, 640 end
C_Spell = {GetSpellTexture=function(id) return id end}
C_UnitAuras = setmetatable({}, {__index=function() error("Raw aura read") end})
local M = {}
function CreateFrame(kind, name, parent, template)
    local f = setmetatable({kind=kind,parent=parent,template=template,children={},shown=true,
        scale=1,w=100,h=100,scripts={},events={},slots={},cx=960,cy=540}, {__index=M})
    if parent then table.insert(parent.children, f) end
    if name then _G[name]=f end
    if kind=="AuraContainer" then table.insert(containers,f) end
    table.insert(frames,f)
    return f
end
UIParent = CreateFrame("Frame")
Minimap = CreateFrame("Minimap",nil,UIParent)
GameTooltip = CreateFrame("Tooltip")
GameTooltip.Hide = function() error("Global tooltip was hidden") end
TargetFrame = CreateFrame("Frame", nil, UIParent)
TargetFrame.Hide = function() error("Target frame was hidden") end
C_NamePlate = setmetatable({}, {__index=function() error("Nameplate access") end})
SetCVar = function() error("Changed global CVar") end
function M:SetSize(w,h) self.w,self.h=w,h end
function M:SetScale(n) self.scale=n end
function M:GetWidth() return self.w end
function M:GetHeight() return self.h end
function M:GetEffectiveScale() return self.scale end
function M:SetAlpha(n) self.alpha=n end
function M:SetBlendMode(mode) self.blend=mode end
function M:SetVertexColor(...) self.tint={...} end
function M:SetValue(n) self.value=n end
function M:SetPoint(...) self.point={...} end
function M:GetFrameLevel() return 5 end
function M:GetCenter() return self.cx,self.cy end
function M:SetUnit(unit) assert(unit=="player") end
function M:CreateLine() return CreateFrame("Line",nil,self) end
function M:SetStartPoint(_,_,x,y) self.startX,self.startY=x,y end
function M:SetEndPoint(_,_,x,y) self.endX,self.endY=x,y end
function M:SetThickness(n) self.thickness=n end
function M:SetColorTexture(r,g,b,a) self.color={r,g,b,a} end
function M:CreateTexture() return CreateFrame("Texture",nil,self) end
function M:CreateFontString() return CreateFrame("Font",nil,self) end
function M:SetText(txt) self.text=txt end
function M:Show() self.shown=true end
function M:Hide() self.shown=false end
function M:IsShown() return self.shown end
function M:SetShown(v) self.shown=not not v end
function M:EnableMouse(v) self.mouse=v end
function M:SetEnabled(v) self.enabled=v end
function M:SetScript(key,fn) self.scripts[key]=fn end
function M:HookScript(key,fn) self.scripts[key]=fn end
function M:RegisterEvent(ev) self.events[ev]=true end
function M:StartMoving() self.moving=true end
function M:StopMovingOrSizing() self.moving=false end
function M:SetApplicationBar(b,options) self.bar,self.options=b,options end
function M:SetDurationBar(b) self.duration=b end
function M:AddAuraSlot(key,filter,options)
    assert(filter=="HELPFUL" and not self.slots[key])
    local f=CreateFrame("AuraButton",nil,self)
    f.filter=options.candidateFilters.includeSpellIDs
    self.slots[key]=f
    options.initializeFrame(f)
end
for _,k in ipairs({"SetMinMaxValues","SetTexture","SetFrameStrata","SetFrameLevel","SetTexCoord",
    "SetStatusBarTexture","SetStatusBarColor","SetAllPoints","SetFont","SetTextColor",
    "SetHighlightTexture","SetClampedToScreen","SetMovable","RegisterForClicks","RegisterForDrag",
    "ClearAllPoints","SetOwner","AddLine"}) do M[k]=function() end end
function send(ev,...)
    for _,f in ipairs(frames) do if f.events[ev] then f.scripts.OnEvent(f,ev,...) end end
end
function auras(values)
    for _,c in ipairs(containers) do
        for _,f in pairs(c.slots) do
            local n=nil
            for id in pairs(f.filter) do if values[id]~=nil then n=values[id] end end
            f:SetShown(n~=nil)
            if f.bar then f.bar:SetShown((n or 0)>=f.options.minApplications) end
        end
    end
end
function visible(f)
    if not f.shown then return false end
    return not f.parent or visible(f.parent)
end
function click(f,key) f.scripts.OnClick(f,key or "LeftButton") end
function withText(f,txt)
    for _,child in ipairs(f.children) do if child.text==txt then return child end end
    error("Missing control "..txt)
end
