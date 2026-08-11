--[[
 Immersive PallyPower - immersive visibility + layout layer
 A continuation of Relar's Turtle-WoW PallyPower (original PallyPower by
 Aznamir). This layer adds, without touching the original logic:
   * "only missing" mode - buff buttons show only when someone actually
     needs that blessing; the whole bar hides when everyone is buffed
   * configurable layout - grow vertical/horizontal, columns (rows), size
 Options: /ipp
--]]

ImmersivePallyPowerDB = ImmersivePallyPowerDB or {}
local db = ImmersivePallyPowerDB

local function Default(k, v) if db[k] == nil then db[k] = v end end
local function InitDefaults()
    Default("immersive", true)     -- hide the bar entirely when nobody needs a buff
    Default("onlyMissing", true)   -- show only buttons with someone missing
    Default("columns", 1)          -- buttons per row (1 = vertical stack)
    Default("scale", 1.0)          -- extra size multiplier on the bar
    Default("spacing", 2)          -- gap between buttons (px)
    Default("growDown", true)      -- grid grows downward (else upward)
end

local BUTTON_W, BUTTON_H = 100, 34
local TITLE_H = 25
local PAD = 5

local fade = { a = 1, target = 1, from = 1, start = 0, dur = 0 }
local FADE_IN, FADE_OUT = 0.15, 0.6
local ticker

local function Bar() return getglobal("PallyPowerBuffBar") end

local function VisibleButtons()
    local out = {}
    for i = 1, 10 do
        local b = getglobal("PallyPowerBuffBarBuff" .. i)
        if b and b:IsShown() then table.insert(out, b) end
    end
    return out
end

local function NeedsCount(btn)
    if btn.need then return table.getn(btn.need) end
    return 0
end

local function HaveCount(btn)
    if btn.have then return table.getn(btn.have) end
    return 0
end

-- In the modern theme, crop the built-in icon border (~8%) so the class and
-- buff icons read as clean edge-to-edge rectangles instead of the default
-- rounded/beveled look. Cropping keeps sharpness (no downscaling).
local ICON_CROP = 0.08
local function CropIcons(btn)
    if ImmersivePallyPower_CurrentStyle and ImmersivePallyPower_CurrentStyle() ~= "modern" then
        return
    end
    local name = btn:GetName()
    if not name then return end
    local lo, hi = ICON_CROP, 1 - ICON_CROP
    local ci = getglobal(name .. "ClassIcon")
    local bi = getglobal(name .. "BuffIcon")
    if ci and ci.SetTexCoord then ci:SetTexCoord(lo, hi, lo, hi) end
    if bi and bi.SetTexCoord then bi:SetTexCoord(lo, hi, lo, hi) end
end

-- Crop the assignment-frame icons (skill icons + class-assignment icons) the
-- same way, so the raid-lead grid gets clean rectangular icons in modern.
local function CropAssignmentIcons()
    if ImmersivePallyPower_CurrentStyle and ImmersivePallyPower_CurrentStyle() ~= "modern" then
        return
    end
    local lo, hi = ICON_CROP, 1 - ICON_CROP
    for i = 1, 12 do
        local row = getglobal("PallyPowerFramePlayer" .. i)
        if row and row:IsShown() then
            for id = 0, 5 do
                local ic = getglobal("PallyPowerFramePlayer" .. i .. "Icon" .. id)
                if ic and ic.SetTexCoord then ic:SetTexCoord(lo, hi, lo, hi) end
            end
            for id = 0, 9 do
                local ci = getglobal("PallyPowerFramePlayer" .. i .. "Class" .. id .. "Icon")
                if ci and ci.SetTexCoord then ci:SetTexCoord(lo, hi, lo, hi) end
            end
        end
    end
end

-- In the modern theme the buttons have no coloured box, so convey status on
-- the count text: red = nobody buffed, yellow = some still missing.
local function ColorStatusText(btn)
    if ImmersivePallyPower_CurrentStyle and ImmersivePallyPower_CurrentStyle() ~= "modern" then
        return
    end
    local name = btn:GetName()
    local txt = name and getglobal(name .. "Text")
    if not txt then return end
    if HaveCount(btn) == 0 then
        txt:SetTextColor(1, 0.25, 0.25)   -- nobody has it
    else
        txt:SetTextColor(1, 0.9, 0.4)     -- some missing
    end
end

-- re-lay-out the buttons PallyPower just populated: optionally drop the
-- fully-buffed ones, arrange the rest in a grid, resize the bar
local function Relayout()
    local bar = Bar()
    if not bar or not bar:IsShown() then return end

    local btns = VisibleButtons()
    local shown = {}
    for i = 1, table.getn(btns) do
        local b = btns[i]
        if db.onlyMissing and NeedsCount(b) == 0 then
            b:Hide()
        else
            table.insert(shown, b)
        end
    end

    local cols = db.columns
    if cols < 1 then cols = 1 end
    local n = table.getn(shown)
    if n == 0 then
        -- nothing needs casting; immersive mode fades the whole bar out
        bar:SetWidth(BUTTON_W + PAD * 2)
        bar:SetHeight(TITLE_H + 8)
        return
    end

    local rowH = BUTTON_H + db.spacing
    local colW = BUTTON_W + db.spacing
    for i = 1, n do
        local b = shown[i]
        local col = math.mod(i - 1, cols)
        local row = math.floor((i - 1) / cols)
        local x = PAD + col * colW
        local y = -(TITLE_H) - row * rowH
        if not db.growDown then y = -(TITLE_H) - (math.floor((n - 1) / cols) - row) * rowH end
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", bar, "TOPLEFT", x, y)
        ColorStatusText(b)
        CropIcons(b)
    end

    local usedCols = (n < cols) and n or cols
    local usedRows = math.floor((n - 1) / cols) + 1
    bar:SetWidth(PAD * 2 + usedCols * colW - db.spacing)
    bar:SetHeight(TITLE_H + usedRows * rowH + 6)
end

-- fade the whole bar based on whether anything needs casting
local function DesiredAlpha()
    if not db.immersive then return 1 end
    local btns = VisibleButtons()
    for i = 1, table.getn(btns) do
        if NeedsCount(btns[i]) > 0 then return 1 end
    end
    return 0
end

local function ApplyScale()
    local bar = Bar()
    if bar and PP_PerUser then
        bar:SetScale((PP_PerUser.scalebar or 1) * (db.scale or 1))
    end
end

-- ---------------------------------------------------------------------------
-- Hook PallyPower's UI update so our layout/immersive pass runs right after
-- ---------------------------------------------------------------------------
local origUpdateUI
local function HookedUpdateUI()
    if origUpdateUI then origUpdateUI() end
    Relayout()
    ApplyScale()
    -- retarget the fade
    local want = DesiredAlpha()
    if want ~= fade.target then
        fade.from = fade.a
        fade.target = want
        fade.start = GetTime()
        fade.dur = (want == 1) and FADE_IN or FADE_OUT
    end
end

local function TickerUpdate()
    if fade.a == fade.target then return end
    local p = (GetTime() - fade.start) / fade.dur
    local bar = Bar()
    if p >= 1 then
        fade.a = fade.target
    else
        local e = p * p * (3 - 2 * p)
        fade.a = fade.from + (fade.target - fade.from) * e
    end
    if bar then bar:SetAlpha(fade.a) end
end

-- ---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:SetScript("OnEvent", function()
    if event ~= "VARIABLES_LOADED" then return end
    InitDefaults()
    -- install the hook once PallyPower's function exists
    if PallyPower_UpdateUI and not origUpdateUI then
        origUpdateUI = PallyPower_UpdateUI
        PallyPower_UpdateUI = HookedUpdateUI
    end
    -- also crop the assignment grid's icons after it repopulates
    if PallyPowerGrid_Update and not ImmersivePP_origGrid then
        ImmersivePP_origGrid = PallyPowerGrid_Update
        PallyPowerGrid_Update = function()
            ImmersivePP_origGrid()
            CropAssignmentIcons()
        end
    end
    ticker = CreateFrame("Frame")
    ticker:SetScript("OnUpdate", TickerUpdate)

    -- Fix a latent PallyPower crash: MouseDown only records startPosX on an
    -- unlocked left-click, but MouseUp reads it unconditionally -> a right-
    -- click or locked-bar release throws "arithmetic on nil". Guard it.
    PallyPowerBuffBar_MouseUp = function()
        local bar = getglobal("PallyPowerBuffBar")
        if not bar then return end
        if bar.isMoving then
            bar:StopMovingOrSizing()
            bar.isMoving = false
        end
        if bar.startPosX and bar.startPosY and bar:GetLeft() and bar:GetTop()
            and abs(bar.startPosX - bar:GetLeft()) < 2
            and abs(bar.startPosY - bar:GetTop()) < 2 then
            if PallyPowerFrame then PallyPowerFrame:Show() end
            if PallyPower_UpdateUI then PallyPower_UpdateUI() end
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccImmersive PallyPower|r loaded. Type |cffffffff/ipp|r for options.")
end)

-- ---------------------------------------------------------------------------
SLASH_IMMERSIVEPALLYPOWER1 = "/ipp"
SlashCmdList["IMMERSIVEPALLYPOWER"] = function(msg)
    local cmd, rest = msg, nil
    local sp = string.find(msg, " ")
    if sp then cmd = string.sub(msg, 1, sp - 1); rest = string.sub(msg, sp + 1) end

    if cmd == "config" or cmd == "options" or cmd == "" then
        if cmd == "" then
            -- bare /ipp opens the panel; keep the command list under /ipp help
        end
        if ImmersivePallyPower_OpenOptions then ImmersivePallyPower_OpenOptions() end
    elseif cmd == "immersive" then
        db.immersive = not db.immersive
        DEFAULT_CHAT_FRAME:AddMessage("ImmersivePallyPower: immersive " .. (db.immersive and "ON" or "OFF"))
    elseif cmd == "missing" then
        db.onlyMissing = not db.onlyMissing
        DEFAULT_CHAT_FRAME:AddMessage("ImmersivePallyPower: only-missing " .. (db.onlyMissing and "ON" or "OFF"))
    elseif cmd == "columns" and rest then
        db.columns = tonumber(rest) or 1
        DEFAULT_CHAT_FRAME:AddMessage("ImmersivePallyPower: columns = " .. db.columns)
    elseif cmd == "scale" and rest then
        db.scale = tonumber(rest) or 1
        ApplyScale()
        DEFAULT_CHAT_FRAME:AddMessage("ImmersivePallyPower: scale = " .. db.scale)
    elseif cmd == "grow" then
        db.growDown = not db.growDown
        DEFAULT_CHAT_FRAME:AddMessage("ImmersivePallyPower: grows " .. (db.growDown and "down" or "up"))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccImmersive PallyPower|r commands:")
        DEFAULT_CHAT_FRAME:AddMessage("/ipp immersive   - hide the bar until a buff is missing")
        DEFAULT_CHAT_FRAME:AddMessage("/ipp missing     - show only buttons with someone missing")
        DEFAULT_CHAT_FRAME:AddMessage("/ipp columns <n> - buttons per row (1 = vertical)")
        DEFAULT_CHAT_FRAME:AddMessage("/ipp scale <n>   - bar size (e.g. 1.2)")
        DEFAULT_CHAT_FRAME:AddMessage("/ipp grow        - grow down or up")
    end
    if PallyPower_UpdateUI then PallyPower_UpdateUI() end
end
