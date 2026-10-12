--[[
    MacUI v2.0.0
    A modern macOS-inspired Roblox UI library
    Liquid Glass + Dock + Boot Sequence + Lucide Icons + Rich Animations
]]

local MacUI = {
    Version = "2.0.0",
    Themes = {},
    CurrentTheme = "Dark",
    Windows = {},
    Notifications = {},
    Config = {
        Folder = "MacUI",
        File = "Config",
        Data = {}
    },
    Accessibility = {
        ReducedMotion = false,
        Scale = 1,
        HighContrast = false
    },
    GlassStyle = {
        Transparency = 0.22,
        Border = true,
        Shadow = true,
        Tint = Color3.fromRGB(30, 30, 35),
        Layers = true
    }
}

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")

-- Utility: Safe parent (executor vs studio)
local function GetUIParent()
    local success, result = pcall(function()
        return CoreGui
    end)
    if success and result then return result end
    return PlayerGui
end

-- Connection manager
local Connections = {}
local function TrackConnection(conn)
    table.insert(Connections, conn)
    return conn
end

local function DisconnectAll(conns)
    if not conns then return end
    for _, c in ipairs(conns) do
        if typeof(c) == "RBXScriptConnection" and c.Connected then
            c:Disconnect()
        end
    end
    table.clear(conns)
end

-- Spring-like tween helper
function MacUI.Tween(object, info, properties)
    if MacUI.Accessibility.ReducedMotion then
        for prop, value in pairs(properties) do
            object[prop] = value
        end
        return nil
    end
    local tweenInfo = TweenInfo.new(
        info.Time or 0.28,
        info.EasingStyle or Enum.EasingStyle.Quint,
        info.EasingDirection or Enum.EasingDirection.Out,
        info.RepeatCount or 0,
        info.Reverses or false,
        info.DelayTime or 0
    )
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Bounce / jump animation (classic Mac dock feel)
function MacUI.Bounce(object, height, duration)
    if MacUI.Accessibility.ReducedMotion then return end
    height = height or 18
    duration = duration or 0.45
    local original = object.Position
    local up = original - UDim2.new(0, 0, 0, height)
    local t1 = MacUI.Tween(object, {Time = duration * 0.35, EasingStyle = Enum.EasingStyle.Quad, EasingDirection = Enum.EasingDirection.Out}, {
        Position = up
    })
    if t1 then
        t1.Completed:Connect(function()
            MacUI.Tween(object, {Time = duration * 0.65, EasingStyle = Enum.EasingStyle.Bounce, EasingDirection = Enum.EasingDirection.Out}, {
                Position = original
            })
        end)
    end
end

-- Scale pulse
function MacUI.PulseScale(object, scale, duration)
    if MacUI.Accessibility.ReducedMotion then return end
    scale = scale or 1.12
    duration = duration or 0.22
    local uiScale = object:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Parent = object
    end
    MacUI.Tween(uiScale, {Time = duration * 0.4, EasingStyle = Enum.EasingStyle.Back}, {Scale = scale})
    task.delay(duration * 0.4, function()
        MacUI.Tween(uiScale, {Time = duration * 0.6, EasingStyle = Enum.EasingStyle.Quint}, {Scale = 1})
    end)
end

-- ============================================================
-- Lucide Icons via GaphopUI spritesheet pack
-- https://raw.githubusercontent.com/gaphop123/GaphopUI/refs/heads/main/icon.lua
-- ============================================================
local LucideSprites = nil
local EmojiIcons = nil

local function LoadLucidePack()
    if LucideSprites then return true end
    local ok, pack = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/GaphopUI/refs/heads/main/icon.lua"))()
    end)
    if ok and type(pack) == "table" and pack.LucideSprites then
        LucideSprites = pack.LucideSprites
        EmojiIcons = pack.Icons
        return true
    end
    -- Offline / failed fallback: minimal single-asset icons
    LucideSprites = {}
    EmojiIcons = {}
    return false
end

-- Normalize icon name: "home", "lucide-home", "Home", "house" → key used in pack
local function NormalizeIconKey(name)
    if not name then return "home" end
    local key = string.lower(tostring(name))
    key = string.gsub(key, "^lucide%-", "")
    key = string.gsub(key, "%-", "") -- home-icon → homeicon (pack uses no hyphens mostly)
    -- common aliases
    if key == "house" then key = "home" end
    if key == "person" then key = "user" end
    if key == "cog" then key = "settings" end
    if key == "close" then key = "x" end
    return key
end

--[[
    Returns either:
      - spritesheet data: { Image = "rbxassetid://...", ImageRectSize = Vector2, ImageRectOffset = Vector2 }
      - or plain: { Image = "rbxassetid://..." }
]]
function MacUI.GetIconData(name)
    LoadLucidePack()
    local key = NormalizeIconKey(name)

    if LucideSprites and LucideSprites[key] then
        local d = LucideSprites[key]
        -- format: { assetId, {w, h}, {ox, oy} }
        return {
            Image = "rbxassetid://" .. tostring(d[1]),
            ImageRectSize = Vector2.new(d[2][1], d[2][2]),
            ImageRectOffset = Vector2.new(d[3][1], d[3][2]),
            IsSprite = true
        }
    end

    -- try without stripping hyphens (e.g. if pack has keys with hyphens - it doesn't)
    -- fallback: empty / default apple or home sprite if available
    if LucideSprites and LucideSprites.home then
        local d = LucideSprites.home
        return {
            Image = "rbxassetid://" .. tostring(d[1]),
            ImageRectSize = Vector2.new(d[2][1], d[2][2]),
            ImageRectOffset = Vector2.new(d[3][1], d[3][2]),
            IsSprite = true
        }
    end

    return { Image = "rbxassetid://0", IsSprite = false }
end

-- Backward-compatible: returns image string only
function MacUI.GetIcon(name)
    local data = MacUI.GetIconData(name)
    return data.Image
end

-- Apply full spritesheet icon onto an ImageLabel / ImageButton
function MacUI.ApplyIcon(imageObject, name)
    if not imageObject then return end
    local data = MacUI.GetIconData(name)
    imageObject.Image = data.Image
    if data.IsSprite then
        imageObject.ImageRectSize = data.ImageRectSize
        imageObject.ImageRectOffset = data.ImageRectOffset
    else
        imageObject.ImageRectSize = Vector2.new(0, 0)
        imageObject.ImageRectOffset = Vector2.new(0, 0)
    end
end

function MacUI.AddIcon(name, assetIdOrData)
    LoadLucidePack()
    local key = NormalizeIconKey(name)
    if type(assetIdOrData) == "table" then
        LucideSprites[key] = assetIdOrData
    else
        -- plain asset id string or number
        local id = tonumber(tostring(assetIdOrData):match("%d+")) or 0
        LucideSprites[key] = { id, {48, 48}, {0, 0} }
    end
end

-- Theme system
MacUI.Themes.Dark = {
    Background = Color3.fromRGB(28, 28, 30),
    SecondaryBackground = Color3.fromRGB(38, 38, 42),
    TertiaryBackground = Color3.fromRGB(48, 48, 52),
    Text = Color3.fromRGB(255, 255, 255),
    SecondaryText = Color3.fromRGB(180, 180, 185),
    Accent = Color3.fromRGB(10, 132, 255),
    Border = Color3.fromRGB(70, 70, 75),
    Glass = Color3.fromRGB(40, 40, 45),
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(35, 35, 40)
}

MacUI.Themes.Light = {
    Background = Color3.fromRGB(246, 246, 248),
    SecondaryBackground = Color3.fromRGB(255, 255, 255),
    TertiaryBackground = Color3.fromRGB(235, 235, 240),
    Text = Color3.fromRGB(28, 28, 30),
    SecondaryText = Color3.fromRGB(90, 90, 95),
    Accent = Color3.fromRGB(0, 122, 255),
    Border = Color3.fromRGB(200, 200, 205),
    Glass = Color3.fromRGB(255, 255, 255),
    Success = Color3.fromRGB(52, 199, 89),
    Warning = Color3.fromRGB(255, 149, 0),
    Danger = Color3.fromRGB(255, 59, 48),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(245, 245, 247)
}

MacUI.Themes.Graphite = {
    Background = Color3.fromRGB(40, 40, 42),
    SecondaryBackground = Color3.fromRGB(50, 50, 53),
    TertiaryBackground = Color3.fromRGB(60, 60, 64),
    Text = Color3.fromRGB(245, 245, 247),
    SecondaryText = Color3.fromRGB(160, 160, 165),
    Accent = Color3.fromRGB(120, 120, 130),
    Border = Color3.fromRGB(80, 80, 85),
    Glass = Color3.fromRGB(55, 55, 58),
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(45, 45, 48)
}

MacUI.Themes.Midnight = {
    Background = Color3.fromRGB(15, 15, 20),
    SecondaryBackground = Color3.fromRGB(22, 22, 28),
    TertiaryBackground = Color3.fromRGB(30, 30, 38),
    Text = Color3.fromRGB(240, 240, 245),
    SecondaryText = Color3.fromRGB(150, 150, 160),
    Accent = Color3.fromRGB(94, 92, 230),
    Border = Color3.fromRGB(50, 50, 60),
    Glass = Color3.fromRGB(25, 25, 32),
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(18, 18, 24)
}

MacUI.Themes.Blue = {
    Background = Color3.fromRGB(20, 30, 50),
    SecondaryBackground = Color3.fromRGB(28, 40, 65),
    TertiaryBackground = Color3.fromRGB(35, 50, 80),
    Text = Color3.fromRGB(240, 245, 255),
    SecondaryText = Color3.fromRGB(160, 180, 210),
    Accent = Color3.fromRGB(10, 132, 255),
    Border = Color3.fromRGB(50, 70, 100),
    Glass = Color3.fromRGB(30, 45, 70),
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(22, 35, 55)
}

MacUI.Themes.Purple = {
    Background = Color3.fromRGB(30, 20, 45),
    SecondaryBackground = Color3.fromRGB(40, 28, 58),
    TertiaryBackground = Color3.fromRGB(50, 35, 70),
    Text = Color3.fromRGB(245, 240, 255),
    SecondaryText = Color3.fromRGB(180, 160, 200),
    Accent = Color3.fromRGB(175, 82, 222),
    Border = Color3.fromRGB(70, 50, 90),
    Glass = Color3.fromRGB(45, 30, 65),
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(35, 25, 50)
}

function MacUI:RegisterTheme(name, themeTable)
    self.Themes[name] = themeTable
end

function MacUI:SetTheme(name)
    if not self.Themes[name] then
        warn("[MacUI] Warning: Theme '" .. tostring(name) .. "' does not exist")
        return
    end
    self.CurrentTheme = name
    local theme = self.Themes[name]
    for _, window in pairs(self.Windows) do
        if window and window.ApplyTheme then
            window:ApplyTheme(theme)
        end
    end
end

function MacUI:SetGlassStyle(style)
    for k, v in pairs(style) do
        self.GlassStyle[k] = v
    end
end

function MacUI:SetAccessibility(opts)
    for k, v in pairs(opts) do
        self.Accessibility[k] = v
    end
end

-- ============================================================
-- LIQUID GLASS FRAME (multi-layer approximation)
-- ============================================================
local function CreateGlassFrame(parent, props)
    props = props or {}
    local theme = MacUI.Themes[MacUI.CurrentTheme]
    local radius = props.Radius or 14
    local transparency = props.Transparency or MacUI.GlassStyle.Transparency
    local color = props.Color or theme.Glass

    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ClipsDescendants = false
    container.Parent = parent

    -- Shadow layer
    if MacUI.GlassStyle.Shadow then
        local shadow = Instance.new("ImageLabel")
        shadow.Name = "GlassShadow"
        shadow.BackgroundTransparency = 1
        shadow.Image = "rbxassetid://6014261993"
        shadow.ImageColor3 = Color3.new(0, 0, 0)
        shadow.ImageTransparency = 0.55
        shadow.ScaleType = Enum.ScaleType.Slice
        shadow.SliceCenter = Rect.new(49, 49, 450, 450)
        shadow.Size = UDim2.new(1, 48, 1, 48)
        shadow.Position = UDim2.new(0, -24, 0, -20)
        shadow.ZIndex = -2
        shadow.Parent = container
    end

    -- Base glass
    local base = Instance.new("Frame")
    base.Name = "GlassBase"
    base.Size = UDim2.new(1, 0, 1, 0)
    base.BackgroundColor3 = color
    base.BackgroundTransparency = transparency
    base.BorderSizePixel = 0
    base.ZIndex = 1
    base.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = base

    -- Frost / tint overlay
    if MacUI.GlassStyle.Layers then
        local frost = Instance.new("Frame")
        frost.Name = "Frost"
        frost.Size = UDim2.new(1, 0, 1, 0)
        frost.BackgroundColor3 = theme.Glass
        frost.BackgroundTransparency = 0.82
        frost.BorderSizePixel = 0
        frost.ZIndex = 2
        frost.Parent = base

        local frostCorner = Instance.new("UICorner")
        frostCorner.CornerRadius = UDim.new(0, radius)
        frostCorner.Parent = frost

        -- Subtle top highlight (liquid glass sheen)
        local sheen = Instance.new("Frame")
        sheen.Name = "Sheen"
        sheen.Size = UDim2.new(1, 0, 0.38, 0)
        sheen.BackgroundColor3 = Color3.new(1, 1, 1)
        sheen.BackgroundTransparency = 0.92
        sheen.BorderSizePixel = 0
        sheen.ZIndex = 3
        sheen.Parent = base

        local sheenCorner = Instance.new("UICorner")
        sheenCorner.CornerRadius = UDim.new(0, radius)
        sheenCorner.Parent = sheen

        local sheenGradient = Instance.new("UIGradient")
        sheenGradient.Rotation = 90
        sheenGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.55),
            NumberSequenceKeypoint.new(0.6, 0.9),
            NumberSequenceKeypoint.new(1, 1)
        })
        sheenGradient.Parent = sheen
    end

    -- Border stroke
    if MacUI.GlassStyle.Border then
        local stroke = Instance.new("UIStroke")
        stroke.Name = "GlassStroke"
        stroke.Color = theme.Border
        stroke.Transparency = 0.45
        stroke.Thickness = 1.2
        stroke.Parent = base
    end

    return container
end

-- Safe accessor (Instances cannot hold custom .GlassBase fields)
local function GetGlassBase(container)
    if not container then return nil end
    return container:FindFirstChild("GlassBase")
end

-- ============================================================
-- BOOT SEQUENCE (Apple logo + loading)
-- ============================================================
function MacUI:PlayBootSequence(options)
    options = options or {}
    local duration = options.Duration or 2.8
    local onComplete = options.OnComplete

    local theme = self.Themes[self.CurrentTheme] or self.Themes.Dark

    local bootGui = Instance.new("ScreenGui")
    bootGui.Name = "MacUI_Boot"
    bootGui.ResetOnSpawn = false
    bootGui.IgnoreGuiInset = true
    bootGui.DisplayOrder = 100000
    bootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    bootGui.Parent = GetUIParent()

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BorderSizePixel = 0
    bg.Parent = bootGui

    -- Apple logo
    local logo = Instance.new("ImageLabel")
    logo.Name = "AppleLogo"
    logo.Size = UDim2.new(0, 72, 0, 72)
    logo.Position = UDim2.new(0.5, -36, 0.42, -36)
    logo.BackgroundTransparency = 1
    MacUI.ApplyIcon(logo, "apple")
    logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
    logo.ImageTransparency = 1
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Parent = bg

    local logoScale = Instance.new("UIScale")
    logoScale.Scale = 0.6
    logoScale.Parent = logo

    -- Progress bar track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(0, 160, 0, 4)
    track.Position = UDim2.new(0.5, -80, 0.58, 0)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    track.BorderSizePixel = 0
    track.BackgroundTransparency = 1
    track.Parent = bg

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    -- Fade in logo
    MacUI.Tween(logo, {Time = 0.55, EasingStyle = Enum.EasingStyle.Quint}, {
        ImageTransparency = 0
    })
    MacUI.Tween(logoScale, {Time = 0.6, EasingStyle = Enum.EasingStyle.Back}, {
        Scale = 1
    })

    task.delay(0.45, function()
        MacUI.Tween(track, {Time = 0.3}, {BackgroundTransparency = 0.35})
        -- Progress fill
        MacUI.Tween(fill, {Time = duration - 0.9, EasingStyle = Enum.EasingStyle.Quad}, {
            Size = UDim2.new(1, 0, 1, 0)
        })
    end)

    -- Finish
    task.delay(duration, function()
        MacUI.Tween(logo, {Time = 0.35}, {ImageTransparency = 1})
        MacUI.Tween(track, {Time = 0.3}, {BackgroundTransparency = 1})
        MacUI.Tween(fill, {Time = 0.3}, {BackgroundTransparency = 1})
        MacUI.Tween(bg, {Time = 0.45}, {BackgroundTransparency = 1})

        task.wait(0.5)
        if bootGui and bootGui.Parent then
            bootGui:Destroy()
        end
        if onComplete then
            pcall(onComplete)
        end
    end)

    return bootGui
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
function MacUI:Notify(options)
    options = options or {}
    local title = options.Title or "MacUI"
    local content = options.Content or ""
    local duration = options.Duration or 4
    local icon = options.Icon or "info"

    local theme = self.Themes[self.CurrentTheme]
    local screenGui = GetUIParent():FindFirstChild("MacUI_Notifications")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MacUI_Notifications"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = 50000
        screenGui.Parent = GetUIParent()
    end

    local notifContainer = CreateGlassFrame(screenGui, {Radius = 14, Transparency = 0.12})
    notifContainer.Size = UDim2.new(0, 320, 0, 72)
    notifContainer.Position = UDim2.new(1, 40, 0, 20 + (#self.Notifications * 84))
    notifContainer.AnchorPoint = Vector2.new(1, 0)
    notifContainer.ZIndex = 100

    local notif = GetGlassBase(notifContainer)

    local iconImg = Instance.new("ImageLabel")
    iconImg.Size = UDim2.new(0, 28, 0, 28)
    iconImg.Position = UDim2.new(0, 14, 0.5, -14)
    iconImg.BackgroundTransparency = 1
    MacUI.ApplyIcon(iconImg, icon)
    iconImg.ImageColor3 = theme.Accent
    iconImg.Parent = notif

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -60, 0, 22)
    titleLbl.Position = UDim2.new(0, 52, 0, 12)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = theme.Text
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 15
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = notif

    local contentLbl = Instance.new("TextLabel")
    contentLbl.Size = UDim2.new(1, -60, 0, 24)
    contentLbl.Position = UDim2.new(0, 52, 0, 34)
    contentLbl.BackgroundTransparency = 1
    contentLbl.Text = content
    contentLbl.TextColor3 = theme.SecondaryText
    contentLbl.Font = Enum.Font.Gotham
    contentLbl.TextSize = 13
    contentLbl.TextXAlignment = Enum.TextXAlignment.Left
    contentLbl.TextWrapped = true
    contentLbl.Parent = notif

    table.insert(self.Notifications, notifContainer)

    -- Slide in + slight bounce
    MacUI.Tween(notifContainer, {Time = 0.4, EasingStyle = Enum.EasingStyle.Quint}, {
        Position = UDim2.new(1, -20, 0, 20 + ((#self.Notifications - 1) * 84))
    })

    task.delay(duration, function()
        if notifContainer and notifContainer.Parent then
            MacUI.Tween(notifContainer, {Time = 0.3}, {
                Position = UDim2.new(1, 50, 0, notifContainer.Position.Y.Offset),
            })
            MacUI.Tween(notif, {Time = 0.3}, {BackgroundTransparency = 1})
            task.wait(0.35)
            notifContainer:Destroy()
            for i, n in ipairs(self.Notifications) do
                if n == notifContainer then
                    table.remove(self.Notifications, i)
                    break
                end
            end
            for i, n in ipairs(self.Notifications) do
                MacUI.Tween(n, {Time = 0.25}, {
                    Position = UDim2.new(1, -20, 0, 20 + ((i - 1) * 84))
                })
            end
        end
    end)
end

-- Configuration
function MacUI:CreateConfig(opts)
    self.Config.Folder = opts.Folder or "MacUI"
    self.Config.File = opts.File or "Config"
end

function MacUI:SaveConfig()
    local success, err = pcall(function()
        if writefile then
            local data = HttpService:JSONEncode(self.Config.Data)
            writefile(self.Config.Folder .. "/" .. self.Config.File .. ".json", data)
        end
    end)
    if not success then
        warn("[MacUI] Config save unavailable in this environment:", err)
    end
end

function MacUI:LoadConfig()
    local success, result = pcall(function()
        if isfile and isfile(self.Config.Folder .. "/" .. self.Config.File .. ".json") then
            local data = readfile(self.Config.Folder .. "/" .. self.Config.File .. ".json")
            self.Config.Data = HttpService:JSONDecode(data)
            return true
        end
        return false
    end)
    if not success then
        warn("[MacUI] Config load unavailable")
    end
    return success and result
end

function MacUI:ResetConfig()
    self.Config.Data = {}
    self:SaveConfig()
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================
function MacUI:CreateWindow(options)
    options = options or {}
    local name = options.Name or "MacUI"
    local subtitle = options.Subtitle or ""
    local themeName = options.Theme or "Dark"
    local acrylic = options.Acrylic ~= false
    local size = options.Size or UDim2.new(0, 760, 0, 500)
    local minSize = options.MinSize or Vector2.new(480, 320)
    local showBoot = options.Boot ~= false
    local useDock = options.Dock ~= false

    self:SetTheme(themeName)
    local theme = self.Themes[themeName]

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MacUI_" .. name
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 100
    screenGui.Parent = GetUIParent()

    -- Main window container (liquid glass)
    local windowContainer = CreateGlassFrame(screenGui, {
        Radius = 18,
        Transparency = acrylic and MacUI.GlassStyle.Transparency or 0.06,
        Color = theme.Background
    })
    windowContainer.Name = "Window"
    windowContainer.Size = size
    windowContainer.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2)
    windowContainer.ClipsDescendants = true

    local window = GetGlassBase(windowContainer)
    window.ClipsDescendants = true

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 44)
    titleBar.BackgroundTransparency = 1
    titleBar.ZIndex = 10
    titleBar.Parent = window

    -- Traffic lights
    local function CreateTrafficLight(color, posX)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 13, 0, 13)
        btn.Position = UDim2.new(0, posX, 0.5, -6.5)
        btn.BackgroundColor3 = color
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 11
        btn.Parent = titleBar

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.new(0, 0, 0)
        stroke.Transparency = 0.65
        stroke.Thickness = 0.6
        stroke.Parent = btn

        return btn
    end

    local closeBtn = CreateTrafficLight(Color3.fromRGB(255, 95, 87), 16)
    local minBtn = CreateTrafficLight(Color3.fromRGB(255, 189, 46), 36)
    local maxBtn = CreateTrafficLight(Color3.fromRGB(40, 200, 64), 56)

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -180, 1, 0)
    titleLabel.Position = UDim2.new(0, 90, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = name
    titleLabel.TextColor3 = theme.Text
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 11
    titleLabel.Parent = titleBar

    if subtitle ~= "" then
        titleLabel.Text = name .. "  —  " .. subtitle
    end

    -- Search button
    local searchBtn = Instance.new("ImageButton")
    searchBtn.Size = UDim2.new(0, 20, 0, 20)
    searchBtn.Position = UDim2.new(1, -36, 0.5, -10)
    searchBtn.BackgroundTransparency = 1
    MacUI.ApplyIcon(searchBtn, "search")
    searchBtn.ImageColor3 = theme.SecondaryText
    searchBtn.ZIndex = 11
    searchBtn.Parent = titleBar

    -- Content area (full width when using dock, otherwise with sidebar)
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -44)
    content.Position = UDim2.new(0, 0, 0, 44)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.ZIndex = 5
    content.Parent = window

    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Name = "Scroll"
    contentScroll.Size = UDim2.new(1, 0, 1, useDock and -70 or 0)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 5
    contentScroll.ScrollBarImageColor3 = theme.Border
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.ZIndex = 6
    contentScroll.Parent = content

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 16)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentScroll

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 20)
    contentPadding.PaddingLeft = UDim.new(0, 28)
    contentPadding.PaddingRight = UDim.new(0, 28)
    contentPadding.PaddingBottom = UDim.new(0, 28)
    contentPadding.Parent = contentScroll

    -- ============================================================
    -- DOCK (bottom, Lucide icons, jump animation)
    -- ============================================================
    local dockContainer, dockFrame, dockLayout
    if useDock then
        dockContainer = CreateGlassFrame(window, {
            Radius = 16,
            Transparency = 0.18,
            Color = theme.Dock or theme.SecondaryBackground
        })
        dockContainer.Name = "Dock"
        dockContainer.Size = UDim2.new(0, 0, 0, 58)
        dockContainer.Position = UDim2.new(0.5, 0, 1, -12)
        dockContainer.AnchorPoint = Vector2.new(0.5, 1)
        dockContainer.ZIndex = 20
        dockContainer.AutomaticSize = Enum.AutomaticSize.X

        dockFrame = GetGlassBase(dockContainer)
        dockFrame.AutomaticSize = Enum.AutomaticSize.X

        local dockPad = Instance.new("UIPadding")
        dockPad.PaddingLeft = UDim.new(0, 12)
        dockPad.PaddingRight = UDim.new(0, 12)
        dockPad.PaddingTop = UDim.new(0, 8)
        dockPad.PaddingBottom = UDim.new(0, 8)
        dockPad.Parent = dockFrame

        dockLayout = Instance.new("UIListLayout")
        dockLayout.FillDirection = Enum.FillDirection.Horizontal
        dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        dockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        dockLayout.Padding = UDim.new(0, 6)
        dockLayout.SortOrder = Enum.SortOrder.LayoutOrder
        dockLayout.Parent = dockFrame
    end

    -- Window object
    local Window = {
        ScreenGui = screenGui,
        Frame = windowContainer,
        GlassBase = window, -- direct reference to the Frame named GlassBase
        TitleBar = titleBar,
        Content = contentScroll,
        Dock = dockContainer,
        Tabs = {},
        TabOrder = {},
        CurrentTab = nil,
        OriginalSize = size,
        OriginalPos = windowContainer.Position,
        IsMaximized = false,
        IsMinimized = false,
        Connections = {},
        Elements = {},
        UseDock = useDock
    }

    -- Dragging
    local dragging, dragStart, startPos
    TrackConnection(titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = windowContainer.Position
        end
    end))
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            windowContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    TrackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    -- Traffic light actions
    TrackConnection(closeBtn.MouseButton1Click:Connect(function()
        MacUI.PulseScale(closeBtn, 0.85, 0.15)
        task.delay(0.12, function()
            Window:Destroy()
        end)
    end))
    TrackConnection(minBtn.MouseButton1Click:Connect(function()
        MacUI.PulseScale(minBtn, 0.85, 0.15)
        Window:Minimize()
    end))
    TrackConnection(maxBtn.MouseButton1Click:Connect(function()
        MacUI.PulseScale(maxBtn, 0.85, 0.15)
        Window:Maximize()
    end))

    local function SetupHover(btn, baseColor)
        TrackConnection(btn.MouseEnter:Connect(function()
            MacUI.Tween(btn, {Time = 0.12}, {BackgroundColor3 = baseColor:Lerp(Color3.new(1,1,1), 0.18)})
        end))
        TrackConnection(btn.MouseLeave:Connect(function()
            MacUI.Tween(btn, {Time = 0.12}, {BackgroundColor3 = baseColor})
        end))
    end
    SetupHover(closeBtn, Color3.fromRGB(255, 95, 87))
    SetupHover(minBtn, Color3.fromRGB(255, 189, 46))
    SetupHover(maxBtn, Color3.fromRGB(40, 200, 64))

    function Window:ApplyTheme(t)
        theme = t
        local winBase = GetGlassBase(windowContainer)
        if winBase then
            winBase.BackgroundColor3 = t.Background
        end
        titleLabel.TextColor3 = t.Text
        searchBtn.ImageColor3 = t.SecondaryText
        if dockContainer then
            local dockBase = GetGlassBase(dockContainer)
            if dockBase then
                dockBase.BackgroundColor3 = t.Dock or t.SecondaryBackground
            end
        end
    end

    function Window:Minimize()
        if self.IsMinimized then
            MacUI.Tween(windowContainer, {Time = 0.35, EasingStyle = Enum.EasingStyle.Quint}, {
                Size = self.OriginalSize,
                Position = self.OriginalPos
            })
            self.IsMinimized = false
        else
            self.OriginalSize = windowContainer.Size
            self.OriginalPos = windowContainer.Position
            MacUI.Tween(windowContainer, {Time = 0.35, EasingStyle = Enum.EasingStyle.Quint}, {
                Size = UDim2.new(0, 220, 0, 44),
                Position = UDim2.new(0, 24, 1, -70)
            })
            self.IsMinimized = true
        end
    end

    function Window:Maximize()
        if self.IsMaximized then
            -- Restore
            screenGui.DisplayOrder = 100
            MacUI.Tween(windowContainer, {
                Time = 0.42,
                EasingStyle = Enum.EasingStyle.Quint,
                EasingDirection = Enum.EasingDirection.Out
            }, {
                Size = self.OriginalSize,
                Position = self.OriginalPos
            })
            self.IsMaximized = false
        else
            -- Maximize: raise layer + sliding animation
            self.OriginalSize = windowContainer.Size
            self.OriginalPos = windowContainer.Position
            screenGui.DisplayOrder = 99999

            -- Slide + expand from current position
            MacUI.Tween(windowContainer, {
                Time = 0.45,
                EasingStyle = Enum.EasingStyle.Quint,
                EasingDirection = Enum.EasingDirection.Out
            }, {
                Size = UDim2.new(1, -32, 1, -32),
                Position = UDim2.new(0, 16, 0, 16)
            })
            self.IsMaximized = true
        end
    end

    function Window:Toggle()
        windowContainer.Visible = not windowContainer.Visible
    end

    function Window:Destroy()
        DisconnectAll(self.Connections)
        if self.ScreenGui then
            -- Fade out
            MacUI.Tween(windowContainer, {Time = 0.25}, {
                Size = UDim2.new(0, 0, 0, 0)
            })
            task.delay(0.28, function()
                if self.ScreenGui then
                    self.ScreenGui:Destroy()
                end
            end)
        end
        for i, w in ipairs(MacUI.Windows) do
            if w == self then
                table.remove(MacUI.Windows, i)
                break
            end
        end
    end

    -- ============================================================
    -- TABS (with Dock integration)
    -- ============================================================
    function Window:CreateTab(opts)
        opts = opts or {}
        local tabName = opts.Name or "Tab"
        local iconName = opts.Icon or "home"

        local tabContent = Instance.new("Frame")
        tabContent.Name = tabName
        tabContent.Size = UDim2.new(1, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.AutomaticSize = Enum.AutomaticSize.Y
        tabContent.Parent = contentScroll

        local tabLayout = Instance.new("UIListLayout")
        tabLayout.Padding = UDim.new(0, 14)
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.Parent = tabContent

        local Tab = {
            Content = tabContent,
            Name = tabName,
            Icon = iconName,
            Sections = {},
            Window = Window,
            DockButton = nil
        }

        local function SelectTab()
            for _, t in pairs(Window.Tabs) do
                t.Content.Visible = false
                if t.DockButton then
                    local icon = t.DockButton:FindFirstChild("Icon")
                    local indicator = t.DockButton:FindFirstChild("Indicator")
                    if icon then
                        MacUI.Tween(icon, {Time = 0.2}, {ImageColor3 = theme.SecondaryText})
                    end
                    if indicator then
                        MacUI.Tween(indicator, {Time = 0.2}, {BackgroundTransparency = 1})
                    end
                end
            end
            tabContent.Visible = true
            Window.CurrentTab = Tab

            if Tab.DockButton then
                local icon = Tab.DockButton:FindFirstChild("Icon")
                local indicator = Tab.DockButton:FindFirstChild("Indicator")
                if icon then
                    MacUI.Tween(icon, {Time = 0.2}, {ImageColor3 = theme.Accent})
                end
                if indicator then
                    MacUI.Tween(indicator, {Time = 0.2}, {BackgroundTransparency = 0})
                end
                -- Jump animation
                MacUI.Bounce(Tab.DockButton, 16, 0.4)
            end
        end

        -- Dock button
        if useDock and dockFrame then
            local dockBtn = Instance.new("TextButton")
            dockBtn.Name = tabName
            dockBtn.Size = UDim2.new(0, 44, 0, 44)
            dockBtn.BackgroundTransparency = 1
            dockBtn.Text = ""
            dockBtn.AutoButtonColor = false
            dockBtn.ZIndex = 21
            dockBtn.Parent = dockFrame

            local icon = Instance.new("ImageLabel")
            icon.Name = "Icon"
            icon.Size = UDim2.new(0, 26, 0, 26)
            icon.Position = UDim2.new(0.5, -13, 0.5, -15)
            icon.BackgroundTransparency = 1
            MacUI.ApplyIcon(icon, iconName)
            icon.ImageColor3 = theme.SecondaryText
            icon.ZIndex = 22
            icon.Parent = dockBtn

            local indicator = Instance.new("Frame")
            indicator.Name = "Indicator"
            indicator.Size = UDim2.new(0, 5, 0, 5)
            indicator.Position = UDim2.new(0.5, -2.5, 1, -6)
            indicator.BackgroundColor3 = theme.Accent
            indicator.BackgroundTransparency = 1
            indicator.ZIndex = 22
            indicator.Parent = dockBtn

            local indCorner = Instance.new("UICorner")
            indCorner.CornerRadius = UDim.new(1, 0)
            indCorner.Parent = indicator

            -- Hover magnification (classic dock feel)
            TrackConnection(dockBtn.MouseEnter:Connect(function()
                if Window.CurrentTab ~= Tab then
                    MacUI.Tween(icon, {Time = 0.18, EasingStyle = Enum.EasingStyle.Back}, {
                        Size = UDim2.new(0, 30, 0, 30),
                        Position = UDim2.new(0.5, -15, 0.5, -18)
                    })
                end
            end))
            TrackConnection(dockBtn.MouseLeave:Connect(function()
                if Window.CurrentTab ~= Tab then
                    MacUI.Tween(icon, {Time = 0.18}, {
                        Size = UDim2.new(0, 26, 0, 26),
                        Position = UDim2.new(0.5, -13, 0.5, -15)
                    })
                end
            end))
            TrackConnection(dockBtn.MouseButton1Click:Connect(SelectTab))

            Tab.DockButton = dockBtn
        end

        function Tab:CreateSection(sectionName)
            local sectionFrame = Instance.new("Frame")
            sectionFrame.Size = UDim2.new(1, 0, 0, 0)
            sectionFrame.BackgroundTransparency = 1
            sectionFrame.AutomaticSize = Enum.AutomaticSize.Y
            sectionFrame.Parent = tabContent

            local sectionTitle = Instance.new("TextLabel")
            sectionTitle.Size = UDim2.new(1, 0, 0, 22)
            sectionTitle.BackgroundTransparency = 1
            sectionTitle.Text = sectionName
            sectionTitle.TextColor3 = theme.SecondaryText
            sectionTitle.Font = Enum.Font.GothamMedium
            sectionTitle.TextSize = 13
            sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
            sectionTitle.Parent = sectionFrame

            local sectionContent = Instance.new("Frame")
            sectionContent.Size = UDim2.new(1, 0, 0, 0)
            sectionContent.Position = UDim2.new(0, 0, 0, 28)
            sectionContent.BackgroundTransparency = 1
            sectionContent.AutomaticSize = Enum.AutomaticSize.Y
            sectionContent.Parent = sectionFrame

            local secLayout = Instance.new("UIListLayout")
            secLayout.Padding = UDim.new(0, 10)
            secLayout.SortOrder = Enum.SortOrder.LayoutOrder
            secLayout.Parent = sectionContent

            local Section = {
                Frame = sectionFrame,
                Content = sectionContent,
                Name = sectionName
            }

            -- Button
            function Section:CreateButton(opts)
                opts = opts or {}
                local btnContainer = CreateGlassFrame(sectionContent, {
                    Radius = 10,
                    Transparency = 0.35,
                    Color = theme.TertiaryBackground
                })
                btnContainer.Size = UDim2.new(1, 0, 0, opts.Description and 54 or 40)

                local btnBase = GetGlassBase(btnContainer)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 1, 0)
                btn.BackgroundTransparency = 1
                btn.Text = ""
                btn.AutoButtonColor = false
                btn.Parent = btnBase

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -20, opts.Description and 0 or 1, opts.Description and 22 or 0)
                lbl.Position = UDim2.new(0, 14, 0, opts.Description and 8 or 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Button"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = btn

                if opts.Description then
                    local desc = Instance.new("TextLabel")
                    desc.Size = UDim2.new(1, -20, 0, 18)
                    desc.Position = UDim2.new(0, 14, 0, 30)
                    desc.BackgroundTransparency = 1
                    desc.Text = opts.Description
                    desc.TextColor3 = theme.SecondaryText
                    desc.Font = Enum.Font.Gotham
                    desc.TextSize = 12
                    desc.TextXAlignment = Enum.TextXAlignment.Left
                    desc.Parent = btn
                end

                TrackConnection(btn.MouseEnter:Connect(function()
                    MacUI.Tween(btnBase, {Time = 0.15}, {BackgroundTransparency = 0.15})
                end))
                TrackConnection(btn.MouseLeave:Connect(function()
                    MacUI.Tween(btnBase, {Time = 0.15}, {BackgroundTransparency = 0.35})
                end))
                TrackConnection(btn.MouseButton1Click:Connect(function()
                    MacUI.PulseScale(btnContainer, 0.97, 0.18)
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                end))

                table.insert(Window.Elements, {Type = "Button", Name = opts.Name, Object = btnContainer})
                return btn
            end

            -- Toggle (macOS style)
            function Section:CreateToggle(opts)
                opts = opts or {}
                local current = opts.CurrentValue or false
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 38)
                row.BackgroundTransparency = 1
                row.Parent = sectionContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -70, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Toggle"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local track = Instance.new("Frame")
                track.Size = UDim2.new(0, 44, 0, 26)
                track.Position = UDim2.new(1, -44, 0.5, -13)
                track.BackgroundColor3 = current and theme.Accent or theme.TertiaryBackground
                track.Parent = row

                local trackCorner = Instance.new("UICorner")
                trackCorner.CornerRadius = UDim.new(1, 0)
                trackCorner.Parent = track

                local knob = Instance.new("Frame")
                knob.Size = UDim2.new(0, 22, 0, 22)
                knob.Position = current and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
                knob.BackgroundColor3 = Color3.new(1, 1, 1)
                knob.Parent = track

                local knobCorner = Instance.new("UICorner")
                knobCorner.CornerRadius = UDim.new(1, 0)
                knobCorner.Parent = knob

                local function SetState(val)
                    current = val
                    MacUI.Tween(track, {Time = 0.22}, {BackgroundColor3 = val and theme.Accent or theme.TertiaryBackground})
                    MacUI.Tween(knob, {Time = 0.22, EasingStyle = Enum.EasingStyle.Quint}, {
                        Position = val and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
                    })
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback, val)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                    MacUI.Config.Data[opts.Name] = val
                end

                TrackConnection(track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        SetState(not current)
                    end
                end))

                table.insert(Window.Elements, {Type = "Toggle", Name = opts.Name, Object = row})
                return {Set = SetState, Get = function() return current end}
            end

            -- Slider
            function Section:CreateSlider(opts)
                opts = opts or {}
                local min, max = opts.Range[1] or 0, opts.Range[2] or 100
                local increment = opts.Increment or 1
                local current = opts.CurrentValue or min

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 52)
                row.BackgroundTransparency = 1
                row.Parent = sectionContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.7, 0, 0, 20)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Slider"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local valueLbl = Instance.new("TextLabel")
                valueLbl.Size = UDim2.new(0.3, 0, 0, 20)
                valueLbl.Position = UDim2.new(0.7, 0, 0, 0)
                valueLbl.BackgroundTransparency = 1
                valueLbl.Text = tostring(current)
                valueLbl.TextColor3 = theme.SecondaryText
                valueLbl.Font = Enum.Font.Gotham
                valueLbl.TextSize = 13
                valueLbl.TextXAlignment = Enum.TextXAlignment.Right
                valueLbl.Parent = row

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, 0, 0, 6)
                track.Position = UDim2.new(0, 0, 0, 34)
                track.BackgroundColor3 = theme.TertiaryBackground
                track.Parent = row

                local trackCorner = Instance.new("UICorner")
                trackCorner.CornerRadius = UDim.new(1, 0)
                trackCorner.Parent = track

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
                fill.BackgroundColor3 = theme.Accent
                fill.Parent = track

                local fillCorner = Instance.new("UICorner")
                fillCorner.CornerRadius = UDim.new(1, 0)
                fillCorner.Parent = fill

                local knob = Instance.new("Frame")
                knob.Size = UDim2.new(0, 16, 0, 16)
                knob.Position = UDim2.new((current - min) / (max - min), -8, 0.5, -8)
                knob.BackgroundColor3 = Color3.new(1, 1, 1)
                knob.Parent = track

                local knobCorner = Instance.new("UICorner")
                knobCorner.CornerRadius = UDim.new(1, 0)
                knobCorner.Parent = knob

                local sliding = false
                local function Update(val)
                    val = math.clamp(math.floor(val / increment + 0.5) * increment, min, max)
                    current = val
                    local alpha = (val - min) / (max - min)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    knob.Position = UDim2.new(alpha, -8, 0.5, -8)
                    valueLbl.Text = tostring(val)
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback, val)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                    MacUI.Config.Data[opts.Name] = val
                end

                TrackConnection(track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                    end
                end))
                TrackConnection(UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        Update(min + rel * (max - min))
                    end
                end))
                TrackConnection(UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end))

                table.insert(Window.Elements, {Type = "Slider", Name = opts.Name, Object = row})
                return {Set = Update, Get = function() return current end}
            end

            -- Dropdown
            function Section:CreateDropdown(opts)
                opts = opts or {}
                local options = opts.Options or {}
                local current = opts.CurrentOption or options[1]

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 38)
                row.BackgroundTransparency = 1
                row.Parent = sectionContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.4, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Dropdown"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local dropBtn = Instance.new("TextButton")
                dropBtn.Size = UDim2.new(0.55, 0, 0, 30)
                dropBtn.Position = UDim2.new(0.45, 0, 0.5, -15)
                dropBtn.BackgroundColor3 = theme.TertiaryBackground
                dropBtn.BackgroundTransparency = 0.3
                dropBtn.Text = current
                dropBtn.TextColor3 = theme.Text
                dropBtn.Font = Enum.Font.Gotham
                dropBtn.TextSize = 13
                dropBtn.AutoButtonColor = false
                dropBtn.Parent = row

                local dropCorner = Instance.new("UICorner")
                dropCorner.CornerRadius = UDim.new(0, 8)
                dropCorner.Parent = dropBtn

                local open = false
                local listFrame
                TrackConnection(dropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        listFrame = Instance.new("Frame")
                        listFrame.Size = UDim2.new(0.55, 0, 0, #options * 30)
                        listFrame.Position = UDim2.new(0.45, 0, 1, 4)
                        listFrame.BackgroundColor3 = theme.SecondaryBackground
                        listFrame.ZIndex = 50
                        listFrame.Parent = row
                        local lc = Instance.new("UICorner")
                        lc.CornerRadius = UDim.new(0, 8)
                        lc.Parent = listFrame
                        local ls = Instance.new("UIStroke")
                        ls.Color = theme.Border
                        ls.Transparency = 0.5
                        ls.Parent = listFrame

                        for i, opt in ipairs(options) do
                            local item = Instance.new("TextButton")
                            item.Size = UDim2.new(1, 0, 0, 30)
                            item.Position = UDim2.new(0, 0, 0, (i-1)*30)
                            item.BackgroundTransparency = 1
                            item.Text = opt
                            item.TextColor3 = theme.Text
                            item.Font = Enum.Font.Gotham
                            item.TextSize = 13
                            item.ZIndex = 51
                            item.Parent = listFrame
                            TrackConnection(item.MouseButton1Click:Connect(function()
                                current = opt
                                dropBtn.Text = opt
                                listFrame:Destroy()
                                open = false
                                if opts.Callback then
                                    local ok, err = pcall(opts.Callback, opt)
                                    if not ok then warn("[MacUI] Callback error:", err) end
                                end
                                MacUI.Config.Data[opts.Name] = opt
                            end))
                        end
                    else
                        if listFrame then listFrame:Destroy() end
                    end
                end))

                table.insert(Window.Elements, {Type = "Dropdown", Name = opts.Name, Object = row})
                return {Set = function(v) current = v; dropBtn.Text = v end}
            end

            -- Input
            function Section:CreateInput(opts)
                opts = opts or {}
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 38)
                row.BackgroundTransparency = 1
                row.Parent = sectionContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.35, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Input"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.6, 0, 0, 30)
                box.Position = UDim2.new(0.38, 0, 0.5, -15)
                box.BackgroundColor3 = theme.TertiaryBackground
                box.BackgroundTransparency = 0.3
                box.Text = ""
                box.PlaceholderText = opts.PlaceholderText or "Enter text..."
                box.TextColor3 = theme.Text
                box.PlaceholderColor3 = theme.SecondaryText
                box.Font = Enum.Font.Gotham
                box.TextSize = 13
                box.ClearTextOnFocus = false
                box.Parent = row

                local boxCorner = Instance.new("UICorner")
                boxCorner.CornerRadius = UDim.new(0, 8)
                boxCorner.Parent = box

                TrackConnection(box.FocusLost:Connect(function()
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback, box.Text)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                end))

                table.insert(Window.Elements, {Type = "Input", Name = opts.Name, Object = row})
                return box
            end

            -- Label
            function Section:CreateLabel(opts)
                opts = opts or {}
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 0, 24)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Label"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = sectionContent
                return lbl
            end

            -- Paragraph
            function Section:CreateParagraph(opts)
                opts = opts or {}
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, 0)
                frame.BackgroundTransparency = 1
                frame.AutomaticSize = Enum.AutomaticSize.Y
                frame.Parent = sectionContent

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0, 20)
                title.BackgroundTransparency = 1
                title.Text = opts.Title or ""
                title.TextColor3 = theme.Text
                title.Font = Enum.Font.GothamMedium
                title.TextSize = 14
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = frame

                local contentLbl = Instance.new("TextLabel")
                contentLbl.Size = UDim2.new(1, 0, 0, 0)
                contentLbl.Position = UDim2.new(0, 0, 0, 24)
                contentLbl.BackgroundTransparency = 1
                contentLbl.Text = opts.Content or ""
                contentLbl.TextColor3 = theme.SecondaryText
                contentLbl.Font = Enum.Font.Gotham
                contentLbl.TextSize = 13
                contentLbl.TextXAlignment = Enum.TextXAlignment.Left
                contentLbl.TextWrapped = true
                contentLbl.AutomaticSize = Enum.AutomaticSize.Y
                contentLbl.Parent = frame
                return frame
            end

            -- Keybind
            function Section:CreateKeybind(opts)
                opts = opts or {}
                local current = opts.CurrentKeybind or Enum.KeyCode.RightShift
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 38)
                row.BackgroundTransparency = 1
                row.Parent = sectionContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.6, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Keybind"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local keyBtn = Instance.new("TextButton")
                keyBtn.Size = UDim2.new(0, 90, 0, 28)
                keyBtn.Position = UDim2.new(1, -90, 0.5, -14)
                keyBtn.BackgroundColor3 = theme.TertiaryBackground
                keyBtn.BackgroundTransparency = 0.3
                keyBtn.Text = current.Name
                keyBtn.TextColor3 = theme.Text
                keyBtn.Font = Enum.Font.Gotham
                keyBtn.TextSize = 12
                keyBtn.AutoButtonColor = false
                keyBtn.Parent = row

                local kc = Instance.new("UICorner")
                kc.CornerRadius = UDim.new(0, 6)
                kc.Parent = keyBtn

                local listening = false
                TrackConnection(keyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    keyBtn.Text = "..."
                end))
                TrackConnection(UserInputService.InputBegan:Connect(function(input, gp)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        current = input.KeyCode
                        keyBtn.Text = current.Name
                        listening = false
                        MacUI.Config.Data[opts.Name] = current.Name
                    end
                    if not gp and input.KeyCode == current and opts.Callback then
                        local ok, err = pcall(opts.Callback)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                end))

                table.insert(Window.Elements, {Type = "Keybind", Name = opts.Name, Object = row})
                return {Get = function() return current end}
            end

            -- Color Picker (simplified cycle)
            function Section:CreateColorPicker(opts)
                opts = opts or {}
                local current = opts.Color or Color3.fromRGB(0, 122, 255)
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 38)
                row.BackgroundTransparency = 1
                row.Parent = sectionContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.6, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Color"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local swatch = Instance.new("TextButton")
                swatch.Size = UDim2.new(0, 36, 0, 24)
                swatch.Position = UDim2.new(1, -36, 0.5, -12)
                swatch.BackgroundColor3 = current
                swatch.Text = ""
                swatch.AutoButtonColor = false
                swatch.Parent = row

                local sc = Instance.new("UICorner")
                sc.CornerRadius = UDim.new(0, 6)
                sc.Parent = swatch

                local colors = {
                    Color3.fromRGB(0, 122, 255),
                    Color3.fromRGB(52, 199, 89),
                    Color3.fromRGB(255, 59, 48),
                    Color3.fromRGB(175, 82, 222),
                    Color3.fromRGB(255, 149, 0)
                }
                local idx = 1
                TrackConnection(swatch.MouseButton1Click:Connect(function()
                    idx = idx % #colors + 1
                    current = colors[idx]
                    swatch.BackgroundColor3 = current
                    MacUI.PulseScale(swatch, 1.15, 0.2)
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback, current)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                end))

                table.insert(Window.Elements, {Type = "ColorPicker", Name = opts.Name, Object = row})
                return {Set = function(c) current = c; swatch.BackgroundColor3 = c end}
            end

            -- Segmented Control
            function Section:CreateSegmentedControl(opts)
                opts = opts or {}
                local options = opts.Options or {"One", "Two"}
                local current = opts.Default or options[1]

                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, 34)
                frame.BackgroundColor3 = theme.TertiaryBackground
                frame.BackgroundTransparency = 0.4
                frame.Parent = sectionContent

                local fc = Instance.new("UICorner")
                fc.CornerRadius = UDim.new(0, 8)
                fc.Parent = frame

                local buttons = {}
                local width = 1 / #options
                for i, opt in ipairs(options) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(width, -4, 1, -4)
                    b.Position = UDim2.new(width * (i-1), 2, 0, 2)
                    b.BackgroundColor3 = (opt == current) and theme.Accent or Color3.new(0,0,0)
                    b.BackgroundTransparency = (opt == current) and 0.2 or 1
                    b.Text = opt
                    b.TextColor3 = theme.Text
                    b.Font = Enum.Font.Gotham
                    b.TextSize = 13
                    b.AutoButtonColor = false
                    b.Parent = frame
                    local bc = Instance.new("UICorner")
                    bc.CornerRadius = UDim.new(0, 6)
                    bc.Parent = b
                    buttons[opt] = b

                    TrackConnection(b.MouseButton1Click:Connect(function()
                        current = opt
                        for name, btn in pairs(buttons) do
                            btn.BackgroundTransparency = (name == opt) and 0.2 or 1
                            btn.BackgroundColor3 = (name == opt) and theme.Accent or Color3.new(0,0,0)
                        end
                        if opts.Callback then
                            local ok, err = pcall(opts.Callback, opt)
                            if not ok then warn("[MacUI] Callback error:", err) end
                        end
                    end))
                end
                return {Get = function() return current end}
            end

            table.insert(Tab.Sections, Section)
            return Section
        end

        Window.Tabs[tabName] = Tab
        table.insert(Window.TabOrder, Tab)
        if not Window.CurrentTab then
            SelectTab()
        end
        return Tab
    end

    function Window:CreateSearch()
        local searchFrame = CreateGlassFrame(window, {Radius = 10, Transparency = 0.1})
        searchFrame.Size = UDim2.new(0, 280, 0, 36)
        searchFrame.Position = UDim2.new(1, -300, 0, 4)
        searchFrame.Visible = false
        searchFrame.ZIndex = 50

        local searchBase = GetGlassBase(searchFrame)
        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(1, -12, 1, -8)
        searchBox.Position = UDim2.new(0, 6, 0, 4)
        searchBox.BackgroundTransparency = 1
        searchBox.Text = ""
        searchBox.PlaceholderText = "Search..."
        searchBox.TextColor3 = theme.Text
        searchBox.PlaceholderColor3 = theme.SecondaryText
        searchBox.Font = Enum.Font.Gotham
        searchBox.TextSize = 14
        searchBox.Parent = searchBase

        TrackConnection(searchBtn.MouseButton1Click:Connect(function()
            searchFrame.Visible = not searchFrame.Visible
            if searchFrame.Visible then searchBox:CaptureFocus() end
        end))

        TrackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local query = string.lower(searchBox.Text)
            for _, el in ipairs(Window.Elements) do
                if el.Object and el.Object.Parent then
                    local match = query == "" or string.find(string.lower(el.Name or ""), query)
                    el.Object.Visible = match and true or false
                end
            end
        end))
    end

    -- Opening animation
    local function OpenWindow()
        local winBase = GetGlassBase(windowContainer)
        windowContainer.Size = UDim2.new(0, 0, 0, 0)
        if winBase then
            winBase.BackgroundTransparency = 1
        end
        MacUI.Tween(windowContainer, {Time = 0.45, EasingStyle = Enum.EasingStyle.Quint}, {
            Size = size
        })
        if winBase then
            MacUI.Tween(winBase, {Time = 0.4}, {
                BackgroundTransparency = acrylic and MacUI.GlassStyle.Transparency or 0.06
            })
        end
    end

    if showBoot then
        self:PlayBootSequence({
            Duration = 2.6,
            OnComplete = OpenWindow
        })
    else
        OpenWindow()
    end

    table.insert(self.Windows, Window)
    return Window
end

return MacUI
