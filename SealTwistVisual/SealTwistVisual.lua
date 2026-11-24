-- SealTwist Visual • WoW Forever
local ADDON = ...
local W, H = 176, 38
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local COMMAND = {20375, 20915, 20918, 20919, 20920}
local RIGHT = {21084, 20287, 20288, 20289, 20290, 20291, 20292, 20293}
local COMMAND_ECHO, RIGHT_ECHO = 1311703, 1311704
local GOLD, BLUE, INK, LIGHT = {1, .79, .40}, {.58, .85, 1}, {.048, .044, .052}, {1, .97, .89}
local defaults = {x = 190, y = -160, scale = 1, alpha = 1, angle = 220, combatOnly = false, hidden = false}
local db, root, live, handle, panel, launcher, refreshPanel, nativeError
local editing, dragging = false, false

local function bounded(value, lo, hi)
    return math.max(lo, math.min(value, hi))
end

local function say(message)
    print("|cffffca70SealTwist|r " .. message)
end

local function loadSettings()
    db = type(SealTwistVisualDB) == "table" and SealTwistVisualDB or {}
    -- Only relocate the old factory anchor. A manually placed HUD keeps its position.
    if not db.layoutVersion and db.x == 0 and db.y == -150 then
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
    db.locked = nil
    db.layoutVersion = 2
    SealTwistVisualDB = db
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

local function bar(parent, x, y, w, h, color)
    local b = CreateFrame("StatusBar", nil, parent)
    b:SetSize(w, h)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    b:SetStatusBarTexture(WHITE)
    b:SetStatusBarColor(unpack(color))
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
        -- The native bar also gates the visibility of any text attached to it.
        frame:SetApplicationBar(b, {minApplications = count - .001, maxApplications = count})
    end
end

local function sealView(frame, isCommand)
    local color = isCommand and GOLD or BLUE
    local echo = isCommand and COMMAND_ECHO or RIGHT_ECHO
    local count = isCommand and 3 or 1
    rect(frame, "BACKGROUND", 0, 0, W, H, INK, .93)
    rect(frame, "BORDER", 4, 4, 28, 28, color, .80)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 5, -5)
    icon:SetSize(26, 26)
    icon:SetTexCoord(.08, .92, .08, .92)
    icon:SetTexture(iconPath(isCommand and COMMAND[1] or RIGHT[1]))
    label(frame, isCommand and "Orden" or "Rectitud", 39, 4, 15, color)

    local c = nativeContainer(frame)
    local pipWidth = isCommand and 41 or 131
    for i = 1, count do
        local x = 39 + (i - 1) * 45
        rect(frame, "ARTWORK", x, 25, pipWidth, 5, {.29, .27, .27})
        slot(c, "lamp" .. i, {echo}, function(f)
            threshold(f, bar(f, x, 25, pipWidth, 5, color), i)
        end)
    end
    local pendingCount = isCommand and 1 or 3
    for i = 1, pendingCount do
        local x = 5 + (i - 1) * 9
        slot(c, "pending" .. i, {isCommand and RIGHT_ECHO or COMMAND_ECHO}, function(f)
            threshold(f, bar(f, x, 33, 7, 2, isCommand and BLUE or GOLD), i)
        end)
    end
    slot(c, "duration", {echo}, function(f)
        f:SetDurationBar(bar(f, 39, 33, 131, 1, color))
    end)
    slot(c, "alert", {echo}, function(f)
        local target = isCommand and BLUE or GOLD
        local b = bar(f, 36, 2, 138, 20, target)
        threshold(f, b, count)
        local text = b:CreateFontString(nil, "OVERLAY")
        text:SetFont(FONT, 13)
        text:SetPoint("CENTER")
        text:SetTextColor(.08, .06, .04)
        text:SetText(isCommand and "Cambiá a Rectitud" or "Volvé a Orden")
    end)
    c:SetEnabled(true)
end

local function buildTracker()
    local c = nativeContainer(live)
    slot(c, "commandSeal", COMMAND, function(f) sealView(f, true) end)
    slot(c, "rightSeal", RIGHT, function(f) sealView(f, false) end)
    c:SetEnabled(true)
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
    if InCombatLockdown() then say("Podés mover el indicador al salir de combate.") return end
    panel:Hide()
    editing = true
    refresh()
end

local function makeHud()
    root = CreateFrame("Frame", "SealTwistVisualFrame", UIParent)
    root:SetSize(W, H)
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
        say("No se pudo cargar el visor de auras. Consultá /st diagnostico.")
    end
    handle = CreateFrame("Button", nil, root)
    handle:SetAllPoints()
    rect(handle, "BACKGROUND", 0, 0, W, H, INK, .96)
    for i = 1, 3 do rect(handle, "ARTWORK", 9 + i * 3, 12, 1, 14, GOLD) end
    label(handle, "Arrastrá el indicador", 30, 10, 13)
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
    panel = CreateFrame("Frame", "SealTwistVisualOptions", UIParent)
    panel:SetSize(266, 240)
    panel:SetFrameStrata("DIALOG")
    panel:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -16)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    rect(panel, "BACKGROUND", 0, 0, 266, 240, INK, .98)
    label(panel, "Seal Twist", 15, 12, 18, GOLD)
    rect(panel, "BORDER", 15, 38, 236, 1, {.42, .34, .21})
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetScript("OnClick", function() panel:Hide() end)
    table.insert(UISpecialFrames, "SealTwistVisualOptions")

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
    local size = stepper("Tamaño", 48, function(step) setScale(db.scale + .1 * step) end)
    local opacity = stepper("Opacidad", 80, function(step) db.alpha = bounded(db.alpha + .1 * step, .4, 1) end)
    local combat = button(panel, "", 15, 117, 236, function()
        db.combatOnly = not db.combatOnly
        refresh()
    end)
    local visibility = button(panel, "", 15, 145, 236, function()
        db.hidden = not db.hidden
        refresh()
    end)
    local move = button(panel, "Mover indicador", 15, 181, 143, beginMove)
    button(panel, "Reubicar", 162, 181, 89, function()
        db.x, db.y = defaults.x, defaults.y
        position()
        refresh()
    end)
    local hint = label(panel, "", 16, 214, 11, GOLD)
    refreshPanel = function()
        size:SetText(("%d%%"):format(math.floor(db.scale * 100 + .5)))
        opacity:SetText(("%d%%"):format(math.floor(db.alpha * 100 + .5)))
        combat:SetText(db.combatOnly and "Cuándo mostrar · Solo en combate" or "Cuándo mostrar · Con sello activo")
        visibility:SetText(db.hidden and "Indicador oculto · Mostrar" or "Indicador visible · Ocultar")
        move:SetEnabled(not InCombatLockdown())
        hint:SetText(InCombatLockdown() and "Podés moverlo al salir de combate." or "Soltá el indicador para fijarlo.")
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
    launcher = CreateFrame("Button", "SealTwistVisualMinimapButton", Minimap)
    launcher:SetSize(32, 32)
    launcher:SetFrameStrata("MEDIUM")
    launcher:SetFrameLevel(Minimap:GetFrameLevel() + 12)
    local icon = launcher:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(iconPath(COMMAND[1]))
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
    local wasDragged = false
    launcher:SetScript("OnMouseDown", function() wasDragged = false end)
    launcher:SetScript("OnDragStart", function(self)
        wasDragged = true
        GameTooltip:Hide()
        self:SetScript("OnUpdate", orbit)
    end)
    launcher:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    launcher:SetScript("OnClick", function(_, key)
        if wasDragged then return end
        GameTooltip:Hide()
        if key == "RightButton" then
            if editing then finishMove() else beginMove() end
        else
            togglePanel()
        end
    end)
    launcher:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Seal Twist")
        GameTooltip:AddLine("Clic izquierdo para ajustar la apariencia.", 1, .92, .78)
        GameTooltip:AddLine("Clic derecho para mover el indicador.", 1, .92, .78)
        GameTooltip:AddLine("Arrastrá el ícono por el borde del minimapa.", .78, .76, .73)
        GameTooltip:Show()
    end)
    launcher:SetScript("OnLeave", function() GameTooltip:Hide() end)
    placeLauncher()
    Minimap:HookScript("OnSizeChanged", placeLauncher)
end

local function command(message)
    if not root then return end
    local cmd, arg = (message or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    if cmd == "desbloquear" or cmd == "unlock" then beginMove() return end
    if cmd == "fijar" or cmd == "lock" then finishMove() return end
    if cmd == "ocultar" or cmd == "hide" then db.hidden = true
    elseif cmd == "mostrar" or cmd == "show" then db.hidden = false
    elseif cmd == "combate" then db.combatOnly = true
    elseif cmd == "siempre" then db.combatOnly, db.hidden = false, false
    elseif cmd == "escala" or cmd == "scale" then
        local s = tonumber(arg)
        if not s or not (s >= .6 and s <= 2) then say("Usá /st escala 1.2 (entre 0.6 y 2).") return end
        setScale(s)
    elseif cmd == "reset" then
        finishMove()
        for key, value in pairs(defaults) do db[key] = value end
        position()
        placeLauncher()
    elseif cmd == "diagnostico" or cmd == "debug" then
        say("1.1.0 · " .. (nativeError or "Visor nativo disponible."))
    else togglePanel() return end
    refresh()
end

SLASH_SEALTWISTVISUAL1 = "/st"
SLASH_SEALTWISTVISUAL2 = "/sealtwist"
SlashCmdList.SEALTWISTVISUAL = command
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
