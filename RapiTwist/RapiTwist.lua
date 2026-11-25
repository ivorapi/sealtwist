-- RapiTwist • WoW Forever
local ADDON = ...
local W, H = 180, 132
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local seals = {
    Command = {echo = 1311703, ranks = {20375, 20915, 20918, 20919, 20920}},
    Righteousness = {echo = 1311704, ranks = {21084, 20154, 20287, 20288, 20289, 20290, 20291, 20292, 20293}},
    Fury = {echo = 1311701, ranks = {1311649, 1311656, 20163, 20419, 20421, 20422, 20423}},
    Justice = {echo = 1311705, ranks = {20164}},
    Light = {echo = 1328198, ranks = {20165, 20347, 20348, 20349}},
    Wisdom = {echo = 1328206, ranks = {20166, 20356, 20357}},
    Crusader = {ranks = {21082, 20162, 20305, 20306, 20307, 20308}},
    Martyrdom = {ranks = {407798}},
}
local choices = {"Command", "Righteousness", "Fury", "Justice", "Light", "Wisdom", "Crusader", "Martyrdom"}
local GOLD, BLUE, INK, LIGHT = {1, .79, .40}, {.58, .85, 1}, {.048, .044, .052}, {1, .97, .89}
local EMPTY = {.42, .50, .58}
local CORAL = {1, .53, .46}
local defaults = {x = 0, y = -55, scale = 1, alpha = 1, angle = 220, combatOnly = false, hidden = false}
local db, root, live, handle, panel, launcher, refreshPanel, nativeError
local editing, dragging = false, false

local function bounded(value, lo, hi)
    return math.max(lo, math.min(value, hi))
end

local function say(message)
    print("|cffffca70RapiTwist|r " .. message)
end

local function loadSettings()
    db = type(RapiTwistDB) == "table" and RapiTwistDB or {}
    -- The paired arcs have a different anchor from the old single-row tracker.
    if db.layoutVersion ~= 3 then
        db.x, db.y = defaults.x, defaults.y
    end
    for key, value in pairs(defaults) do
        local saved = db[key]
        if type(saved) ~= type(value) or (type(saved) == "number" and not (math.abs(saved) < math.huge)) then
            db[key] = value
        end
    end
    db.scale = bounded(db.scale, .6, 2)
    db.alpha = bounded(db.alpha, .4, 1)
    if not seals[db.firstSeal] or not seals[db.secondSeal] or db.firstSeal == db.secondSeal then
        db.firstSeal, db.secondSeal = "Command", "Righteousness"
    end
    for key, fallback in pairs({firstCount = 3, secondCount = 1}) do
        local n = db[key]
        if n ~= 1 and n ~= 2 and n ~= 3 then db[key] = fallback end
    end
    db.locked = nil
    db.layoutVersion = 3
    RapiTwistDB = db
end

local function rect(parent, layer, x, y, w, h, color, alpha)
    local t = parent:CreateTexture(nil, layer)
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    t:SetSize(w, h)
    t:SetColorTexture(color[1], color[2], color[3], alpha or 1)
    return t
end

local function label(parent, value, x, y, size, color)
    local t = parent:CreateFontString(nil, "OVERLAY")
    t:SetFont(FONT, size, "OUTLINE")
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    t:SetTextColor(unpack(color or LIGHT))
    t:SetText(value)
    return t
end

local function iconPath(id)
    return C_Spell.GetSpellTexture(id) or "Interface\\Icons\\Spell_Holy_SealOfMight"
end

local function nativeContainer(parent)
    local c = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
    c:SetSize(W, H)
    c:SetPoint("TOPLEFT")
    c:EnableMouse(false)
    c:SetUnit("player")
    return c
end

local function slot(container, key, ids, draw)
    local allowed = {}
    for _, id in ipairs(ids) do allowed[id] = true end
    container:AddAuraSlot(key, "HELPFUL", {
        candidateFilters = {includeSpellIDs = allowed},
        initializeFrame = function(frame)
            frame:SetSize(W, H)
            frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
            frame:EnableMouse(false)
            draw(frame)
        end,
    })
end

local function echoBar(parent)
    -- The native bar controls visibility only. All visible art is in its children.
    local b = CreateFrame("StatusBar", nil, parent)
    b:SetAllPoints()
    b:EnableMouse(false)
    return b
end

-- Blizzard controls slot visibility. Presence alone represents the first echo,
-- including on clients that display a single application without a stack count.
local function threshold(frame, b, count)
    if count == 1 then
        b:SetMinMaxValues(0, 1)
        b:SetValue(1)
    else
        -- Only visibility matters: the rune and the cue are separate regions.
        -- Start dark until the client has applied this echo's exact stack count.
        b:Hide()
        frame:SetApplicationBar(b, {minApplications = count, maxApplications = count + 1})
    end
end

-- Mirror one antialiased atlas tile. Transparent padding separates adjacent tiles.
local ARC_TEXTURE = "Interface\\AddOns\\RapiTwist\\SideArcs"
local function arcSegment(parent, index, count, color, alpha, additive)
    local u = (count - 1) * 128 / 512
    local v = (index - 1) * 340 / 1024
    for side = -1, 1, 2 do
        local t = parent:CreateTexture(nil, "ARTWORK")
        t:SetTexture(ARC_TEXTURE, "CLAMP", "CLAMP", "LINEAR")
        local left, right = u, u + 128 / 512
        if side < 0 then left, right = right, left end
        t:SetTexCoord(left, right, v, v + 336 / 1024)
        t:SetSize(32, 84)
        t:SetPoint("TOPLEFT", parent, "TOPLEFT", side > 0 and 154 or W - 186, 3)
        t:SetVertexColor(color[1], color[2], color[3], alpha)
        if additive then t:SetBlendMode("ADD") end
    end
end

local function caption(parent, message, color, offset)
    local t = label(parent, message, 0, 0, 13, color)
    t:ClearAllPoints()
    t:SetPoint("TOP", parent, "TOP", 0, -(offset or 116))
    return t
end

local waitCues = {}

local function refreshWaitCues()
    for _, cue in ipairs(waitCues) do
        -- Pass the client-owned visibility directly to the native alpha setter.
        cue.hit:SetAlphaFromBoolean(cue.ready:IsVisible(), 0, 1)
    end
end

local function sealView(frame, active, nextSeal, count, color)
    local echo = seals[active].echo
    if not echo then
        arcSegment(frame, 1, 1, color, .4)
        caption(frame, active .. " (manual)", color)
        return
    end
    local waiting = CreateFrame("Frame", nil, frame)
    waiting:SetAllPoints()
    waiting:EnableMouse(false)
    local hit = caption(waiting, "HIT", BLUE, 78)
    local lamps = nativeContainer(waiting)
    for i = 1, count do
        arcSegment(waiting, i, count, EMPTY, .32)
        slot(lamps, "lamp" .. i, {echo}, function(f)
            local b = echoBar(f)
            arcSegment(b, i, count, color, 1)
            threshold(f, b, i)
        end)
    end
    lamps:SetEnabled(true)
    local c = nativeContainer(frame)
    -- Keep completed segments above the lamp container nested under waiting.
    c:SetFrameLevel(lamps:GetFrameLevel() + 2)
    slot(c, "alert", {echo}, function(f)
        local b = echoBar(f)
        local pulse = CreateFrame("Frame", nil, b, "RapiTwistArcPulseTemplate")
        pulse:SetAllPoints()
        pulse:EnableMouse(false)
        for i = 1, count do
            arcSegment(b, i, count, CORAL, 1)
            arcSegment(pulse, i, count, CORAL, .65, true)
        end
        caption(b, "SWAP", CORAL, 97)
        caption(b, nextSeal, CORAL)
        threshold(f, b, count)
        table.insert(waitCues, {hit = hit, ready = b})
    end)
    c:SetEnabled(true)
end

local function buildTracker()
    local c = nativeContainer(live)
    slot(c, "firstSeal", seals[db.firstSeal].ranks, function(f)
        sealView(f, db.firstSeal, db.secondSeal, db.firstCount, GOLD)
    end)
    slot(c, "secondSeal", seals[db.secondSeal].ranks, function(f)
        sealView(f, db.secondSeal, db.firstSeal, db.secondCount, BLUE)
    end)
    c:SetEnabled(true)
    live:SetScript("OnUpdate", refreshWaitCues)
end

local function position()
    root:ClearAllPoints()
    root:SetScale(db.scale)
    root:SetPoint("CENTER", UIParent, "CENTER", db.x / db.scale, db.y / db.scale)
end

local function refresh()
    root:SetShown(editing or (not db.hidden and (not db.combatOnly or InCombatLockdown())))
    live:SetShown(not editing and not nativeError)
    live:SetAlpha(db.alpha)
    handle:SetShown(editing)
    if refreshPanel then refreshPanel() end
end

local function finishMove()
    if dragging then
        root:StopMovingOrSizing()
        local x, y = root:GetCenter()
        local px, py = UIParent:GetCenter()
        if x and y then
            db.x, db.y = x * db.scale - px, y * db.scale - py
        end
        dragging = false
        position()
    end
    editing = false
    refresh()
end

local function beginMove()
    if InCombatLockdown() then say("Move the tracker after combat.") return end
    panel:Hide()
    editing = true
    refresh()
end

local function makeHud()
    root = CreateFrame("Frame", "RapiTwistFrame", UIParent)
    root:SetSize(W, H)
    root:SetFrameStrata("LOW")
    root:SetMovable(true)
    root:SetClampedToScreen(true)
    root:EnableMouse(false)
    position()
    live = CreateFrame("Frame", nil, root)
    live:SetAllPoints()
    live:EnableMouse(false)
    -- There is intentionally no idle backdrop. Only an actual seal paints a HUD.
    local ok, err = pcall(buildTracker)
    if not ok then
        nativeError = tostring(err)
        say("Aura tracking failed to load. Use /st debug for details.")
    end
    handle = CreateFrame("Button", nil, root)
    handle:SetAllPoints()
    arcSegment(handle, 1, 1, GOLD, .85)
    caption(handle, "Drag both arcs", LIGHT)
    handle:RegisterForDrag("LeftButton")
    handle:RegisterForClicks("RightButtonUp")
    handle:SetScript("OnDragStart", function()
        if editing and not InCombatLockdown() then
            root:StartMoving()
            dragging = true
        end
    end)
    handle:SetScript("OnDragStop", finishMove)
    handle:SetScript("OnClick", finishMove)
end

local function button(parent, text, x, y, w, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 24)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    b:SetText(text)
    b:SetScript("OnClick", callback)
    return b
end

local function setScale(value)
    db.scale = bounded(value, .6, 2)
    position()
end

local function makePanel()
    panel = CreateFrame("Frame", "RapiTwistOptions", UIParent)
    panel:SetSize(266, 369)
    panel:SetFrameStrata("DIALOG")
    panel:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -16)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    rect(panel, "BACKGROUND", 0, 0, 266, 369, INK, .98)
    label(panel, "RapiTwist", 15, 12, 18, GOLD)
    rect(panel, "BORDER", 15, 38, 236, 1, {.42, .34, .21})
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetScript("OnClick", function() panel:Hide() end)
    table.insert(UISpecialFrames, "RapiTwistOptions")

    local function stepper(title, y, change)
        label(panel, title, 16, y + 4, 13)
        local value = label(panel, "", 175, y + 4, 13)
        local function adjust(step)
            change(step)
            refresh()
        end
        button(panel, "-", 136, y, 28, function() adjust(-1) end)
        button(panel, "+", 223, y, 28, function() adjust(1) end)
        return value
    end
    local size = stepper("Size", 48, function(step) setScale(db.scale + .1 * step) end)
    local opacity = stepper("Opacity", 80, function(step) db.alpha = bounded(db.alpha + .1 * step, .4, 1) end)
    local combat = button(panel, "", 15, 117, 236, function()
        db.combatOnly = not db.combatOnly
        refresh()
    end)
    local visibility = button(panel, "", 15, 145, 236, function()
        db.hidden = not db.hidden
        refresh()
    end)
    local move = button(panel, "Move tracker", 15, 181, 143, beginMove)
    button(panel, "Reset position", 162, 181, 89, function()
        db.x, db.y = defaults.x, defaults.y
        position()
        refresh()
    end)
    local hint = label(panel, "", 16, 214, 11, GOLD)
    local draft = {}
    local function clearDraft()
        draft = {firstSeal = db.firstSeal, secondSeal = db.secondSeal,
            firstCount = db.firstCount, secondCount = db.secondCount}
    end
    clearDraft()
    panel:SetScript("OnHide", clearDraft)
    local function selector(title, key, other, countKey, y)
        label(panel, title, 15, y + 5, 12)
        local selectSeal = button(panel, "", 71, y, 111, function()
            if InCombatLockdown() then return end
            local index = 1
            while choices[index] ~= draft[key] do index = index + 1 end
            -- Selecting the other seal exchanges the two slots.
            local value = choices[index % #choices + 1]
            if value == draft[other] then draft[other] = draft[key] end
            draft[key] = value
            refresh()
        end)
        local stacks = button(panel, "", 185, y, 66, function()
            if InCombatLockdown() or not seals[draft[key]].echo then return end
            draft[countKey] = draft[countKey] % 3 + 1
            refresh()
        end)
        return function()
            selectSeal:SetText(draft[key])
            selectSeal:SetEnabled(not InCombatLockdown())
            local echo = seals[draft[key]].echo
            stacks:SetEnabled(echo ~= nil and not InCombatLockdown())
            stacks:SetText(echo and (draft[countKey] .. " / 3") or "Manual")
        end
    end
    rect(panel, "BORDER", 15, 238, 236, 1, {.42, .34, .21})
    label(panel, "Seal pair", 15, 245, 13, GOLD)
    label(panel, "Echo goal", 185, 245, 12, LIGHT)
    local firstRow = selector("First", "firstSeal", "secondSeal", "firstCount", 265)
    local secondRow = selector("Second", "secondSeal", "firstSeal", "secondCount", 295)
    local apply = button(panel, "Apply and reload UI", 15, 330, 236, function()
        if InCombatLockdown() then return end
        for key, value in pairs(draft) do db[key] = value end
        local reload = C_UI and C_UI.Reload or ReloadUI
        reload()
    end)
    refreshPanel = function()
        firstRow()
        secondRow()
        local changed = draft.firstSeal ~= db.firstSeal or draft.secondSeal ~= db.secondSeal
            or draft.firstCount ~= db.firstCount or draft.secondCount ~= db.secondCount
        apply:SetEnabled(changed and not InCombatLockdown())
        size:SetText(("%d%%"):format(math.floor(db.scale * 100 + .5)))
        opacity:SetText(("%d%%"):format(math.floor(db.alpha * 100 + .5)))
        combat:SetText(db.combatOnly and "Show in combat only" or "Show with an active seal")
        visibility:SetText(db.hidden and "Tracker hidden · Show" or "Tracker visible · Hide")
        move:SetEnabled(not InCombatLockdown())
        hint:SetText(InCombatLockdown() and "Move the tracker after combat." or "Drop the tracker to save its position.")
    end
    panel:Hide()
end

local function togglePanel()
    if editing then finishMove() end
    panel:SetShown(not panel:IsShown())
    refresh()
end

local function placeLauncher()
    local angle = math.rad(db.angle)
    launcher:ClearAllPoints()
    launcher:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * Minimap:GetWidth() / 2,
        math.sin(angle) * Minimap:GetHeight() / 2)
end

local function orbit()
    local x, y = GetCursorPosition()
    local cx, cy = Minimap:GetCenter()
    if not cx then return end
    local scale = Minimap:GetEffectiveScale()
    db.angle = math.deg(math.atan2(y / scale - cy, x / scale - cx))
    placeLauncher()
end

local function makeLauncher()
    launcher = CreateFrame("Button", "RapiTwistMinimapButton", Minimap)
    launcher:SetSize(32, 32)
    launcher:SetFrameStrata("MEDIUM")
    launcher:SetFrameLevel(Minimap:GetFrameLevel() + 12)
    local icon = launcher:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(iconPath(seals[db.firstSeal].ranks[1]))
    icon:SetSize(19, 19)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(.08, .92, .08, .92)
    local border = launcher:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", 0, 0)
    launcher:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    launcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    launcher:RegisterForDrag("LeftButton")
    local tip = CreateFrame("GameTooltip", "RapiTwistMinimapTip", UIParent, "GameTooltipTemplate")
    local wasDragged = false
    launcher:SetScript("OnMouseDown", function() wasDragged = false end)
    launcher:SetScript("OnDragStart", function(self)
        wasDragged = true
        tip:Hide()
        self:SetScript("OnUpdate", orbit)
    end)
    launcher:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    launcher:SetScript("OnClick", function(_, key)
        if wasDragged then return end
        tip:Hide()
        if key == "RightButton" then
            if editing then finishMove() else beginMove() end
        else
            togglePanel()
        end
    end)
    launcher:SetScript("OnEnter", function(self)
        tip:SetOwner(self, "ANCHOR_LEFT")
        tip:SetText("RapiTwist")
        tip:AddLine("Left-click for seals and appearance.", 1, .92, .78)
        tip:AddLine("Right-click to move the tracker.", 1, .92, .78)
        tip:AddLine("Drag to move this minimap button.", .78, .76, .73)
        tip:Show()
    end)
    launcher:SetScript("OnLeave", function() tip:Hide() end)
    placeLauncher()
    launcher:SetScript("OnShow", placeLauncher)
end

local function command(message)
    if not root then return end
    local cmd, arg = (message or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    if cmd == "desbloquear" or cmd == "unlock" then beginMove() return end
    if cmd == "fijar" or cmd == "lock" then finishMove() return end
    if cmd == "ocultar" or cmd == "hide" then db.hidden = true
    elseif cmd == "mostrar" or cmd == "show" then db.hidden = false
    elseif cmd == "combat" or cmd == "combate" then db.combatOnly = true
    elseif cmd == "always" or cmd == "siempre" then db.combatOnly, db.hidden = false, false
    elseif cmd == "escala" or cmd == "scale" then
        local s = tonumber(arg)
        if not s or not (s >= .6 and s <= 2) then say("Use /st scale 1.2 (range 0.6 to 2).") return end
        setScale(s)
    elseif cmd == "reset" then
        finishMove()
        for key, value in pairs(defaults) do db[key] = value end
        position()
        placeLauncher()
    elseif cmd == "diagnostico" or cmd == "debug" then
        say("1.6.3 · " .. (nativeError or "Native aura tracker available."))
    else togglePanel() return end
    refresh()
end

SLASH_RAPITWIST1 = "/st"
SLASH_RAPITWIST2 = "/rapitwist"
SLASH_RAPITWIST3 = "/sealtwist"
SlashCmdList.RAPITWIST = command
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= ADDON or root or select(2, UnitClass("player")) ~= "PALADIN" then return end
        loadSettings()
        makeHud()
        makePanel()
        makeLauncher()
        refresh()
    elseif root then
        if editing then finishMove() else refresh() end
    end
end)
