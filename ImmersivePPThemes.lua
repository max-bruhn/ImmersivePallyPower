--[[
 Immersive PallyPower - theme layer
 Reskins PallyPower's frames into Modern (flat) or Classic (untouched).
 Applied once after load; changing it prompts a UI reload. The buff
 buttons keep their status fill colour (red/yellow/dark) - only borders
 and container panels are themed.
--]]

ImmersivePallyPowerDB = ImmersivePallyPowerDB or {}

local pixelSize
local function GetPixel()
    if pixelSize then return pixelSize end
    local scale = tonumber(GetCVar("uiScale")) or 1
    local _, _, _, h = string.find(GetCVar("gxResolution") or "", "(.+)x(.+)")
    h = tonumber(h)
    pixelSize = h and (768 / h / scale) or 1
    if pixelSize > 1 then pixelSize = 1 end
    if pixelSize < 0.5 then pixelSize = pixelSize * 2 end
    return pixelSize
end

local STYLE = "modern"
local function ResolveStyle()
    STYLE = (ImmersivePallyPowerDB.style == "classic") and "classic" or "modern"
end

function ImmersivePallyPower_CurrentStyle()
    return (ImmersivePallyPowerDB.style == "classic") and "classic" or "modern"
end

local function ModernPanel(f, a)
    if not f then return end
    local px = GetPixel()
    f:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0,
        edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = px,
        insets = { left = -px, right = -px, top = -px, bottom = -px },
    })
    f:SetBackdropColor(0.06, 0.06, 0.06, a or 0.9)
    f:SetBackdropBorderColor(0.22, 0.22, 0.22, 1)
end

-- buff buttons: keep PallyPower's status fill, just give a clean 1px border
local function ModernButtonBorder(b)
    if not b then return end
    local px = GetPixel()
    local r, g, bl, a = b:GetBackdropColor()
    b:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0,
        edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = px,
        insets = { left = -px, right = -px, top = -px, bottom = -px },
    })
    if r then b:SetBackdropColor(r, g, bl, a) end
    b:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
end

local function ApplyTheme()
    if STYLE == "classic" then return end
    ModernPanel(getglobal("PallyPowerBuffBar"), 0.9)
    ModernPanel(getglobal("PallyPowerFrame"), 0.92)
    ModernPanel(getglobal("PallyPower_OptionsFrame"), 0.95)
    for i = 1, 10 do
        ModernButtonBorder(getglobal("PallyPowerBuffBarBuff" .. i))
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:SetScript("OnEvent", function()
    if event ~= "VARIABLES_LOADED" then return end
    ResolveStyle()
    local delay, waited = CreateFrame("Frame"), 0
    delay:SetScript("OnUpdate", function()
        waited = waited + arg1
        if waited < 0.3 then return end
        delay:SetScript("OnUpdate", nil)
        pcall(ApplyTheme)
    end)
end)

StaticPopupDialogs["IMMERSIVEPALLYPOWER_RELOAD"] = {
    text = "Theme changes take effect after a UI reload. Reload now?",
    button1 = "OK", button2 = "Cancel",
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
}

function ImmersivePallyPower_SetTheme(s)
    if s ~= "classic" then s = "modern" end
    ImmersivePallyPowerDB.style = s
    DEFAULT_CHAT_FRAME:AddMessage("ImmersivePallyPower: theme set to " .. s .. " (reload to apply).")
    StaticPopup_Show("IMMERSIVEPALLYPOWER_RELOAD")
end
