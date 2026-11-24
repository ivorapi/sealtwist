-- SealTwist Visual - Forever 16001.
-- No aura reads, combat-log estimates, hidden frame inspection, or secret-value
-- comparisons. Blizzard owns aura matching, thresholds, durations and visibility.
local ADDON = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local W, H = 324, 148
local GOLD, BLUE, GREEN = {1, .77, .30}, {.40, .79, 1}, {.55, 1, .72}
local COMMAND_ECHO, RIGHT_ECHO = 1311703, 1311704
local COMMAND_IDS = {20375, 20915, 20918, 20919, 20920}
local RIGHT_IDS = {21084, 20287, 20288, 20289, 20290, 20291, 20292, 20293}
local defaults = {x = 0, y = -150, scale = 1, locked = true, combatOnly = false, hidden = false}
local root, live, demo, db
local nativeReady, demoStep, refreshDemo = false, nil, nil
local failure

local function Say(text)
    print("|cffffc64dSealTwist|r " .. text)
end

local function Color(region, color, alpha)
    region:SetColorTexture(color[1], color[2], color[3], alpha or 1)
end

local function Text(parent, value, size, x, y, color)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont(FONT, size, "OUTLINE")
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    text:SetText(value)
    text:SetTextColor(unpack(color or {1, .96, .86}))
    return text
end

local function Backdrop(parent)
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(.035, .043, .058, .97)
    local top = parent:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", 0, 0)
    top:SetHeight(1)
    top:SetColorTexture(.45, .42, .33, 1)
end

local function Bar(parent, x, y, width, height, color)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width, height)
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    bar:SetStatusBarTexture(WHITE)
    bar:SetStatusBarColor(unpack(color))
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    return bar
end

local function Icon(parent, spellID)
    local texture = parent:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", 16, -18)
    texture:SetSize(48, 48)
    local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
    texture:SetTexture(icon or "Interface\\Icons\\Spell_Holy_SealOfMight")
    texture:SetTexCoord(.07, .93, .07, .93)
    return texture
end

-- The same drawing functions are used by live aura slots and the labelled demo.
local function DrawView(frame, kind)
    frame:SetSize(W, H)
    Backdrop(frame)
    local command = kind == "command"
    local color = command and GOLD or BLUE
    Icon(frame, command and COMMAND_IDS[1] or RIGHT_IDS[1])
    Text(frame, command and "ORDEN" or "RECTITUD", 21, 80, -16, color)
    Text(frame, command and "Juntá 3 ecos" or "Descargá con un autoataque", 12, 80, -41)
    local count = command and 3 or 1
    for i = 1, count do
        local bg = frame:CreateTexture(nil, "ARTWORK")
        bg:SetPoint("TOPLEFT", 80 + (i - 1) * 70, -65)
        bg:SetSize(command and 62 or 202, 13)
        bg:SetColorTexture(.16, .18, .21, 1)
    end
    Text(frame, command and "ACUMULÁ ECOS" or "ESPERÁ EL AUTOATAQUE", 15, 16, -98)
    Text(frame, command and "Rectitud guardada" or "Orden por descargar", 10, 16, -127, {.72, .79, .88})
    for i = 1, 3 do
        local bg = frame:CreateTexture(nil, "ARTWORK")
        bg:SetPoint("TOPLEFT", 180 + (i - 1) * 17, -130)
        bg:SetSize(12, 7)
        bg:SetColorTexture(.16, .18, .21, 1)
    end
end

local function DrawLamp(frame, index, command, pending)
    local x = pending and (180 + (index - 1) * 17) or (80 + (index - 1) * 70)
    local y = pending and -130 or -65
    return Bar(frame, x, y, pending and 12 or (command and 62 or 202), pending and 7 or 13,
        command and GOLD or BLUE)
end

local function DrawAlert(frame, command)
    local bar = Bar(frame, 10, -91, W - 20, 30, command and GOLD or GREEN)
    local text = Text(bar, command and "CAMBIÁ A RECTITUD" or "VOLVÉ A ORDEN", 16, 0, 0, {.04, .05, .065})
    text:ClearAllPoints()
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    return bar
end

local function Map(ids)
    local result = {}
    for _, id in ipairs(ids) do result[id] = true end
    return result
end

local function NewContainer(parent)
    local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
    container:SetSize(W, H)
    container:SetPoint("TOPLEFT")
    container:SetUnit("player")
    return container
end

local function Slot(container, key, ids, initialize)
    return container:AddAuraSlot(key, "HELPFUL", {
        candidateFilters = {includeSpellIDs = Map(ids)},
        initializeFrame = function(frame)
            -- Called before Blizzard seals access to this frame. No references to
            -- aura-owned regions are retained or inspected after initialization.
            frame:SetSize(W, H)
            frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
            frame:EnableMouse(false)
            initialize(frame)
        end,
    })
end

local function BindLamp(container, key, echoID, index, command, pending)
    Slot(container, key, {echoID}, function(frame)
        local lamp = DrawLamp(frame, index, command, pending)
        -- A tiny range yields one completely filled lamp at its integer threshold.
        -- The engine owns both the value AND the shown state, even in combat.
        frame:SetApplicationBar(lamp, {minApplications = index - .001, maxApplications = index})
    end)
end

local function BuildNativeView(frame, kind)
    DrawView(frame, kind)
    local command = kind == "command"
    local primaryID = command and COMMAND_ECHO or RIGHT_ECHO
    local pendingID = command and RIGHT_ECHO or COMMAND_ECHO
    local container = NewContainer(frame)
    for i = 1, (command and 3 or 1) do
        BindLamp(container, "lamp" .. i, primaryID, i, command, false)
    end
    for i = 1, 3 do
        BindLamp(container, "pending" .. i, pendingID, i, not command, true)
    end
    Slot(container, "alert", {primaryID}, function(auraFrame)
        local alert = DrawAlert(auraFrame, command)
        local threshold = command and 3 or 1
        auraFrame:SetApplicationBar(alert, {minApplications = threshold - .001, maxApplications = threshold})
    end)
    Slot(container, "duration", {primaryID}, function(auraFrame)
        local bar = Bar(auraFrame, 80, -83, 202, 3, command and GOLD or BLUE)
        auraFrame:SetDurationBar(bar)
    end)
    container:SetEnabled(true)
end

local function BuildNative()
    local container = NewContainer(live)
    Slot(container, "commandSeal", COMMAND_IDS, function(frame) BuildNativeView(frame, "command") end)
    Slot(container, "rightSeal", RIGHT_IDS, function(frame) BuildNativeView(frame, "right") end)
    container:SetEnabled(true)
end

local function BuildDemo()
    local steps = {
        {"command", 0, 0}, {"command", 1, 0}, {"command", 2, 0}, {"command", 3, 0},
        {"right", 0, 3}, {"right", 1, 0}, {"command", 1, 0},
    }
    local views = {}
    for _, kind in ipairs({"command", "right"}) do
        local view = CreateFrame("Frame", nil, demo)
        view:SetAllPoints()
        DrawView(view, kind)
        local command = kind == "command"
        local lamps, pending = {}, {}
        for i = 1, (command and 3 or 1) do lamps[i] = DrawLamp(view, i, command, false) end
        for i = 1, 3 do pending[i] = DrawLamp(view, i, not command, true) end
        views[kind] = {frame = view, lamps = lamps, pending = pending, alert = DrawAlert(view, command)}
    end
    local tag = Text(demo, "DEMO · clic para avanzar", 11, 16, 20, GOLD)
    tag:SetDrawLayer("OVERLAY", 7)
    refreshDemo = function()
        local step = steps[demoStep or 1]
        for kind, view in pairs(views) do
            view.frame:SetShown(kind == step[1])
            for i, lamp in ipairs(view.lamps) do lamp:SetValue(1); lamp:SetShown(i <= step[2]) end
            for i, lamp in ipairs(view.pending) do lamp:SetValue(1); lamp:SetShown(i <= step[3]) end
            view.alert:SetValue(1)
            view.alert:SetShown(step[2] >= (kind == "command" and 3 or 1))
        end
    end
    demo:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then demoStep = (demoStep or 1) % #steps + 1; refreshDemo() end
    end)
    demo:EnableMouse(true)
end

local function ApplyVisibility()
    local _, class = UnitClass("player")
    local visible = class == "PALADIN" and not db.hidden
    if demoStep then visible = true end
    if db.combatOnly and not InCombatLockdown() and db.locked and not demoStep then visible = false end
    root:SetShown(visible)
    live:SetShown(not demoStep)
    demo:SetShown(demoStep ~= nil)
    root:EnableMouse(not db.locked)
end

local function Position()
    root:ClearAllPoints()
    root:SetScale(db.scale)
    root:SetPoint("CENTER", UIParent, "CENTER", db.x / db.scale, db.y / db.scale)
end

local function Init()
    if root then return end
    SealTwistVisualDB = type(SealTwistVisualDB) == "table" and SealTwistVisualDB or {}
    db = SealTwistVisualDB
    for key, value in pairs(defaults) do if db[key] == nil then db[key] = value end end
    for _, key in ipairs({"x", "y", "scale"}) do
        if type(db[key]) ~= "number" or db[key] ~= db[key] then db[key] = defaults[key] end
    end
    db.scale = math.max(.6, math.min(2, db.scale))
    root = CreateFrame("Frame", "SealTwistVisualFrame", UIParent)
    root:SetSize(W, H)
    root:SetFrameStrata("MEDIUM")
    root:SetClampedToScreen(true)
    root:SetMovable(true)
    root:RegisterForDrag("LeftButton")
    root:SetScript("OnDragStart", function(self)
        if not db.locked and not InCombatLockdown() then self:StartMoving() end
    end)
    root:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = self:GetCenter()
        local ux, uy = UIParent:GetCenter()
        -- Store offsets in UIParent units, independent of the widget scale.
        db.x = cx * db.scale - ux
        db.y = cy * db.scale - uy
        Position()
    end)
    Position()
    live = CreateFrame("Frame", nil, root); live:SetAllPoints()
    Backdrop(live)
    Text(live, "SEAL TWIST", 19, 16, -19, GOLD)
    Text(live, "Activá Orden o Rectitud", 15, 16, -55)
    Text(live, "3 ecos de Orden · 1 golpe con Rectitud", 11, 16, -88)
    Text(live, "/st demo para probar el indicador", 10, 16, -123, {.72, .79, .88})
    local ok, err = pcall(BuildNative)
    nativeReady = ok
    if not ok then
        failure = tostring(err)
        -- Do not render a false hit counter if the client lacks the native API.
        for _, child in ipairs({live:GetChildren()}) do child:Hide() end
        Text(live, "API DE AURAS NO DISPONIBLE", 13, 16, -108, {1, .5, .45})
        Say("No se pudo iniciar el visor de auras. /st diagnostico para ver el error.")
    end
    demo = CreateFrame("Frame", nil, root); demo:SetAllPoints()
    BuildDemo()
    ApplyVisibility()
    Say("Cargado. /st demo para verlo; /st desbloquear para moverlo.")
end

local function Command(message)
    if not root then return end
    local cmd, arg = (message or ""):match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    if cmd == "demo" or cmd == "test" then
        if InCombatLockdown() then Say("Salí de combate para usar la demo."); return end
        if demoStep then demoStep = nil else demoStep = 1 end
        if demoStep then refreshDemo() end
        Say(demoStep and "DEMO: clic sobre el panel para avanzar; /st demo para salir." or "Seguimiento real activado.")
    elseif cmd == "desbloquear" or cmd == "unlock" then
        db.locked = false; Say("Arrastrá el panel. /st fijar para bloquearlo.")
    elseif cmd == "fijar" or cmd == "lock" then
        db.locked = true
    elseif cmd == "escala" or cmd == "scale" then
        local scale = tonumber(arg)
        if not scale or scale ~= scale or scale < .6 or scale > 2 then Say("Usá /st escala 1.2 (de 0.6 a 2)."); return end
        if InCombatLockdown() then Say("Cambiá la escala fuera de combate."); return end
        db.scale = scale; Position()
    elseif cmd == "combate" then
        db.combatOnly = true; Say("Se muestra en combate. Desbloqueado o en demo también se ve fuera de combate.")
    elseif cmd == "siempre" then
        db.combatOnly = false; db.hidden = false
    elseif cmd == "ocultar" or cmd == "hide" then
        db.hidden = true; demoStep = nil
    elseif cmd == "mostrar" or cmd == "show" then
        db.hidden = false
    elseif cmd == "reset" then
        if InCombatLockdown() then Say("Restablecé el panel fuera de combate."); return end
        for key, value in pairs(defaults) do db[key] = value end
        demoStep = nil; Position()
    elseif cmd == "diagnostico" or cmd == "debug" then
        Say("Versión 1.0.0 | Interfaz " .. tostring(select(4, GetBuildInfo())) .. " | visor nativo: " .. tostring(nativeReady))
        if failure then Say(failure) end
        Say("Ecos: Orden " .. COMMAND_ECHO .. ", Rectitud " .. RIGHT_ECHO .. ". No se estiman golpes.")
    else
        Say("/st demo · /st desbloquear · /st fijar · /st escala 1.2 · /st combate · /st siempre · /st ocultar · /st mostrar · /st reset · /st diagnostico")
    end
    ApplyVisibility()
end

SLASH_SEALTWISTVISUAL1 = "/st"
SLASH_SEALTWISTVISUAL2 = "/sealtwist"
SlashCmdList.SEALTWISTVISUAL = Command
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == ADDON then
        Init()
    elseif root and event == "PLAYER_REGEN_DISABLED" then
        -- A demo must never masquerade as live tracking when a fight begins.
        demoStep = nil; ApplyVisibility()
    elseif root and event == "PLAYER_REGEN_ENABLED" then
        ApplyVisibility()
    end
end)
