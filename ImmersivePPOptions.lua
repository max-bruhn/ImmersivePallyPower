--[[
 Immersive PallyPower - options panel
 A small modern-styled settings window for the immersive/layout/theme
 features. The original PallyPower options are still available from
 PallyPower's own Options button. Open this with /ipp config.
--]]

ImmersivePallyPowerDB = ImmersivePallyPowerDB or {}
local db = ImmersivePallyPowerDB

local panel, themeButtons

local function Flat(f, r, g, b, a)
    f:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false,
        edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 1,
        insets = { left = -1, right = -1, top = -1, bottom = -1 },
    })
    f:SetBackdropColor(r, g, b, a)
    f:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
end

local function Apply()
    if PallyPower_UpdateUI then PallyPower_UpdateUI() end
end

local function Btn(parent, w, text, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(w); b:SetHeight(18)
    Flat(b, 0.14, 0.14, 0.14, 0.9)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetAllPoints(b); fs:SetText(text)
    b.label = fs
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function() if not this.active then this:SetBackdropColor(0.22, 0.22, 0.22, 0.9) end end)
    b:SetScript("OnLeave", function() if not this.active then this:SetBackdropColor(0.14, 0.14, 0.14, 0.9) end end)
    return b
end

local function Check(parent, label, x, y, get, set)
    local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    c:SetWidth(22); c:SetHeight(22)
    c:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local t = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetPoint("LEFT", c, "RIGHT", 2, 0)
    t:SetText(label)
    c:SetChecked(get() and 1 or nil)
    c:SetScript("OnClick", function() set(this:GetChecked() and true or false); Apply() end)
    return c
end

local function Slider(parent, name, label, x, y, lo, hi, step, get, set)
    local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    s:SetWidth(180); s:SetHeight(16)
    s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    s:SetMinMaxValues(lo, hi); s:SetValueStep(step)
    getglobal(name .. "Low"):SetText(""); getglobal(name .. "High"):SetText("")
    getglobal(name .. "Text"):SetText(label)
    local val = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    val:SetPoint("LEFT", s, "RIGHT", 8, 0)
    -- clean display: integers for whole-number steps, else 2 decimals
    local function fmt(v)
        if step >= 1 then return tostring(math.floor(v + 0.5)) end
        return string.format("%.2f", v)
    end
    s:SetValue(get())
    val:SetText(fmt(get()))
    s:SetScript("OnValueChanged", function()
        local v = this:GetValue()
        if step >= 1 then
            v = math.floor(v + 0.5)
        else
            v = math.floor(v * 100 + 0.5) / 100   -- round stored value to 2dp
        end
        set(v); val:SetText(fmt(v)); Apply()
    end)
    return s
end

local function RefreshThemeButtons()
    if not themeButtons then return end
    local cur = ImmersivePallyPower_CurrentStyle and ImmersivePallyPower_CurrentStyle() or "modern"
    for key, b in pairs(themeButtons) do
        local active = (key == cur)
        b.active = active
        b:SetBackdropColor(active and 0.28 or 0.14, active and 0.28 or 0.14, active and 0.28 or 0.14, 0.9)
        b:SetBackdropBorderColor(active and 0.6 or 0.25, active and 0.9 or 0.25, active and 0.8 or 0.25, 1)
        b.label:SetText((active and "|cff33ffcc" or "|cffffffff") .. b.styleName .. "|r")
    end
end

-- reparent a PallyPower checkbox into our panel with our own label
local function HostCheck(name, label, x, y)
    local c = getglobal(name)
    if not c then return end
    c:SetParent(panel)
    c:ClearAllPoints()
    c:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    c:SetWidth(22); c:SetHeight(22)
    c:Show()
    if not c.idcLabel then
        local t = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("LEFT", c, "RIGHT", 2, 0)
        c.idcLabel = t
    end
    c.idcLabel:SetText(label)
    c.idcLabel:Show()
end

local function Build()
    db = ImmersivePallyPowerDB   -- rebind to the saved table (see ImmersivePP.lua)
    panel = CreateFrame("Frame", "ImmersivePPOptions", UIParent)
    panel:SetWidth(340); panel:SetHeight(456)
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    panel:SetFrameStrata("DIALOG")
    Flat(panel, 0.06, 0.06, 0.06, 0.95)
    panel:SetMovable(true); panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function() this:StartMoving() end)
    panel:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    panel:Hide()

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", panel, "TOP", 0, -8)
    title:SetText("|cff33ffccImmersive PallyPower|r")

    local close = Btn(panel, 18, "x", function() panel:Hide() end)
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6, -6)

    Check(panel, "Immersive (hide bar until a buff is missing)", 14, -34,
        function() return db.immersive end, function(v) db.immersive = v end)
    Check(panel, "Show only buttons with someone missing", 14, -58,
        function() return db.onlyMissing end, function(v) db.onlyMissing = v end)
    Check(panel, "Grow downward", 14, -82,
        function() return db.growDown end, function(v) db.growDown = v end)

    Slider(panel, "ImmersivePPCols", "Columns (1 = vertical)", 20, -116, 1, 10, 1,
        function() return db.columns end, function(v) db.columns = v end)
    Slider(panel, "ImmersivePPScale", "Size", 20, -150, 0.5, 2.0, 0.1,
        function() return db.scale end, function(v) db.scale = v end)
    Slider(panel, "ImmersivePPSpacing", "Spacing", 20, -184, 0, 12, 1,
        function() return db.spacing end, function(v) db.spacing = v end)
    Slider(panel, "ImmersivePPAlpha", "Background opacity", 20, -218, 0, 1.0, 0.05,
        function() return db.barAlpha end,
        function(v) db.barAlpha = v; if ImmersivePallyPower_ApplyBarAlpha then ImmersivePallyPower_ApplyBarAlpha() end end)

    -- PallyPower's own options, merged in (reparented from its options frame)
    local ppLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ppLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -248)
    ppLabel:SetText("|cffffd200PallyPower|r")
    HostCheck("PallyPower_OptionsFrameSmart",    "Smart buffs (auto-pick best blessing)", 14, -266)
    HostCheck("PallyPower_OptionsFrameFeedback", "Chat feedback on cast",                 14, -288)
    HostCheck("FiveMinBlessingChk",              "Normal blessings only (10 min, no Greater)", 14, -310)

    local themeLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    themeLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -340)
    themeLabel:SetText("|cffffd200Theme|r")

    themeButtons = {}
    local defs = { { "modern", "Modern", 0 }, { "classic", "Classic", 76 } }
    for i = 1, table.getn(defs) do
        local key, lbl, off = defs[i][1], defs[i][2], defs[i][3]
        local b = Btn(panel, 70, lbl, function()
            if ImmersivePallyPower_SetTheme then ImmersivePallyPower_SetTheme(key) end
        end)
        b:SetPoint("TOPLEFT", themeLabel, "BOTTOMLEFT", off, -6)
        b.styleName = lbl
        themeButtons[key] = b
    end

    local demoBtn = Btn(panel, 150, "Demo (test layout)", function()
        local on = ImmersivePallyPower_ToggleDemo and ImmersivePallyPower_ToggleDemo()
        this.label:SetText(on and "|cff33ffccStop demo|r" or "Demo (test layout)")
    end)
    demoBtn:SetPoint("TOPLEFT", themeLabel, "BOTTOMLEFT", 0, -34)

    local note = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 14, 20)
    note:SetText("|cff888888Open any time with /ipp config|r")

    local ver = GetAddOnMetadata and GetAddOnMetadata("ImmersivePallyPower", "Version")
    local verText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    verText:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 8)
    verText:SetText("|cff555555v" .. (ver or "0.1.0") .. "|r")

    RefreshThemeButtons()
end

function ImmersivePallyPower_OpenOptions()
    if not panel then return end
    if panel:IsVisible() then panel:Hide() else RefreshThemeButtons(); panel:Show() end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:SetScript("OnEvent", function()
    if event ~= "VARIABLES_LOADED" then return end
    local delay, waited = CreateFrame("Frame"), 0
    delay:SetScript("OnUpdate", function()
        waited = waited + arg1
        if waited < 0.35 then return end
        delay:SetScript("OnUpdate", nil)
        pcall(Build)
        -- PallyPower's Options button now opens our merged panel
        PallyPower_Options = ImmersivePallyPower_OpenOptions
    end)
end)
